#!/bin/bash
# install.sh
# Complete macOS system setup from dotfiles

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================"
echo "  macOS Dotfiles Setup"
echo "======================================"
echo ""
echo "This script will set up your entire development environment."
echo ""

# 1. Check and install Homebrew
echo "Step 1: Checking Homebrew..."
if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "✓ Homebrew already installed"
fi

echo ""

# 2. Install stow (needed before Brewfile for symlinking)
echo "Step 2: Installing stow..."
brew install stow
echo "✓ Stow installed"

echo ""

# 3. Stow dotfiles
echo "Step 3: Symlinking dotfiles with stow..."

# Backup existing files if they exist and aren't symlinks
backup_dir="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

for file in .zshrc .zprofile .p10k.zsh .wezterm.lua .gitconfig; do
    if [[ -f "$HOME/$file" ]] && [[ ! -L "$HOME/$file" ]]; then
        echo "Backing up existing $file to $backup_dir"
        mv "$HOME/$file" "$backup_dir/"
    fi
done

if [[ -d "$HOME/.config" ]] && [[ ! -L "$HOME/.config" ]]; then
    echo "Backing up existing .config directory to $backup_dir"
    cp -r "$HOME/.config" "$backup_dir/"
fi

cd "$DOTFILES_DIR"
echo ""
echo "Unstowing existing dotfiles..."
stow -D . 2>/dev/null || true

echo ""
echo "Stowing dotfiles..."
stow --adopt . 2>/dev/null || stow .

echo "✓ Dotfiles symlinked"

# Create SSH sockets directory for connection multiplexing
mkdir -p "$HOME/.ssh/sockets"

echo ""

# 4. Install Homebrew packages via Brewfile
echo "Step 4: Installing Homebrew packages from Brewfile..."

# Homebrew refuses to load formulae from third-party taps until they are
# trusted, and both borders and sketchybar come from this one. Without this the
# bundle below fails outright.
brew trust FelixKratz/formulae

brew bundle --file="$DOTFILES_DIR/Brewfile"
echo "✓ Brewfile packages installed"

echo ""

# 5. Setup language runtimes and widgets
echo "Step 5: Setting up language runtimes and widgets..."

# Setup NVM directory
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

# Install latest LTS Node via NVM
echo "Installing Node.js LTS via NVM..."
nvm install --lts
nvm use --lts

# Build SbarLua, the Lua binding SketchyBar's config is written in.
echo "Building SbarLua..."
SBARLUA_SRC="$(mktemp -d)"
git clone --depth 1 https://github.com/FelixKratz/SbarLua.git "$SBARLUA_SRC/SbarLua"
make -C "$SBARLUA_SRC/SbarLua" install

# SbarLua builds its module against the Lua version it vendors. Load that module
# into a different Lua and the interpreter dies of SIGSEGV -- no error message,
# just an empty bar. Homebrew's lua currently matches, but it will move on
# eventually, so check here where the failure is still readable.
sbarlua_version="$(sed -n 's/^LUA_DIR=lua-\([0-9]*\.[0-9]*\).*/\1/p' \
    "$SBARLUA_SRC/SbarLua/makefile")"
system_version="$(lua -v 2>&1 | sed -n 's/^Lua \([0-9]*\.[0-9]*\).*/\1/p')"
if [[ "$sbarlua_version" != "$system_version" ]]; then
    echo "ERROR: SbarLua builds against Lua $sbarlua_version but lua is $system_version." >&2
    echo "       Loading the module would segfault and leave the bar empty." >&2
    echo "       Install a matching Lua before continuing." >&2
    exit 1
fi
rm -rf "$SBARLUA_SRC"
echo "✓ SbarLua built (Lua $system_version)"

# Build the C event providers that push cpu and network data into the bar.
# A silent failure here means those two widgets stay empty forever, so make it
# stop the install instead.
echo "Building SketchyBar event providers..."
if ! make -C "$DOTFILES_DIR/.config/sketchybar/helpers"; then
    echo "ERROR: failed to build helpers/event_providers." >&2
    echo "       The cpu and netstats widgets would stay empty." >&2
    exit 1
fi
echo "✓ Event providers built"

cd "$DOTFILES_DIR"

echo "✓ Language runtimes and widgets set up"

echo ""

# 6. Load Borders LaunchAgent and start SketchyBar
echo "Step 6: Setting up Borders and SketchyBar..."
launchctl unload "$HOME/Library/LaunchAgents/com.felixkratz.borders.plist" 2>/dev/null || true
launchctl load -w "$HOME/Library/LaunchAgents/com.felixkratz.borders.plist"
echo "✓ Borders LaunchAgent loaded (starts automatically at login)"

brew services restart sketchybar
echo "✓ SketchyBar started (restarts automatically at login)"

# Let the wifi widget show the network name.
#
# macOS 14+ redacts the SSID for processes without Location Services
# authorization, and it checks the calling binary rather than its parent, so
# granting sketchybar the permission would not help even if a CLI could hold it.
# This flag turns the redaction off instead. It survives reboots and only
# ipconfig honours it -- system_profiler and networksetup stay redacted.
#
# Note this lifts the redaction for every process on the machine, not just for
# sketchybar. Skipping it costs nothing but the network name: the widget falls
# back to showing the icon alone.
echo ""
echo "The wifi widget can show the network name, which macOS hides by default."
echo "Enabling it lifts that restriction system-wide and needs sudo."
read -r -p "Show the wifi network name? [y/N] " reply
if [[ $reply =~ ^[Yy]$ ]]; then
    if sudo ipconfig sethidewifiinfo 0; then
        echo "✓ Wifi network name enabled"
    else
        echo "! Could not enable it; the widget will show the icon only" >&2
    fi
else
    echo "Skipped, the wifi widget will show the icon only"
fi

echo ""

# 7. Switch git remote to SSH (if SSH keys exist)
if [[ -f "$HOME/.ssh/id_ed25519_github" ]]; then
    echo "Step 7: Switching git remote to SSH..."
    cd "$DOTFILES_DIR"
    current_remote=$(git remote get-url origin)

    if [[ $current_remote == https://* ]]; then
        repo_path=$(echo "$current_remote" | sed -E 's|https://github.com/(.+)|\1|' | sed 's|\.git$||')
        git remote set-url origin "git@github.com:${repo_path}.git"
        echo "✓ Git remote switched to SSH"
    else
        echo "✓ Git remote already using SSH"
    fi
else
    echo "Step 7: Skipping git remote switch (no SSH keys found)"
fi

echo ""
echo "======================================"
echo "  Setup Complete!"
echo "======================================"
echo ""

if [[ -d "$backup_dir" ]] && [[ -n "$(ls -A "$backup_dir" 2>/dev/null)" ]]; then
    echo "Your old dotfiles have been backed up to:"
    echo "  $backup_dir"
    echo ""
fi

echo "Restart your terminal to see changes"
echo ""

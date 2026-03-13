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

# Install simple-bar widget
echo "Installing simple-bar..."
WIDGETS_DIR="$HOME/Library/Application Support/Übersicht/widgets"
mkdir -p "$WIDGETS_DIR"
if [[ -d "$WIDGETS_DIR/simple-bar" ]]; then
    echo "simple-bar already installed, updating..."
    cd "$WIDGETS_DIR/simple-bar" && git pull
else
    git clone https://github.com/Jean-Tinland/simple-bar.git "$WIDGETS_DIR/simple-bar"
fi
cd "$DOTFILES_DIR"

echo "✓ Language runtimes and widgets set up"

echo ""

# 6. Load Borders LaunchAgent
echo "Step 6: Setting up Borders..."
launchctl unload "$HOME/Library/LaunchAgents/com.felixkratz.borders.plist" 2>/dev/null || true
launchctl load -w "$HOME/Library/LaunchAgents/com.felixkratz.borders.plist"
echo "✓ Borders LaunchAgent loaded (starts automatically at login)"
echo ""
echo "Note: Enable 'Open at Login' for Übersicht via its menu bar icon"

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

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

# Function to ask yes/no questions
ask() {
    local prompt default reply

    if [[ ${2:-} = 'Y' ]]; then
        prompt='Y/n'
        default='Y'
    elif [[ ${2:-} = 'N' ]]; then
        prompt='y/N'
        default='N'
    else
        prompt='y/n'
        default=''
    fi

    while true; do
        echo -n "$1 [$prompt] "
        read -r reply </dev/tty

        if [[ -z $reply ]]; then
            reply=$default
        fi

        case "$reply" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
    done
}

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

# 2. Install essential tools
echo "Step 2: Installing essential tools..."
brew install stow

echo ""

# 3. SSH Setup (with user confirmation)
if ask "Do you want to set up SSH keys from Bitwarden?" Y; then
    echo ""
    echo "Step 3: Setting up SSH keys from Bitwarden..."
    
    # Install Bitwarden CLI if needed
    if ! command -v bw &> /dev/null; then
        echo "Installing Bitwarden CLI..."
        brew install bitwarden-cli
    fi
    
    # Install jq if needed
    if ! command -v jq &> /dev/null; then
        echo "Installing jq..."
        brew install jq
    fi
    
    # Run SSH bootstrap
    "$DOTFILES_DIR/bootstrap-ssh.sh"
else
    echo ""
    echo "Skipping SSH setup. You can run './bootstrap-ssh.sh' later."
fi

echo ""

# 4. Stow dotfiles
echo "Step 4: Symlinking dotfiles with stow..."

# Backup existing files if they exist and aren't symlinks
backup_dir="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

# Common dotfiles that might exist
for file in .zshrc .zprofile .p10k.zsh .wezterm.lua; do
    if [[ -f "$HOME/$file" ]] && [[ ! -L "$HOME/$file" ]]; then
        echo "Backing up existing $file to $backup_dir"
        mv "$HOME/$file" "$backup_dir/"
    fi
done

# Backup .config directory if it exists and isn't a symlink
if [[ -d "$HOME/.config" ]] && [[ ! -L "$HOME/.config" ]]; then
    echo "Backing up existing .config directory to $backup_dir"
    cp -r "$HOME/.config" "$backup_dir/"
fi

# Unstow first to clean up any existing symlinks
cd "$DOTFILES_DIR"
echo ""
echo "Unstowing existing dotfiles..."
stow -D . 2>/dev/null || true

# Stow all dotfiles
echo ""
echo "Stowing dotfiles..."
stow --adopt . 2>/dev/null || stow .

echo "✓ Dotfiles symlinked"

echo ""

# 5. Install Homebrew packages
echo "Step 5: Installing Homebrew packages..."

# Core development tools
echo "Installing core development tools..."
brew install git neovim ripgrep fd bat fzf eza tree-sitter jq lazygit zoxide yazi

# Terminal and shell tools
echo "Installing terminal tools..."
brew install powerlevel10k opencode

# Language runtimes
echo "Installing language runtimes..."
brew install node ruby

# Window management and UI
echo "Installing window management tools..."
brew install --cask nikitabobko/tap/aerospace

# SketchyBar
echo "Installing SketchyBar..."
brew tap FelixKratz/formulae
brew install sketchybar borders

# Install SbarLua (Lua plugin for SketchyBar)
echo "Installing SbarLua..."
git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && cd /tmp/SbarLua/ && make install && rm -rf /tmp/SbarLua/
cd "$DOTFILES_DIR"

# Fonts
echo "Installing fonts..."
brew install --cask font-sf-mono font-sf-pro font-symbols-only-nerd-font sf-symbols

# Optional: Install additional tools
if ask "Do you want to install additional development tools? (Docker, Python, etc.)" Y; then
    echo "Installing additional tools..."
    brew install --cask docker
fi

echo "✓ Homebrew packages installed"

echo ""

# 6. Setup sketchybar and borders
echo "Step 6: Setting up SketchyBar and Borders..."
echo ""
if ask "Do you want to start SketchyBar and Borders now?" Y; then
    # Kill any existing processes
    killall sketchybar 2>/dev/null || true
    killall borders 2>/dev/null || true
    
    # Start sketchybar service
    brew services start sketchybar
    
    # Start borders with Nord theme colors
    borders active_color=0xff88c0d0 inactive_color=0xff4c566a &
    
    echo "✓ SketchyBar started"
    echo "✓ Borders started (active: Nord cyan, inactive: Nord gray)"
    echo ""
    echo "⚠️  IMPORTANT: SketchyBar needs permissions!"
    echo "You may see a permission dialog - please grant access."
    echo ""
    echo "If you see a gray bar with no items:"
    echo "1. Go to System Settings → Privacy & Security → Accessibility"
    echo "2. Click the '+' button and add: /opt/homebrew/opt/sketchybar/bin/sketchybar"
    echo "3. Enable the checkbox for sketchybar"
    echo "4. Run: brew services restart sketchybar"
else
    echo "To start SketchyBar later, run: brew services start sketchybar"
    echo "To start Borders later, run: borders active_color=0xff88c0d0 inactive_color=0xff4c566a &"
fi

echo ""

# 7. Switch git remote to SSH (if SSH was set up)
if [[ -f "$HOME/.ssh/id_ed25519_github" ]]; then
    echo "Step 7: Switching git remote to SSH..."
    cd "$DOTFILES_DIR"
    current_remote=$(git remote get-url origin)
    
    if [[ $current_remote == https://* ]]; then
        # Extract username/repo from HTTPS URL
        repo_path=$(echo "$current_remote" | sed -E 's|https://github.com/(.+)|\1|' | sed 's|\.git$||')
        git remote set-url origin "git@github.com:${repo_path}.git"
        echo "✓ Git remote switched to SSH"
    else
        echo "✓ Git remote already using SSH"
    fi
else
    echo "Step 7: Skipping git remote switch (SSH keys not set up)"
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

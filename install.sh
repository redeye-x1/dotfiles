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
brew install git neovim ripgrep fd bat fzf eza tree-sitter jq lazygit lazydocker zoxide yazi

# Terminal and shell tools
echo "Installing terminal tools..."
brew install powerlevel10k opencode
brew install --cask wezterm

# Language runtimes
echo "Installing language runtimes..."
brew install nvm ruby

# Setup NVM directory
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

# Install latest LTS Node via NVM
echo "Installing Node.js LTS via NVM..."
nvm install --lts
nvm use --lts

# Window management and UI
echo "Installing window management tools..."
brew install --cask nikitabobko/tap/aerospace

# Borders (window borders)
echo "Installing Borders..."
brew tap FelixKratz/formulae
brew install borders

# Ubersicht and simple-bar (status bar)
echo "Installing Ubersicht..."
brew install --cask ubersicht

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

# Container tools
echo "Installing container tools..."
brew install podman

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

# 6. Setup simple-bar and borders
echo "Step 6: Setting up simple-bar and Borders..."
echo ""
if ask "Do you want to start Ubersicht (simple-bar) and Borders now?" Y; then
    # Kill any existing processes
    killall Übersicht 2>/dev/null || true
    killall borders 2>/dev/null || true
    
    # Start Ubersicht (simple-bar runs as a widget inside it)
    open -a "Übersicht"
    
    # Start borders with Nord theme colors
    borders active_color=0xff88c0d0 inactive_color=0xff4c566a &
    
    echo "✓ Ubersicht started (simple-bar widget)"
    echo "✓ Borders started (active: Nord cyan, inactive: Nord gray)"
    echo ""
    echo "⚠️  IMPORTANT: Ubersicht needs permissions!"
    echo "You may see a permission dialog - please grant access."
    echo ""
    echo "If simple-bar doesn't appear:"
    echo "1. Go to System Settings → Privacy & Security → Accessibility"
    echo "2. Enable the checkbox for Ubersicht"
    echo "3. Restart Ubersicht from the menu bar icon"
else
    echo "To start Ubersicht later, run: open -a 'Übersicht'"
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

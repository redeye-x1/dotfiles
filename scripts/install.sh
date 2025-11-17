#!/bin/bash
# install.sh
# Complete macOS system setup from dotfiles

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == 'arm64' ]]; then
        echo "Adding Homebrew to PATH..."
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
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
    "$DOTFILES_DIR/scripts/bootstrap-ssh.sh"
else
    echo ""
    echo "Skipping SSH setup. You can run './scripts/bootstrap-ssh.sh' later."
fi

echo ""

# 4. Stow dotfiles
echo "Step 4: Symlinking dotfiles with stow..."

# Backup existing files if they exist and aren't symlinks
backup_dir="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$backup_dir"

# Files that will be stowed from shell/
for file in .zshrc .zprofile .p10k.zsh; do
    if [[ -f "$HOME/$file" ]] && [[ ! -L "$HOME/$file" ]]; then
        echo "Backing up existing $file to $backup_dir"
        mv "$HOME/$file" "$backup_dir/"
    fi
done

# Files that will be stowed from wezterm/
if [[ -f "$HOME/.wezterm.lua" ]] && [[ ! -L "$HOME/.wezterm.lua" ]]; then
    echo "Backing up existing .wezterm.lua to $backup_dir"
    mv "$HOME/.wezterm.lua" "$backup_dir/"
fi

# Unstow existing packages first to avoid conflicts
cd "$DOTFILES_DIR"
echo ""
echo "Unstowing existing packages..."
for package in .config shell wezterm ssh scripts opencode; do
    if [[ -d "$package" ]]; then
        echo "  Unstowing $package..."
        stow -D "$package" 2>/dev/null || true
    fi
done

# Stow all dotfiles packages
echo ""
echo "Stowing packages..."
for package in .config shell wezterm ssh scripts opencode; do
    if [[ -d "$package" ]]; then
        echo "  Stowing $package..."
        stow "$package" 2>/dev/null || echo "    (Skipping $package - conflicts or empty)"
    fi
done

echo "✓ Dotfiles symlinked"

echo ""

# 5. Install Homebrew packages
echo "Step 5: Installing Homebrew packages..."

# Core development tools
echo "Installing core development tools..."
brew install git neovim ripgrep fd bat fzf

# Terminal and shell tools
echo "Installing terminal tools..."
brew install wezterm zsh-autosuggestions zsh-syntax-highlighting yazi opencode

# Powerlevel10k theme
echo "Installing Powerlevel10k..."
brew install powerlevel10k

# Window management and UI
echo "Installing window management tools..."
brew install --cask nikitabobko/tap/aerospace

# SketchyBar
echo "Installing SketchyBar..."
brew tap FelixKratz/formulae
brew install sketchybar
brew install font-sketchybar-app-font

# Optional: Install additional tools
if ask "Do you want to install additional development tools? (Node.js, Python, Docker, etc.)" Y; then
    echo "Installing additional tools..."
    brew install node python@3.11 docker
fi

echo "✓ Homebrew packages installed"

echo ""

# 6. Setup sketchybar
echo "Step 6: Setting up SketchyBar..."
if ask "Do you want to start SketchyBar now?" Y; then
    brew services start sketchybar
    echo "✓ SketchyBar started"
else
    echo "To start SketchyBar later, run: brew services start sketchybar"
fi

echo ""

# 7. Setup default shell
echo "Step 7: Setting up Zsh..."
if [[ "$SHELL" != "$(which zsh)" ]]; then
    if ask "Do you want to set Zsh as your default shell?" Y; then
        chsh -s "$(which zsh)"
        echo "✓ Default shell changed to Zsh"
    fi
else
    echo "✓ Zsh is already your default shell"
fi

echo ""

# 8. Switch git remote to SSH (if SSH was set up)
if [[ -f "$HOME/.ssh/id_ed25519_github" ]]; then
    echo "Step 8: Switching git remote to SSH..."
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
    echo "Step 8: Skipping git remote switch (SSH keys not set up)"
fi

echo ""
echo "======================================"
echo "  Setup Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: source ~/.zshrc)"
echo "  2. Open a new terminal window to see your setup"
echo ""

if [[ -d "$backup_dir" ]] && [[ -n "$(ls -A "$backup_dir")" ]]; then
    echo "Your old dotfiles have been backed up to:"
    echo "  $backup_dir"
    echo ""
fi

echo "Enjoy your new setup! 🚀"

# Dotfiles

My personal macOS development environment setup with automated installation.

## Features

- **Automated Installation**: One command to set up everything
- **Secure SSH Key Management**: Store SSH keys securely in Bitwarden
- **Window Management**: AeroSpace for tiling window management
- **Status Bar**: Custom SketchyBar configuration
- **Terminal**: WezTerm with custom configuration
- **Shell**: Zsh with Powerlevel10k theme
- **Editor**: Neovim with extensive plugin configuration

## Quick Start

### Prerequisites

- macOS (tested on Apple Silicon, works on Intel too)
- Git (pre-installed on macOS)
- A Bitwarden account (for SSH key management)

### Installation

1. **Clone this repository:**
   ```bash
   cd ~
   git clone https://github.com/yourusername/dotfiles.git
   cd dotfiles
   ```

2. **Run the install script:**
   ```bash
   ./install.sh
   ```

   The script will:
   - Install Homebrew (if not already installed)
   - Prompt you to set up SSH keys from Bitwarden
   - Install essential tools (stow, neovim, etc.)
   - Symlink all dotfiles to your home directory
   - Install development tools and applications
   - Set up SketchyBar and AeroSpace
   - Configure Zsh as your default shell

3. **Restart your terminal** to apply all changes

That's it! Your entire development environment is now set up.

## SSH Key Management

This setup uses **Bitwarden** to securely store and sync SSH keys across machines.

### First-Time Setup: Adding SSH Keys to Bitwarden

You only need to do this once. Your existing SSH keys need to be uploaded to Bitwarden.

**Important:** The bootstrap script requires a folder named **"SSH Keys"** in Bitwarden. All SSH keys must be stored as Secure Notes in this folder.

#### Option 1: Via Bitwarden Web Vault (Easiest)

1. Go to [your Bitwarden vault](https://vault.bitwarden.com) (the bootstrap script will ask which server you use)
2. **Create the "SSH Keys" folder** (required):
   - Click Settings → Folders
   - Click "New Folder"
   - Name it exactly: `SSH Keys`
3. **Add your SSH keys**:
   - Click "New Item" → "Secure Note"
   - **Name**: Whatever you want (e.g., `GitHub`, `Work Server`, `Personal VPS`)
   - **Folder**: Select "SSH Keys" (required!)
   - Copy your **private key** content:
     ```bash
     cat ~/.ssh/id_ed25519_yourkey
     ```
   - Paste the entire private key into the "Notes" field
   - Click "Save"
4. **Repeat for all your SSH keys** - add as many as you need!

#### Option 2: Via Bitwarden CLI

```bash
# Install Bitwarden CLI
brew install bitwarden-cli jq

# Set server if not using US (optional)
# bw config server https://vault.bitwarden.eu

# Login to Bitwarden
bw login

# Unlock vault
export BW_SESSION=$(bw unlock --raw)

# Create "SSH Keys" folder (required)
FOLDER_ID=$(bw get template folder | jq '.name = "SSH Keys"' | bw encode | bw create folder | jq -r '.id')

# Add your SSH keys (add as many as you need - these are just examples)
bw get template item | jq ".type = 2 | .secureNote.type = 0 | .name = \"GitHub\" | .folderId = \"$FOLDER_ID\" | .notes = \"$(cat ~/.ssh/id_ed25519_github)\"" | bw encode | bw create item

bw get template item | jq ".type = 2 | .secureNote.type = 0 | .name = \"Work Server\" | .folderId = \"$FOLDER_ID\" | .notes = \"$(cat ~/.ssh/id_ed25519_work)\"" | bw encode | bw create item
```

### How It Works: Auto-Discovery

The bootstrap script automatically discovers and downloads **ALL** SSH keys from the "SSH Keys" folder:

- **Item name** in Bitwarden → **Filename** on disk
- Item names are sanitized (lowercased, special characters removed)
- Downloaded to `~/.ssh/id_ed25519_{sanitized_name}`

**Examples:**
- `GitHub` → `~/.ssh/id_ed25519_github`
- `Work GitHub` → `~/.ssh/id_ed25519_work_github`
- `My Personal Server` → `~/.ssh/id_ed25519_my_personal_server`
- `Production DB` → `~/.ssh/id_ed25519_production_db`

**Benefits:**
- ✅ Add new SSH keys to Bitwarden folder → automatically downloaded on all machines
- ✅ No need to modify the bootstrap script
- ✅ Works with unlimited SSH keys
- ✅ Name your keys however you want

**Override Protection:**
If an SSH key file already exists locally, the script will ask if you want to override it.

### On New Machines

When you run `./install.sh` on a new machine, it will:
1. Ask which Bitwarden server you use (US .com [default], EU .eu, or custom)
2. Prompt for your Bitwarden email and master password
3. Automatically download all SSH keys from Bitwarden
4. Set correct permissions (600) on the private keys
5. Link your SSH config file

No manual SSH key generation needed!

## What Gets Installed

### CLI Tools
- **stow**: Dotfile symlink manager
- **neovim**: Modern Vim-based text editor
- **ripgrep**: Fast grep alternative
- **fd**: Fast find alternative
- **bat**: Cat with syntax highlighting
- **fzf**: Fuzzy finder

### Applications
- **WezTerm**: GPU-accelerated terminal emulator
- **AeroSpace**: Tiling window manager for macOS
- **SketchyBar**: Custom macOS menu bar

### Shell Setup
- **Zsh**: Modern shell with autosuggestions and syntax highlighting
- **Powerlevel10k**: Beautiful and fast Zsh theme

## Repository Structure

```
dotfiles/
├── .config/
│   ├── nvim/              # Neovim configuration
│   ├── sketchybar/        # SketchyBar configuration
│   └── aerospace/         # AeroSpace window manager config
├── .ssh/
│   └── config             # SSH configuration (safe to commit)
├── .zshrc                 # Zsh configuration
├── .zprofile              # Zsh profile
├── .wezterm.lua           # WezTerm terminal config
├── .p10k.zsh              # Powerlevel10k theme config
├── .gitignore             # Prevents committing SSH private keys
├── install.sh             # Main installation script
├── bootstrap-ssh.sh       # SSH key setup from Bitwarden
└── README.md              # This file
```

## How It Works

### Stow
This setup uses [GNU Stow](https://www.gnu.org/software/stow/) to manage dotfiles. Stow creates symlinks from this repository to your home directory.

For example:
- `~/dotfiles/.zshrc` → `~/.zshrc`
- `~/dotfiles/.config/nvim` → `~/.config/nvim`

This means you can edit files in your home directory, and changes are automatically tracked in the git repository.

### Security

**What's committed to git:**
- ✅ All configuration files
- ✅ SSH `config` file (contains no secrets)
- ✅ Installation scripts

**What's NEVER committed:**
- ❌ Private SSH keys (stored in Bitwarden)
- ❌ `known_hosts` files
- ❌ Any secrets or API keys

The `.gitignore` file ensures private keys are never accidentally committed.

## Customization

### Adding New SSH Keys

Adding a new SSH key is simple - no script modifications needed!

1. **Generate a new SSH key:**
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_newservice -C "your@email.com"
   ```

2. **Add it to Bitwarden:**
   - Go to your Bitwarden vault (vault.bitwarden.com or vault.bitwarden.eu)
   - Create a Secure Note with any name (e.g., `NewService`, `Production Server`, etc.)
   - **Important:** Put it in the "SSH Keys" folder
   - Paste the private key content in the Notes field
   - Save

3. **Update `ssh/.ssh/config`:** (optional)
   
   The SSH config file is a template with examples. Customize it for your needs:
   ```ssh-config
   Host newservice
     HostName example.com
     User youruser
     IdentityFile ~/.ssh/id_ed25519_newservice
     IdentitiesOnly yes
   ```
   
   Note: The `IdentityFile` path should match your Bitwarden item name (sanitized to lowercase with underscores).

4. **That's it!** The next time you run `./bootstrap-ssh.sh` (or `./install.sh` on a new machine), it will automatically discover and download your new key.

No script changes needed - the bootstrap script auto-discovers all keys from the "SSH Keys" folder!

### SSH Config Customization

The `ssh/.ssh/config` file is a **template** with examples and comments. It's stowed to `~/.ssh/config` on your machine.

**Customize it for your needs:**
- Uncomment and modify the examples
- Add your own hosts
- Configure global settings (connection keepalive, agent forwarding, etc.)
- Set up jump hosts, wildcards, and advanced patterns

The config file is safe to commit (contains no secrets) and will be synced across your machines via dotfiles.

### Work vs Personal GitHub Keys

The SSH config supports multiple GitHub accounts. To use separate keys for work and personal:

1. Generate separate keys and add to Bitwarden as `GitHub` and `Work GitHub` (in the "SSH Keys" folder)

2. Update `.ssh/config`:
   ```ssh-config
   # Personal GitHub
   Host github.com
     HostName github.com
     User git
     IdentityFile ~/.ssh/id_ed25519_github
     IdentitiesOnly yes

   # Work GitHub (use alias)
   Host github-work
     HostName github.com
     User git
     IdentityFile ~/.ssh/id_ed25519_work
     IdentitiesOnly yes
   ```

3. Clone work repos using the alias:
   ```bash
   git clone git@github-work:company/repo.git
   ```

## Manual Setup (Without Bitwarden)

If you don't want to use Bitwarden:

1. Run `./install.sh` and answer "No" when asked about SSH setup
2. Manually generate SSH keys:
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_github -C "your@email.com"
   ```
3. The SSH config will still work with your manually generated keys

## Updating

To update your dotfiles on any machine:

```bash
cd ~/dotfiles
git pull
stow . --restow
```

## Troubleshooting

### SSH Keys Not Working

1. Check if keys exist:
   ```bash
   ls -la ~/.ssh/
   ```

2. Check key permissions (should be 600):
   ```bash
   chmod 600 ~/.ssh/id_ed25519_*
   ```

3. Test SSH connection:
   ```bash
   ssh -T git@github.com
   ```

### Stow Conflicts

If stow reports conflicts, you may have existing files. Back them up:

```bash
mv ~/.zshrc ~/.zshrc.backup
cd ~/dotfiles
stow .
```

### Bitwarden Login Issues

If you have 2FA enabled on Bitwarden:

```bash
bw login --method 0  # For Authenticator app
# Or
bw login --method 1  # For Email
```

## Credits

- Neovim config based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
- SketchyBar inspired by various community configs
- Terminal and shell setup curated from best practices

## License

Feel free to use this configuration as inspiration for your own dotfiles!

## Contributing

This is a personal configuration, but if you find bugs or have suggestions, feel free to open an issue!

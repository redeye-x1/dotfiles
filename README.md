# Dotfiles

My personal macOS development environment setup with automated installation.

## Features

- **Automated Installation**: One command to set up everything via `install.sh` + declarative `Brewfile`
- **Window Management**: AeroSpace tiling window manager with SketchyBar status bar
- **Terminal**: WezTerm (GPU-accelerated) with workspace persistence, pane management, and quick-select
- **Shell**: Zsh with Powerlevel10k, autosuggestions, syntax highlighting, fuzzy finding, and smart directory jumping
- **Editor**: Neovim (Kickstart-based) with LSP, Telescope, Harpoon, and Nord theme
- **Git**: Productivity-focused `.gitconfig` with aliases, rebase workflow, and conflict memory
- **Theme**: Nord -- consistently applied across every tool

## Quick Start

### Prerequisites

- macOS (tested on Apple Silicon, works on Intel too)
- Git (pre-installed on macOS)

### Installation

1. **Clone this repository:**
   ```bash
   cd ~
   git clone https://github.com/redeye-x1/dotfiles.git
   cd dotfiles
   ```

2. **Run the install script:**
   ```bash
   ./install.sh
   ```

   The script will:
   - Install Homebrew (if not already installed)
   - Symlink all dotfiles via GNU Stow (existing files are backed up first)
   - Trust the `FelixKratz/formulae` tap and install everything in the `Brewfile`
   - Set up Node.js LTS via NVM
   - Build SbarLua (aborting if Homebrew's Lua doesn't match its version) and the SketchyBar event providers
   - Start SketchyBar and Borders
   - Ask whether the wifi widget may show the network name (needs sudo)
   - Switch this repo's remote to SSH if the GitHub key is present

3. **Restart your terminal** to apply all changes.

## Repository Structure

```
dotfiles/
├── .claude/
│   ├── CLAUDE.md          # Global Claude Code instructions
│   └── settings.json      # Claude Code settings, permissions, hooks
├── .t3/userdata/          # T3 Code settings, client settings and keybindings
├── .config/
│   ├── ccstatusline/      # Claude Code status line
│   ├── nvim/              # Neovim configuration (Kickstart + custom plugins)
│   ├── directories        # Machine-specific directory shortcuts (cddev, cddot, etc.)
│   ├── sketchybar/        # SketchyBar status bar (Lua + C event providers)
│   └── superfile/         # superfile (spf) file manager config + hotkeys
├── .ssh/
│   └── config             # SSH host configuration (multiplexed connections)
├── Library/LaunchAgents/  # Borders LaunchAgent (window borders at login)
├── docs/                  # Design specs and migrations (not stowed)
├── .zshrc                 # Zsh configuration (plugins, aliases, tools)
├── .zprofile              # Zsh profile (Homebrew init)
├── .p10k.zsh              # Powerlevel10k theme config
├── .wezterm.lua           # WezTerm terminal config (Nord theme, resurrect, quick-select)
├── .gitconfig             # Git aliases, rebase workflow, diff settings
├── .aerospace.toml        # AeroSpace tiling window manager
├── .stow-local-ignore     # Files excluded from stow symlinking
├── .gitignore             # Prevents committing SSH private keys
├── Brewfile               # Declarative Homebrew package list
├── install.sh             # Main installation script
└── README.md              # This file
```

## Shell Features

### Aliases

| Alias | Command | Purpose |
|---|---|---|
| `ls` | `eza -la --icons=always` | Enhanced file listing with icons |
| `wt` | `wezterm cli set-tab-title` | Quick tab title setting |
| `lg` | `lazygit` | Git TUI |
| `ld` | `lazydocker` | Docker TUI (OrbStack) |
| `reload` | `source ~/.zshrc` | Reload shell config |
| `..` / `...` | `cd ..` / `cd ../..` | Go up one or two directories |
| `ports` | `lsof -iTCP -sTCP:LISTEN -P -n` | List listening TCP ports |
| `ip` | `curl -s ifconfig.me` | Show public IP |
| `hs` | `history 1` | Full shell history |
| `cc` | `claude --dangerously-skip-permissions` | Claude Code without permission prompts |
| `ctg` | `claude --channels plugin:telegram@… --dangerously-skip-permissions` | Claude Code with the Telegram channel |
| `cddev` | `cd ~/development` | Jump to dev directory |
| `cddot` | `cd ~/dotfiles` | Jump to dotfiles |

`spf` wraps superfile so it uses the config in this repo and leaves the shell in the last directory when you quit.

The `cd<name>` functions come from `~/.config/directories` (`name=/path` per line). That file is gitignored, so each machine keeps its own.

### History

50,000 entries, shared live across all open terminals, older duplicates dropped. Commands starting with a space are not saved.

### Zoxide -- Smart Directory Jumping

Zoxide learns which directories you visit and lets you jump with partial matches:

```bash
z dev        # jumps to ~/development
z dot        # jumps to ~/dotfiles
z proj       # jumps to whichever "proj" directory you visit most
zi           # interactive fuzzy picker of all known directories
```

It gets smarter over time. After a week it feels like teleportation.

### fzf -- Fuzzy Finding

| Keybinding | Action |
|---|---|
| `Ctrl+R` | Fuzzy search command history (replaces default reverse search) |
| `Ctrl+T` | Fuzzy file finder -- inserts selected path at cursor |
| `Alt+C` | Fuzzy cd -- search and jump into subdirectories |

All styled in Nord colors.

### Zsh Plugins

- **zsh-autosuggestions**: Ghost text suggestions from history as you type. Press **right arrow** to accept.
- **zsh-syntax-highlighting**: Valid commands appear green, invalid appear red. Catches typos before you hit enter.
- **zsh-history-substring-search**: Type a partial command, then **Up/Down arrows** to cycle only matching history entries.
- **zsh-completions**: Extended tab completions for git, brew, docker, and hundreds of other tools.

### bat -- Syntax-Highlighted Help

- `man git` renders with full syntax highlighting
- Any `--help` output is automatically piped through bat

## Git Configuration

### Aliases

| Command | What it does |
|---|---|
| `git st` | Short status with branch info |
| `git lg` | Pretty one-line graph log (last 20 commits) |
| `git co <branch>` | Checkout branch |
| `git sw <branch>` | Switch to branch |
| `git sc <branch>` | Create and switch to new branch |
| `git cm "msg"` | Commit with message |
| `git ca` | Amend last commit, keep message |
| `git undo` | Soft-reset last commit (keeps changes staged) |
| `git unstage` | Unstage all files |
| `git wip` | Quick "work in progress" commit of everything |
| `git gone` | List branches whose remote tracking branch is deleted |
| `git prune-merged` | Delete those dead branches |

### Workflow Settings

| Setting | Effect |
|---|---|
| `pull.rebase = true` | `git pull` rebases instead of creating merge commits |
| `push.autoSetupRemote = true` | First push auto-sets upstream -- no more `-u origin branch` |
| `rebase.autoStash = true` | Rebase auto-stashes dirty changes and re-applies after |
| `rerere.enabled = true` | Git remembers conflict resolutions and auto-applies them next time |
| `merge.conflictstyle = zdiff3` | Conflict markers include the original base version for context |
| `diff.algorithm = histogram` | Better diff output, especially for moved code |
| `fetch.prune = true` | Auto-removes stale remote-tracking branches on fetch |
| `branch.sort = -committerdate` | Branches sorted by most recently committed |
| `pushInsteadOf` for GitHub | Pushes to `https://github.com/` URLs go over SSH; fetches stay on HTTPS so Homebrew and plugin clones work before the keys exist |

### Multiple GitHub Accounts

Use `includeIf` in `.gitconfig` to auto-switch identity based on directory:

```gitconfig
[includeIf "gitdir:~/work/"]
    path = ~/.gitconfig-work
```

## WezTerm

- **Theme**: Nord (custom color palette)
- **Font**: JetBrainsMono Nerd Font, size 16
- **Renderer**: WebGPU at 120 FPS
- **Session persistence**: Workspaces auto-save every 15 minutes via resurrect plugin

### Keybindings

| Binding | Action |
|---|---|
| `Ctrl+Cmd + h/j/k/l` | Navigate panes (vim-style) |
| `Ctrl+Shift+Cmd + H` | Split pane horizontally |
| `Ctrl+Shift+Cmd + V` | Split pane vertically |
| `Ctrl+Shift+Cmd + W` | Close current pane |
| `Cmd+Shift+P` | Command palette |
| `Cmd+Shift+S` | Save workspace (with name prompt) |
| `Cmd+S` | Load workspace (fuzzy finder) |
| `Cmd+Shift+D` | Delete saved workspace |
| `Cmd+Shift+Space` | Quick-select mode (URLs, paths, hashes, IPs, UUIDs) |

### Right Status Bar

Shows current working directory, git branch, and git status (staged/modified/untracked counts) in Nord colors.

## AeroSpace (Window Manager)

**Modifier**: `Ctrl+Alt+Cmd` (Hyper key without Shift)

| Binding | Action |
|---|---|
| `Hyper + h/j/k/l` | Focus window left/down/up/right |
| `Hyper+Shift + h/j/k/l` | Move window left/down/up/right |
| `Hyper + 1-6` | Switch to workspace 1-6 |
| `Hyper+Shift + 1-6` | Move window to workspace 1-6 |
| `Hyper + Space` | Toggle floating/tiling |
| `Hyper + f` | Fullscreen |
| `Hyper + s` | Vertical accordion (stack) |
| `Hyper + t` | Tiles layout |
| `Hyper + e` | Horizontal accordion |
| `Hyper + r` | Enter resize mode (then h/j/k/l to resize, Enter/Esc to leave) |

Uses config version 2 with six persistent workspaces. Workspace, focus and new-window events trigger SketchyBar so the workspace app icons stay current.

## SketchyBar

Written in Lua via [SbarLua](https://github.com/FelixKratz/SbarLua). Left: AeroSpace workspaces with app icons and unread badges. Right: network, CPU, memory, battery, sound, mic, wifi, date/time. The CPU and network widgets are fed by small C event providers in `helpers/event_providers`, built by `install.sh`.

- **Lua version**: SbarLua builds against Lua 5.5. If Homebrew's `lua` moves to a different major.minor, the bar segfaults silently, so `install.sh` refuses to continue on a mismatch.
- **App icons**: `helpers/app_icons.lua` is generated from the `mappings/` directory of [sketchybar-app-font](https://github.com/kvndrsslr/sketchybar-app-font) at the tag the cask installs (currently v3.0.14). Regenerate it after a font upgrade. Put your own overrides in `helpers/app_icons_local.lua`.

## SSH Configuration

### Connection Multiplexing

SSH connections are multiplexed -- after the first connection to a host, subsequent connections reuse the same socket for 10 minutes. This makes `git push`, `git pull`, and repeated SSH commands near-instant (no handshake overhead).

Configured hosts are defined in `.ssh/config` with per-host identity files.

## Neovim

Kickstart-based configuration with lazy.nvim plugin manager. Leader key is **Space**.

### Key Plugins

Telescope (fuzzy finder), LSP (TypeScript, Lua, MDX), Treesitter (syntax highlighting), Harpoon (file bookmarks), Flash (motion), Neo-tree (file explorer), conform.nvim (formatting), gitsigns (git gutter), which-key (keybinding discovery).

### Key Keymaps

| Keymap | Action |
|---|---|
| `Space + sf` | Search files |
| `Space + sg` | Live grep |
| `Space + Space` | Find buffers |
| `Space + /` | Fuzzy search in current buffer |
| `gd` / `gr` | Go to definition / references |
| `Space + ca` | Code action |
| `Space + rn` | Rename symbol |
| `Space + f` | Format buffer |
| `\` | Toggle Neo-tree sidebar |
| `Space + 1-4` | Harpoon navigate to file 1-4 |

## Brewfile (Package Management)

Packages are managed declaratively via `Brewfile`:

```bash
brew bundle                    # install everything in Brewfile
brew bundle check              # see what's missing
brew bundle cleanup            # remove packages not in Brewfile
brew bundle dump --force       # regenerate Brewfile from installed packages
```

`borders` and `sketchybar` come from the `FelixKratz/formulae` tap, which Homebrew only loads after `brew trust FelixKratz/formulae`. `install.sh` does this for you.

## Claude Code

`~/.claude/CLAUDE.md` and `~/.claude/settings.json` are stowed from `.claude/`.

- Answers are in English. The `language: "German"` setting only sets the voice dictation language.
- Subagents run on Sonnet (`CLAUDE_CODE_SUBAGENT_MODEL`).
- Hooks report agent status to Orca. They do nothing when Orca isn't installed.
- The status line comes from `.config/ccstatusline/`.

## SSH Keys

Private keys are not part of this repo. On a new machine, copy them into `~/.ssh` by hand (`chmod 600`). Since `~/.ssh` is stowed, the files live in `~/dotfiles/.ssh`, where `.gitignore` keeps them out of git.

To add a key: `ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_newservice -C "your@email.com"`, then add a `Host` entry to `.ssh/config`.

## How Stow Works

[GNU Stow](https://www.gnu.org/software/stow/) creates symlinks from this repository to your home directory:

- `~/dotfiles/.zshrc` -> `~/.zshrc`
- `~/dotfiles/.config/nvim/` -> `~/.config/nvim/`

Edit files in either location -- changes are tracked in git automatically.

## Updating

```bash
cd ~/dotfiles
git pull
stow . --restow
brew bundle
```

Some changes need one-time manual steps on each Mac. Those live in
`docs/migrations/`. After a pull, the git hook lists the ones this Mac hasn't
applied yet, and Claude Code is told about them at session start. See
`docs/migrations/README.md`.

## Security

**Committed**: All configuration files, SSH `config` (no secrets), installation scripts.

**Never committed**: Private SSH keys, `known_hosts`, API keys, `.env` files.

## Credits

- Neovim config based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
- Nord theme by [Arctic Ice Studio](https://www.nordtheme.com/)
- Terminal and shell setup curated from best practices

# ── Core development tools ─────────────────────────────────────────
brew "git"
brew "neovim"
brew "ripgrep"
brew "fd"
brew "bat"
brew "fzf"
brew "eza"
brew "tree-sitter"
brew "jq"
brew "bats-core"
brew "lazygit"
brew "lazydocker"
brew "zoxide"
brew "yazi"
brew "superfile"
brew "stow"
brew "gh"
# .zshrc puts these on PATH ahead of the system versions
brew "unzip"
brew "python@3.12"

# ── Shell plugins ──────────────────────────────────────────────────
brew "powerlevel10k"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "zsh-history-substring-search"
brew "zsh-completions"

# ── Terminal ───────────────────────────────────────────────────────
cask "wezterm"
# The font .wezterm.lua asks for
cask "font-jetbrains-mono-nerd-font"

# ── Language runtimes ──────────────────────────────────────────────
brew "nvm"
brew "ruby"

# ── Window management and UI ──────────────────────────────────────
cask "nikitabobko/tap/aerospace"
tap  "FelixKratz/formulae"
brew "borders"
brew "sketchybar"
# Runs sketchybarrc. Must stay on the major.minor version SbarLua builds
# against, currently 5.5 -- install.sh checks this and refuses to continue on a
# mismatch, because loading the module into the wrong Lua segfaults silently.
brew "lua"

# ── Container tools ────────────────────────────────────────────────
brew "podman"

# ── Fonts ──────────────────────────────────────────────────────────
cask "font-sf-mono"
cask "font-sf-pro"
cask "font-symbols-only-nerd-font"
cask "sf-symbols"
# App icons for the SketchyBar workspace items
cask "font-sketchybar-app-font"

# ── Secrets ────────────────────────────────────────────────────────
# bootstrap-ssh.sh pulls the SSH keys out of Bitwarden with it
brew "bitwarden-cli"

# ── Optional (uncomment if needed) ─────────────────────────────────
# cask "docker"

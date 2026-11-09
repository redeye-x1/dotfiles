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
brew "lazygit"
brew "lazydocker"
brew "zoxide"
brew "superfile"
brew "stow"
brew "gh"
# Proton Pass CLI: agents read secrets as pass:// references through a vault-scoped token
brew "protonpass/tap/pass-cli"
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
# Rotates displays when System Settings doesn't offer it
brew "displayplacer"

# ── Network ────────────────────────────────────────────────────────
# Reaches the home dev server "night" (ssh night, T3, VNC)
cask "tailscale-app"

# ── Container tools ────────────────────────────────────────────────
# Docker engine and docker CLI; replaces Docker Desktop
cask "orbstack"

# ── Fonts ──────────────────────────────────────────────────────────
cask "font-sf-mono"
cask "font-sf-pro"
cask "font-symbols-only-nerd-font"
cask "sf-symbols"
# App icons for the SketchyBar workspace items
cask "font-sketchybar-app-font"

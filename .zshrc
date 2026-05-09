# Initialize Homebrew (must be before instant prompt)
eval "$(/opt/homebrew/bin/brew shellenv)"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export PATH="/opt/homebrew/opt/unzip/bin:$PATH"
source $HOMEBREW_PREFIX/share/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

alias ls="eza -la --icons=always"
alias wt="wezterm cli set-tab-title"

# Load directory shortcuts from ~/.config/directories
() {
  [[ -f ~/.config/directories ]] || return
  local name dir
  while IFS='=' read -r name dir || [[ -n "$name" ]]; do
    [[ -z "$name" || "$name" == \#* ]] && continue
    eval "cd${name}() { [[ -d ${dir} ]] && cd ${dir} || echo 'Directory not found: ${dir}'; }"
  done < ~/.config/directories
}
# Podman socket for lazydocker (macOS)
export DOCKER_HOST="unix://$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)"
alias lg="lazygit"
alias ld="lazydocker"
alias reload="source ~/.zshrc"
alias ..="cd .."
alias ...="cd ../.."
alias ports="lsof -iTCP -sTCP:LISTEN -P -n"
alias ip="curl -s ifconfig.me"
alias hs="history 1"
alias ctg="claude --channels plugin:telegram@claude-plugins-official --dangerously-skip-permissions"

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

# Android SDK
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Python (unversioned symlinks from Homebrew)
export PATH="/opt/homebrew/opt/python@3.12/libexec/bin:$PATH"

# ── History ────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY          # share history across all open terminals
setopt HIST_IGNORE_ALL_DUPS   # remove older duplicate entries
setopt HIST_REDUCE_BLANKS     # remove extra whitespace
setopt HIST_IGNORE_SPACE      # don't save commands starting with a space
setopt APPEND_HISTORY         # append instead of overwrite

# ── Zsh completion system ──────────────────────────────────────────
FPATH=$HOMEBREW_PREFIX/share/zsh-completions:$FPATH
autoload -Uz compinit
# Only regenerate .zcompdump once a day for speed
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# ── Zoxide (smart cd) ─────────────────────────────────────────────
eval "$(zoxide init zsh)"

# ── fzf shell integration (Ctrl+R, Ctrl+T, Alt+C) ─────────────────
source <(fzf --zsh)
export FZF_DEFAULT_OPTS="--color=fg:#D8DEE9,bg:#2E3440,hl:#88C0D0 --color=fg+:#ECEFF4,bg+:#434C5E,hl+:#8FBCBB --color=info:#81A1C1,prompt:#88C0D0,pointer:#88C0D0 --color=marker:#A3BE8C,spinner:#B48EAD,header:#5E81AC"

# ── Zsh plugins (via Homebrew) ─────────────────────────────────────
source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $HOMEBREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh

# History substring search: use Up/Down arrows to search matching history
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# ── bat: syntax-highlighted man pages and help ─────────────────────
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain'
export PATH=$PATH:$HOME/.maestro/bin

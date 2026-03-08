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

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

# Android SDK
export ANDROID_HOME="/Users/mago/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin"

# opencode
export PATH="$HOME/.opencode/bin:$PATH"

# bun completions
[ -s "/Users/magon/.bun/_bun" ] && source "/Users/magon/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

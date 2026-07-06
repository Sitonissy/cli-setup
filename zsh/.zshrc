# 1. PATH (can add ~/.zshlocal)
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# 2. Vim as default
export EDITOR=vi
export VISUAL=vi

# 3. Powerlevel10k instant prompt
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# 4. Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source "$ZSH/oh-my-zsh.sh"

# 5. OS-Specific (1Password SSH Agent for macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ -S "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ]]; then
        export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    fi
fi

# 6.  Modern Unix Intagration
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh --cmd cd)" # Change default cd to zoxide
fi

if command -v thefuck >/dev/null 2>&1; then
    eval "$(thefuck --alias 2>/dev/null || echo true)"
fi

# 7. Load Dotfiles modules
# Load aliases
[[ -f "$HOME/.zsh_aliases" ]] && source "$HOME/.zsh_aliases"

# Load local secrets
[[ -f "$HOME/.zshlocal" ]] && source "$HOME/.zshlocal"

# 8. Load p10k
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

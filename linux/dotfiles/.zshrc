# Peter's .zshrc configuration
# Managed by peter-terminal-utils - do not edit directly

###############################################################################
### Powerlevel10k Instant Prompt
###############################################################################
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

###############################################################################
### Oh My Zsh Configuration
###############################################################################

# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Theme - Powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search)

# Load oh-my-zsh
source $ZSH/oh-my-zsh.sh

###############################################################################
### Modern CLI aliases
###############################################################################

alias ls="eza --icons"
alias ll="eza -la --icons"
alias cat="batcat"
alias fd="fdfind"

###############################################################################
### Git aliases
###############################################################################

alias gs="git status"
alias gd="git diff"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git log --oneline -20"

###############################################################################
### Navigation
###############################################################################

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

###############################################################################
### Python
###############################################################################

alias py="uv run python"
alias ipy="uv run ipython"

###############################################################################
### Tool initializations
###############################################################################

# Initialize zoxide (smarter cd)
eval "$(zoxide init zsh)"

# Initialize fnm (Node.js version manager) if installed
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd)"
fi

# Add uv tools to PATH
export PATH="$HOME/.local/bin:$PATH"

# Add Cargo (Rust) to PATH
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

###############################################################################
### Powerlevel10k Configuration
###############################################################################

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

###############################################################################
### Cursor Bugfix
###############################################################################

# See https://github.com/cursor/cursor/issues/2904
if [[ -n $CURSOR_TRACE_ID ]]; then
  dump_zsh_state() { echo ""; }
  precmd() { print -Pn "\e]133;D;%?\a" }
  preexec() { print -Pn "\e]133;C;\a" }
fi

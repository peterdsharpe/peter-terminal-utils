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

###############################################################################
### zsh-autocomplete (must be sourced BEFORE oh-my-zsh)
###############################################################################
# Real-time type-ahead completion - shows completions as you type
# https://github.com/marlonrichert/zsh-autocomplete
if [[ -f "$ZSH/custom/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh" ]]; then
    source "$ZSH/custom/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh"

    # Customize behavior (see https://github.com/marlonrichert/zsh-autocomplete)
    # Wait 0.1s after typing stops before showing completions (reduces CPU usage)
    zstyle ':autocomplete:*' delay 0.1

    # Limit completion menu to 8 lines (less intrusive)
    zstyle ':autocomplete:*:*' list-lines 8

    # Make Tab insert the common substring first, then cycle through completions
    zstyle ':autocomplete:*complete*:*' insert-unambiguous yes

    # Make Enter always submit the command line (even when menu is open)
    bindkey -M menuselect '\r' .accept-line
fi

# Load oh-my-zsh
source $ZSH/oh-my-zsh.sh

###############################################################################
### Modern CLI aliases
###############################################################################

# eza (ls replacement)
if command -v eza &> /dev/null; then
    alias ls="eza --icons"
    alias ll="eza -la --icons"
fi

# bat (cat replacement) - named 'batcat' on Debian/Ubuntu, 'bat' elsewhere
if command -v batcat &> /dev/null; then
    alias cat="batcat"
elif command -v bat &> /dev/null; then
    alias cat="bat"
fi

# fd (find replacement) - named 'fdfind' on Debian/Ubuntu, 'fd' elsewhere
if command -v fdfind &> /dev/null; then
    alias fd="fdfind"
fi

# nvim (vim replacement)
if command -v nvim &> /dev/null; then
    alias vim="nvim"
    alias vi="nvim"
fi

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
### Environment variables
###############################################################################

# Set editor (prefer nvim if available, fall back to vim)
if command -v nvim &> /dev/null; then
    export EDITOR="nvim"
    export VISUAL="nvim"
else
    export EDITOR="vim"
    export VISUAL="vim"
fi

# Add user-local binaries to PATH
export PATH="$HOME/local/bin:$HOME/.local/bin:$PATH"

###############################################################################
### History configuration
###############################################################################

HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS      # Don't record duplicate commands
setopt HIST_IGNORE_SPACE     # Don't record commands starting with space
setopt SHARE_HISTORY         # Share history between sessions
setopt EXTENDED_HISTORY      # Record timestamp with history

###############################################################################
### Tool initializations
###############################################################################

# Initialize zoxide (smarter cd)
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# Initialize fzf (fuzzy finder) - Ctrl+R for history, Ctrl+T for files
if command -v fzf &> /dev/null; then
    # Source fzf keybindings - check multiple locations
    if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
        source /usr/share/doc/fzf/examples/key-bindings.zsh
    elif [ -f ~/.fzf/shell/key-bindings.zsh ]; then
        source ~/.fzf/shell/key-bindings.zsh
    fi
    if [ -f /usr/share/doc/fzf/examples/completion.zsh ]; then
        source /usr/share/doc/fzf/examples/completion.zsh
    elif [ -f ~/.fzf/shell/completion.zsh ]; then
        source ~/.fzf/shell/completion.zsh
    fi
    # Use fd for fzf if available (faster, respects .gitignore)
    # Handle both 'fdfind' (Debian/Ubuntu) and 'fd' (direct install) names
    if command -v fdfind &> /dev/null; then
        export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fdfind --type d --hidden --follow --exclude .git'
    elif command -v fd &> /dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    fi
fi

# Initialize fnm (Node.js version manager) if installed
if command -v fnm &> /dev/null; then
    eval "$(fnm env --use-on-cd)"
fi

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

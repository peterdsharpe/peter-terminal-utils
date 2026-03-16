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
    # Configure behavior BEFORE sourcing (plugin reads these during init)
    zstyle ':autocomplete:*' delay 0.1           # Wait 0.1s after typing (reduces CPU)
    zstyle ':autocomplete:*:*' list-lines 8      # Limit menu to 8 lines
    zstyle ':autocomplete:*complete*:*' insert-unambiguous yes  # Tab inserts common substring

    # Now source the plugin
    source "$ZSH/custom/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh"

    # Keybindings can be set after sourcing
    bindkey -M menuselect '\r' .accept-line      # Enter always submits
fi

# Load oh-my-zsh
source $ZSH/oh-my-zsh.sh

###############################################################################
### Shared shell configuration
###############################################################################

# Common aliases, PATH, env vars, tool inits, functions
if [[ -f "$HOME/.shell_common" ]]; then
    source "$HOME/.shell_common"
fi

###############################################################################
### Zsh history configuration
###############################################################################

HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS      # Don't record duplicate commands
setopt HIST_IGNORE_SPACE     # Don't record commands starting with space
setopt SHARE_HISTORY         # Share history between sessions
setopt EXTENDED_HISTORY      # Record timestamp with history

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

###############################################################################
### Local overrides
###############################################################################

# Source machine-specific config that shouldn't be tracked
if [[ -f "$HOME/.zshrc.local" ]]; then
    source "$HOME/.zshrc.local"
fi


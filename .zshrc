# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
source /opt/homebrew/opt/powerlevel10k/powerlevel10k.zsh-theme
source ~/.p10k.zsh

# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
plugins=()
source $ZSH/oh-my-zsh.sh

# Aliases
alias fgg="fg %1"
alias fggg="fg %2"
alias fin="~/.finnish-word.sh"
alias gdh="git diff HEAD~1"
alias gdsh="git diff --compact-summary HEAD~1"
alias gdsum="git diff --compact-summary"
alias gg="lazygit"
alias hh="lazydocker"
alias nv="nvim"
alias swe="~/.swedish-word.sh"

# load z tool
# latest at: https://raw.githubusercontent.com/rupa/z/master/z.sh
source ~/.z.sh

# pyenv-virtualenv
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"

# Go path
export GOPATH=$HOME/gowork
PATH=$PATH:$GOPATH/bin

# direnv
eval "$(direnv hook zsh)"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_COMPLETION_TRIGGER='`'

# System-specific .zshrc
source $HOME/.zshrc.specific

# Remove duplicate entries from PATH
if [ -n "$PATH" ]; then
  old_PATH=$PATH:; PATH=
  while [ -n "$old_PATH" ]; do
    x=${old_PATH%%:*}       # the first remaining entry
    case $PATH: in
      *:"$x":*) ;;          # already there
      *) PATH=$PATH:$x;;    # not there yet
    esac
    old_PATH=${old_PATH#*:}
  done
  PATH=${PATH#:}
  unset old_PATH x
fi

# zsh syntax highlighting (must be at the end of .zshrc)
source /opt/homebrew/opt/zsh-syntax-highlighting/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

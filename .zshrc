# Path to your oh-my-zsh installation.
export ZSH=$HOME/git-repos/oh-my-zsh

# Set name of the theme to load.
ZSH_THEME="jeffyrussell"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
plugins=(iterm2-touch-bar-status sudo)

# oh-my-zsh
source $ZSH/oh-my-zsh.sh

# pyenv-virtualenv
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Aliases
alias swe="~/svenskt-ord.sh"
alias gclogs="~/gclogs.sh"
alias i="ipython"
alias j="jobs"
alias fgg="fg %1"
alias fggg="fg %2"
alias wo="pyenv activate"
alias de="pyenv deactivate"
alias gs="git status"
alias gdh="git diff HEAD~1"
alias gdsum="git diff --compact-summary"
alias gdsh="git diff --compact-summary HEAD~1"

# Go path
export GOPATH=$HOME/gowork
PATH=$PATH:$GOPATH/bin

# perl
export PERLPATH=/usr/local/Cellar/perl/5.28.1
PATH=$PATH:$PERLPATH/bin

# haskell
PATH=$PATH:$HOME/.local/bin

# direnv
eval "$(direnv hook zsh)"

# iTerm2
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

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

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
alias i="ipython"
alias j="jobs"
alias wo="pyenv activate"
alias de="pyenv deactivate"
alias gs="git status"
alias gdh="git diff HEAD~1"
alias gdsum="git diff --compact-summary"
alias gdsh="git diff --compact-summary HEAD~1"

# Go path
export GOPATH=$HOME/gowork
export PATH=$PATH:$GOPATH/bin

# direnv
eval "$(direnv hook zsh)"

# iTerm2
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_COMPLETION_TRIGGER='`'

# System-specific .zshrc
source $HOME/.zshrc.specific

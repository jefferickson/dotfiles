# Path to your oh-my-zsh installation.
export ZSH=$HOME/git-repos/oh-my-zsh

# Set name of the theme to load.
ZSH_THEME="robbyrussell"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
plugins=(iterm2-touch-bar-status sudo)

# virtualenvwrapper
export WORKON_HOME=~/.envs
source /usr/local/bin/virtualenvwrapper.sh

# oh-my-zsh
source $ZSH/oh-my-zsh.sh

# Aliases
alias swe="~/svenskt-ord.sh"

# Go path
export GOPATH=$HOME/gowork

# direnv
eval "$(direnv hook zsh)"

# iTerm2
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# System-specific .zshrc
source $HOME/.zshrc.specific

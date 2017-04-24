# Path to your oh-my-zsh installation.
export ZSH=/home/jeff/.oh-my-zsh

# Set name of the theme to load.
ZSH_THEME="bira"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(sudo)

# User configuration

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/opt/anaconda3/bin:/home/jeff/bin"

source $ZSH/oh-my-zsh.sh

alias avenv="source activate"
alias dvenv="source deactivate"

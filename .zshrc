# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
source ~/.p10k.zsh

# brew
export PATH="/opt/homebrew/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"  # pipx et al

# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
plugins=()
source $ZSH/oh-my-zsh.sh

# zsh vi mode
bindkey -v

# Git
export GITHOME="$HOME/git-repos"

# System-specific .zshrc
source $HOME/.zshrc.specific

# Aliases
# ag specific:
alias ag="ag --hidden --ignore .git"
alias cag="ag -A 5 -B 5"
alias qag="ag -Q"
alias cqag="cag -Q"
alias qcag="cqag"
# others
alias fd="fd --no-ignore-vcs --hidden --exclude .git --exclude cdk.out --exclude \"**pycache**\" --exclude .venv"
alias fgg="fg %1"
alias fggg="fg %2"
alias fin="~/.finnish-word.sh"
alias gd="git diff"
alias gdh="git diff HEAD~1"
alias gds="git diff --compact-summary"
alias gdsh="git diff --compact-summary HEAD~1"
alias gl="git log"
alias gg="lazygit"
alias hh="lazydocker"
alias nor="~/.norwegian-word.sh"
alias sso="aws sso login"
alias swe="~/.swedish-word.sh"
alias te="trans -b en:sv+fi"
alias tf="trans -b fi:en+sv"
alias ts="trans -b sv:sv+fi"

# load z tool
# latest at: https://raw.githubusercontent.com/rupa/z/master/z.sh
source ~/.z.sh

# pyenv-virtualenv
eval "$(pyenv init --path)"
eval "$(pyenv virtualenv-init -)"

# node/npm/nvm
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

autoload -U add-zsh-hook
load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use --silent
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    nvm use default --silent
  fi
}
# add-zsh-hook chpwd load-nvmrc
# load-nvmrc

# Go path
export GOPATH=$HOME/gowork
PATH=$PATH:$GOPATH/bin

# direnv
eval "$(direnv hook zsh)"

# fzf
source <(fzf --zsh)
export FZF_COMPLETION_TRIGGER='`'

_fzf_compgen_path() {
  fd --hidden --follow --exclude ".git" . "$1"
}

_fzf_compgen_dir() {
  fd --type d --hidden --follow --exclude ".git" . "$1"
}

# zsh autocomplete
setopt MENU_COMPLETE
bindkey -M menuselect '^[' undo
bindkey '\e.' insert-last-word

# zsh shared history off
unsetopt share_history

# terraform autocomplete
autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /opt/homebrew/bin/terraform terraform

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

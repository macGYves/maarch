# Path to your oh-my-zsh installation.
export ZSH=/home/macgyves/.oh-my-zsh

# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="ys"

autoload zmv

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="yyyy-mm-dd"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  docker
  docker-compose
  git
  git-extras
  mvn
  z
#   zsh-better-npm-completion
#   zsh-nvm
#   zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# User configuration

# ALIASES
# =======
alias mci="mvn clean install"
alias mcp="mvn clean package"
alias open="xdg-open"

alias pip="pip2"


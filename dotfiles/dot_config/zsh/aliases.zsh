# ALIASES
# =======
## maven
alias mci="mvn clean install"
alias mcp="mvn clean package"

# git
alias ga="git add"
alias gb="git branch"
alias gbd="git branch -d"
alias gbD="git branch -D"
alias gco="git checkout"
alias gcom="git checkout main"
alias gcam="git commit --all -m"
alias gd="git diff"
alias gf="git fetch"
alias gfp="git fetch --prune"
alias glog='git log --oneline --decorate --graph'
alias gp="git pull"
alias gpu="git push"
alias grh="git reset --hard"
alias gst="git status"

## chezmoi
alias che="chezmoi"

## docker/docker-compose
alias dps="docker ps"
alias dcup="docker-compose up"

## python
alias pip="pip3"

# misc
alias -g v="less"
alias -g e="nvim"
alias open="xdg-open"
alias email="neomutt"

# Workaround for starting vscodium on native wayland
alias code="vscodium --enable-features=UseOzonePlatform --ozone-platform=wayland"

# Pacman aliases
alias -g pacman-upgrade="sudo pacman -Syu"      # Synchronize with repositories and then upgrade packages on local system.
alias -g pacman-download="pacman -Sw"           # Download specified package(s) as .tar.xz ball
alias -g pacman-install="sudo pacman -S"        # Install specific package(s) from the repositories
alias -g pacman-install-file="sudo pacman -U"   # Install specific package not from the repositories but from a file
alias -g pacman-remove="sudo pacman -R"         # Remove the specified package(s), retaining its configuration(s) and required dependencies
alias -g pacman-purge="sudo pacman -Rns"        # Remove the specified package(s), its configuration(s) and unneeded dependencies
alias -g pacman-repoinfo="pacman -Si"           # Display information about a given package in the repositories
alias -g pacman-search="pacman -Ss"             # Search for package(s) in the repositories
alias -g pacman-dbinfo="pacman -Qi"             # Display information about a given package in the local database
alias -g pacman-dbsearch="pacman -Qs"           # Search for package(s) in the local database
alias -g pacman-list-orphaned="pacman -Qdt"     # List all packages which are orphaned
alias -g pacman-clean-cache="sudo pacman -Scc"  # Clean cache - delete all the package files in the cache
alias -g pacman-list-package-files="pacman -Ql" # List all files installed by a given package
alias -g pacman-provides-="pacman -Qo"          # Show package(s) owning the specified file(s)

alias btctl="bluetoothctl"

alias -g sctl="systemctl"


# taskmanager
alias ta="task add"
alias t="task"

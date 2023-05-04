autoload bashcompinit && bashcompinit
autoload -Uz compinit && compinit

complete -C '~/.local/bin/aws_completer' aws

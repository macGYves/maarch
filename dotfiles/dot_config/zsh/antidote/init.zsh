
antidote_dir=~/.local/bin/antidote
plugins_txt=${ZDOTDIR:-~}/antidote/zsh_plugins.txt
plugins_bundle=${ZCACHEDIR:-~}/antidote/zsh_plugins.zsh

# Clone antidote if $antidote_dir does not exist.
[[ -e "$antidote_dir" ]] || git clone --depth=1 https://github.com/mattmc3/antidote.git $antidote_dir

# Ensure the .zsh_plugins.txt file exists so you can add plugins.
[[ -f ${plugins_txt} ]] || touch ${plugins_txt}

# Lazy-load antidote from its functions directory.
fpath=(${antidote_dir}/functions $fpath)
autoload -Uz antidote

# Generate a new static file whenever .zsh_plugins.txt is updated.
if [[ ! ${plugins_bundle} -nt ${plugins_txt} ]]; then
  antidote bundle <${plugins_txt} >|${plugins_bundle}
fi

source ${plugins_bundle}
unset antidote_dir plugins_txt plugins_bundle
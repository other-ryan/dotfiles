# source pre configs
if [[ -d "${ZDOTDIR}/.pre.zsh" ]]; then
    source "${ZDOTDIR}/.pre.zsh"
fi

# source main configs
if [[ -d "${ZDOTDIR}/conf.d" ]]; then
  for f in "${ZDOTDIR}/conf.d/"*.zsh(N); do
    source "$f"
  done
fi

# source post configs
if [[ -d "${ZDOTDIR}/.post.zsh" ]]; then
    source "${ZDOTDIR}/.post.zsh"
fi

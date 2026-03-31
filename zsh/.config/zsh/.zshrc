# source pre configs
if [[ -f "${HOME}/.pre.zsh" ]]; then
    source "${HOME}/.pre.zsh"
fi

# source main configs
if [[ -d "${ZDOTDIR}/conf.d" ]]; then
  for f in "${ZDOTDIR}/conf.d/"*.zsh(N); do
    source "$f"
  done
fi

# source post configs
if [[ -f "${HOME}/.post.zsh" ]]; then
    source "${HOME}/.post.zsh"
fi

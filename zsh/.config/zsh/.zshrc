# source pre configs
if [[ -f "${HOME}/.zsh_pre" ]]; then
    source "${HOME}/.zsh_pre"
fi

# source main configs
if [[ -d "${ZDOTDIR}/conf.d" ]]; then
  for f in "${ZDOTDIR}/conf.d/"*.zsh(N); do
    source "$f"
  done
fi

# source post configs
if [[ -f "${HOME}/.zsh_post" ]]; then
    source "${HOME}/.zsh_post"
fi

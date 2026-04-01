# 💾 prompt configs
typeset -g ZSH_PROMPT_USE=starship
typeset -g ZSH_PROMPT_THEME=starship
zstyle -s ':rm:zsh:zephyr:prompt' use ZSH_PROMPT_USE
zstyle -s ':rm:zsh:zephyr:prompt' theme ZSH_PROMPT_THEME

zstyle ':zephyr:plugin:prompt' use-cache yes

# 🚀 starship - (starship init is taken care of by zephyr)
if [[ ${ZSH_PROMPT_USE:-starship} == starship ]]; then
  # VIRTUAL_ENV_DISABLE_PROMPT=1 prevents the shell from
  # print (${VENV_NAME}) at every prompt
  export VIRTUAL_ENV_DISABLE_PROMPT=1
  export STARSHIP_LOG=error
  zstyle ':zephyr:plugin:prompt' theme starship ${ZSH_PROMPT_THEME}
fi
# 🚀 end

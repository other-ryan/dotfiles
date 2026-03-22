# 🍺 brew
export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:${PATH}

### 🧪 antidote setup
zstyle ':antidote:bundle' use-friendly-names 'yes'

## 💾 prompt
export POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true # use `p10k configure` to run the wizard
typeset -g ZSH_PROMPT_USE=starship
zstyle -s ':rm:zsh:zephyr:prompt' use ZSH_PROMPT_USE

zstyle ':zephyr:plugin:prompt' use-cache yes

# 🚀 starship - (starship init is taken care of by zephyr)
if [[ ${ZSH_PROMPT_USE} == starship ]]; then
  # VIRTUAL_ENV_DISABLE_PROMPT=1 prevents the shell from
  # print (${VENV_NAME}) at every prompt
  export VIRTUAL_ENV_DISABLE_PROMPT=1
  export STARSHIP_LOG=error
  zstyle ':zephyr:plugin:prompt' theme starship
fi
# 🚀 end

# 🔋 p10k
if [[ ${ZSH_PROMPT_USE} == p10k ]]; then
  zstyle ':zephyr:plugin:prompt' theme p10k rm
fi
# 🔋 end
## 💾 end

source "${HOME}/.config/antidote/antidote.zsh"
antidote load
### 🧪 end

# 📜 histr setup
export HISTFILE=~/.zsh_history
SAVEHIST=500000
HISTSIZE=500000

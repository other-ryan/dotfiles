#!/usr/bin/env bash

set -euo pipefail

BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RUN_PREFS=1
RUN_TOOLS=1
RUN_FONTS=1
RUN_ZSH=1
RUN_GHOSTTY=1

timestamp() {
  date +"%Y%m%d%H%M%S"
}

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [options]

Options:
  --only <steps>   Run only the listed steps. Comma-separated.
  --skip <steps>   Skip the listed steps. Comma-separated.
  --help           Show this help text.

Steps:
  prefs
  tools
  fonts
  zsh
  ghostty

Examples:
  ./bootstrap.sh
  ./bootstrap.sh --only tools
  ./bootstrap.sh --only fonts,ghostty
  ./bootstrap.sh --skip fonts
EOF
}

backup_path() {
  local path="$1"
  local backup="${path}.bak.$(timestamp)"

  mv "$path" "$backup"
}

ensure_symlink() {
  local target_path="$1"
  local source_path="$2"

  if [[ -L "$target_path" ]]; then
    local current_target
    current_target="$(readlink "$target_path")"

    if [[ "$current_target" != "$source_path" ]]; then
      backup_path "$target_path"
      ln -s "$source_path" "$target_path"
    fi
    return
  fi

  if [[ -e "$target_path" ]]; then
    backup_path "$target_path"
  fi

  ln -s "$source_path" "$target_path"
}

require_command() {
  local command_name="$1"
  local message="$2"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "$message" >&2
    exit 1
  fi
}

disable_all_steps() {
  RUN_PREFS=0
  RUN_TOOLS=0
  RUN_FONTS=0
  RUN_ZSH=0
  RUN_GHOSTTY=0
}

enable_step() {
  local step_name="$1"

  case "$step_name" in
    prefs) RUN_PREFS=1 ;;
    tools) RUN_TOOLS=1 ;;
    fonts) RUN_FONTS=1 ;;
    zsh) RUN_ZSH=1 ;;
    ghostty) RUN_GHOSTTY=1 ;;
    *)
      echo "Unknown step: $step_name" >&2
      usage >&2
      exit 1
      ;;
  esac
}

disable_step() {
  local step_name="$1"

  case "$step_name" in
    prefs) RUN_PREFS=0 ;;
    tools) RUN_TOOLS=0 ;;
    fonts) RUN_FONTS=0 ;;
    zsh) RUN_ZSH=0 ;;
    ghostty) RUN_GHOSTTY=0 ;;
    *)
      echo "Unknown step: $step_name" >&2
      usage >&2
      exit 1
      ;;
  esac
}

apply_step_list() {
  local mode="$1"
  local step_list="$2"
  local step_name

  IFS=',' read -r -a step_names <<<"$step_list"

  for step_name in "${step_names[@]}"; do
    case "$mode" in
      only) enable_step "$step_name" ;;
      skip) disable_step "$step_name" ;;
    esac
  done
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --only)
        [[ $# -ge 2 ]] || { echo "--only requires a comma-separated step list." >&2; exit 1; }
        disable_all_steps
        apply_step_list "only" "$2"
        shift 2
        ;;
      --skip)
        [[ $# -ge 2 ]] || { echo "--skip requires a comma-separated step list." >&2; exit 1; }
        apply_step_list "skip" "$2"
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

load_homebrew_env() {
  if command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
    return
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    return
  fi

  if [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
    return
  fi

  echo "Homebrew is installed but could not be located." >&2
  exit 1
}

install_font_archive() {
  local font_name="$1"
  local font_glob="$2"
  local font_url="$3"
  local font_install_dir="$4"
  local temp_dir
  local archive_name

  if compgen -G "$font_install_dir/$font_glob" >/dev/null; then
    echo "$font_name already present in $font_install_dir"
    return
  fi

  temp_dir="$(mktemp -d)"
  archive_name="$(basename "$font_url")"

  echo "Downloading $font_name..."
  curl -fL "$font_url" -o "$temp_dir/$archive_name"

  echo "Installing $font_name..."
  mkdir -p "$font_install_dir"
  unzip -q "$temp_dir/$archive_name" -d "$temp_dir/extracted"
  find "$temp_dir/extracted" -type f -name '*.ttf' -exec cp {} "$font_install_dir/" \;
  rm -rf "$temp_dir"
}

install_font_archives() {
  local fonts_yaml_path="$BOOTSTRAP_DIR/fonts/fonts.yaml"
  local font_install_dir="$HOME/Library/Fonts"
  local font_entries
  local font_name
  local font_glob
  local font_url

  require_command "yq" "The fonts step requires yq. Install tools first or install yq manually."

  if [[ ! -f "$fonts_yaml_path" ]]; then
    echo "Fonts config not found at $fonts_yaml_path" >&2
    exit 1
  fi

  font_entries="$(yq -r '.fonts[] | [.name, .glob, .url] | @tsv' "$fonts_yaml_path")"

  if [[ -z "$font_entries" ]]; then
    echo "No fonts defined in $fonts_yaml_path"
    return
  fi

  while IFS=$'\t' read -r font_name font_glob font_url; do
    install_font_archive "$font_name" "$font_glob" "$font_url" "$font_install_dir"
  done <<<"$font_entries"
}

setup_zdotdir() {
  local zdotdir_target="$HOME/.config/zsh"
  local repo_zsh_dir="$BOOTSTRAP_DIR/zsh"
  local zshenv_path="$HOME/.zshenv"
  local desired_zshenv='export ZDOTDIR="$HOME/.config/zsh"'

  mkdir -p "$HOME/.config"
  ensure_symlink "$zdotdir_target" "$repo_zsh_dir"

  if [[ -f "$zshenv_path" ]]; then
    local current_zshenv_contents
    current_zshenv_contents="$(<"$zshenv_path")"
    if [[ "$current_zshenv_contents" != "$desired_zshenv" ]]; then
      backup_path "$zshenv_path"
      printf '%s\n' "$desired_zshenv" > "$zshenv_path"
    fi
  else
    if [[ -e "$zshenv_path" ]]; then
      backup_path "$zshenv_path"
    fi
    printf '%s\n' "$desired_zshenv" > "$zshenv_path"
  fi
}

setup_antidote() {
  local antidote_dir="$HOME/.config/antidote"

  if [[ -d "$antidote_dir/.git" ]]; then
    echo "Antidote already present at $antidote_dir"
    return
  fi

  if [[ -e "$antidote_dir" ]]; then
    backup_path "$antidote_dir"
  fi
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$antidote_dir"
}

setup_ghostty() {
  local ghostty_dir="$HOME/.config/ghostty"
  local ghostty_config_target="$ghostty_dir/config"
  local repo_ghostty_config="$BOOTSTRAP_DIR/ghostty/config"

  mkdir -p "$ghostty_dir"
  ensure_symlink "$ghostty_config_target" "$repo_ghostty_config"
}

parse_args "$@"

# ⌨️ Configure macOS keyboard repeat settings so the shell environment
# feels consistent on new machines without extra manual setup.
if [[ "$RUN_PREFS" -eq 1 ]]; then
  echo "⌨️ Configuring macOS key repeat settings..."
  defaults write -g InitialKeyRepeat -int 10
  defaults write -g KeyRepeat -int 1
fi

# 🍺 Install Homebrew if it is missing, then load its environment into the
# current shell so the rest of the script can use `brew` immediately.
if [[ "$RUN_TOOLS" -eq 1 ]]; then
  echo "🍺 Ensuring Homebrew is installed..."
  ensure_homebrew
  load_homebrew_env

  # 📦 Install the repo-managed CLI/tooling set from a Brewfile. `brew bundle`
  # safely ignores comments and keeps the package list declarative.
  echo "📦 Installing Homebrew packages from Brewfile..."
  brew bundle --file="$BOOTSTRAP_DIR/tools/brew"
fi

# 🔤 Install repo-managed font archives before wiring Ghostty so terminal
# configs can reference fonts that already exist on the system.
if [[ "$RUN_FONTS" -eq 1 ]]; then
  echo "🔤 Ensuring configured fonts are installed..."
  install_font_archives
fi

# 🏠 Point zsh at the repo-managed config by wiring `~/.config/zsh` to the
# checked-out `zsh/` directory and ensuring `~/.zshenv` exports `ZDOTDIR`.
if [[ "$RUN_ZSH" -eq 1 ]]; then
  echo "🏠 Setting up ZDOTDIR..."
  setup_zdotdir

  # 🧪 Install antidote in a stable XDG-style config location so the zsh config
  # can source it consistently across machines.
  echo "🧪 Installing antidote plugin manager..."
  setup_antidote
fi

# 👻 Point Ghostty at the repo-managed config using its XDG config path.
if [[ "$RUN_GHOSTTY" -eq 1 ]]; then
  echo "👻 Setting up Ghostty config..."
  setup_ghostty
fi

echo "✅ Bootstrap complete."

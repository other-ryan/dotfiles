#!/usr/bin/env zsh

set -euo pipefail

BOOTSTRAP_DIR="${0:A:h}"
STOW_ONLY=0
typeset -a STOW_PACKAGES=(zsh ghostty)

log_step() {
  print -P "%F{cyan}==>%f $*"
}

log_warn() {
  print -P "%F{yellow}warning:%f $*" >&2
}

log_error() {
  print -P "%F{red}error:%f $*" >&2
}

die() {
  log_error "$1"
  exit 1
}

timestamp() {
  date +"%Y%m%d%H%M%S"
}

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [options]

Options:
  --stow-only             Run only the stow placement step.
  --packages <packages>   Comma-separated stow packages to process.
  --help                  Show this help text.

Examples:
  ./bootstrap.sh
  ./bootstrap.sh --stow-only
  ./bootstrap.sh --packages zsh
  ./bootstrap.sh --stow-only --packages zsh,ghostty
EOF
}

backup_path() {
  local target_path="$1"
  local backup="${target_path}.bak.$(timestamp)"

  log_warn "Backing up $target_path to $backup"
  mv "$target_path" "$backup"
}

require_command() {
  local command_name="$1"
  local message="$2"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    die "$message"
  fi
}

parse_packages() {
  local package_csv="$1"
  local raw_package
  local package_name
  local -a parsed_packages=()

  for raw_package in "${(@s:,:)package_csv}"; do
    package_name="${raw_package//[[:space:]]/}"
    [[ -n "$package_name" ]] || die "--packages requires at least one non-empty package name."
    parsed_packages+=("$package_name")
  done

  STOW_PACKAGES=("${parsed_packages[@]}")
}

parse_args() {
  while (( $# > 0 )); do
    case "$1" in
      --stow-only)
        STOW_ONLY=1
        shift
        ;;
      --packages)
        (( $# >= 2 )) || die "--packages requires a comma-separated package list."
        parse_packages "$2"
        shift 2
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
  done
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  log_step "Installing Homebrew"
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
}

ensure_stow_available() {
  if command -v stow >/dev/null 2>&1; then
    return
  fi

  load_homebrew_env

  require_command "stow" "GNU Stow is required for the stow step. Run the full bootstrap first or install stow manually."
}

install_font_archive() {
  local font_name="$1"
  local font_glob="$2"
  local font_url="$3"
  local font_install_dir="$4"
  local temp_dir
  local archive_name

  if find "$font_install_dir" -maxdepth 1 -name "$font_glob" -print -quit 2>/dev/null | grep -q .; then
    log_step "$font_name already present in $font_install_dir"
    return
  fi

  temp_dir="$(mktemp -d)"
  archive_name="$(basename "$font_url")"

  log_step "Downloading $font_name"
  curl -fL "$font_url" -o "$temp_dir/$archive_name"

  log_step "Installing $font_name"
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
    die "Fonts config not found at $fonts_yaml_path"
  fi

  font_entries="$(yq -r '.fonts[] | [.name, .glob, .url] | @tsv' "$fonts_yaml_path")"

  if [[ -z "$font_entries" ]]; then
    log_step "No fonts defined in $fonts_yaml_path"
    return
  fi

  while IFS=$'\t' read -r font_name font_glob font_url; do
    install_font_archive "$font_name" "$font_glob" "$font_url" "$font_install_dir"
  done <<<"$font_entries"
}

setup_antidote() {
  local antidote_dir="$HOME/.config/antidote"

  if [[ -d "$antidote_dir/.git" ]]; then
    log_step "Antidote already present at $antidote_dir"
    return
  fi

  if [[ -e "$antidote_dir" ]]; then
    backup_path "$antidote_dir"
  fi

  log_step "Installing antidote"
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$antidote_dir"
}

validate_stow_packages() {
  local package_name

  for package_name in "${STOW_PACKAGES[@]}"; do
    [[ -d "$BOOTSTRAP_DIR/$package_name" ]] || die "Unknown stow package: $package_name"
  done
}

backup_stow_conflicts() {
  local package_name="$1"
  local package_dir="$BOOTSTRAP_DIR/$package_name"
  local source_path
  local relative_path
  local target_path

  while IFS= read -r source_path; do
    relative_path="${source_path#$package_dir/}"
    target_path="$HOME/$relative_path"

    if [[ -d "$source_path" && ! -L "$source_path" ]]; then
      if [[ -e "$target_path" && ! -d "$target_path" ]]; then
        backup_path "$target_path"
      fi
      continue
    fi

    if [[ ( -e "$target_path" || -L "$target_path" ) && "$target_path" -ef "$source_path" ]]; then
      continue
    fi

    if [[ -e "$target_path" || -L "$target_path" ]]; then
      backup_path "$target_path"
    fi
  done < <(find "$package_dir" -mindepth 1 -print)
}

stow_packages() {
  local package_name

  ensure_stow_available
  validate_stow_packages

  for package_name in "${STOW_PACKAGES[@]}"; do
    log_step "Preparing stow package: $package_name"
    backup_stow_conflicts "$package_name"
    log_step "Stowing package: $package_name"
    stow --dir="$BOOTSTRAP_DIR" --target="$HOME" --restow --no-folding "$package_name"
  done
}

run_full_bootstrap() {
  log_step "Configuring macOS key repeat settings"
  defaults write -g InitialKeyRepeat -int 10
  defaults write -g KeyRepeat -int 1

  log_step "Ensuring Homebrew is installed"
  ensure_homebrew
  load_homebrew_env

  log_step "Installing Homebrew packages from Brewfile"
  brew bundle --file="$BOOTSTRAP_DIR/tools/Brewfile"

  log_step "Ensuring configured fonts are installed"
  install_font_archives

  setup_antidote

  stow_packages
}

parse_args "$@"

if (( STOW_ONLY )); then
  stow_packages
else
  run_full_bootstrap
fi

log_step "Bootstrap complete"

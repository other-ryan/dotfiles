# dotfiles

Personal macOS dotfiles managed from this repo and installed with `bootstrap.sh`.

## Bootstrap

Run the full setup:

```sh
./bootstrap.sh
```

Run only the stow placement step:

```sh
./bootstrap.sh --stow-only
```

Target specific stow packages:

```sh
./bootstrap.sh --packages zsh
./bootstrap.sh --stow-only --packages zsh,ghostty
```

Show available options:

```sh
./bootstrap.sh --help
```

Notes:

- Full bootstrap applies macOS defaults, installs tools from [`tools/Brewfile`](/Users/ryan/dev/dotfiles/tools/Brewfile), installs fonts, installs antidote if missing, and then stows dotfiles.
- `--stow-only` skips everything except the stow placement logic.
- `--packages` overrides the default stow package list in [`bootstrap.sh`](/Users/ryan/dev/dotfiles/bootstrap.sh).
- `fonts` reads download metadata from [`fonts/fonts.yaml`](/Users/ryan/dev/dotfiles/fonts/fonts.yaml) and requires `yq`.
- `zsh` now owns `~/.zshenv` and `~/.config/zsh` through the stow package at [`zsh/.zshenv`](/Users/ryan/dev/dotfiles/zsh/.zshenv) and [`zsh/.config/zsh/.zshrc`](/Users/ryan/dev/dotfiles/zsh/.config/zsh/.zshrc).
- `ghostty` is placed through the stow package at [`ghostty/.config/ghostty/config`](/Users/ryan/dev/dotfiles/ghostty/.config/ghostty/config).

## Editing

Edit the repo files directly, then rerun bootstrap or the stow-only mode.

- Zsh config lives under [`zsh/.config/zsh`](/Users/ryan/dev/dotfiles/zsh/.config/zsh) and [`zsh/.zshenv`](/Users/ryan/dev/dotfiles/zsh/.zshenv).
- Ghostty config lives in [`ghostty/.config/ghostty/config`](/Users/ryan/dev/dotfiles/ghostty/.config/ghostty/config).
- Tool installs are declared in [`tools/Brewfile`](/Users/ryan/dev/dotfiles/tools/Brewfile).
- Font downloads are declared in [`fonts/fonts.yaml`](/Users/ryan/dev/dotfiles/fonts/fonts.yaml).
- Bootstrap behavior lives in [`bootstrap.sh`](/Users/ryan/dev/dotfiles/bootstrap.sh).

Common edit loop:

```sh
$EDITOR zsh/.config/zsh/.zshrc
./bootstrap.sh --stow-only --packages zsh
```

```sh
$EDITOR ghostty/.config/ghostty/config
./bootstrap.sh --stow-only --packages ghostty
```

```sh
$EDITOR fonts/fonts.yaml
./bootstrap.sh
```

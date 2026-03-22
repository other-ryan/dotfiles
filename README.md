# dotfiles

Personal macOS dotfiles managed from this repo and installed with `bootstrap.sh`.

## Bootstrap

Run the full setup:

```sh
./bootstrap.sh
```

Show available options:

```sh
./bootstrap.sh --help
```

Run only specific steps:

```sh
./bootstrap.sh --only prefs
./bootstrap.sh --only tools
./bootstrap.sh --only fonts
./bootstrap.sh --only zsh,ghostty
```

Skip specific steps:

```sh
./bootstrap.sh --skip fonts
./bootstrap.sh --skip prefs,ghostty
```

Available steps:

- `prefs`
- `tools`
- `fonts`
- `zsh`
- `ghostty`

Notes:

- `prefs` applies the macOS defaults managed by the script.
- `tools` installs Homebrew if needed, then installs packages from [`tools/brew`](/Users/ryan/dev/dotfiles/tools/brew).
- `fonts` reads download metadata from [`fonts/fonts.yaml`](/Users/ryan/dev/dotfiles/fonts/fonts.yaml) and requires `yq`.
- `zsh` sets `ZDOTDIR`, links `~/.config/zsh` to the repo `zsh/` directory, and installs antidote.
- `ghostty` links [`ghostty/config`](/Users/ryan/dev/dotfiles/ghostty/config) to `~/.config/ghostty/config`.

## Editing

Edit the repo files directly, then rerun the relevant bootstrap step.

- Zsh config lives in [`zsh/.zshrc`](/Users/ryan/dev/dotfiles/zsh/.zshrc), [`zsh/.zsh_plugins.txt`](/Users/ryan/dev/dotfiles/zsh/.zsh_plugins.txt), [`zsh/.zsh_plugins.zsh`](/Users/ryan/dev/dotfiles/zsh/.zsh_plugins.zsh), and the theme files under [`zsh/`](/Users/ryan/dev/dotfiles/zsh).
- Ghostty config lives in [`ghostty/config`](/Users/ryan/dev/dotfiles/ghostty/config).
- Tool installs are declared in [`tools/brew`](/Users/ryan/dev/dotfiles/tools/brew).
- Font downloads are declared in [`fonts/fonts.yaml`](/Users/ryan/dev/dotfiles/fonts/fonts.yaml).
- Bootstrap behavior lives in [`bootstrap.sh`](/Users/ryan/dev/dotfiles/bootstrap.sh).

Common edit loop:

```sh
$EDITOR zsh/.zshrc
./bootstrap.sh --only zsh
```

```sh
$EDITOR ghostty/config
./bootstrap.sh --only ghostty
```

```sh
$EDITOR fonts/fonts.yaml
./bootstrap.sh --only fonts
```

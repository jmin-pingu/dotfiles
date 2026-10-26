# dotfiles

Configs for my machines.

## Machines

| Name | Machine | OS | Arch | Git email | Gets |
|---|---|---|---|---|---|
| `personal-mac` | Personal MacBook Pro | macOS | aarch64 | personal | core + its own packages, brews, casks, env vars |
| `work-mac` | Work MacBook | macOS | aarch64 | work (set locally) | core + its own packages, brews, casks, env vars |
| `linux` | Linux machine | NixOS | x86_64 | personal | core + its own packages |

Each one lives in `nix/hosts/<name>/` and builds with `switch`.

## How it works

- Each folder is a [GNU Stow](https://www.gnu.org/software/stow/manual/stow.html) package. It mirrors `$HOME`.
- `make link` symlinks every package into `$HOME`. `make unlink` removes the links.
- Edit files in place. The links point here, so changes land in the repo.
- Claude skills and hooks: put shared ones in `claude/.claude/skills/` or `hooks/`. Ones only in `~/.claude` stay local.
- `nix/` is the system flake. It isn't stowed.
  - `modules/core/`: packages for every machine.
  - `modules/darwin/`, `modules/nixos/`: settings for every Mac or every NixOS machine.
  - `modules/home/`: git and zsh for every machine.
  - `hosts/<name>/`: one machine's own packages, brews, casks and aliases.
  - New machine: copy a `hosts/` folder and add one line to `flake.nix`.

## New machine

Fresh installs don't have flakes turned on, so the first commands pass `--extra-experimental-features 'nix-command flakes'`. After the first build, the flake turns them on for good.

### Mac (`personal-mac`, `work-mac`)

1. Install Nix and Homebrew. nix-darwin manages brews and casks but doesn't install Homebrew itself.
   ```
   curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh
   ```
   Homebrew: see https://brew.sh. Open a new terminal after both.
2. Link:
   ```
   cd $HOME/dotfiles && make link
   ```
   If a real file is already in the way, move it out and run again.
3. Make `~/.config/zsh/secrets.zsh` with `chmod 600`. One `NAME="value"` per line.
4. If `~/.gitconfig` exists, remove its `user.name` and `user.email`. It overrides the per-machine git email from nix.
   ```
   git config -f ~/.gitconfig --unset user.email; git config -f ~/.gitconfig --unset user.name
   ```
   On `work-mac`, set the work email locally (it's not in git):
   ```
   git config -f ~/.config/git/local user.email <work email>
   ```
5. Install the tmux plugin manager, then press `prefix` + `I` inside tmux:
   ```
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   ```
6. First build, with the machine's name:
   ```
   sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin/master#darwin-rebuild -- switch --flake $HOME/dotfiles/nix#work-mac
   ```
7. Open a new terminal. From now on, just run `switch`.

### NixOS (`linux`)

1. Install NixOS from the ISO. Create the user `jmin` with a password. The flake doesn't set one.
2. Link (make isn't installed yet):
   ```
   cd $HOME/dotfiles && nix-shell -p gnumake --run 'make link'
   ```
3. Replace the placeholder hardware file with this machine's:
   ```
   nixos-generate-config --show-hardware-config > $HOME/dotfiles/nix/hosts/linux/hardware-configuration.nix
   ```
   Commit it: flakes only see files git tracks.
4. Make `~/.config/zsh/secrets.zsh` and install tpm (Mac steps 3 and 5).
5. First build:
   ```
   sudo nixos-rebuild switch --flake $HOME/dotfiles/nix#linux --option experimental-features 'nix-command flakes'
   ```
6. Log out and back in. From now on, just run `switch`.

### New machine type

Copy a folder in `nix/hosts/`, edit its packages, and add one line to `nix/flake.nix`. Then `git add` it before building.

## Not in git

- `~/.config/zsh/secrets.zsh`
- Vault notes. Only the top-level folders, `_template.md` and `notes/references/` are tracked.
- `~/.claude/settings.json` and `~/.claude/skills/synced/`

## TODO

- [ ] Trusted references: switch to one folder per topic if a topic grows past one list (e.g. `trusted/systems/` with separate lists for papers, blogs and courses). For now it's one file per topic.

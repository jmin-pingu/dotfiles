# dotfiles

Configs for my machines: `personal-mac`, `work-mac`, `linux` (NixOS).

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

1. Install Nix.
2. Clone and link:
   ```
   git clone https://github.com/jmin-pingu/dotfiles.git $HOME/dotfiles
   cd $HOME/dotfiles && make link
   ```
   If a real file is already in the way, move it out and run again.
3. Make `~/.config/zsh/secrets.zsh` with `chmod 600`. One `NAME="value"` per line.
4. First build. `<name>` is the machine's folder in `nix/hosts/`.
   - Mac:
     ```
     sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake $HOME/dotfiles/nix#<name>
     ```
   - NixOS: first replace `nix/hosts/linux/hardware-configuration.nix` with the machine's own (`nixos-generate-config --show-hardware-config`). Then:
     ```
     sudo nixos-rebuild switch --flake $HOME/dotfiles/nix#linux
     ```
   After that, just run `switch`.

## Not in git

- `~/.config/zsh/secrets.zsh`
- Vault notes. Only the folders and `_template.md` are tracked.
- `~/.claude/settings.json` and `~/.claude/skills/synced/`

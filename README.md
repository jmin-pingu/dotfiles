# dotfiles

Configs for my Macs. Every Mac gets the same settings.

## How it works

- Each folder is a [GNU Stow](https://www.gnu.org/software/stow/manual/stow.html) package. It mirrors `$HOME`.
- `make link` symlinks every package into `$HOME`. `make unlink` removes the links.
- Edit files in place. The links point here, so changes land in the repo.
- Claude skills and hooks: put shared ones in `claude/.claude/skills/` or `hooks/`. Ones only in `~/.claude` stay local.
- `nix/` is the system flake. It isn't stowed.
  - `hosts/<name>/` holds one machine's config.
  - `modules/` holds shared pieces. Hosts import the ones they need.
  - New machine type: add a `hosts/<name>/` folder and an entry in `flake.nix`.

## New machine

1. Install Nix.
2. Clone and link:
   ```
   git clone https://github.com/jmin-pingu/dotfiles.git $HOME/dotfiles
   cd $HOME/dotfiles && make link
   ```
   If a real file is already in the way, move it out and run again.
3. Make `~/.config/zsh/secrets.zsh` with `chmod 600`. One `NAME="value"` per line.
4. First build:
   ```
   sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake $HOME/dotfiles/nix#macbook
   ```
   After that, just run `switch`.

## Not in git

- `~/.config/zsh/secrets.zsh`
- Vault notes. Only the folders and `_template.md` are tracked.
- `~/.claude/settings.json` and `~/.claude/skills/synced/`

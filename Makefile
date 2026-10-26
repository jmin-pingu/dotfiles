# Stow packages: each dir mirrors $HOME and gets symlinked into it.
PACKAGES := alacritty bin claude coc fish ghostty karabiner nvim sioyek tex tmux vim yazi zsh
# Use stow if installed, else run it through nix (flakes flag for fresh installs).
STOW := $(shell command -v stow 2>/dev/null)
ifeq ($(STOW),)
STOW := nix --extra-experimental-features 'nix-command flakes' run nixpkgs\#stow --
endif

# Dirs that also hold local, unshared files. Making them real dirs first
# stops stow from linking the whole dir, so only shared items get linked.
LOCAL_DIRS := .config .claude/skills .claude/hooks bin .vim \
	.config/alacritty .config/coc/extensions .config/sioyek

.PHONY: link unlink

link:
	@cd $(HOME) && mkdir -p $(LOCAL_DIRS)
	$(STOW) -v -R -t $(HOME) $(PACKAGES)

unlink:
	$(STOW) -v -D -t $(HOME) $(PACKAGES)

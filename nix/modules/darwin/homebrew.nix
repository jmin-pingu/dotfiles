# Homebrew on every Mac: casks my dotfiles configure or my workflow needs.
# Hosts add their own brews and casks in hosts/<name>/homebrew.nix.
{ ... }: {
    homebrew = {
        enable = true;
        taps = [];
        casks = [
            "ghostty"
            "karabiner-elements"
            "firefox"
            "obsidian"
            "anki"
        ];
    };
}

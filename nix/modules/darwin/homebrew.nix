# Homebrew formulae and casks (GUI apps) that nixpkgs doesn't cover well.
{ ... }: {
    homebrew = {
        enable = true;
        taps = [];
        brews = [
            "zig"
            "zls"
            "go"
            "portaudio"
            # Haskell: ghcup manages ghc/cabal/stack/hls (in ~/.ghcup/bin).
            # Don't add brew's ghc/cabal-install/haskell-stack - they shadow ghcup's.
            "ghcup"
            "qemu"
            "llvm"
            "lld"
            "openjdk@17"
            "postgresql"
            "libiconv"
            "coursier"
        ];
        casks = [ 
            "spotify" 
            "firefox" 
            "obsidian" 
            "anki" 
            "ghostty" 
            "anaconda"
            "rekordbox"
            "mactex"
            "rstudio"
            "zoom"
            "flux-app"
            "touchdesigner"
            "godot"
            "discord"
            "karabiner-elements"
            "sublime-text"
        ];
    };
}

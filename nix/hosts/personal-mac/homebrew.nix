# Extra Homebrew formulae and casks for my personal Mac, on top of modules/darwin/homebrew.nix.
{ ... }: {
    homebrew = {
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
            "anaconda"
            "rekordbox"
            "mactex"
            "rstudio"
            "zoom"
            "flux-app"
            "touchdesigner"
            "godot"
            "discord"
            "sublime-text"
        ];
    };
}

# Extra nix packages for my personal Mac, on top of modules/core/packages.nix.
{ pkgs, ... }: {
    environment.systemPackages = with pkgs;
        [
            # dev tools
            (pkgs.vim-full.override {
                python3 = pkgs.python3;
                guiSupport = "no";
                darwinSupport = true;
                wrapPythonDrv = true;
            })
            cmake
            gcc
            wasmtime
            wabt

            # languages
            erlang
            ocaml
            # data science
            opam
            lightgbm
            jupyter
            # networking
            zeromq
            # useful cli tools
            docker_28
            gdb
            mactop
            qemu
            neofetch
            texliveFull
            # auxiliary cli tools
            templ
            hledger
            mupdf
            spicetify-cli
            # LSPs
            zls
            texlab                         # latex
            metals                         # scala
            jdt-language-server            # java
            erlang-ls                      # erlang
            # NOTE: haskell-language-server intentionally NOT here - HLS must
            # match your GHC, and your GHC comes from brew/ghcup. Use:
            #   ghcup install hls
            # zls is already installed above (and also via brew - one is enough).
        ];
}

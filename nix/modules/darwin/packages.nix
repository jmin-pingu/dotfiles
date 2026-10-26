# CLI tools, languages and LSPs installed system-wide.
{ pkgs, ... }: {
    environment.systemPackages = with pkgs; 
        [ 
            # dev tools
            direnv
            git
            tmux
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
            neovim
            fzf

            # languages
            lua
            python3
            erlang
            nodejs
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
            gzip
            wget
            mactop
            qemu
            neofetch
            yazi
            texliveFull
            # auxiliary cli tools
            templ 
            hledger
            mupdf
            spicetify-cli
            zsh-powerlevel10k
            # LSPs
            zls
            gopls
            lua-language-server
            pyright
            typescript-language-server
            vscode-langservers-extracted   # json, html, css, eslint servers
            bash-language-server
            texlab                         # latex
            marksman                       # markdown
            markdownlint-cli2              # markdown linter (replaces coc-markdownlint)
            metals                         # scala
            terraform-ls                   # terraform
            yaml-language-server           # yaml (+ docker-compose schemas)
            dockerfile-language-server-nodejs
            docker-compose-language-service
            taplo                          # toml
            jdt-language-server            # java
            erlang-ls                      # erlang
            tree-sitter                    # CLI: needed to build grammars like latex
            # NOTE: haskell-language-server intentionally NOT here - HLS must
            # match your GHC, and your GHC comes from brew/ghcup. Use:
            #   ghcup install hls
            # zls is already installed above (and also via brew - one is enough).
        ];
}

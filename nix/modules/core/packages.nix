# Packages for every machine (Macs and servers): shell, editor, and the LSPs my nvim config uses.
{ pkgs, ... }: {
    environment.systemPackages = with pkgs;
        [
            # shell and editor
            direnv
            git
            tmux
            neovim
            fzf
            gzip
            wget
            yazi
            zsh-powerlevel10k
            tree-sitter                    # CLI: needed to build grammars like latex

            # languages
            lua
            python3
            nodejs

            # LSPs
            gopls
            lua-language-server
            pyright
            typescript-language-server
            vscode-langservers-extracted   # json, html, css, eslint servers
            bash-language-server
            marksman                       # markdown
            markdownlint-cli2              # markdown linter (replaces coc-markdownlint)
            yaml-language-server           # yaml (+ docker-compose schemas)
            dockerfile-language-server
            docker-compose-language-service
            taplo                          # toml
            terraform-ls                   # terraform
        ];
}

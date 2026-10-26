# Zsh setup that works on any machine. Hosts add their own aliases and paths.
{ lib, pkgs, ... }: {
    programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion.enable = true;
        history = {
            ignoreAllDups = true;
        };
        # TODO: add oh-my-zsh and p10k config here
        shellAliases = {
            ll = "ls -l";
            ev = "nvim $HOME/.config/nvim";
            vim = "nvim";
            cpmac = "cp $HOME/.macros.tex ./macros.tex";
            emac = "nvim $HOME/.macros.tex";
            enix = "nvim $HOME/dotfiles";
            nt = "vim /tmp/$(echo $(uuidgen) | tr '[:upper:]' '[:lower:]' | tr -d '[\-]')";
        };
        initContent = lib.mkOrder 1500 ''
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        source $HOME/.p10k.zsh
        bindkey '^ ' autosuggest-accept
        eval "$(direnv hook zsh)"
        # Secrets live outside the flake so they never reach /nix/store.
        # set -a exports every variable the file sets.
        if [ -f $HOME/.config/zsh/secrets.zsh ]; then
            set -a; source $HOME/.config/zsh/secrets.zsh; set +a
        fi
        '';
    };
}

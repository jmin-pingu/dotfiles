# Zsh setup that works on any machine. Hosts add their own aliases and paths.
{ lib, ... }: {
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
            ev = "nvim ~/.config/nvim";
            vim = "nvim";
            cpmac = "cp ~/.macros.tex ./macros.tex";
            emac = "nvim ~/.macros.tex";
            enix = "nvim ~/dotfiles/nix";
            nt = "vim /tmp/$(echo $(uuidgen) | tr '[:upper:]' '[:lower:]' | tr -d '[\-]')";
        };
        initContent = lib.mkOrder 1500 ''
        source ~/powerlevel10k/powerlevel10k.zsh-theme
        source ~/.p10k.zsh
        bindkey '^ ' autosuggest-accept
        eval "$(direnv hook zsh)"
        # Secrets live outside the flake so they never reach /nix/store
        [ -f ~/.config/zsh/secrets.zsh ] && source ~/.config/zsh/secrets.zsh
        '';
    };
}

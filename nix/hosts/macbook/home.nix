# home-manager config for jmin on my Macs.
{ ... }: {
    imports = [
        ../../modules/home/git.nix
        ../../modules/home/zsh.nix
        ./env.nix
    ];

    # this is internal compatibility configuration
    # for home-manager, don't change this!
    home = {
        stateVersion = "23.05";
    };
    # Let home-manager install and manage itself.
    programs.home-manager.enable = true;

    # Mac-only aliases.
    programs.zsh = {
        shellAliases = {
            switch = "darwin-rebuild switch --flake ~/dotfiles/nix#macbook";
            rebuild = "darwin-rebuild switch --flake ~/dotfiles/nix#macbook";
            python = "python3";
            man = "/usr/bin/man";
        };
    };
}

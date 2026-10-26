# home-manager config for my user on my Linux machine.
{ ... }: {
    imports = [
        ../../modules/home/git.nix
        ../../modules/home/zsh.nix
    ];

    # Set once when home-manager is first installed here. Don't change it after.
    home.stateVersion = "25.05";
    programs.home-manager.enable = true;

    programs.zsh.shellAliases = {
        switch = "sudo nixos-rebuild switch --flake $HOME/dotfiles/nix#linux";
        rebuild = "sudo nixos-rebuild switch --flake $HOME/dotfiles/nix#linux";
    };
}

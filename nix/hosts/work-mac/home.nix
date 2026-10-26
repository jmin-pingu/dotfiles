# home-manager config for my user on my work Mac.
{ ... }: {
    imports = [
        ../../modules/home/git.nix
        ../../modules/home/zsh.nix
    ];

    # Set once when home-manager is first installed here. Don't change it after.
    home.stateVersion = "25.05";
    programs.home-manager.enable = true;

    programs.git.userEmail = "WORK_EMAIL_REMOVED";

    programs.zsh.shellAliases = {
        switch = "darwin-rebuild switch --flake $HOME/dotfiles/nix#work-mac";
        rebuild = "darwin-rebuild switch --flake $HOME/dotfiles/nix#work-mac";
    };
}

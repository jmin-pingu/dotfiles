# nix-darwin config for my personal Mac. Shared Mac settings are in modules/darwin/.
{ ... }: {
    imports = [
        ./packages.nix
        ./homebrew.nix
    ];

    # Services
    services = {
    };

    # Enable alternative shell support in nix-darwin.
    # programs.fish.enable = true;

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    system.stateVersion = 6;
}

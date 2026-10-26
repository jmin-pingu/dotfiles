# nix-darwin config for my work Mac. Shared Mac settings are in modules/darwin/.
{ ... }: {
    imports = [
        ./packages.nix
        ./homebrew.nix
    ];

    # Set once when nix-darwin is first installed on this Mac. Don't change it after.
    system.stateVersion = 6;
}

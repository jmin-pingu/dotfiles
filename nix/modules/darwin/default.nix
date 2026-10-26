# Settings for every Mac. Hosts add their own in hosts/<name>/.
{ self, ... }: {
    imports = [
        ../core/packages.nix
        ./homebrew.nix
    ];

    # Necessary for using flakes on this system.
    nix.settings.experimental-features = "nix-command flakes";

    # Set Git commit hash for darwin-version.
    system.configurationRevision = self.rev or self.dirtyRev or null;
}

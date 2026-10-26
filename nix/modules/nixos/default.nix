# Settings for every NixOS machine. Hosts add their own in hosts/<name>/.
{ self, pkgs, user, ... }: {
    imports = [
        ../core/packages.nix
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    system.configurationRevision = self.rev or self.dirtyRev or null;

    programs.zsh.enable = true;
    users.users.${user} = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        shell = pkgs.zsh;
    };
}

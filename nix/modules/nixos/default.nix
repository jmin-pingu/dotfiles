# Settings for every NixOS machine. Hosts add their own in hosts/<name>/.
{ self, pkgs, user, ... }: {
    imports = [
        ../core/packages.nix
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    system.configurationRevision = self.rev or self.dirtyRev or null;

    programs.zsh.enable = true;
    # No password here (it would land in git and the nix store). Keep users
    # mutable so the password set at install or with `passwd` survives rebuilds.
    users.mutableUsers = true;
    users.users.${user} = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        shell = pkgs.zsh;
    };
}

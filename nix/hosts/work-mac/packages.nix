# Extra nix packages for my work Mac, on top of modules/core/packages.nix.
{ pkgs, ... }: {
    environment.systemPackages = with pkgs; [
    ];
}

# Extra nix packages for my Linux machine, on top of modules/core/packages.nix.
{ pkgs, ... }: {
    environment.systemPackages = with pkgs; [
    ];
}

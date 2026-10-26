# NixOS config for my Linux machine. Shared NixOS settings are in modules/nixos/.
{ ... }: {
    imports = [
        ./hardware-configuration.nix
        ./packages.nix
    ];

    networking.hostName = "linux";
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Set once when NixOS is first installed. Don't change it after.
    system.stateVersion = "25.05";
}

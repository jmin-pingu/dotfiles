# PLACEHOLDER so the flake evaluates. On the machine, replace this file with:
#   nixos-generate-config --show-hardware-config > hardware-configuration.nix
{ ... }: {
    fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
    };
}

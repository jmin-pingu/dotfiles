{
    description = "Jonathan's machines";
    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
        nix-darwin = {
            url = "github:nix-darwin/nix-darwin/master";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };

    outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }:
        let
            # A Mac: shared modules/darwin + hosts/<name>/.
            mkMac = { name, user ? "jmin", system ? "aarch64-darwin" }:
                nix-darwin.lib.darwinSystem {
                    specialArgs = { inherit self user; };
                    modules = [
                        { nixpkgs.hostPlatform = system; }
                        ./modules/darwin
                        (./hosts + "/${name}")
                        home-manager.darwinModules.home-manager {
                            users.users.${user}.home = "/Users/${user}";
                            home-manager.useGlobalPkgs = true;
                            home-manager.useUserPackages = true;
                            home-manager.verbose = true;
                            # Move a file in the way to <name>.backup instead of failing.
                            home-manager.backupFileExtension = "backup";
                            home-manager.users.${user} = import (./hosts + "/${name}/home.nix");
                        }
                    ];
                };

            # A NixOS machine: shared modules/nixos + hosts/<name>/.
            mkLinux = { name, user ? "jmin", system ? "x86_64-linux" }:
                nixpkgs.lib.nixosSystem {
                    specialArgs = { inherit self user; };
                    modules = [
                        { nixpkgs.hostPlatform = system; }
                        ./modules/nixos
                        (./hosts + "/${name}")
                        home-manager.nixosModules.home-manager {
                            home-manager.useGlobalPkgs = true;
                            home-manager.useUserPackages = true;
                            home-manager.users.${user} = import (./hosts + "/${name}/home.nix");
                        }
                    ];
                };
        in
        {
            # One line per machine. Pick one with: --flake .#<name>
            darwinConfigurations."personal-mac" = mkMac { name = "personal-mac"; };
            darwinConfigurations."work-mac" = mkMac { name = "work-mac"; user = "jonathan"; };
            nixosConfigurations."linux" = mkLinux { name = "linux"; };
        };
}

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

    # One entry per machine. Each machine's config lives in hosts/<name>/.
    outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager }: {
        darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
            specialArgs = { inherit self; };
            modules = [
                ./hosts/macbook
                home-manager.darwinModules.home-manager {
                    users.users.jmin.home = "/Users/jmin";
                    home-manager.useGlobalPkgs = true;
                    home-manager.useUserPackages = true;
                    home-manager.verbose = true;
                    home-manager.users.jmin = import ./hosts/macbook/home.nix;
                }
            ];
        };
    };
}

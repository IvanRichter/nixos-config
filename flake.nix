{
  description = "COSMIC DE + NVIDIA + Apple Silicon";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";

    # Asahi/Apple Silicon support
    apple-silicon.url = "github:nix-community/nixos-apple-silicon";
  };

  outputs = { self, nixpkgs, home-manager, flake-utils, apple-silicon, ... }: {
    nixosConfigurations = {
      desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/desktop/desktop.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "bak";
            home-manager.users.ivan = import ./home/ivan.nix;
          }
        ];
        specialArgs = {
          starshipToml = ./dotfiles/starship.toml;
        };
      };

      
      mbp-m2max = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          # Wire up Asahi
          apple-silicon.nixosModules.apple-silicon-support

          # Host module
          ./hosts/mbp-m2max/mbp-m2max.nix

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "bak";
            home-manager.users.ivan = import ./home/ivan.nix;
          }
        ];
        specialArgs = {
          starshipToml = ./dotfiles/starship.toml;
        };
      };
    };
  };
}

{
  description = "COSMIC DE + NVIDIA + Apple Silicon";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";

    # Asahi/Apple Silicon support
    apple-silicon.url = "github:nix-community/nixos-apple-silicon";

    # nix-index prebuilt database + comma runner
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
  };

  # Bind inputs
  outputs = { self, nixpkgs, home-manager, flake-utils, apple-silicon, stylix, ... } @ inputs:
    let
      overlays = import ./overlays;
    in {
      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            { nixpkgs.overlays = overlays; }
            ./hosts/desktop/desktop.nix
            stylix.nixosModules.stylix

            # nix-index database module
            inputs."nix-index-database".nixosModules.nix-index

            # nix-index + comma integration
            {
              programs.nix-index.enable = true;
              programs.nix-index.enableFishIntegration = true;
              programs.command-not-found.enable = false;
              programs.nix-index-database.comma.enable = true;
            }

            # Home Manager
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "bak";
              home-manager.users.ivan = import ./home/ivan.nix;
            }
          ];
        };

        mbp-m2max = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            { nixpkgs.overlays = overlays; }
            # Wire up Asahi
            apple-silicon.nixosModules.apple-silicon-support
            stylix.nixosModules.stylix

            # Host module
            ./hosts/mbp-m2max/mbp-m2max.nix

            # nix-index database module
            inputs."nix-index-database".nixosModules.nix-index

            # nix-index + comma integration
            {
              programs.nix-index.enable = true;
              programs.nix-index.enableFishIntegration = true;
              programs.command-not-found.enable = false;
              programs.nix-index-database.comma.enable = true;
            }

            # Home Manager
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "bak";
              home-manager.users.ivan = import ./home/ivan.nix;
            }
          ];
        };
      };
    };
}

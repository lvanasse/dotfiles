{
  description = "lvanasse's flake";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    determinate.url = "github:DeterminateSystems/determinate";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-gc-env.url = "github:Julow/nix-gc-env";

  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      determinate,
      plasma-manager,
      nix-flatpak,
      nix-ld,
      stylix,
      nix-gc-env,
      ...
    }:
    let
      qbittorrent510 = final: prev: {
        qbittorrent = prev.qbittorrent.overrideAttrs (_: {
          version = "5.1.0";
          src = prev.fetchurl {
            url = "https://github.com/qbittorrent/qBittorrent/archive/refs/tags/release-5.1.0.tar.gz";
            sha256 = "sha256-rFTNizxgNc/NaEvlr9DszIxfu8MAiptvm6QvbvkRBa8=";
          };
        });
      };

      mkHost =
        {
          hostname,
          username ? "ludovic",
          system ? "x86_64-linux",
          overlays ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs username hostname nix-gc-env; };
          modules = [
            (
              { ... }:
              {
                nixpkgs.overlays = overlays;
              }
            )
            ./hosts/${hostname}/${hostname}.nix
            determinate.nixosModules.default
            home-manager.nixosModules.home-manager
            nix-flatpak.nixosModules.nix-flatpak
            nix-ld.nixosModules.nix-ld
            nix-gc-env.nixosModules.default
            # stylix.nixosModules.stylix
            (
              { pkgs, ... }:
              {
                home-manager.useUserPackages = true;
                home-manager.extraSpecialArgs = { inherit username hostname inputs; };
                home-manager.users.${username}.imports = [
                  ./home/default.nix
                  ./home/${hostname}.nix
                ];
                home-manager.sharedModules = [
                  plasma-manager.homeManagerModules.plasma-manager
                ];
              }
            )
          ];
        };
    in
    {
      nixosConfigurations = {
        pc = mkHost {
          hostname = "pc";
          overlays = [ qbittorrent510 ];
        };

        laptop = mkHost {
          hostname = "laptop";
        };
      };

      homeConfigurations = {
        "ludovic@pc" = self.nixosConfigurations.pc.config.home-manager.users.ludovic;
        "ludovic@laptop" = self.nixosConfigurations.laptop.config.home-manager.users.ludovic;
      };
    };
}

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
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      determinate,
      plasma-manager,
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

      username = "ludovic";

      mkHost =
        {
          hostname,
          system ? "x86_64-linux",
          overlays ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs username hostname; };
          modules = [
            (
              { ... }:
              {
                nixpkgs.overlays = overlays;
              }
            )
            ./host/${hostname}/${hostname}.nix
            determinate.nixosModules.default
            home-manager.nixosModules.home-manager
            plasma-manager.homeManagerModules.plasma-manager
            (
              { pkgs, ... }:
              {
                home-manager.useUserPackages = true;
                home-manager.users.${username} = import ./home/default.nix;
              }
            )
          ];
        };
    in
    {
      nixosConfigurations = {
        pc = mkHost {
          hostname = "pc";
          overlays = [ self.overlays.qbittorrent510 ];
        };

        laptop = mkHost {
          hostname = "laptop";
        };
      };

      homeConfigurations = {
        "${username}@pc" = self.nixosConfigurations.pc.config.home-manager.users.${username};
        "${username}@laptop" = self.nixosConfigurations.laptop.config.home-manager.users.${username};
      };
    };

  # outputs =
  #   inputs@{
  #     self,
  #     nixpkgs,
  #     home-manager,
  #     determinate,
  #     plasma-manager,
  #     ...
  #   }:
  #   let
  #     system = "x86_64-linux";
  #     username = "ludovic";
  #     hostname = "pc";

  #     qbittorrent510 = final: prev: {
  #       qbittorrent = prev.qbittorrent.overrideAttrs (_: {
  #         version = "5.1.0";
  #         src = prev.fetchurl {
  #           url = "https://github.com/qbittorrent/qBittorrent/archive/refs/tags/release-5.1.0.tar.gz";
  #           sha256 = "sha256-rFTNizxgNc/NaEvlr9DszIxfu8MAiptvm6QvbvkRBa8=";
  #         };
  #       });
  #     };
  #   in
  #   {
  #     overlays.default = qbittorrent510;

  #     nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
  #       inherit system;
  #       specialArgs = { inherit inputs username hostname; };

  #       modules = [
  #         ./configuration.nix
  #         determinate.nixosModules.default

  #         (
  #           { config, ... }:
  #           {
  #             nixpkgs.overlays = [ qbittorrent510 ];
  #           }
  #         )

  #         home-manager.nixosModules.home-manager
  #         (
  #           { pkgs, ... }:
  #           {
  #             home-manager.useUserPackages = true;
  #             home-manager.users.${username} = import ./home.nix;

  #             home-manager.sharedModules = [
  #               plasma-manager.homeManagerModules.plasma-manager
  #               (
  #                 { config, ... }:
  #                 {
  #                   nixpkgs.overlays = [ qbittorrent510 ];
  #                 }
  #               )
  #             ];
  #           }
  #         )
  #       ];
  #     };

  #     homeConfigurations."${username}@${hostname}" = home-manager.lib.homeManagerConfiguration {
  #       pkgs = import nixpkgs {
  #         inherit system;
  #         overlays = [ qbittorrent510 ];
  #       };

  #       extraSpecialArgs = { inherit inputs username hostname; };

  #       modules = [
  #         ./home.nix
  #         plasma-manager.homeManagerModules.plasma-manager
  #       ];
  #     };
  #   };
}

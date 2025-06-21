{
  description = "NixOS and Home Manager Configuration";

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
      system = "x86_64-linux";
      username = "ludovic";
      hostname = "pc";

      qbittorrent505 = final: prev: {
        qbittorrent = prev.qbittorrent.overrideAttrs (_: {
          version = "5.0.5";
          src = prev.fetchurl {
            url = "https://github.com/qbittorrent/qBittorrent/archive/refs/tags/release-5.0.5.tar.gz";
            sha256 = "sha256-ebAwVl+jkqa8Jnsk9TjXuOdi9gfuc0s9RZsZxhwWi3M=";
          };
        });
      };
    in
    {
      overlays.default = qbittorrent505;

      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs username hostname; };

        modules = [
          ./configuration.nix
          determinate.nixosModules.default

          (
            { config, ... }:
            {
              nixpkgs.overlays = [ qbittorrent505 ];
            }
          )

          home-manager.nixosModules.home-manager
          (
            { pkgs, ... }:
            {
              home-manager.useUserPackages = true;
              home-manager.users.${username} = import ./home.nix;

              home-manager.sharedModules = [
                plasma-manager.homeManagerModules.plasma-manager
                (
                  { config, ... }:
                  {
                    nixpkgs.overlays = [ qbittorrent505 ];
                  }
                )
              ];

              nixpkgs.overlays = [ qbittorrent505 ];
            }
          )
        ];
      };

      homeConfigurations."${username}@${hostname}" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ qbittorrent505 ];
        };

        extraSpecialArgs = { inherit inputs username hostname; };

        modules = [
          ./home.nix
          plasma-manager.homeManagerModules.plasma-manager
        ];
      };
    };
}

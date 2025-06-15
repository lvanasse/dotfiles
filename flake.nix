{
  description = "NixOS and Home Manager Configuration";

  inputs = {
    determinate.url = "github:DeterminateSystems/determinate";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      determinate,
      ...
    }:
    let
      system = "x86_64-linux";
      username = "ludovic";
      hostname = "pc";
    in
    {
      nixosConfigurations = {
        ${hostname} = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${username} = import ./home.nix;
            }
            determinate.nixosModules.default
          ];
        };
      };

      homeConfigurations = {
        "${username}@${hostname}" = home-manager.lib.homeManagerConfiguration {
          inherit system;
          pkgs = import nixpkgs { inherit system; };
          modules = [
            ./home.nix
            {
              home.username = username;
              home.homeDirectory = "/home/${username}";
              home.stateVersion = "24.11"; # Adjust to your Home Manager version
            }
            determinate.nixosModules.default
          ];
        };
      };
    };
}



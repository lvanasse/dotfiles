# {
#   description = "Ludovic Vanasse NixOS's flake";

#   inputs = {
#     nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
#     home-manager.url = "github:nix-community/home-manager/release-24.11";
#     home-manager.inputs.nixpkgs.follows = "nixpkgs";
#   };

#   outputs = { self, nixpkgs, home-manager, ... }@inputs: {
#     nixosConfigurations.pc = nixpkgs.lib.nixosSystem {
#       system = "x86_64-linux";
#       modules = [
#         ./configuration.nix

#         home-manager.nixosModules.home-manager {
#             home-manager.useGlobalPkgs = true;
#             home-manager.useUserPackages = true;
#             home-manager.users.ludovic = import ./home.nix;
#             home-manager.backupFileExtension = "backup";
#         }
#       ];
#     };
#   };
# }


{
  description = "NixOS and Home Manager Configuration";

  inputs = {
    determinate.url = "github:DeterminateSystems/determinate";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, determinate, ... }:
    let
      system = "x86_64-linux";
      username = "ludovic";
      hostname = "pc";
    in {
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

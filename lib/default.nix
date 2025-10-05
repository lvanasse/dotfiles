{ lib }:
{
  # Custom library functions for the dotfiles configuration

  # Helper function to create a host configuration
  mkHost =
    {
      inputs,
      hostname,
      username ? "ludovic",
      system ? "x86_64-linux",
      overlays ? [ ],
      extraModules ? [ ],
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit
          inputs
          username
          hostname
          ;
      };
      modules = [
        (
          { ... }:
          {
            nixpkgs.overlays = overlays;
          }
        )
        ./hosts/${hostname}/${hostname}.nix
        inputs.determinate.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.nix-gc-env.nixosModules.default
        (
          { pkgs, ... }:
          {
            home-manager.useUserPackages = true;
            home-manager.users.${username} = {
              nixpkgs.overlays = overlays ++ [ inputs.nix-vscode-extensions.overlays.default ];
              nixpkgs.config.allowUnfree = true;
              imports = [
                ./home/default.nix
                ./home/${hostname}.nix
              ];
            };
            home-manager.sharedModules = [
              inputs.plasma-manager.homeModules.plasma-manager
              inputs.stylix.homeModules.stylix
            ];
          }
        )
      ]
      ++ extraModules;
    };

  # Helper to get all Nix files in a directory
  getNixFiles =
    dir:
    let
      files = lib.attrNames (lib.filterAttrs (name: type: type == "regular") (builtins.readDir dir));
      nixFiles = lib.filter (lib.hasSuffix ".nix") files;
    in
    map (file: dir + "/${file}") nixFiles;

  # Helper to import all Nix files in a directory
  importNixFiles =
    dir:
    let
      files = lib.attrNames (lib.filterAttrs (name: type: type == "regular") (builtins.readDir dir));
      nixFiles = lib.filter (lib.hasSuffix ".nix") files;
    in
    map (file: import (dir + "/" + file)) nixFiles;
}

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
        (_: {
          nixpkgs.overlays = overlays;
        })
        ./hosts/${hostname}/${hostname}.nix
        inputs.determinate.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.nix-gc-env.nixosModules.default
        (_: {
          home-manager = {
            useUserPackages = true;
            users.${username} = {
              nixpkgs.overlays = overlays ++ [ inputs.nix-vscode-extensions.overlays.default ];
              nixpkgs.config.allowUnfree = true;
              imports = [
                ./home/default.nix
                ./home/${hostname}.nix
              ];
            };
            sharedModules = [
              inputs.plasma-manager.homeModules.plasma-manager
              inputs.stylix.homeModules.stylix
            ];
          };
        })
      ]
      ++ extraModules;
    };

  # Helper to get all Nix files in a directory
  getNixFiles =
    dir:
    let
      files = lib.attrNames (lib.filterAttrs (_: type: type == "regular") (builtins.readDir dir));
      nixFiles = lib.filter (lib.hasSuffix ".nix") files;
    in
    map (file: dir + "/${file}") nixFiles;

  # Helper to import all Nix files in a directory
  importNixFiles =
    dir:
    let
      files = lib.attrNames (lib.filterAttrs (_: type: type == "regular") (builtins.readDir dir));
      nixFiles = lib.filter (lib.hasSuffix ".nix") files;
    in
    map (file: import (dir + "/" + file)) nixFiles;
}

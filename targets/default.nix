{
  config,
  inputs,
  lib,
  ...
}:
let
  defaultUsername = config.flake.lib.username;
  system = "x86_64-linux";
  targets = {
    pc = {
      nixos = true;
      modules = [ "target.pc" ];
    };
    laptop = {
      nixos = true;
      modules = [ "target.laptop" ];
    };
    "hm-only" = {
      nixos = false;
      modules = [ "target.hm-only" ];
    };
    "work-laptop" = {
      nixos = false;
      modules = [ "target.work-laptop" ];
    };
    steamdeck = {
      nixos = false;
      username = "deck";
      modules = [ "target.steamdeck" ];
    };
    server = {
      nixos = true;
      modules = [ "target.server" ];
    };
    gateway = {
      nixos = true;
      modules = [ "target.gateway" ];
      nixpkgsInput = inputs.gateway-nixpkgs;
      homeManagerInput = inputs.gateway-home-manager;
      sharedHomeModules = [ ];
    };
  };

  mkNixos =
    hostname: target:
    config.flake.lib.mkNixosConfiguration {
      username = defaultUsername;
      inherit hostname system;
      modules = target.modules;
      nixpkgsInput = target.nixpkgsInput or inputs.nixpkgs;
      homeManagerInput = target.homeManagerInput or inputs.home-manager;
      sharedHomeModules =
        target.sharedHomeModules or [ inputs.plasma-manager.homeModules.plasma-manager ];
    };

  mkHome =
    _hostname: target:
    config.flake.lib.mkHomeConfiguration {
      inherit system;
      modules = target.modules;
      nixpkgsInput = target.nixpkgsInput or inputs.nixpkgs;
      homeManagerInput = target.homeManagerInput or inputs.home-manager;
      sharedHomeModules =
        target.sharedHomeModules or [ inputs.plasma-manager.homeModules.plasma-manager ];
    };

in
{
  # NixOS target modules
  flake.modules.nixos."target.pc" = ./pc/nixos.nix;
  flake.modules.nixos."target.laptop" = ./laptop/nixos.nix;
  flake.modules.nixos."target.server" = ./server/nixos.nix;
  flake.modules.nixos."target.gateway" = ./gateway/nixos.nix;

  # Home Manager target modules
  flake.modules.homeManager."target.pc" = ./pc/hm.nix;
  flake.modules.homeManager."target.laptop" = ./laptop/hm.nix;
  flake.modules.homeManager."target.hm-only" = ./hm-only/hm.nix;
  flake.modules.homeManager."target.work-laptop" = ./work-laptop/hm.nix;
  flake.modules.homeManager."target.steamdeck" = ./steamdeck/hm.nix;
  flake.modules.homeManager."target.server" = ./server/hm.nix;
  flake.modules.homeManager."target.gateway" = ./gateway/hm.nix;

  flake.nixosConfigurations = lib.mapAttrs mkNixos (
    lib.filterAttrs (_: target: target.nixos or false) targets
  );

  flake.homeConfigurations = lib.mapAttrs' (
    hostname: target:
    let
      targetUsername = target.username or defaultUsername;
    in
    lib.nameValuePair "${targetUsername}@${hostname}" (mkHome hostname target)
  ) targets;
}

{ config, lib, ... }:
let
  defaultUsername = config.flake.lib.username;
  system = "x86_64-linux";
  hosts = {
    pc = {
      nixos = true;
      modules = [
        "profile.workstation"
        "desktop.sway"
        "desktop.kde"
        "feature.steam"
        "host.pc"
      ];
    };
    laptop = {
      nixos = true;
      modules = [
        "profile.workstation"
        "desktop.sway"
        "desktop.kde"
        "host.laptop"
      ];
    };
    "hm-only" = {
      nixos = false;
      modules = [
        "profile.workstation"
        "desktop.sway"
        "host.hm-only"
      ];
    };
    steamdeck = {
      nixos = false;
      username = "deck";
      modules = [
        "core"
        "terminalFish"
        "terminalStarship"
        "host.steamdeck"
      ];
    };
    server = {
      nixos = true;
      modules = [
        "profile.server"
        "host.server"
      ];
    };
  };

  mkNixos =
    hostname: host:
    config.flake.lib.mkNixosConfiguration {
      username = defaultUsername;
      inherit hostname system;
      modules = host.modules;
    };

  mkHome =
    _hostname: host:
    config.flake.lib.mkHomeConfiguration {
      inherit system;
      modules = host.modules;
    };

in
{
  # NixOS host modules
  flake.modules.nixos."host.pc" = ./pc/pc.nix;
  flake.modules.nixos."host.laptop" = ./laptop/laptop.nix;
  flake.modules.nixos."host.server" = ./server/server.nix;

  # Home Manager host modules
  flake.modules.homeManager."host.pc" = ./pc/home.nix;
  flake.modules.homeManager."host.laptop" = ./laptop/home.nix;
  flake.modules.homeManager."host.hm-only" = ./hm-only/home.nix;
  flake.modules.homeManager."host.steamdeck" = ./steamdeck/home.nix;
  flake.modules.homeManager."host.server" = ./server/home.nix;

  flake.nixosConfigurations = lib.mapAttrs mkNixos (
    lib.filterAttrs (_: host: host.nixos or false) hosts
  );

  flake.homeConfigurations = lib.mapAttrs' (
    hostname: host:
    let
      hostUsername = host.username or defaultUsername;
    in
    lib.nameValuePair "${hostUsername}@${hostname}" (mkHome hostname host)
  ) hosts;
}

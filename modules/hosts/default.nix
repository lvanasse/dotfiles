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
    laptop-ubuntu = {
      nixos = false;
      modules = [
        "profile.workstation"
        "desktop.sway"
        "desktop.kde"
        "host.laptop-ubuntu"
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
  flake.modules.nixos."host.pc" = ../../nixos/pc/pc.nix;
  flake.modules.nixos."host.laptop" = ../../nixos/laptop/laptop.nix;

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

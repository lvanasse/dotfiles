{ config, lib, ... }:
let
  username = config.flake.lib.username;
  system = "x86_64-linux";
  hosts = {
    pc = {
      modules = [
        "profile.workstation"
        "desktop.sway"
        "desktop.kde"
        "feature.steam"
        "host.pc"
      ];
    };
    laptop = {
      modules = [
        "profile.workstation"
        "desktop.sway"
        "desktop.kde"
        "host.laptop"
      ];
    };
  };

  mkNixos =
    hostname: host:
    config.flake.lib.mkNixosConfiguration {
      inherit hostname system username;
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
  flake.modules.nixos."host.pc" = ../../hosts/pc/pc.nix;
  flake.modules.nixos."host.laptop" = ../../hosts/laptop/laptop.nix;

  flake.nixosConfigurations = lib.mapAttrs mkNixos hosts;

  flake.homeConfigurations = lib.mapAttrs' (
    hostname: host: lib.nameValuePair "${username}@${hostname}" (mkHome hostname host)
  ) hosts;
}

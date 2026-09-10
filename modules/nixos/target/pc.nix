{ config, ... }:
let
  username = config.flake.lib.username;
in
{
  flake.modules.nixos."target.config.pc" =
    { inputs, lib, ... }:
    let
      atticPushTokenAge = "${inputs.secrets}/attic/pc-push-token.age";
    in
    {
      imports = [
        inputs.disko.nixosModules.disko
        ../../../hardware/pc/hardware-configuration.nix
        ../../../hardware/pc/disko.nix
        config.flake.modules.nixos."target.config.pc.hardware"
        config.flake.modules.nixos."target.config.pc.networking"
        config.flake.modules.nixos."target.config.pc.services"
        config.flake.modules.nixos."target.config.pc.programs"
        config.flake.modules.nixos."target.config.pc.packages"
        config.flake.modules.nixos."target.config.pc.torrenting"
      ];

      age.secrets."attic-pc-push-token" = lib.mkIf (builtins.pathExists atticPushTokenAge) {
        file = atticPushTokenAge;
        path = "/run/agenix/attic-pc-push-token";
        mode = "0400";
        owner = username;
        group = "users";
      };
    };
}

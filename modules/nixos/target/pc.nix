{ config, ... }:
{
  flake.modules.nixos."target.config.pc" =
    { inputs, ... }:
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
    };
}

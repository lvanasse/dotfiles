{ config, ... }:
{
  flake.modules.nixos."targetConfig.pc" =
    { inputs, ... }:
    {
      imports = [
        inputs.disko.nixosModules.disko
        ../../../hardware/pc/hardware-configuration.nix
        ../../../hardware/pc/disko.nix
        config.flake.modules.nixos."targetConfig.pc.hardware"
        config.flake.modules.nixos."targetConfig.pc.networking"
        config.flake.modules.nixos."targetConfig.pc.services"
        config.flake.modules.nixos."targetConfig.pc.programs"
        config.flake.modules.nixos."targetConfig.pc.packages"
        config.flake.modules.nixos."targetConfig.pc.torrenting"
      ];
    };
}

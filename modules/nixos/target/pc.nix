{ config, ... }:
{
  flake.modules.nixos."targetConfig.pc" =
    { ... }:
    {
      imports = [
        ../../../hardware/pc/hardware-configuration.nix
        config.flake.modules.nixos."targetConfig.pc.hardware"
        config.flake.modules.nixos."targetConfig.pc.networking"
        config.flake.modules.nixos."targetConfig.pc.services"
        config.flake.modules.nixos."targetConfig.pc.programs"
        config.flake.modules.nixos."targetConfig.pc.packages"
        config.flake.modules.nixos."targetConfig.pc.torrenting"
      ];
    };
}

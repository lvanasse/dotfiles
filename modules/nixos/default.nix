{ config, ... }:
{
  flake.modules.nixos."profile.workstation" =
    { ... }:
    {
      imports = [
        config.flake.modules.nixos.core
        config.flake.modules.nixos."desktop.common"
        config.flake.modules.nixos.services
        config.flake.modules.nixos.programs
      ];
    };
}

{ config, ... }:
{
  flake.modules.nixos."desktop.common" =
    { ... }:
    {
      imports = [
        config.flake.modules.nixos."desktop.audio"
        config.flake.modules.nixos."desktop.fonts"
      ];
    };
}

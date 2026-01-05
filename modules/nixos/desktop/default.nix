{ config, ... }:
{
  flake.modules.nixos."desktop.common" =
    { ... }:
    {
      imports = [
        config.flake.modules.nixos.desktopAudio
        config.flake.modules.nixos.desktopFonts
      ];
    };
}

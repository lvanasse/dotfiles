{ ... }:
{
  flake.modules.homeManager."packages.gaming" =
    { pkgs, ... }:
    {
      # Gaming packages
      home.packages = with pkgs; [
        # Gaming platforms
        qbittorrent
        gamescope
        gamemode

        # Emulation
        xemu
        pcsx2
        (retroarch.withCores (
          cores: with cores; [
            snes9x # Super NES
            mupen64plus # Nintendo 64
            genesis-plus-gx # Mega Drive / SMS / GG
            pcsx2 # PlayStation 2
            dolphin # GameCube / Wii
          ]
        ))
        retroarch-assets
      ];
    };
}

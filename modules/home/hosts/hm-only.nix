{ ... }:
{
  flake.modules.homeManager."host.hm-only" =
    { pkgs, ... }:
    {
      # Host-specific overrides for the Home Manager-only configuration go here.
      # Install fonts for non-NixOS systems
      fonts.fontconfig.enable = true;
      home.packages = with pkgs; [
        nerd-fonts.fira-code
        mesa # Provides libEGL.so.1 for Wayland/EGL
      ];
      home.sessionVariables.WEZTERM_ENABLE_WAYLAND = "0";
    };
}

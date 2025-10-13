# Sway desktop (system-level)
{ pkgs, lib, ... }:
{
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraSessionCommands = ''
      export XDG_CURRENT_DESKTOP=sway
      export XDG_SESSION_DESKTOP=sway
      export GTK_USE_PORTAL=1
      export QT_QPA_PLATFORM=wayland
      export SDL_VIDEODRIVER=wayland
      export MOZ_ENABLE_WAYLAND=1
    '';
  };

  # Portals suitable for Sway (wlr + GTK)
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
    # Prefer GTK backend first for broader interface coverage (FileChooser, Settings),
    # then fall back to wlr for screenshot/screencast under Sway.
    config = {
      sway = {
        default = lib.mkForce "gtk;wlr";
      };
    };
  };
}

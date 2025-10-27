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
      # Encourage Firefox to use server-side decorations under Sway
      export MOZ_GTK_TITLEBAR_DECORATION=system
    '';
  };

  # Portals suitable for Sway (wlr + GTK)
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
    # Prefer wlr backend first under Sway to avoid portal startup timeouts,
    # then fall back to GTK for file chooser and generic portals.
    config = {
      sway = {
        default = lib.mkForce "wlr;gtk";
      };
    };
  };
}

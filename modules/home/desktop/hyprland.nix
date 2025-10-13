{ ... }:
{
  # Hyprland (Home Manager). Scoped to hyprland-session via systemd integration
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true; # ensures Hyprland user services don't run under KDE
    # Minimal config to silence HM warning; real config can be added later.
    settings = { };
    extraConfig = "# managed by Home Manager";
  };
}

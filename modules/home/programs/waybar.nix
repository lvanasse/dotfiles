# Waybar package (Sway will start it)
{ ... }:
{
  # Keep Waybar installed but do not manage a systemd unit here.
  # Sway will launch Waybar in its own startup config so it never
  # appears under KDE/Plasma sessions.
  programs.waybar = {
    enable = true;
    systemd.enable = false;
  };
}

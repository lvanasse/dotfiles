# KDE Plasma desktop environment
{ ... }:
{
  # Display manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    # Revert to default SDDM theme
  };

  # Desktop environment
  services.desktopManager.plasma6.enable = true;

  # Additional desktop packages (none specific)
}

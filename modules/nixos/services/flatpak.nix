{ ... }:
{
  flake.modules.nixos.servicesFlatpak =
    { ... }:
    {
      # Flatpak application management
      services.flatpak = {
        enable = true;
        update.auto = {
          enable = true;
          onCalendar = "weekly";
        };
      };
    };
}

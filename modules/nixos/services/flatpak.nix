{ ... }:
{
  flake.modules.nixos."services.flatpak" =
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

{ ... }:
{
  flake.modules.nixos."core.locale" =
    { ... }:
    {
      # Locale, timezone, and keyboard configuration

      # Timezone
      time.timeZone = "America/Toronto";
      time.hardwareClockInLocalTime = true;

      # Locale
      i18n.defaultLocale = "en_CA.UTF-8";

      # XKB keyboard layout (X11 + most Wayland desktops)
      services.xserver.xkb = {
        layout = "us";
        variant = "intl";
      };

      # Console keyboard layout
      console.keyMap = "us-acentos";

      # Environment variables
      environment.sessionVariables = {
        POWERDEVIL_NO_DDCUTIL = "1";
      };
    };
}

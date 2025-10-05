# Locale, timezone, and keyboard configuration
{ config, pkgs, ... }:
{
  # Timezone
  time.timeZone = "America/Toronto";
  time.hardwareClockInLocalTime = true;

  # Locale
  i18n.defaultLocale = "en_CA.UTF-8";

  # Console keyboard layout
  console.keyMap = "us-acentos";

  # Environment variables
  environment.sessionVariables = {
    POWERDEVIL_NO_DDCUTIL = "1";
  };
}

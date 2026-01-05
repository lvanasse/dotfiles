{ ... }:
{
  flake.modules.nixos.servicesPower =
    { ... }:
    {
      # Power management and idle behavior

      # Use systemd-logind to suspend the machine after 10 minutes of system idle.
      # This applies at the SDDM login screen and within desktop sessions unless
      # something explicitly inhibits idle (e.g., media playback, presentations).
      services.logind.settings = {
        Login = {
          IdleAction = "suspend";
          IdleActionSec = "10min";
        };
      };
    };
}

{ ... }:
{
  flake.modules.homeManager."programs.swayidle" =
    { config, pkgs, ... }:
    let
      # Use absolute paths so systemd user services don't depend on PATH ordering.
      swaylockPixelate = "${config.home.homeDirectory}/.nix-profile/bin/swaylock-pixelate";
      swaymsg = "${pkgs.sway}/bin/swaymsg";
    in
    {
      # Manage idle behavior within Sway: blank screen on idle
      services.swayidle = {
        enable = true;
        systemdTarget = "sway-session.target";

        # Timeouts in seconds
        timeouts = [
          # Lock after 5 minutes (temporarily disabled)
          /*
          {
            timeout = 300;
            command = swaylockPixelate;
          }
          */
          # Turn displays off after 15 minutes (resume turns them back on)
          {
            timeout = 900;
            command = "${swaymsg} 'output * power off'";
            resumeCommand = "${swaymsg} 'output * power on'";
          }
        ];

        events = [
          # Ensure we lock right before system sleep (temporarily disabled)
          /*
          {
            event = "before-sleep";
            command = "${swaylockPixelate}; swaymsg 'output * power off'";
          }
          */
          # Wake displays after resume
          {
            event = "after-resume";
            command = "${swaymsg} 'output * power on'";
          }
          /*
          {
            event = "lock";
            command = swaylockPixelate;
          }
          */
        ];
      };
    };
}

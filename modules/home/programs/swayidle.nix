{ ... }:
{
  flake.modules.homeManager."programs.swayidle" =
    { config, pkgs, ... }:
    let
      # Use absolute paths so systemd user services don't depend on PATH ordering.
      swaylockPixelate = "${config.home.homeDirectory}/.nix-profile/bin/swaylock-pixelate";
      swaymsg = "${pkgs.sway}/bin/swaymsg";
      systemctl = "${pkgs.systemd}/bin/systemctl";
      sleep = "${pkgs.coreutils}/bin/sleep";
      jq = "${pkgs.jq}/bin/jq";
      wakeDisplays = pkgs.writeShellScript "wake-displays" ''
        # Some external monitors miss the first wake command after DPMS/suspend.
        ${swaymsg} 'output * power on' || true
        ${sleep} 1
        ${systemctl} --user restart kanshi.service || true
        ${sleep} 1
        ${swaymsg} 'output * power on' || true
      '';
      wakeDisplaysHard = pkgs.writeShellScript "wake-displays-hard" ''
        # Run the standard wake path first.
        ${wakeDisplays}

        # HDMI can stay black after idle on some docks/monitors.
        hdmi_outputs="$(${swaymsg} -t get_outputs -r 2>/dev/null | ${jq} -r '.[] | select(.name | startswith("HDMI-A-")) | .name' || true)"
        if [ -n "$hdmi_outputs" ]; then
          for out in $hdmi_outputs; do
            ${swaymsg} "output $out power off" || true
            ${sleep} 1
            ${swaymsg} "output $out power on" || true
            ${sleep} 1
            ${swaymsg} "output $out disable" || true
            ${sleep} 1
            ${swaymsg} "output $out enable" || true
          done
        fi

        ${systemctl} --user restart kanshi.service || true
        ${swaymsg} 'output * power on' || true
      '';
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
            resumeCommand = "${wakeDisplaysHard}";
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
            command = "${wakeDisplaysHard}";
          }
          # Run the same hard wake path when unlocking a swaylock session.
          {
            event = "unlock";
            command = "${wakeDisplaysHard}";
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

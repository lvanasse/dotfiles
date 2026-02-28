{ ... }:
{
  flake.modules.homeManager."targetConfig.pc" =
    {
      lib,
      pkgs,
      ...
    }:
{
  # PC-specific Sway output layout (host-only)
  wayland.windowManager.sway.extraConfig = lib.mkAfter ''
        # Displays (from sway-export-outputs)
        output DVI-D-1 mode 1920x1080@60Hz
        output DVI-D-1 pos 0 1080
        output DVI-D-1 transform 90
        output HDMI-A-2 mode 1920x1080@60Hz
        output HDMI-A-2 pos 3000 1080
        output HDMI-A-1 mode 1920x1080@60Hz
        output HDMI-A-1 pos 1080 1080
        output DP-2 mode 2560x1080@60Hz
        output DP-2 pos 440 0

        # Treat HDMI-A-1 as the main display by assigning primary workspaces to it
        workspace 1 output HDMI-A-1
      '';

  # Ensure Yeti microphone input level is set around 70% on login
  # Uses pactl via PipeWire-Pulse; matches sources with "Yeti" in description
  systemd.user.services.yeti-mic-volume =
    let
      setYeti = pkgs.writeShellApplication {
        name = "set-yeti-mic-volume";
        runtimeInputs = [
          pkgs.pulseaudio
          pkgs.jq
          pkgs.coreutils
          pkgs.gnugrep
          pkgs.gnused
        ];
        text = ''
              #!/usr/bin/env bash
              set -euo pipefail

              # Wait up to 20s for PipeWire/Pulse to expose sources
              for ((i=0; i<20; i++)); do
                if pactl info >/dev/null 2>&1; then
                  # Look for sources whose description contains "Yeti" (case-insensitive)
                  if pactl --help 2>&1 | grep -q "--format"; then
                    mapfile -t SOURCES < <(pactl --format=json list sources \
                      | jq -r '.[] | select(.description|test("Yeti"; "i")) | .name') || true
                  else
                    # Fallback to text parsing
                    mapfile -t SOURCES < <(pactl list sources | awk '/^Source #/{n=$2} /Description:/{if (tolower($0) ~ /yeti/) print prev;}{prev=$0}' | sed 's/^Source #//; s/://') || true
                  fi
                  if [ "''${#SOURCES[@]}" -gt 0 ]; then
                    for src in "''${SOURCES[@]}"; do
                      pactl set-source-mute "$src" 0 || true
                      pactl set-source-volume "$src" 70% || true
                    done
                    exit 0
                  fi
                fi
                sleep 1
              done

              # As a fallback, set default source volume if any device present
              if pactl list short sources >/dev/null 2>&1; then
                pactl set-source-mute @DEFAULT_SOURCE@ 0 || true
                pactl set-source-volume @DEFAULT_SOURCE@ 70% || true
              fi
        '';
      };
    in
    {
      Unit = {
        Description = "Set Yeti microphone input volume to 70%";
        After = [
          "pipewire.service"
          "pipewire-pulse.service"
          "graphical-session.target"
        ];
        PartOf = [ "graphical-session.target" ];
      };
      Install.WantedBy = [
        "graphical-session.target"
        "default.target"
      ];
      Service = {
        Type = "oneshot";
        ExecStart = "${setYeti}/bin/set-yeti-mic-volume";
      };
    };
    };
}

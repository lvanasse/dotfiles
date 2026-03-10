{ ... }:
{
  flake.modules.homeManager."target.config.pc" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
{
  # PC-specific Sway output layout (host-only)
  wayland.windowManager.sway.extraConfig = lib.mkAfter ''
        # Displays/workspaces (from nwg-displays)
        include ${config.home.homeDirectory}/.config/sway/outputs
        include ${config.home.homeDirectory}/.config/sway/workspaces
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
          pkgs.gawk
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
                  if pactl --help 2>&1 | grep -q -- "--format"; then
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

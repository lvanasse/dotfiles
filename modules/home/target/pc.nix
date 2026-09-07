{ ... }:
{
  flake.modules.homeManager."target.config.pc" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      spotifydToml = pkgs.formats.toml { };
      spotifydConfig = spotifydToml.generate "spotifyd.conf" {
        global = {
          backend = "pulseaudio";
          bitrate = 320;
          device_name = "pc";
          device_type = "computer";
          use_mpris = true;
          zeroconf_port = 57621;
        };
      };
    in
    {
      home.file = {
        ".local/bin/deck-game-install" = {
          source = ../../../scripts/deck-game-install;
          executable = true;
        };
        ".local/bin/deck-game-add" = {
          source = ../../../scripts/deck-game-add;
          executable = true;
        };
        ".local/bin/bootstrap-steamdeck-home-manager" = {
          source = ../../../scripts/bootstrap-steamdeck-home-manager;
          executable = true;
        };
      };

      xdg.configFile."spotifyd/spotifyd.conf".source = spotifydConfig;

      programs.swayTools.autostartSlack = false;

      # The GTX 1660 Ti can decode VP9 in hardware, but not AV1.
      # Prefer codecs that can actually use hardware decode on this host.
      programs.firefox.profiles.default.settings = {
        "media.av1.enabled" = false;
      };

      # PC-specific Sway output layout (host-only)
      wayland.windowManager.sway.extraOptions = [ "--unsupported-gpu" ];
      wayland.windowManager.sway.extraConfig = lib.mkAfter ''
        # Displays (captured from nwg-displays)
        output "DP-3" {
          mode 1920x1080@60.0Hz
          pos 2060 1080
          transform normal
          scale 1.0
          scale_filter nearest
          adaptive_sync off
          dpms on
        }
        output "HDMI-A-1" {
          mode 1920x1080@60.0Hz
          pos 980 1080
          transform 90
          scale 1.0
          scale_filter nearest
          adaptive_sync off
          dpms on
        }
        output "DP-2" {
          mode 1920x1080@60.0Hz
          pos 3980 1080
          transform normal
          scale 1.0
          scale_filter nearest
          adaptive_sync off
          dpms on
        }
        output "DP-1" {
          mode 2560x1080@74.991Hz
          pos 1756 0
          transform normal
          scale 1.0
          scale_filter nearest
          adaptive_sync off
          dpms on
        }

        # Keep one initial workspace on each display, with DP-3 as the primary.
        workspace 1 output DP-3
        workspace 2 output DP-2
        workspace 3 output HDMI-A-1
        workspace 4 output DP-1
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

      systemd.user.services.spotifyd = {
        Unit = {
          Description = "spotifyd, a Spotify Connect background daemon";
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
          ExecStart = "${pkgs.spotifyd}/bin/spotifyd --no-daemon --cache-path %h/.cache/spotifyd --config-path %h/.config/spotifyd/spotifyd.conf";
          Restart = "always";
          RestartSec = 12;
        };
      };
    };
}

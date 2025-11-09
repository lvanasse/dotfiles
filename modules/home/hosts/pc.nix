{
  lib,
  pkgs,
  ...
}:
let
  jsonFormat = pkgs.formats.json { };
  moonlightLocalTest = pkgs.writeShellApplication {
    name = "moonlight-local-test";
    runtimeInputs = [
      pkgs.moonlight-embedded
      pkgs.coreutils
    ];
    text = ''
      set -euo pipefail

      usage() {
        cat <<'EOF'
      Usage: moonlight-local-test [pair|list|stream|unpair] [APP] [moonlight options...]
      Defaults: stream Desktop from Sunshine listening on 127.0.0.1

      Environment:
        MOONLIGHT_HOST    Override Sunshine host (defaults to 127.0.0.1)

      stream-specific flags:
        --host <host>     Override Sunshine host for this invocation
        --host=<host>

      Commands:
        pair         Pair this client with the local Sunshine instance
        list         List available Sunshine apps
        stream       Stream the given app (defaults to Desktop)
        unpair       Remove the saved pairing with Sunshine
      EOF
      }

      host="''${MOONLIGHT_HOST:-127.0.0.1}"
      command="stream"
      if [ $# -gt 0 ]; then
        command="$1"
        shift
      fi

      case "$command" in
        help|-h|--help)
          usage
          ;;
        pair)
          exec moonlight pair "$host" "$@"
          ;;
        list)
          exec moonlight list "$host" "$@"
          ;;
        unpair)
          exec moonlight unpair "$host" "$@"
          ;;
        stream)
          app="Desktop"
          while [ $# -gt 0 ]; do
            case "$1" in
              --host)
                if [ $# -lt 2 ]; then
                  echo "error: --host requires a value" >&2
                  exit 1
                fi
                host="$2"
                shift 2
                continue
                ;;
              --host=*)
                host="''${1#--host=}"
                shift
                continue
                ;;
              --)
                shift
                if [ $# -gt 0 ]; then
                  app="$1"
                  shift
                fi
                break
                ;;
              -*)
                break
                ;;
              *)
                app="$1"
                shift
                break
                ;;
            esac
          done
          exec moonlight stream "$host" "$app" "$@"
          ;;
        *)
          usage >&2
          exit 1
          ;;
      esac
    '';
  };
  steamBigPictureLaunch = pkgs.writeShellApplication {
    name = "steam-big-picture-launch";
    runtimeInputs = [
      pkgs.gamescope
      pkgs.steam
      pkgs.util-linux
      pkgs.coreutils
      pkgs.procps
    ];
    text = ''
      set -euo pipefail

      export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      export WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-wayland-0}"

      steam_still_running() {
        ${pkgs.procps}/bin/pgrep -x steam >/dev/null 2>&1 && return 0
        ${pkgs.procps}/bin/pgrep -f "''${HOME}/.local/share/Steam" >/dev/null 2>&1 && return 0
        return 1
      }

      wait_for_steam_exit() {
        local attempts="$1"
        for _ in $(seq 1 "''${attempts}"); do
          if ! steam_still_running; then
            return 0
          fi
          sleep 1
        done
        return 1
      }

      ${pkgs.steam}/bin/steam -shutdown >/dev/null 2>&1 || true
      wait_for_steam_exit 20 || true

      if steam_still_running; then
        ${pkgs.procps}/bin/pkill -TERM -x steam >/dev/null 2>&1 || true
        ${pkgs.procps}/bin/pkill -TERM -f "''${HOME}/.local/share/Steam" >/dev/null 2>&1 || true
        wait_for_steam_exit 10 || true
      fi

      if steam_still_running; then
        ${pkgs.procps}/bin/pkill -KILL -x steam >/dev/null 2>&1 || true
        ${pkgs.procps}/bin/pkill -KILL -f "''${HOME}/.local/share/Steam" >/dev/null 2>&1 || true
        wait_for_steam_exit 5 || true
      fi

      exec ${pkgs.util-linux}/bin/setpriv \
        --no-new-privs \
        --keep-groups \
        --inh-caps=-all \
        --ambient-caps=-all \
        ${pkgs.util-linux}/bin/setsid ${pkgs.gamescope}/bin/gamescope \
          -f \
          --backend wayland \
          --prefer-output=HDMI-A-1,DP-2,HDMI-A-2 \
          -w 1920 -h 1080 \
          -W 1920 -H 1080 \
          -- ${pkgs.steam}/bin/steam -gamepadui -pipewire-dmabuf
    '';
  };
  steamBigPictureWrapped = pkgs.writeShellApplication {
    name = "steam-big-picture-wrapped";
    runtimeInputs = [
      pkgs.coreutils
      steamBigPictureLaunch
    ];
    text = ''
      set -euo pipefail

      log_dir="''${HOME}/.cache/sunshine"
      mkdir -p "''${log_dir}"
      log_file="''${log_dir}/steam-big-picture.log"

      {
        printf '\n[%s] >>> Sunshine Steam Big Picture request\n' "$(date --iso-8601=seconds)"
        printf 'WAYLAND_DISPLAY=%s\n' "''${WAYLAND_DISPLAY:-<unset>}"
        printf 'XDG_RUNTIME_DIR=%s\n' "''${XDG_RUNTIME_DIR:-<unset>}"
        printf 'DBUS_SESSION_BUS_ADDRESS=%s\n' "''${DBUS_SESSION_BUS_ADDRESS:-<unset>}"
      } >>"''${log_file}"

      exec >>"''${log_file}" 2>&1
      printf '[%s] Launching steam-big-picture...\n' "$(date --iso-8601=seconds)"
      exec ${steamBigPictureLaunch}/bin/steam-big-picture-launch
    '';
  };
  sunshineApps = {
    env = {
      PATH = "$(PATH):$(HOME)/.local/bin";
    };
    apps = [
      {
        name = "Desktop";
        "image-path" = "desktop.png";
      }
      {
        name = "Low Res Desktop";
        "image-path" = "desktop.png";
        "prep-cmd" = [
          {
            do = "xrandr --output HDMI-1 --mode 1920x1080";
            undo = "xrandr --output HDMI-1 --mode 1920x1200";
          }
        ];
      }
      {
        name = "Steam Big Picture";
        cmd = [
          "${steamBigPictureWrapped}/bin/steam-big-picture-wrapped"
        ];
        "image-path" = "steam.png";
      }
    ];
  };
in
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

  # Provide a local Moonlight client helper for Sunshine smoke tests
  home.packages = lib.mkAfter [ moonlightLocalTest ];

  xdg.desktopEntries."moonlight-local-test" = {
    name = "Moonlight (Local Sunshine)";
    genericName = "Moonlight Stream";
    comment = "Stream from the local Sunshine server for quick testing";
    exec = "moonlight-local-test stream Desktop";
    icon = "moonlight";
    terminal = false;
    categories = [
      "Game"
      "Utility"
    ];
  };

  # Sunshine configuration managed via Home Manager
  xdg.configFile."sunshine/sunshine.conf".text = ''
    hevc_mode = 1
    av1_mode = 1
    output_name = 2
    resolutions = [
      1920x1080
    ]
  '';

  xdg.configFile."sunshine/apps.json".source = jsonFormat.generate "sunshine-apps.json" sunshineApps;
}

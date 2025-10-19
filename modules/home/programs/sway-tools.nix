{ pkgs, ... }:
{
  # Helper scripts for Wayland sessions (Sway) and Rofi wrappers
  home.packages = [
    (pkgs.writeShellScriptBin "rofi-combi" ''
      #!/usr/bin/env bash
      set -euo pipefail
      exec ${pkgs.rofi-wayland}/bin/rofi \
        -show combi \
        -modi "combi,drun,run" \
        -combi-modi "drun,run" \
        -matching prefix
    '')
    (pkgs.writeShellScriptBin "rofi-run-only" ''
      #!/usr/bin/env bash
      set -euo pipefail
      exec ${pkgs.rofi-wayland}/bin/rofi \
        -show run \
        -modi "run,drun" \
        -matching prefix
    '')
    (pkgs.writeShellScriptBin "screenshot" ''
      #!/usr/bin/env bash
      set -euo pipefail

      have() { command -v "$1" >/dev/null 2>&1; }

      action="''${1:-copy}"   # copy|save
      target="''${2:-area}"   # area|window|active|screen|output

      shots_dir="$HOME/Pictures/Screenshots"
      ts="$(date +'%F_%H-%M-%S')"
      out_file="$shots_dir/Screenshot_$ts.png"

      mkdir -p "$shots_dir" || true

      if [ -n "''${SWAYSOCK:-}" ]; then
        # Sway / wlroots path
        if have grimshot; then
          if [ "$action" = copy ]; then
            exec grimshot copy "$target"
          else
            exec grimshot save "$target" "$out_file"
          fi
        else
          # Fallback to grim+slurp
          if [ "$target" = area ] && have grim && have slurp; then
            if [ "$action" = copy ]; then
              grim -g "$(slurp)" - | wl-copy
            else
              grim -g "$(slurp)" "$out_file"
              printf '%s\n' "$out_file"
            fi
          else
            # Full screen fallback
            if [ "$action" = copy ]; then
              grim - | wl-copy
            else
              grim "$out_file"
              printf '%s\n' "$out_file"
            fi
          fi
        fi
      else
        # KDE / other Wayland via portals
        if have spectacle; then
          if [ "$action" = copy ]; then
            case "$target" in
              area)   exec spectacle -r -n -c ;;
              window|active) exec spectacle -a -n -c ;;
              screen|output) exec spectacle -f -n -c ;;
              *)      exec spectacle -r -n -c ;;
            esac
          else
            case "$target" in
              area)   exec spectacle -r -n -o "$out_file" ;;
              window|active) exec spectacle -a -n -o "$out_file" ;;
              screen|output) exec spectacle -f -n -o "$out_file" ;;
              *)      exec spectacle -r -n -o "$out_file" ;;
            esac
          fi
        elif have ksnip; then
          # As a generic portal-based fallback, open region capture UI
          exec ksnip -r
        else
          echo "No screenshot tool available. Install 'spectacle' or 'ksnip' (KDE) or 'grimshot' (Sway)." >&2
          exit 1
        fi
      fi
    '')
    (pkgs.writeShellScriptBin "power-menu" ''
            #!/usr/bin/env bash
            set -euo pipefail

            have() { command -v "$1" >/dev/null 2>&1; }

            # Menu runner: use rofi-wayland dmenu like other launchers
            dmenu() {
              "${pkgs.rofi-wayland}/bin/rofi" -dmenu -p "Power" -matching prefix
            }

            # Build menu entries
            entries=$(cat <<'EOF'
      Lock
      Sleep
      Hibernate
      Reboot
      Shutdown
      Logout
      EOF
      )

            choice=$(printf "%s\n" "$entries" | dmenu)
            case "''${choice:-}" in
              Lock)
                if have swaylock; then
                  exec swaylock -f -c 000000
                else
                  exec loginctl lock-session
                fi
                ;;
              Sleep)
                exec systemctl suspend
                ;;
              Hibernate)
                exec systemctl hibernate
                ;;
              Reboot)
                exec systemctl reboot
                ;;
              Shutdown)
                exec systemctl poweroff
                ;;
              Logout)
                if [ -n "''${SWAYSOCK:-}" ] && have swaymsg; then
                  exec swaymsg exit
                else
                  # Fallback for other sessions
                  exec loginctl terminate-user "$USER"
                fi
                ;;
              *)
                exit 0
                ;;
            esac
    '')
    (pkgs.writeShellScriptBin "sway-export-outputs" ''
      #!/usr/bin/env bash
      set -euo pipefail
      if ! command -v swaymsg >/dev/null 2>&1; then
        echo "sway-export-outputs: swaymsg not found (run inside a Sway session)" >&2
        exit 1
      fi
      json="$(swaymsg -t get_outputs -r || true)"
      if [ -z "$json" ]; then
        echo "sway-export-outputs: no output data (Sway not running?)" >&2
        exit 1
      fi
      if ! echo "$json" | ${pkgs.jq}/bin/jq -e 'type=="array" and length>0' >/dev/null 2>&1; then
        echo "sway-export-outputs: no active outputs found. Ensure you are in a Sway session." >&2
        exit 1
      fi
      echo "# Paste these lines into your Sway config (Home Manager)"
      echo "# Example: modules/home/desktop/sway.nix -> config.extraConfig or config.output"
      ${pkgs.jq}/bin/jq -r '
        .[] | select(.active == true) as $o |
        ($o.current_mode.width|tostring) as $w |
        ($o.current_mode.height|tostring) as $h |
        ($o.current_mode.refresh / 1000 | floor | tostring) as $hz |
        ("output " + $o.name + " mode " + $w + "x" + $h + "@" + $hz + "Hz"),
        ("output " + $o.name + " pos " + ($o.rect.x|tostring) + " " + ($o.rect.y|tostring)),
        (if $o.transform != "normal" then "output " + $o.name + " transform " + $o.transform else empty end),
        (if $o.scale != 1 then "output " + $o.name + " scale " + ($o.scale|tostring) else empty end)
      ' <<<"$json"
    '')
    (pkgs.writeShellScriptBin "screenshot-annotate" ''
      #!/usr/bin/env bash
      set -euo pipefail
      if command -v grim >/dev/null 2>&1 && command -v slurp >/dev/null 2>&1 && command -v swappy >/dev/null 2>&1; then
        grim -g "$(slurp)" - | swappy -f -
      else
        echo "screenshot-annotate: requires grim, slurp, swappy" >&2
        exit 1
      fi
    '')
    (pkgs.writeShellScriptBin "start-chat-apps" ''
      #!/usr/bin/env bash
      set -euo pipefail

      PGREP="${pkgs.procps}/bin/pgrep"

      launch_if_missing() {
        local bin="$1"
        if command -v "$bin" >/dev/null 2>&1; then
          if ! "$PGREP" -x "$bin" >/dev/null 2>&1; then
            ("$bin" >/dev/null 2>&1 &)
          fi
        fi
      }

      # Prefer Vesktop over Discord if both installed
      launch_if_missing slack
      if command -v vesktop >/dev/null 2>&1; then
        launch_if_missing vesktop
      else
        launch_if_missing discord
      fi
    '')
  ];
}

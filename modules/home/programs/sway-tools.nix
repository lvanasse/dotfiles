{ ... }:
{
  flake.modules.homeManager."programs.sway-tools" =
    { pkgs, config, ... }:
    {
      # Helper scripts for Wayland sessions (Sway) and Rofi wrappers
      home.packages = [
        (pkgs.writeShellScriptBin "rofi-combi" ''
          #!/usr/bin/env bash
          set -euo pipefail
          exec ${pkgs.rofi}/bin/rofi \
            -config "$HOME/.config/rofi/config.rasi" \
            -show combi \
            -modi "combi,drun,run" \
            -combi-modi "drun,run" \
            -matching prefix
        '')
        (pkgs.writeShellScriptBin "rofi-run-only" ''
          #!/usr/bin/env bash
          set -euo pipefail
          exec ${pkgs.rofi}/bin/rofi \
            -config "$HOME/.config/rofi/config.rasi" \
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

                # Menu runner: use rofi dmenu with our config
                dmenu() {
                  "${pkgs.rofi}/bin/rofi" \
                    -config "$HOME/.config/rofi/config.rasi" \
                    -dmenu -p "Power" -matching prefix
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
                    if have swaylock-pixelate; then
                      exec swaylock-pixelate
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
          have() { command -v "$1" >/dev/null 2>&1; }

          if have grim && have slurp; then
            if have satty; then
              shots_dir="$HOME/Pictures/Screenshots"
              ts="$(date +'%F_%H-%M-%S')"
              out_file="$shots_dir/Satty_$ts.png"
              mkdir -p "$shots_dir" || true
              selection="$(slurp -o -r -c '#ff0000ff')" || exit 0
              copy_cmd="${pkgs.wl-clipboard}/bin/wl-copy --type image/png"
              satty_args=(--filename - --fullscreen --output-filename "$out_file" --early-exit)
              if satty --help 2>&1 | ${pkgs.gnugrep}/bin/grep -q -- '--copy-command'; then
                satty_args+=(--copy-command "$copy_cmd")
              fi
              grim -g "$selection" -t ppm - | satty "''${satty_args[@]}"
              if [ -s "$out_file" ] && have wl-copy; then
                ${pkgs.wl-clipboard}/bin/wl-copy --type image/png < "$out_file"
              fi
            elif have swappy; then
              selection="$(slurp)" || exit 0
              grim -g "$selection" - | swappy -f -
            else
              echo "screenshot-annotate: requires satty or swappy (plus grim + slurp)" >&2
              exit 1
            fi
          else
            echo "screenshot-annotate: requires grim and slurp" >&2
            exit 1
          fi
        '')
        (pkgs.writeShellScriptBin "swaylock-pixelate" ''
          #!/usr/bin/env bash
          set -euo pipefail

          grim="${pkgs.grim}/bin/grim"
          convert="${pkgs.imagemagick}/bin/convert"
          swaylock="${pkgs.swaylock}/bin/swaylock"

          runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}"
          raw="$runtime_dir/swaylock-raw.png"
          out="$runtime_dir/swaylock-pixel.png"
          wallpaper="$HOME/.local/share/wallpapers/1458678242783.jpg"

          src=""
          if [ -f "$wallpaper" ]; then
            src="$wallpaper"
          elif "$grim" -t png "$raw"; then
            src="$raw"
          fi

          if [ -z "$src" ]; then
            exec "$swaylock" -f -c 000000
          fi
          if ! "$convert" "$src" -scale 10% -scale 1000% "$out"; then
            exec "$swaylock" -f -c 000000
          fi

          exec "$swaylock" -f -i "$out" -s fill
        '')
        (pkgs.writeShellScriptBin "start-chat-apps" ''
          #!/usr/bin/env bash
          set -euo pipefail

          PGREP="${pkgs.procps}/bin/pgrep"
          home_bin="${config.home.homeDirectory}/.local/bin"

          # Wait briefly for Secret Service to be ready so Slack can persist login
          # (provided by gnome-keyring). Succeeds quickly if already active.
          for svc in gnome-keyring-secrets.service gnome-keyring-daemon.service; do
            for i in {1..20}; do
              if systemctl --user --quiet is-active "$svc"; then
                break 2
              fi
              sleep 0.25
            done
          done

          # Give Waybar time to bring up tray watcher so tray-only apps register.
          for i in {1..40}; do
            if "$PGREP" -x waybar >/dev/null 2>&1; then
              break
            fi
            sleep 0.25
          done

          resolve_app() {
            local bin="$1"
            local wrapper="$home_bin/$bin"

            if [ -x "$wrapper" ]; then
              printf '%s\n' "$wrapper"
              return 0
            fi

            if command -v "$bin" >/dev/null 2>&1; then
              command -v "$bin"
              return 0
            fi

            return 1
          }

          launch_if_missing() {
            local bin="$1"
            local app

            if ! app="$(resolve_app "$bin")"; then
              return 0
            fi

            if ! "$PGREP" -x "$bin" >/dev/null 2>&1; then
              ("$app" >/dev/null 2>&1 &)
            fi
          }

          # Prefer Vesktop over Discord if both installed
          launch_if_missing slack
          if app="$(resolve_app vesktop)"; then
            # Start minimized so Vesktop reliably registers its tray item.
            if ! "$PGREP" -x vesktop >/dev/null 2>&1; then
              ("$app" --start-minimized --ozone-platform-hint=auto >/dev/null 2>&1 &)
            fi
          else
            launch_if_missing discord
          fi
        '')
      ];
    };
}

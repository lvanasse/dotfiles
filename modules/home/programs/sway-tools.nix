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
  ];
}

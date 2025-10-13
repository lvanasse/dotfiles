{ pkgs, ... }:
{
  # Provide a helper to export current Hyprland monitor layout
  # into ready-to-paste `monitor=` config lines.
  home.packages = [
    (pkgs.writeShellScriptBin "hypr-export-monitors" ''
      #!/usr/bin/env bash
      set -euo pipefail
      if ! command -v hyprctl >/dev/null 2>&1; then
        echo "hypr-export-monitors: hyprctl not found (run inside Hyprland)" >&2
        exit 1
      fi
      json="$(hyprctl -j monitors || true)"
      if [ -z "$json" ]; then
        echo "hypr-export-monitors: no monitor data (Hyprland not running?)" >&2
        exit 1
      fi
      echo "# Paste these lines into your Hyprland config"
      echo "# Example placement: modules/home/desktop/hyprland.nix -> settings.monitor"
      ${pkgs.jq}/bin/jq -r '
        .[] | select(.name != null and .active == true) |
        def normTransform:
          if (.transform|type) == "number" then .transform
          else
            ( .transform // "normal" ) as $t |
            if $t == "normal" then 0
            elif $t == "90" or $t == "rotate90" then 1
            elif $t == "180" or $t == "rotate180" then 2
            elif $t == "270" or $t == "rotate270" then 3
            elif $t == "flipped" or $t == "fliph" then 4
            else 0 end
          end;

        . as $m |
        (if ($m.refreshRate|type) == "number" then ($m.refreshRate|floor) else 0 end) as $hz |
        "monitor=" + $m.name + "," +
        ($m.width|tostring) + "x" + ($m.height|tostring) +
        (if $hz > 0 then "@" + ($hz|tostring) else "" end) + "," +
        ($m.x|tostring) + "x" + ($m.y|tostring) + "," +
        ($m.scale|tostring) +
        (if (normTransform) != 0 then ",transform," + ((normTransform)|tostring) else "" end)
      ' <<<"$json"
    '')
  ];
}

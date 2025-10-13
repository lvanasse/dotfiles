# Waybar (minimal) for Hyprland
{ lib, pkgs, ... }:
let
  datetimeScript = pkgs.writeShellScript "waybar-datetime" ''
    date_local=$(date +%Y-%m-%d\ %H:%M:%S)
    date_utc=$(date -u +%H:%M:%S)
    printf "%s | %s" "$date_local" "$date_utc"
  '';
in
{
  programs.waybar = {
    enable = true;
    # Start Waybar via Hyprland's exec-once instead of a user service.
    # This avoids target mismatches and ensures it only runs under Hyprland.
    systemd.enable = false;

    settings = [
      {
        layer = "top";
        position = "top";
        height = 28;
        margin = "0";
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ ];
        modules-right = [
          "battery"
          "custom/weather"
          "custom/datetime"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{name}";
          sort-by-number = true;
          on-click = "activate";
        };

        "custom/datetime" = {
          interval = 5;
          exec = "${datetimeScript}";
          format = "{}";
          tooltip = false;
        };

        battery = {
          # Hidden automatically if no battery is present
          states = {
            warning = 20;
            critical = 10;
          };
          format = "{icon} {capacity}%";
          format-icons = [
            "󰂎"
            "󰁼"
            "󰁾"
            "󰂀"
            "󰁹"
            "󰂂"
            "󰁹"
            "󰂄"
            "󰁹"
            "󰁹"
            "󰁹"
          ];
          tooltip = false;
        };

        "custom/weather" = {
          interval = 600;
          exec = "bash -lc 'curl -sf https://wttr.in/?format=1'";
          # Use plain text output from wttr.in
          format = "{}";
          tooltip = false;
        };
      }
    ];

    style = lib.mkForce ''
      * {
        border: none;
        border-radius: 0;
        min-height: 0;
        font-family: Inter, Cantarell, Noto Sans, sans-serif;
        font-size: 12px;
      }
      window#waybar {
        background: rgba(29, 32, 33, 0.92); /* #1d2021 */
        color: #ebdbb2; /* gruvbox fg */
      }
      #workspaces button {
        padding: 0 6px;
        color: #a89984; /* gruvbox gray */
        background: transparent;
      }
      #workspaces button.active {
        color: #fbf1c7;
        background: rgba(60, 56, 54, 0.9); /* #3c3836 */
      }
      #battery, #tray, #custom-weather, #custom-datetime {
        padding: 0 10px;
      }
    '';
  };
}

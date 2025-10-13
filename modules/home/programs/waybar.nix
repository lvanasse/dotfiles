# Waybar (minimal) for Hyprland
{ lib, ... }:
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
          "network"
          "battery"
          "custom/weather"
          "clock#local"
          "clock#utc"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{name}";
          sort-by-number = true;
          on-click = "activate";
        };

        "clock#local" = {
          interval = 5;
          format = "{:%Y-%m-%d %H:%M:%S}";
          tooltip = false;
        };

        "clock#utc" = {
          interval = 5;
          timezone = "UTC";
          format = "UTC {:%Y-%m-%d %H:%M:%S}";
          tooltip = false;
        };

        network = {
          format-wifi = "  {essid}";
          format-ethernet = "󰈁  {ifname}";
          format-disconnected = "";
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
      #battery, #network, #clock, #tray, #custom-weather {
        padding: 0 10px;
      }
    '';
  };
}

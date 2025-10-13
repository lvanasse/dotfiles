# Waybar (minimal) for Hyprland
{ lib, ... }:
{
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };

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
          "clock"
          "tray"
        ];

        "hyprland/workspaces" = {
          format = "{name}";
          sort-by-number = true;
          on-click = "activate";
        };

        clock = {
          # ISO-8601 time
          format = "{:%FT%T%z}";
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
          return-type = "json";
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

# Waybar (Sway-focused)
{ config, lib, pkgs, ... }:
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
    # Managed via a custom systemd user service (below) so it only runs
    # under Sway sessions and not under KDE/other DEs.
    systemd.enable = false;

    settings = [
      {
        layer = "top";
        position = "bottom";
        height = 28;
        margin = "0";
        modules-left = [ "sway/workspaces" ];
        modules-center = [ ];
        modules-right = [
          "battery"
          "custom/weather"
          "custom/datetime"
          "tray"
        ];

        "sway/workspaces" = {
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
      /* Add spacing between individual tray icons */
      #tray > .passive, #tray > .active, #tray > .needs-attention {
        padding: 0 5px;
      }
    '';
  };

  # Start Waybar only during a Sway session.
  # Avoids running under KDE Plasma or other sessions.
  systemd.user.services.waybar = {
    Unit = {
      Description = "Waybar status bar";
      PartOf = [ "sway-session.target" ];
      After = [ "sway-session.target" ];
    };
    Service = {
      # Ensure we're in a Wayland session
      ExecCondition = "${pkgs.bash}/bin/bash -lc 'test -n \"$WAYLAND_DISPLAY\"'";
      ExecStart = "${pkgs.bash}/bin/bash";
      ExecStartArgs = [
        "-lc"
        ''
          if [ -n "$SWAYSOCK" ]; then
            exec ${pkgs.waybar}/bin/waybar \
              -c ${config.home.homeDirectory}/.config/waybar/config-sway.jsonc \
              -s ${config.home.homeDirectory}/.config/waybar/style-sway.css
          else
            exec ${pkgs.waybar}/bin/waybar
          fi
        ''
      ];
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install = {
      WantedBy = [ "sway-session.target" ];
    };
  };
}

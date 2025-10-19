{ pkgs, config, ... }:
let
  datetimeScript = pkgs.writeShellScript "waybar-datetime" ''
    date_local=$(date +%Y-%m-%d\ %H:%M:%S)
    date_utc=$(date -u +%H:%M:%S)
    printf "%s | %s" "$date_local" "$date_utc"
  '';

  waybarConfig = {
    layer = "top";
    position = "bottom";
    height = 28;
    margin = "0";
    exclusive = true; # reserve space so clients don't render underneath
    "modules-left" = [ "sway/workspaces" ];
    "modules-center" = [ ];
    "modules-right" = [
      "custom/power"
      "battery"
      "custom/weather"
      "custom/datetime"
      "tray"
    ];

    "sway/workspaces" = {
      format = "{index}"; # always show numeric index (e.g., 1)
      "sort-by-number" = true;
      "on-click" = "activate";
    };

    "custom/datetime" = {
      interval = 5;
      exec = "${datetimeScript}";
      format = "{}";
      tooltip = false;
    };

    network = {
      "format-wifi" = "  {essid}";
      "format-ethernet" = "󰈁  {ifname}";
      "format-disconnected" = "";
      tooltip = false;
    };

    battery = {
      states = {
        warning = 20;
        critical = 10;
      };
      format = "{icon} {capacity}%";
      "format-icons" = [
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
      format = "{}";
      tooltip = false;
    };

    "custom/power" = {
      format = ""; # power icon (Font Awesome)
      tooltip = true;
      "tooltip-format" = "Power menu";
      "on-click" = "power-menu";
    };
  };

  waybarConfigJSON = builtins.toJSON waybarConfig;

  waybarStyle = ''
    * { border: none; border-radius: 0; min-height: 0; font-family: Inter, Cantarell, Noto Sans, sans-serif; font-size: 12px; }
    window#waybar { background: ${config.theme.waybar.backgroundRgba}; color: ${config.theme.waybar.foreground}; border: none; outline: none; box-shadow: none; }
    #workspaces button { padding: 0 6px; color: ${config.theme.waybar.workspaceInactive}; background: transparent; }
    #workspaces button.active { color: ${config.theme.waybar.workspaceActiveFg}; background: ${config.theme.waybar.workspaceActiveBgRgba}; }
    #battery, #tray, #custom-weather, #custom-datetime, #custom-power { padding: 0 10px; }
    /* Add spacing between individual tray icons */
    #tray > .passive, #tray > .active, #tray > .needs-attention { padding: 0 5px; }
  '';
in
{
  # Sway-specific Waybar config and style
  home.file.".config/waybar/config-sway.jsonc".text = waybarConfigJSON;
  home.file.".config/waybar/style-sway.css".text = waybarStyle;

  # Also write defaults so Waybar uses our config if launched without -c
  home.file.".config/waybar/config.jsonc".text = waybarConfigJSON;
  home.file.".config/waybar/config".text = waybarConfigJSON;
  home.file.".config/waybar/style.css".text = waybarStyle;
}

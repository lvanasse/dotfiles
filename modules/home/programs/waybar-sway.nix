{ ... }:
{
  flake.modules.homeManager."programs.waybar-sway" =
    { pkgs, config, ... }:
    let
      datetimeScript = pkgs.writeShellScript "waybar-datetime" ''
        date_local=$(date +%Y-%m-%d\ %H:%M:%S)
        date_utc=$(date -u +%H:%M:%S)
        printf "%s | %s" "$date_local" "$date_utc"
      '';
      mailScript = pkgs.writeShellScript "waybar-mail-unread" ''
        set -euo pipefail
        mu_bin="${pkgs.mu}/bin/mu"
        if [ ! -x "$mu_bin" ]; then
          exit 0
        fi
        if [ ! -d "$HOME/.cache/mu" ]; then
          printf '{"text":"","class":"hidden","tooltip":"mu database not initialized"}'
          exit 0
        fi
        query='flag:unread AND NOT flag:trashed AND (maildir:/ludovic/Index OR maildir:/ludovic/Promotions OR maildir:/ludovic/SocialNetworks)'
        count="$("$mu_bin" find --nocolor --format=plain "$query" 2>/dev/null | wc -l)"
        count="$(printf '%s' "$count" | tr -d '[:space:]')"
        if [ -z "$count" ] || [ "$count" = "0" ]; then
          printf '{"text":"󰇯 0","class":"idle","tooltip":"No unread mail in Inbox, Promotions, or Social Networks"}'
        else
          printf '{"text":"󰇮 %s","class":"attention","tooltip":"%s unread mail in Inbox, Promotions, or Social Networks"}' "$count" "$count"
        fi
      '';
      modeScript = pkgs.writeShellScript "waybar-sway-mode" ''
        set -euo pipefail
        mode="$(${pkgs.sway}/bin/swaymsg -t get_binding_modes -r | ${pkgs.jq}/bin/jq -r '.[0]')"
        if [ -n "$mode" ] && [ "$mode" != "default" ] && [ "$mode" != "null" ]; then
          printf "󰌽 %s" "$mode"
        fi
      '';

      waybarConfig = {
        layer = "top";
        position = "bottom";
        height = 28;
        margin = "0";
        exclusive = true; # reserve space so clients don't render underneath
        "modules-left" = [
          "sway/workspaces"
          "custom/mode"
        ];
        "modules-center" = [ ];
        "modules-right" = [
          "custom/power"
          "custom/mail"
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

        "custom/mode" = {
          interval = 1;
          exec = "${modeScript}";
          tooltip = false;
        };

        "custom/datetime" = {
          interval = 5;
          exec = "${datetimeScript}";
          format = "{}";
          tooltip = false;
        };

        "custom/mail" = {
          interval = 30;
          exec = "${mailScript}";
          return-type = "json";
          format = "{}";
          "on-click" = "emacsclient -n -c --eval '(progn (require (quote mu4e)) (mu4e))'";
        };

        network = {
          "format-wifi" = "  {essid}";
          "format-ethernet" = "󰈁  {ifname}";
          "format-disconnected" = "";
          tooltip = false;
        };

        tray = {
          # Some apps (including Slack) publish as passive; keep them visible.
          "show-passive-items" = true;
          spacing = 6;
          "icon-size" = 16;
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
          exec = "bash -lc 'curl -sf https://wttr.in/Montreal,QC?format=1'";
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
        #workspaces button {
          min-width: 20px;
          margin: 2px 2px;
          padding: 2px 6px;
          color: ${config.theme.waybar.workspaceInactive};
          background: transparent;
        }
        #workspaces button.active, #workspaces button.focused { color: ${config.theme.waybar.workspaceActiveFg}; background: ${config.theme.palette.dark1}; box-shadow: inset 0 -2px ${config.theme.palette.bright_orange}; font-weight: 600; }
        #battery, #tray, #custom-weather, #custom-datetime, #custom-power, #custom-mode, #custom-mail { padding: 0 10px; }
        #custom-mode { background: ${config.theme.palette.dark1}; color: ${config.theme.palette.bright_orange}; font-weight: 600; }
        #custom-mail.attention { color: ${config.theme.palette.bright_orange}; font-weight: 700; }
        #custom-mail.idle { color: ${config.theme.waybar.foreground}; }
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
    };
}

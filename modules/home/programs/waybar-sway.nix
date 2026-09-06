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
        jq_bin="${pkgs.jq}/bin/jq"
        print_state() {
          "$jq_bin" -cn \
            --arg text "$1" \
            --arg class "$2" \
            --arg tooltip "$3" \
            '{text:$text,class:$class,tooltip:$tooltip}'
        }
        if [ ! -x "$mu_bin" ]; then
          print_state "󰍹 !" "error" "mu binary not available"
          exit 0
        fi
        if [ ! -d "$HOME/.cache/mu" ]; then
          print_state "󰍹 !" "error" "mu database not initialized"
          exit 0
        fi
        query='flag:unread AND NOT flag:trashed AND (maildir:/ludovic/Index OR maildir:/ludovic/Promotions OR maildir:/ludovic/SocialNetworks)'
        set +e
        find_output="$("$mu_bin" find --nocolor --format=plain "$query" 2>&1)"
        find_status=$?
        set -e
        if [ "$find_status" -eq 2 ]; then
          # mu returns 2 when there are no matches
          print_state "󰇯" "idle" "No unread mail in Inbox, Promotions, or Social Networks"
          exit 0
        elif [ "$find_status" -ne 0 ]; then
          error_text="$(printf '%s' "$find_output" | head -n 1)"
          if [ -z "$error_text" ]; then
            error_text="mu find failed with exit code $find_status"
          fi
          print_state "󰍹 !" "error" "$error_text"
          exit 0
        fi
        count="$(printf '%s\n' "$find_output" | sed '/^$/d' | wc -l)"
        count="$(printf '%s' "$count" | tr -d '[:space:]')"
        if [ -z "$count" ] || [ "$count" = "0" ]; then
          print_state "󰇯" "idle" "No unread mail in Inbox, Promotions, or Social Networks"
        else
          print_state "󰇮 $count" "attention" "$count unread mail in Inbox, Promotions, or Social Networks"
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
          "custom/mail"
          "battery"
          "custom/weather"
          "custom/datetime"
          "tray"
          "custom/power"
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
          "on-click" = "${config.home.homeDirectory}/.local/bin/emacs-mu4e-frame";
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
        #custom-datetime { font-feature-settings: "tnum"; }
        #custom-mail.attention { color: ${config.theme.palette.bright_orange}; font-weight: 700; }
        #custom-mail.error { color: ${config.theme.palette.bright_red}; font-weight: 700; }
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

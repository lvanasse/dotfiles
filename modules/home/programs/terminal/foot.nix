{ ... }:
{
  flake.modules.homeManager.terminalFoot =
    { config, ... }:
    {
      # Foot: fast, lightweight Wayland-native terminal
      # Supports Ctrl+Shift+C/V for copy/paste, mouse selection works out of the box
      programs.foot = {
        enable = true;
        settings = {
          main = {
            # Font configuration - match wezterm setup
            font = "FiraCode Nerd Font Mono:size=11";
            # Fallback fonts are handled automatically by fontconfig
            dpi-aware = "yes";
            pad = "0x0"; # No padding, like wezterm
          };

          mouse = {
            hide-when-typing = "yes";
          };

          cursor = {
            style = "block";
            blink = "no";
          };

          # Gruvbox Dark Hard colors from shared theme
          colors = {
            foreground = "${config.theme.wezterm.foreground}";
            background = "${config.theme.wezterm.background}";

            # Selection colors
            selection-foreground = "${config.theme.wezterm.selectionFg}";
            selection-background = "${config.theme.wezterm.selectionBg}";

            # Normal colors (0-7)
            regular0 = "${builtins.elemAt config.theme.wezterm.ansi 0}"; # black
            regular1 = "${builtins.elemAt config.theme.wezterm.ansi 1}"; # red
            regular2 = "${builtins.elemAt config.theme.wezterm.ansi 2}"; # green
            regular3 = "${builtins.elemAt config.theme.wezterm.ansi 3}"; # yellow
            regular4 = "${builtins.elemAt config.theme.wezterm.ansi 4}"; # blue
            regular5 = "${builtins.elemAt config.theme.wezterm.ansi 5}"; # magenta
            regular6 = "${builtins.elemAt config.theme.wezterm.ansi 6}"; # cyan
            regular7 = "${builtins.elemAt config.theme.wezterm.ansi 7}"; # white

            # Bright colors (8-15)
            bright0 = "${builtins.elemAt config.theme.wezterm.brights 0}"; # bright black
            bright1 = "${builtins.elemAt config.theme.wezterm.brights 1}"; # bright red
            bright2 = "${builtins.elemAt config.theme.wezterm.brights 2}"; # bright green
            bright3 = "${builtins.elemAt config.theme.wezterm.brights 3}"; # bright yellow
            bright4 = "${builtins.elemAt config.theme.wezterm.brights 4}"; # bright blue
            bright5 = "${builtins.elemAt config.theme.wezterm.brights 5}"; # bright magenta
            bright6 = "${builtins.elemAt config.theme.wezterm.brights 6}"; # bright cyan
            bright7 = "${builtins.elemAt config.theme.wezterm.brights 7}"; # bright white
          };

          # Keybindings - Ctrl+Shift+C/V enabled by default in foot
          # Mouse selection also works by default (select to copy, middle-click to paste)
          key-bindings = {
            clipboard-copy = "Control+Shift+c";
            clipboard-paste = "Control+Shift+v";
            primary-paste = "Shift+Insert";
            search-start = "Control+Shift+f";
            font-increase = "Control+plus Control+equal";
            font-decrease = "Control+minus";
            font-reset = "Control+0";
          };

          mouse-bindings = {
            # Right-click paste from clipboard (like wezterm/GNOME Terminal)
            clipboard-paste = "BTN_RIGHT";
            # Select text copies to clipboard automatically
            select-extend = "BTN_RIGHT";
          };
        };
      };
    };
}

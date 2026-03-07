{ ... }:
{
  flake.modules.homeManager.terminalFoot =
    { config, lib, ... }:
    let
      # Remove # prefix from hex colors for foot
      stripHash = color: lib.removePrefix "#" color;
      hasWeztermTheme = config ? theme && config.theme ? wezterm;
    in
    {
      # Foot: fast, lightweight Wayland-native terminal
      # Supports Ctrl+Shift+C/V for copy/paste, mouse selection works out of the box
      programs.foot = lib.mkIf hasWeztermTheme {
        enable = true;
        settings = {
          main = {
            # Font configuration
            font = "FiraCode Nerd Font Mono:size=8";
            # Fallback fonts are handled automatically by fontconfig
            dpi-aware = "yes";
            pad = "0x0"; # No padding
            shell = "fish";
          };

          mouse = {
            hide-when-typing = "yes";
          };

          cursor = {
            style = "block";
            blink = "no";
          };

          # Gruvbox Dark Hard colors from shared theme (foot wants no # prefix)
          colors = {
            foreground = stripHash config.theme.wezterm.foreground;
            background = stripHash config.theme.wezterm.background;

            # Selection colors
            selection-foreground = stripHash config.theme.wezterm.selectionFg;
            selection-background = stripHash config.theme.wezterm.selectionBg;

            # Normal colors (0-7)
            regular0 = stripHash (builtins.elemAt config.theme.wezterm.ansi 0); # black
            regular1 = stripHash (builtins.elemAt config.theme.wezterm.ansi 1); # red
            regular2 = stripHash (builtins.elemAt config.theme.wezterm.ansi 2); # green
            regular3 = stripHash (builtins.elemAt config.theme.wezterm.ansi 3); # yellow
            regular4 = stripHash (builtins.elemAt config.theme.wezterm.ansi 4); # blue
            regular5 = stripHash (builtins.elemAt config.theme.wezterm.ansi 5); # magenta
            regular6 = stripHash (builtins.elemAt config.theme.wezterm.ansi 6); # cyan
            regular7 = stripHash (builtins.elemAt config.theme.wezterm.ansi 7); # white

            # Bright colors (8-15)
            bright0 = stripHash (builtins.elemAt config.theme.wezterm.brights 0); # bright black
            bright1 = stripHash (builtins.elemAt config.theme.wezterm.brights 1); # bright red
            bright2 = stripHash (builtins.elemAt config.theme.wezterm.brights 2); # bright green
            bright3 = stripHash (builtins.elemAt config.theme.wezterm.brights 3); # bright yellow
            bright4 = stripHash (builtins.elemAt config.theme.wezterm.brights 4); # bright blue
            bright5 = stripHash (builtins.elemAt config.theme.wezterm.brights 5); # bright magenta
            bright6 = stripHash (builtins.elemAt config.theme.wezterm.brights 6); # bright cyan
            bright7 = stripHash (builtins.elemAt config.theme.wezterm.brights 7); # bright white
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
            # Disable default select-extend on BTN_RIGHT first
            select-extend = "none";
            clipboard-paste = "BTN_RIGHT";
          };
        };
      };
    };
}

{ lib, ... }:
let
  # Shared Gruvbox Dark Hard theme for Waybar, Sway, and WezTerm
  palette = {
    dark0_hard = "#1d2021";
    dark1 = "#3c3836";
    dark2 = "#504945";
    light0 = "#fbf1c7";
    light1 = "#ebdbb2";
    light4 = "#a89984";
    bright_orange = "#fe8019";
    bright_red = "#fb4934";
    green = "#b8bb26";
    yellow = "#fabd2f";
    blue = "#83a598";
    magenta = "#d3869b";
    cyan = "#8ec07c";
    bright_black = "#928374";
  };

  theme = {
    name = "gruvbox-dark-hard";
    inherit palette;

    # Waybar-specific derived values
    waybar = {
      # Make Waybar fully opaque and uniform
      backgroundRgba = palette.dark0_hard; # solid background for minimal look
      foreground = palette.light1;
      workspaceInactive = palette.light4;
      # Keep a subtle distinction via text only; no background change
      workspaceActiveFg = palette.light1;
      workspaceActiveBgRgba = "transparent";
    };

    # Sway colors block (client decorations)
    sway = {
      background = palette.dark0_hard;
      # Match border color to background so borders are invisible, keep titlebar
      focused = {
        border = palette.dark0_hard;
        background = palette.dark0_hard;
        text = palette.light1;
        indicator = palette.dark1;
        childBorder = palette.dark0_hard;
      };
      focusedInactive = {
        border = palette.dark0_hard;
        background = palette.dark0_hard;
        text = palette.light1;
        indicator = palette.dark1;
        childBorder = palette.dark0_hard;
      };
      unfocused = {
        border = palette.dark0_hard;
        background = palette.dark0_hard;
        text = palette.light1;
        indicator = palette.dark1;
        childBorder = palette.dark0_hard;
      };
      urgent = {
        border = palette.bright_red;
        background = palette.dark1;
        text = palette.light0;
        indicator = palette.bright_red;
        childBorder = palette.bright_red;
      };
      placeholder = {
        border = palette.dark0_hard;
        background = palette.dark0_hard;
        text = palette.light1;
        indicator = palette.dark1;
        childBorder = palette.dark0_hard;
      };
    };

    # WezTerm color tables
    wezterm = {
      foreground = palette.light1;
      background = palette.dark0_hard;
      cursorBg = palette.light1;
      cursorFg = palette.dark0_hard;
      selectionBg = palette.dark1;
      selectionFg = palette.light1;
      ansi = [
        palette.dark0_hard
        palette.bright_red
        palette.green
        palette.yellow
        palette.blue
        palette.magenta
        palette.cyan
        palette.light1
      ];
      brights = [
        palette.bright_black
        palette.bright_red
        palette.green
        palette.yellow
        palette.blue
        palette.magenta
        palette.cyan
        palette.light0
      ];
    };
  };
in
{
  options.theme = lib.mkOption {
    type = lib.types.attrs;
    default = theme;
    description = "Shared theme attributes for Sway, Waybar, and WezTerm.";
  };
}

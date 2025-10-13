# WezTerm: modern terminal with right-click copy/paste and Gruvbox Dark Hard theme
{ ... }:
{
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require 'wezterm'
      local act = wezterm.action

      -- Right-click: copy selection if any, else paste (GNOME Terminal-like UX)
      local function right_click(window, pane)
        local sel = window:get_selection_text_for_pane(pane)
        if sel and sel ~= "" then
          window:perform_action(act.CopyTo("Clipboard"), pane)
        else
          window:perform_action(act.PasteFrom("Clipboard"), pane)
        end
      end

      return {
        -- Minimal chrome
        enable_tab_bar = false, -- never show the tab/header bar
        use_fancy_tab_bar = false,
        hide_tab_bar_if_only_one_tab = true,
        -- Disable WezTerm's window title/header; let Sway draw titlebars
        window_decorations = 'NONE',
        -- Minimal symmetric padding; Waybar reserves space via exclusive layer
        window_padding = { left = 2, right = 2, top = 2, bottom = 2 },

        -- Gruvbox Dark Hard palette
        colors = {
          foreground = '#ebdbb2',
          background = '#1d2021',
          cursor_bg = '#ebdbb2',
          cursor_fg = '#1d2021',
          cursor_border = '#ebdbb2',
          selection_bg = '#3c3836',
          selection_fg = '#ebdbb2',
          ansi = {
            '#1d2021', -- black
            '#fb4934', -- red
            '#b8bb26', -- green
            '#fabd2f', -- yellow
            '#83a598', -- blue
            '#d3869b', -- magenta
            '#8ec07c', -- cyan
            '#ebdbb2', -- white
          },
          brights = {
            '#928374', -- bright black
            '#fb4934', -- bright red
            '#b8bb26', -- bright green
            '#fabd2f', -- bright yellow
            '#83a598', -- bright blue
            '#d3869b', -- bright magenta
            '#8ec07c', -- bright cyan
            '#fbf1c7', -- bright white
          },
        },

        -- Keybindings: Ctrl+Shift+C/V for copy/paste
        keys = {
          { key = 'C', mods = 'CTRL|SHIFT', action = act.CopyTo('Clipboard') },
          { key = 'V', mods = 'CTRL|SHIFT', action = act.PasteFrom('Clipboard') },
        },

        -- Mouse: right-click copy-or-paste
        mouse_bindings = {
          -- Copy selection to Clipboard on left mouse release
          {
            event = { Up = { streak = 1, button = 'Left' } },
            mods = 'NONE',
            action = wezterm.action.CompleteSelection 'Clipboard',
          },
          {
            event = { Up = { streak = 1, button = 'Right' } },
            mods = 'NONE',
            action = wezterm.action_callback(right_click),
          },
        },

        -- Quality of life
        adjust_window_size_when_changing_font_size = false,
        enable_wayland = true,
        audible_bell = 'Disabled',
      }
    '';
  };
}

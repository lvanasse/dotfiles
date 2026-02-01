{ ... }:
{
  flake.modules.homeManager.terminalWezterm =
    { config, ... }:
    {
      # WezTerm: modern terminal with right-click copy/paste and Gruvbox Dark Hard theme
      # Note: For Wayland support on non-NixOS systems, install libegl1-mesa via system package manager
      # (e.g., `sudo apt install libegl1-mesa` on Ubuntu/Debian). WezTerm will fallback to X11 if unavailable.
      programs.wezterm = {
        enable = true;
        extraConfig =
          let
            ansi = builtins.concatStringsSep ",\n            " (
              map (c: "'" + c + "'") config.theme.wezterm.ansi
            );
            brights = builtins.concatStringsSep ",\n            " (
              map (c: "'" + c + "'") config.theme.wezterm.brights
            );
          in
          ''
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

            local enable_wayland = true
            local wayland_env = os.getenv('WEZTERM_ENABLE_WAYLAND')
            if wayland_env == '0' or wayland_env == 'false' then
              enable_wayland = false
            end

            return {
              -- Font configuration
              -- Try FiraCode Nerd Font first, fallback to common monospace fonts
              font = wezterm.font_with_fallback({
                'FiraCode Nerd Font Mono',
                'FiraCode Nerd Font',
                'Fira Code',
                'FiraCode',
                'DejaVu Sans Mono',
                'Liberation Mono',
                'monospace',
              }),
              font_size = 11.0,

              -- Minimal chrome
              enable_tab_bar = false, -- never show the tab/header bar
              use_fancy_tab_bar = false,
              hide_tab_bar_if_only_one_tab = true,
              -- Disable WezTerm's window title/header; let Sway draw titlebars
              window_decorations = 'NONE',
              -- Minimal symmetric padding; Waybar reserves space via exclusive layer
              window_padding = { left = 0, right = 0, top = 0, bottom = 0 },

              -- Gruvbox Dark Hard palette (shared)
              colors = {
                foreground = '${config.theme.wezterm.foreground}',
                background = '${config.theme.wezterm.background}',
                cursor_bg = '${config.theme.wezterm.cursorBg}',
                cursor_fg = '${config.theme.wezterm.cursorFg}',
                cursor_border = '${config.theme.wezterm.cursorBg}',
                selection_bg = '${config.theme.wezterm.selectionBg}',
                selection_fg = '${config.theme.wezterm.selectionFg}',
                ansi = {
                  ${ansi}
                },
                brights = {
                  ${brights}
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
              -- Enable Wayland if available, fallback to X11
              enable_wayland = enable_wayland,
              audible_bell = 'Disabled',

              -- Disable notifications for completed commands
              notification_handling = 'NeverShow',
            }
          '';
      };
    };
}

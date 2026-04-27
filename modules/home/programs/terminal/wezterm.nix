{ lib, ... }:
{
  flake.modules.homeManager."terminal.wezterm" =
    { config, pkgs, ... }:
    let
      hasWeztermTheme = config ? theme && config.theme ? wezterm;
    in
    {
      home.file.".wezterm.lua" = {
        force = true;
        text = ''
          local home = os.getenv("HOME") or "."
          local config_path = home .. "/.config/wezterm/wezterm.lua"
          local ok, cfg = pcall(dofile, config_path)

          if ok then
            return cfg
          end

          local wezterm = require "wezterm"
          wezterm.log_warn("Failed to load " .. config_path .. ": " .. tostring(cfg))
          return {}
        '';
      };

      # WezTerm: modern terminal with right-click copy/paste and Gruvbox Dark Hard theme
      # Note: For Wayland support on non-NixOS systems, install libegl1-mesa via system package manager
      # (e.g., `sudo apt install libegl1-mesa` on Ubuntu/Debian). WezTerm will fallback to X11 if unavailable.
      programs.wezterm = lib.mkIf hasWeztermTheme {
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

            local function basename(path)
              if not path or path == "" then
                return nil
              end
              return path:gsub('(.*[/\\])', "")
            end

            local function cwd_from_pane(pane)
              local cwd = pane.current_working_dir
              if not cwd then
                return nil
              end
              if type(cwd) == 'string' then
                if wezterm.url and wezterm.url.parse then
                  local ok, url = pcall(wezterm.url.parse, cwd)
                  if ok and url and url.file_path then
                    return url.file_path
                  end
                end
                return cwd:gsub('^file://[^/]*', "")
              end
              if type(cwd) == 'table' or type(cwd) == 'userdata' then
                local ok, file_path = pcall(function()
                  return cwd.file_path
                end)
                if ok and file_path and file_path ~= "" then
                  return file_path
                end
              end
              return nil
            end

            wezterm.on('format-window-title', function(tab, pane)
              local proc = pane.foreground_process_name
              proc = basename(proc) or pane.title
              if proc == 'wezterm' then
                proc = nil
              end

              local cwd = cwd_from_pane(pane)
              if cwd then
                local home = wezterm.home_dir
                if home and cwd:sub(1, #home) == home then
                  cwd = '~' .. cwd:sub(#home + 1)
                end
              end

              if proc and cwd then
                return proc .. ' - ' .. cwd
              end
              if cwd then
                return cwd
              end
              if proc and proc ~= "" then
                return proc
              end
              return 'wezterm'
            end)

            local enable_wayland = true
            local wayland_env = os.getenv('WEZTERM_ENABLE_WAYLAND')
            if wayland_env == '0' or wayland_env == 'false' then
              enable_wayland = false
            end

            return {
              -- Font configuration
              -- Prefer JetBrains Mono for crisp rendering, fallback to common monospace fonts
              font = wezterm.font_with_fallback({
                'JetBrainsMono Nerd Font Mono',
                'JetBrains Mono',
                'FiraCode Nerd Font Mono',
                'FiraCode Nerd Font',
                'Fira Code',
                'FiraCode',
                'DejaVu Sans Mono',
                'Liberation Mono',
                'monospace',
              }),
              -- Force Fish as the default shell inside WezTerm
              default_prog = { '${pkgs.fish}/bin/fish', '-l' },
              font_size = 11.0,

              -- Minimal chrome
              enable_tab_bar = false, -- never show the tab/header bar
              use_fancy_tab_bar = false,
              hide_tab_bar_if_only_one_tab = true,
              -- Disable WezTerm's window title/header; let Sway draw titlebars
              window_decorations = 'NONE',
              -- Minimal symmetric padding; Waybar reserves space via exclusive layer
              window_padding = { left = 0, right = 0, top = 0, bottom = 0 },
              scrollback_lines = 100000,

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
                {
                  key = 'Enter',
                  mods = 'SHIFT',
                  action = wezterm.action_callback(function(window, pane)
                    local proc = basename(pane.foreground_process_name)
                    if proc == 'codex' then
                      -- Codex treats Ctrl+J as "insert newline" instead of submit.
                      window:perform_action(act.SendKey({ key = 'j', mods = 'CTRL' }), pane)
                    else
                      window:perform_action(act.SendKey({ key = 'Enter' }), pane)
                    end
                  end),
                },
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

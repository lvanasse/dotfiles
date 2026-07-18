{ config, ... }:
{
  flake.modules.homeManager.terminal =
    { ... }:
    {
      imports = [
        config.flake.modules.homeManager."terminal.bash"
        config.flake.modules.homeManager."terminal.fish"
        config.flake.modules.homeManager."terminal.starship"
        config.flake.modules.homeManager."terminal.wezterm"
        config.flake.modules.homeManager."terminal.foot"
      ];

      home.file.".local/bin/term-emacs" = {
        executable = true;
        text = ''
          #!/bin/sh
          if [ "$#" -eq 0 ]; then
            exec spacemacsclient -t -a "" --eval '(switch-to-buffer "*scratch*")'
          fi

          exec spacemacsclient -t -a "" "$@"
        '';
      };

      home.file.".local/bin/space" = {
        executable = true;
        text = ''
          #!/bin/sh
          exec "$HOME/.local/bin/term-emacs" "$@"
        '';
      };

      home.file.".local/bin/semacs" = {
        executable = true;
        text = ''
          #!/bin/sh
          exec "$HOME/.local/bin/term-emacs" "$@"
        '';
      };
    };

  flake.modules.homeManager.terminalBash = config.flake.modules.homeManager."terminal.bash";
  flake.modules.homeManager.terminalFish = config.flake.modules.homeManager."terminal.fish";
  flake.modules.homeManager.terminalStarship = config.flake.modules.homeManager."terminal.starship";
  flake.modules.homeManager.terminalWezterm = config.flake.modules.homeManager."terminal.wezterm";
  flake.modules.homeManager.terminalFoot = config.flake.modules.homeManager."terminal.foot";
}

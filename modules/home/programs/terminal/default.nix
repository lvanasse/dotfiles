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
          exec emacsclient -t -a "" "$@"
        '';
      };

      home.sessionVariables = {
        EDITOR = "$HOME/.local/bin/term-emacs";
        VISUAL = "$HOME/.local/bin/term-emacs";
      };
    };

  flake.modules.homeManager.terminalBash = config.flake.modules.homeManager."terminal.bash";
  flake.modules.homeManager.terminalFish = config.flake.modules.homeManager."terminal.fish";
  flake.modules.homeManager.terminalStarship = config.flake.modules.homeManager."terminal.starship";
  flake.modules.homeManager.terminalWezterm = config.flake.modules.homeManager."terminal.wezterm";
  flake.modules.homeManager.terminalFoot = config.flake.modules.homeManager."terminal.foot";
}

{ config, ... }:
{
  flake.modules.homeManager."profile.server" =
    { pkgs, ... }:
    {
      imports = [
        config.flake.modules.homeManager.core
      ];

      # Minimal server home config
      home.packages = with pkgs; [
        htop
        tmux
        git
      ];

      programs.bash.enable = true;

      programs.git = {
        enable = true;
        settings.user = {
          name = "Ludovic Vanasse";
          email = "mail@ludovicvanasse.com";
        };
      };
    };
}

{ flakeModules, pkgs, ... }:
{
  imports = [
    flakeModules.homeManager.core
  ];

  # Minimal server home config
  home.packages = with pkgs; [
    htop
    git
    openclaw
  ];

  programs.bash.enable = true;

  programs.git = {
    enable = true;
    settings.user = {
      name = "Ludovic Vanasse";
      email = "mail@ludovicvanasse.com";
    };
  };

  # Server-specific Home Manager overrides go here
}

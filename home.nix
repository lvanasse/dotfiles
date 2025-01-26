{ config, pkgs, ... }: {

  home.username = "ludovic";
  home.homeDirectory = "/home/ludovic";

  programs.git = {
    enable = true;
    userEmail = "lvanasse@luxaerobot.com";
    userName = "Ludovic Vanasse";
  };
  programs.emacs = {
    enable = true;
    package = pkgs.emacs;
  };
  # home.file."Code" = {
  #   text = "";
  #   directory = true;
  # };
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;
}

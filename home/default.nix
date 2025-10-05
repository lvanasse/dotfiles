# Main Home Manager configuration
{
  config,
  pkgs,
  inputs,
  username ? "ludovic",
  hostname,
  ...
}:
{
  imports = [
    ../modules/home
  ];

  # Basic home configuration
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.05";
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
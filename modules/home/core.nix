# Core Home Manager configuration
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  home.enableNixpkgsReleaseCheck = false;
  nixpkgs.config.allowUnfree = true;

  home.username = "ludovic";
  home.homeDirectory = "/home/ludovic";
  home.stateVersion = "25.05";

  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
  };
}
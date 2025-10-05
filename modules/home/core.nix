# Core Home Manager configuration
{
  config,
  pkgs,
  inputs,
  username ? "ludovic",
  ...
}:
{
  home.enableNixpkgsReleaseCheck = false;
  nixpkgs.config.allowUnfree = true;

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.05";

  home.sessionVariables = {
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
  };
}

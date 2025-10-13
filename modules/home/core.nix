# Core Home Manager configuration
{
  config,
  username ? "ludovic",
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  home = {
    enableNixpkgsReleaseCheck = false;
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.05";

    sessionVariables = {
      NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
      NH_FLAKE = "${config.home.homeDirectory}/Code/personal/dotfiles";
    };
  };
}

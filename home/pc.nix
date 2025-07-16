# # TODO A way to store the gnome-terminal profile
# # TODO fix zsh not showing git status -> it's source $ZSH/oh-my-zsh.sh that was not called
# # TODO fix git to use lvanasse instead of random user
# # TODO Add sway config
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  programs.plasma = {
    enable = true;
    workspace = {
      theme = "Ant-Dark";
      wallpaper = "${config.home.homeDirectory}/Code/dotfiles/wallpapers/1458678242783.jpg";
    };
    powerdevil = {
      AC = {
        autoSuspend.action = "nothing";
        autoSuspend.idleTimeout = null;
        whenSleepingEnter = "standby";

        dimDisplay.enable = false;
        turnOffDisplay.idleTimeout = 600;
        turnOffDisplay.idleTimeoutWhenLocked = "whenLockedAndUnlocked";
      };
    };
    kscreenlocker = {
      autoLock = true;
      timeout = 5;
    };
  };
}

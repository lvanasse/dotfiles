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
  # wayland.windowManager.sway = {
  #   enable = true;
  #   systemd.enable = true;

  #   config = {
  #     modifier = "Mod4";

  #     bars = [
  #       {
  #         command = "waybar";
  #         position = "bottom";
  #       }
  #     ];
  #   };
  # };

  programs.git = {
    enable = true;

    # default identity when no condition matches
    userName = "Ludovic Vanasse";
    userEmail = "ludovicvanasse@gmail.com";

    includes = [
      {
        # personal projects
        condition = "gitdir:~/Code/personal/";
        contents.user = {
          name = "Ludovic Vanasse";
          email = "ludovicvanasse@gmail.com";
        };
      }
      {
        # work projects
        condition = "gitdir:~/Code/work/";
        contents.user = {
          name = "Ludovic Vanasse";
          email = "lvanasse@luxaerobot.com";
        };
      }
    ];
  };

}

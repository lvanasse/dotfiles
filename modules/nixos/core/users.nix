{ pkgs, username, ... }:
{
  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "input"
      "video"
      "render"
    ];
    shell = pkgs.fish;
    ignoreShellProgramCheck = true;
  };
}

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
    ];
    shell = pkgs.fish;
    ignoreShellProgramCheck = true;
  };
}

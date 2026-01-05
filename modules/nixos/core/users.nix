{ config, ... }:
let
  username = config.flake.lib.username;
in
{
  flake.modules.nixos.users =
    { pkgs, ... }:
    {
      users.users.${username} = {
        isNormalUser = true;
        description = "${username}";
        linger = true;
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
    };
}

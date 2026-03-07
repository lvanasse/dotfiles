{ config, ... }:
let
  username = config.flake.lib.username;
in
{
  flake.modules.nixos."core.users" =
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
          "dialout"
        ];
        shell = pkgs.fish;
        ignoreShellProgramCheck = true;
      };
    };
}

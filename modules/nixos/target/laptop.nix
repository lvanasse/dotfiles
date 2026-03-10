{ config, ... }:
{
  flake.modules.nixos."target.config.laptop" =
    { inputs, username, ... }:
    {
      imports = [
        inputs.disko.nixosModules.disko
        ../../../hardware/laptop/hardware-configuration.nix
        ../../../hardware/laptop/disko.nix
        config.flake.modules.nixos."target.config.laptop.hardware"
      ];

      services.libinput = {
        enable = true;
        touchpad.tapping = true;
      };

      users.users.${username}.initialPassword = "linux123";
    };
}

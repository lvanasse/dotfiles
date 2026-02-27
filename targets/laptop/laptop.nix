{ inputs, username, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./hardware.nix
    ./disko.nix
  ];

  services.libinput = {
    enable = true;
    touchpad.tapping = true;
  };

  users.users.${username}.initialPassword = "linux123";
}

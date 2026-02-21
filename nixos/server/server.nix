{ inputs, username, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./disko.nix
    # hardware-configuration.nix will be generated during install
  ];

  # Server-specific settings
  users.users.${username}.initialPassword = "changeme";
}

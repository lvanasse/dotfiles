{ ... }:
{
  flake.modules.nixos.networking =
    { ... }:
    {
      # Basic networking configuration

      # Enable NetworkManager
      networking.networkmanager.enable = true;

      # Security
      security.polkit.enable = true;
    };
}

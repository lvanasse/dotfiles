{ config, ... }:
{
  flake.modules.nixos.services =
    { ... }:
    {
      imports = [
        config.flake.modules.nixos."services.virtualization"
        config.flake.modules.nixos."services.flatpak"
        config.flake.modules.nixos."services.printing"
        config.flake.modules.nixos."services.power"
        config.flake.modules.nixos."services.secrets"
        config.flake.modules.nixos."services.keyring"
        config.flake.modules.nixos."services.ssh"
        config.flake.modules.nixos."services.ssh-keys"
        config.flake.modules.nixos."services.tailscale"
      ];
    };
}

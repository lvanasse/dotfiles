{ flakeModules, ... }:
{
  imports = [
    flakeModules.nixos.core
    flakeModules.nixos."services.ssh"
    flakeModules.nixos."services.ssh-keys"
    flakeModules.nixos."services.fail2ban"
    flakeModules.nixos."services.tailscale"
    flakeModules.nixos."targetConfig.gateway"
  ];
}

{ flakeModules, ... }:
{
  imports = [
    flakeModules.nixos.core
    flakeModules.nixos."services.ssh"
    flakeModules.nixos."services.docker"
    flakeModules.nixos."services.snapraid"
    flakeModules.nixos."services.mergerfs"
    flakeModules.nixos."services.jellyfin"
    flakeModules.nixos."services.arr"
    flakeModules.nixos."services.nextcloud"
    flakeModules.nixos."services.mariadb"
    flakeModules.nixos."services.vaultwarden"
    flakeModules.nixos."services.cloudflared"
    flakeModules.nixos."services.fail2ban"
    flakeModules.nixos."services.planka"
    flakeModules.nixos."services.linkwarden"
    flakeModules.nixos."services.ebooks"
    flakeModules.nixos."services.actual"
    flakeModules.nixos."services.watchtower"
    flakeModules.nixos."services.portainer"
    flakeModules.nixos."targetConfig.server"
  ];
}

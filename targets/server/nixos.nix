{ flakeModules, ... }:
{
  imports = [
    flakeModules.nixos.core
    flakeModules.nixos."services.ssh"
    flakeModules.nixos."services.ssh-keys"
    flakeModules.nixos."services.docker"
    flakeModules.nixos."services.snapraid"
    flakeModules.nixos."services.mergerfs"
    flakeModules.nixos."services.jellyfin"
    flakeModules.nixos."services.audiobookshelf"
    flakeModules.nixos."services.arr"
    flakeModules.nixos."services.arr-sync"
    flakeModules.nixos."services.nextcloud"
    flakeModules.nixos."services.mariadb"
    flakeModules.nixos."services.vaultwarden"
    flakeModules.nixos."services.cloudflared"
    flakeModules.nixos."services.fail2ban"
    flakeModules.nixos."services.vikunja"
    flakeModules.nixos."services.linkwarden"
    flakeModules.nixos."services.ebooks"
    flakeModules.nixos."services.shelfmark"
    flakeModules.nixos."services.actual"
    flakeModules.nixos."services.dockhand"
    flakeModules.nixos."target.config.server"
  ];
}

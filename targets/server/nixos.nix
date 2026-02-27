{ flakeModules, pkgs, ... }:
{
  imports = [
    flakeModules.nixos.core
    flakeModules.nixos.servicesSsh
    flakeModules.nixos."services.docker"
    flakeModules.nixos."services.snapraid"
    flakeModules.nixos."services.mergerfs"
    flakeModules.nixos."services.jellyfin"
    flakeModules.nixos."services.arr"
    flakeModules.nixos."services.nextcloud"
    flakeModules.nixos."services.mariadb"
    flakeModules.nixos."services.vaultwarden"
    flakeModules.nixos."services.cloudflared"
    flakeModules.nixos."services.planka"
    flakeModules.nixos."services.linkwarden"
    flakeModules.nixos."services.ebooks"
    flakeModules.nixos."services.actual"
    flakeModules.nixos."services.headscale"
    ./server.nix
  ];

  # Headless server settings
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Tailscale client for secure remote access
  services.tailscale.enable = true;

  # Basic server packages
  environment.systemPackages = with pkgs; [
    htop
    iotop
    ncdu
    git
    curl
    wget
    rsync
  ];

  # Enable fstrim for SSD
  services.fstrim.enable = true;

  # Firewall - trust tailscale
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
  };
}

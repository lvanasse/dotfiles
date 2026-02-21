{ config, ... }:
{
  flake.modules.nixos."profile.server" =
    { pkgs, ... }:
    {
      imports = [
        config.flake.modules.nixos.core
        config.flake.modules.nixos.servicesSsh
        config.flake.modules.nixos."services.docker"
        config.flake.modules.nixos."services.snapraid"
        config.flake.modules.nixos."services.mergerfs"
        config.flake.modules.nixos."services.jellyfin"
        config.flake.modules.nixos."services.arr"
        config.flake.modules.nixos."services.nextcloud"
        config.flake.modules.nixos."services.vaultwarden"
        config.flake.modules.nixos."services.cloudflared"
      ];

      # Headless server settings
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      # Tailscale for secure remote access
      services.tailscale.enable = true;

      # Basic server packages
      environment.systemPackages = with pkgs; [
        htop
        iotop
        ncdu
        tmux
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
    };
}

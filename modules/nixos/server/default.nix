{ config, ... }:
{
  flake.modules.nixos."profile.server" =
    { pkgs, ... }:
    {
      imports = [
        config.flake.modules.nixos.core
        config.flake.modules.nixos."server.ssh"
        config.flake.modules.nixos."server.docker"
        config.flake.modules.nixos."server.snapraid"
        config.flake.modules.nixos."server.mergerfs"
        config.flake.modules.nixos."server.jellyfin"
        config.flake.modules.nixos."server.arr"
        config.flake.modules.nixos."server.nextcloud"
        config.flake.modules.nixos."server.vaultwarden"
        config.flake.modules.nixos."server.cloudflared"
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

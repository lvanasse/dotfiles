{ ... }:
{
  flake.modules.nixos."targetConfig.server" =
    { inputs, username, pkgs, ... }:
    {
      imports = [
        inputs.disko.nixosModules.disko
        ../../../hardware/server/disko.nix
        # hardware-configuration.nix will be generated during install
      ];

      # Server-specific settings
      users.users.${username}.initialPassword = "changeme";

      # Server identity/time services
      networking.timeServers = [
        "time1.google.com"
        "time2.google.com"
        "time3.google.com"
        "time4.google.com"
      ];
      networking.nameservers = [ "1.1.1.1" ];

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
    };
}

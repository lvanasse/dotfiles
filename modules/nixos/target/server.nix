{ lib, ... }:
{
  flake.modules.nixos."target.config.server" =
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
      networking = {
        nameservers = [ "1.1.1.1" ];

        # Server network is managed by systemd-networkd with static LAN address.
        useNetworkd = true;
        networkmanager.enable = lib.mkForce false;
        useDHCP = false;

        interfaces.enp1s0 = {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = "192.168.0.50";
              prefixLength = 24;
            }
          ];
        };

        defaultGateway = {
          address = "192.168.0.1";
          interface = "enp1s0";
        };
      };

      # Headless server settings
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      # Tailscale client for secure remote access
      services.tailscale.enable = true;

      # Basic server packages
      environment.systemPackages = with pkgs; [
        htop
        btop
        iotop
        ncdu
        git
        curl
        wget
        rsync
        codex
      ];

      # Enable fstrim for SSD
      services.fstrim.enable = true;

      # Firewall - trust tailscale and allow LAN access on enp1s0
      networking.firewall = {
        enable = true;
        trustedInterfaces = [ "tailscale0" "docker0" ];
        allowedTCPPorts = lib.mkForce [ ];
        allowedUDPPorts = lib.mkForce [ ];
        interfaces.enp1s0.allowedTCPPorts = lib.mkForce [ 22 59793 ];
        interfaces.enp1s0.allowedUDPPorts = lib.mkForce [ 59793 ];
      };

      services.openssh.openFirewall = lib.mkForce false;
    };
}

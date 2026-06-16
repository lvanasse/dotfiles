{ lib, ... }:
{
  flake.modules.nixos."target.config.server" =
    {
      inputs,
      username,
      pkgs,
      ...
    }:
    let
      wakePcLan = pkgs.writeShellApplication {
        name = "wake-pc-lan";
        runtimeInputs = [ pkgs.wakeonlan ];
        text = ''
          set -euo pipefail

          exec wakeonlan -i 192.168.0.255 f0:2f:74:da:87:01
        '';
      };
    in
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
        # Server network is managed by systemd-networkd via a gateway DHCP reservation.
        useNetworkd = true;
        networkmanager.enable = lib.mkForce false;
        useDHCP = false;

        interfaces.enp1s0 = {
          useDHCP = true;
        };
        nameservers = [
          "1.1.1.1"
          "9.9.9.9"
        ];
      };

      # Headless server settings
      # Use the release kernel on infrastructure hosts instead of the
      # globally configured unstable kernel.
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
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
        wakePcLan
        wakeonlan
        pkgs.llm-agents.codex
      ];

      # Enable fstrim for SSD
      services.fstrim.enable = true;

      # Firewall - trust tailscale and allow LAN access on enp1s0
      networking.firewall = {
        enable = true;
        trustedInterfaces = [
          "tailscale0"
          "docker0"
        ];
        allowedTCPPorts = lib.mkForce [ ];
        allowedUDPPorts = lib.mkForce [ ];
        interfaces.enp1s0.allowedTCPPorts = lib.mkForce [
          22
          6767
          8082
          8083
          8084
          8085
          13378
          59793
        ];
        interfaces.enp1s0.allowedUDPPorts = lib.mkForce [ 59793 ];
      };

      services.openssh.openFirewall = lib.mkForce false;
    };
}

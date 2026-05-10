{ lib, ... }:
let
  staged = true;

  mgmtIf = "enp3s0";
  wanIf = "enp5s0";
  lanIf = "enp4s0";
  activeUplinkIf = if staged then mgmtIf else wanIf;

  stagedLanAddress = "192.168.10.1";
  finalLanAddress = "192.168.0.1";
  lanAddress = if staged then stagedLanAddress else finalLanAddress;
  lanPrefixLength = 24;
  lanCidr = "${lanAddress}/${toString lanPrefixLength}";
  dhcpRange =
    if staged then
      "192.168.10.100,192.168.10.199,255.255.255.0,12h"
    else
      "192.168.0.100,192.168.0.199,255.255.255.0,12h";
in
{
  flake.modules.nixos."target.config.gateway" =
    { inputs, pkgs, username, config, ... }:
    {
      imports = [
        inputs.disko.nixosModules.disko
        ../../../hardware/gateway/disko.nix
        # hardware-configuration.nix will be generated during install
      ];

      # Router-specific bootstrap setting.
      users.users.${username}.initialPassword = "changeme";

      # Headless gateway defaults.
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;
      services.fstrim.enable = true;

      networking = {
        # Router/gateway networking is managed by networkd.
        useNetworkd = true;
        networkmanager.enable = lib.mkForce false;
        useDHCP = false;

        interfaces.${mgmtIf}.useDHCP = staged;
        interfaces.${wanIf}.useDHCP = !staged;
        interfaces.${lanIf} = {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = lanAddress;
              prefixLength = lanPrefixLength;
            }
          ];
        };

        # NAT follows the active uplink so staging can route via the current router.
        nat = {
          enable = true;
          externalInterface = activeUplinkIf;
          internalInterfaces = [ lanIf ];
        };

        # Firewall defaults: SSH on management/LAN only, DHCP+DNS on LAN only.
        firewall = {
          enable = true;
          trustedInterfaces = [ "tailscale0" ];
          allowedTCPPorts = lib.mkForce [ ];
          allowedUDPPorts = lib.mkForce [ ];

          interfaces.${mgmtIf}.allowedTCPPorts = lib.mkForce [ 22 ];
          interfaces.${lanIf} = {
            allowedTCPPorts = lib.mkForce [ 22 53 ];
            allowedUDPPorts = lib.mkForce [ 53 67 ];
          };
          interfaces.${wanIf} = {
            allowedTCPPorts = lib.mkForce [ ];
            allowedUDPPorts = lib.mkForce [ ];
          };
        };
      };

      # dnsmasq provides DHCP and DNS on the LAN segment.
      services.dnsmasq = {
        enable = true;
        settings = {
          interface = [ lanIf ];
          "bind-interfaces" = true;
          "domain-needed" = true;
          "bogus-priv" = true;
          "dhcp-authoritative" = true;
          listen-address = [ lanAddress "127.0.0.1" ];
          server = config.networking.nameservers;
          "dhcp-range" = dhcpRange;
          "dhcp-option" = [
            "option:router,${lanAddress}"
            "option:dns-server,${lanAddress}"
          ];
        };
      };

      # Ensure forwarding is enabled for routing/NAT.
      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
      };

      # SSH service module sets openFirewall=true by default; keep it closed on WAN.
      services.openssh.openFirewall = lib.mkForce false;

      # Helpful operational tools for a gateway box.
      environment.systemPackages = with pkgs; [
        btop
        dnsmasq
        ethtool
        iperf3
        nftables
        tcpdump
        traceroute
      ];

      systemd.network.wait-online.ignoredInterfaces = lib.mkIf staged [ wanIf ];

      warnings = [
        "Gateway target is in staged mode: ${lanIf} serves ${lanCidr} and NAT egress uses ${activeUplinkIf}. Set `staged = false` in modules/nixos/target/gateway.nix for final cutover to ${finalLanAddress}/24 on ${lanIf} via ${wanIf}."
      ];
    };
}

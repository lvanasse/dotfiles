{ lib, ... }:
let
  # Replace with your NIC names once the machine is installed.
  wanIf = "enp1s0";
  lanIf = "enp2s0";

  lanAddress = "192.168.10.1";
  lanPrefixLength = 24;
in
{
  flake.modules.nixos."target.config.gateway" =
    { inputs, pkgs, username, ... }:
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

        interfaces.${wanIf}.useDHCP = true;
        interfaces.${lanIf} = {
          useDHCP = false;
          ipv4.addresses = [
            {
              address = lanAddress;
              prefixLength = lanPrefixLength;
            }
          ];
        };

        # NAT: WAN uplink + LAN downstream.
        nat = {
          enable = true;
          externalInterface = wanIf;
          internalInterfaces = [ lanIf ];
        };

        # Firewall defaults: only SSH/DNS/DHCP on LAN, nothing open on WAN.
        firewall = {
          enable = true;
          trustedInterfaces = [ lanIf "tailscale0" ];
          allowedTCPPorts = lib.mkForce [ ];
          allowedUDPPorts = lib.mkForce [ ];

          interfaces.${lanIf} = {
            allowedTCPPorts = [ 22 53 3000 ];
            allowedUDPPorts = [ 53 67 ];
          };
        };
      };

      # dnsmasq provides DHCP only for the LAN segment.
      services.dnsmasq = {
        enable = true;
        settings = {
          interface = lanIf;
          "port" = 0;
          "bind-interfaces" = true;
          "domain-needed" = true;
          "bogus-priv" = true;
          "dhcp-authoritative" = true;
          "dhcp-range" = "192.168.10.100,192.168.10.199,255.255.255.0,12h";
          "dhcp-option" = [
            "option:router,${lanAddress}"
            "option:dns-server,${lanAddress}"
          ];
        };
      };

      # Open-source local recursive resolver (no Google/Cloudflare upstream required).
      services.unbound = {
        enable = true;
        enableRootTrustAnchor = true;
        settings = {
          server = {
            interface = [ "127.0.0.1" ];
            port = 5335;
            prefetch = true;
            prefetch-key = true;
            qname-minimisation = true;
            aggressive-nsec = true;
            harden-dnssec-stripped = true;
            harden-glue = true;
            harden-referral-path = true;
            use-caps-for-id = true;
            hide-identity = true;
            hide-version = true;
            cache-min-ttl = 300;
            cache-max-ttl = 86400;
            serve-expired = true;
            serve-expired-ttl = 86400;
            edns-buffer-size = 1232;
          };
        };
      };

      # Pi-hole-like DNS filtering layer with web UI on http://<gateway-lan-ip>:3000.
      services.adguardhome = {
        enable = true;
        host = lanAddress;
        port = 53;
        openFirewall = false;
        mutableSettings = false;
        settings = {
          http = {
            address = "${lanAddress}:3000";
          };
          dns = {
            bind_hosts = [
              lanAddress
              "127.0.0.1"
            ];
            upstream_dns = [ "127.0.0.1:5335" ];
            bootstrap_dns = [ "127.0.0.1" ];
            # Fallback resolvers (non-corporate/community-oriented) used only if local upstream is unavailable.
            fallback_dns = [
              "88.198.92.222" # LibreOps radicalDNS
              "134.195.4.2" # OpenNIC public resolver
            ];
            dnssec_enabled = true;
          };
          filtering = {
            protection_enabled = true;
            filtering_enabled = true;
          };
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
        ethtool
        iperf3
        nftables
        tcpdump
        traceroute
      ];
    };
}

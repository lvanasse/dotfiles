{ lib, ... }:
let
  # Live gateway hardware mapping:
  # - enp3s0: lower Intel I225-V add-in NIC port; currently unused spare port.
  # - enp4s0: upper Intel I225-V add-in NIC port; routed LAN interface.
  # - enp5s0: onboard Realtek RTL8111/8168/8411 NIC; WAN/PPPoE interface.
  spareIf = "enp3s0";
  wanPhyIf = "enp5s0";
  wanIf = "${wanPhyIf}.40";
  lanIf = "enp4s0";
  pppoeIf = "ppp0";
  pppoePeer = "gateway-wan";

  lanAddress = "192.168.0.1";
  lanPrefixLength = 24;
  pcMacAddress = "f0:2f:74:da:87:01";
  serverMacAddress = "04:7c:16:88:d0:f0";
  apMacAddress = "a8:6e:84:e3:f3:27";
  upstreamDns = [
    "1.1.1.1"
    "9.9.9.9"
  ];
in
{
  flake.modules.nixos."target.config.gateway" =
    {
      inputs,
      pkgs,
      username,
      config,
      ...
    }:
    let
      lanCidr = "${lanAddress}/${toString lanPrefixLength}";
      pcLeaseAddress = "192.168.0.100";
      serverLeaseAddress = "192.168.0.50";
      apLeaseAddress = "192.168.0.2";
      gatewayStatusPort = 8094;
      dhcpRange = "192.168.0.100,192.168.0.199,255.255.255.0,12h";
      lanDomain = "home.arpa";
      gatewayPppoeEnvAge = "${inputs.secrets}/gateway/pppoe.env.age";
      hasGatewayPppoeEnvAge = builtins.pathExists gatewayPppoeEnvAge;
      gatewayPppoeEnvPath = "/run/agenix/gateway-pppoe-env";
    in
    {
      imports = [
        inputs.disko.nixosModules.disko
        ../../../hardware/gateway/disko.nix
        # hardware-configuration.nix will be generated during install
      ];

      config = {
        # Router-specific bootstrap setting.
        users.users.${username}.initialPassword = "changeme";

        # Headless gateway defaults.
        # Prefer the LTS kernel on infrastructure hosts. The 6.18 unstable
        # kernel hit an igc driver oops on the gateway's Intel NICs.
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages_6_12;
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        services.fstrim.enable = true;

        networking = {
          # Router/gateway networking is managed by networkd.
          useNetworkd = true;
          networkmanager.enable = lib.mkForce false;
          useDHCP = false;

          interfaces.${spareIf}.useDHCP = false;
          interfaces.${wanPhyIf}.useDHCP = false;
          interfaces.${wanIf}.useDHCP = false;
          interfaces.${lanIf} = {
            useDHCP = false;
            ipv4.addresses = [
              {
                address = lanAddress;
                prefixLength = lanPrefixLength;
              }
            ];
          };

          # NAT always leaves through the PPPoE uplink after cutover.
          nat = {
            enable = true;
            externalInterface = pppoeIf;
            internalInterfaces = [ lanIf ];
          };

          vlans.${wanIf} = {
            id = 40;
            interface = wanPhyIf;
          };

          # Firewall defaults: SSH on management/LAN only, DHCP+DNS on LAN only.
          firewall = {
            enable = true;
            allowPing = false;
            trustedInterfaces = [ "tailscale0" ];
            allowedTCPPorts = lib.mkForce [ ];
            allowedUDPPorts = lib.mkForce [ ];
            extraCommands = ''
              # Clamp forwarded TCP MSS to the discovered path MTU.
              # This avoids selective HTTPS stalls behind the PPPoE uplink.
              iptables -t mangle -A FORWARD -o ${pppoeIf} -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
              iptables -A INPUT -i ${lanIf} -p icmp --icmp-type echo-request -j ACCEPT
              iptables -A INPUT -i tailscale0 -p icmp --icmp-type echo-request -j ACCEPT
              iptables -A INPUT -i ${lanIf} -p tcp -s ${serverLeaseAddress} --dport ${toString gatewayStatusPort} -j ACCEPT
            '';
            extraStopCommands = ''
              iptables -t mangle -D FORWARD -o ${pppoeIf} -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu || true
              iptables -D INPUT -i ${lanIf} -p icmp --icmp-type echo-request -j ACCEPT || true
              iptables -D INPUT -i tailscale0 -p icmp --icmp-type echo-request -j ACCEPT || true
              iptables -D INPUT -i ${lanIf} -p tcp -s ${serverLeaseAddress} --dport ${toString gatewayStatusPort} -j ACCEPT || true
            '';
            interfaces = {
              ${lanIf} = {
                allowedTCPPorts = lib.mkForce [
                  22
                  53
                ];
                allowedUDPPorts = lib.mkForce [
                  53
                  67
                ];
              };
              ${wanPhyIf} = {
                allowedTCPPorts = lib.mkForce [ ];
                allowedUDPPorts = lib.mkForce [ ];
              };
              ${wanIf} = {
                allowedTCPPorts = lib.mkForce [ ];
                allowedUDPPorts = lib.mkForce [ ];
              };
              ${pppoeIf} = {
                allowedTCPPorts = lib.mkForce [ ];
                allowedUDPPorts = lib.mkForce [ ];
              };
            };
          };
        };

        # dnsmasq provides DHCP and DNS on the LAN segment.
        services.dnsmasq = {
          enable = true;
          settings = {
            interface = [ lanIf ];
            "bind-interfaces" = true;
            "filter-AAAA" = true;
            "domain-needed" = true;
            "bogus-priv" = true;
            domain = lanDomain;
            local = "/${lanDomain}/";
            "expand-hosts" = true;
            "dhcp-authoritative" = true;
            listen-address = [
              lanAddress
              "127.0.0.1"
            ];
            server = upstreamDns;
            "dhcp-range" = dhcpRange;
            "dhcp-host" = [
              "${pcMacAddress},pc,${pcLeaseAddress}"
              "${serverMacAddress},server,${serverLeaseAddress}"
              "${apMacAddress},ap,${apLeaseAddress}"
            ];
            "host-record" = [
              "gateway,${lanAddress}"
              "gateway.${lanDomain},${lanAddress}"
              "server,${serverLeaseAddress}"
              "server.${lanDomain},${serverLeaseAddress}"
              "pc,${pcLeaseAddress}"
              "pc.${lanDomain},${pcLeaseAddress}"
              "ap,${apLeaseAddress}"
              "ap.${lanDomain},${apLeaseAddress}"
            ];
            "dhcp-option" = [
              "option:router,${lanAddress}"
              "option:dns-server,${lanAddress}"
              "option:domain-name,${lanDomain}"
              "option:domain-search,${lanDomain}"
            ];
          };
        };

        age.secrets = lib.mkIf hasGatewayPppoeEnvAge {
          "gateway-pppoe-env" = {
            file = gatewayPppoeEnvAge;
            path = gatewayPppoeEnvPath;
            owner = "root";
            group = "root";
            mode = "0400";
          };
        };

        systemd.services.gateway-pppoe = lib.mkIf hasGatewayPppoeEnvAge {
          description = "PPPoE uplink for gateway WAN";
          after = [
            "network-pre.target"
          ];
          wants = [ "network.target" ];
          before = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          environment = {
            LD_PRELOAD = "${pkgs.libredirect}/lib/libredirect.so";
            NIX_REDIRECTS = "/var/run=/run/pppd";
          };
          serviceConfig =
            let
              capabilities = [
                "CAP_BPF"
                "CAP_SYS_TTY_CONFIG"
                "CAP_NET_ADMIN"
                "CAP_NET_RAW"
              ];
              peerPath = "/run/ppp/peers/${pppoePeer}";
            in
            {
              Type = "notify";
              ExecStartPre = pkgs.writeShellScript "gateway-pppoe-prepare" ''
                set -euo pipefail

                . ${gatewayPppoeEnvPath}

                : "''${PPPOE_USERNAME:?set PPPOE_USERNAME in ${gatewayPppoeEnvPath}}"
                : "''${PPPOE_PASSWORD:?set PPPOE_PASSWORD in ${gatewayPppoeEnvPath}}"

                install -d -m 0700 /run/ppp /run/ppp/peers

                cat > ${peerPath} <<EOF
                plugin pppoe.so ${wanIf}
                user "$PPPOE_USERNAME"
                password "$PPPOE_PASSWORD"
                noauth
                persist
                defaultroute
                hide-password
                mtu 1492
                mru 1492
                lcp-echo-interval 10
                lcp-echo-failure 3
                EOF
                chmod 0600 ${peerPath}
              '';
              ExecStart = "${pkgs.ppp}/sbin/pppd file /run/ppp/peers/${pppoePeer} up_sdnotify nolog";
              Restart = "always";
              RestartSec = 5;
              AmbientCapabilities = capabilities;
              CapabilityBoundingSet = capabilities;
              KeyringMode = "private";
              LockPersonality = true;
              MemoryDenyWriteExecute = true;
              NoNewPrivileges = true;
              PrivateMounts = true;
              PrivateTmp = true;
              ProtectControlGroups = true;
              ProtectHome = true;
              ProtectHostname = true;
              ProtectKernelModules = true;
              ProtectKernelTunables = false;
              ProtectSystem = "strict";
              RemoveIPC = true;
              RestrictAddressFamilies = [
                "AF_ATMPVC"
                "AF_ATMSVC"
                "AF_INET"
                "AF_INET6"
                "AF_IPX"
                "AF_NETLINK"
                "AF_PACKET"
                "AF_PPPOX"
                "AF_UNIX"
              ];
              RestrictNamespaces = true;
              RestrictRealtime = true;
              RestrictSUIDSGID = true;
              SecureBits = "no-setuid-fixup-locked noroot-locked";
              SystemCallFilter = "@system-service";
              SystemCallArchitectures = "native";
              RuntimeDirectory = "pppd";
              RuntimeDirectoryPreserve = true;
            };
        };

        # Ensure forwarding is enabled for routing/NAT.
        boot.kernel.sysctl = {
          "net.ipv4.ip_forward" = 1;
          "net.ipv6.conf.all.forwarding" = 1;
        };

        # SSH service module sets openFirewall=true by default; keep it closed on WAN.
        services.openssh.openFirewall = lib.mkForce false;
        services.openssh.settings = {
          PasswordAuthentication = lib.mkForce false;
          KbdInteractiveAuthentication = lib.mkForce false;
        };

        # Helpful operational tools for a gateway box.
        environment.systemPackages = with pkgs; [
          btop
          dnsmasq
          ethtool
          fail2ban
          iperf3
          nftables
          ppp
          tcpdump
          traceroute
          wakeonlan
        ];

        systemd.network.networks = {
          "40-${spareIf}" = {
            matchConfig.Name = spareIf;
            linkConfig.RequiredForOnline = false;
          };

          "40-${lanIf}" = {
            matchConfig.Name = lanIf;
            networkConfig.ConfigureWithoutCarrier = true;
            linkConfig.RequiredForOnline = "routable";
          };

          "40-${wanPhyIf}" = {
            matchConfig.Name = wanPhyIf;
            linkConfig.RequiredForOnline = false;
          };

          "40-${wanIf}" = {
            matchConfig.Name = wanIf;
            linkConfig.RequiredForOnline = false;
          };
        };

        systemd.network.wait-online.anyInterface = true;
        systemd.network.wait-online.ignoredInterfaces = [
          spareIf
          wanPhyIf
          wanIf
        ];

        warnings =
          lib.optional (!hasGatewayPppoeEnvAge)
            "Gateway expects an agenix secret at ${gatewayPppoeEnvAge} with PPPOE_USERNAME=... and PPPOE_PASSWORD=....";
      };
    };
}

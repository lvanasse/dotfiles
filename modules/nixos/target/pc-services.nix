{ ... }:
{
  flake.modules.nixos."target.config.pc.services" =
    { lib, ... }:
    {
      services = {
        # Proxy DHCP and TFTP service for Raspberry Pi network booting.
        dnsmasq = {
          enable = true;
          settings = {
            port = 0;
            interface = [ "enp5s0" ];
            "bind-interfaces" = true;
            "dhcp-range" = "192.168.0.255,proxy";
            "log-dhcp" = true;
            "enable-tftp" = true;
            "tftp-root" = "/srv/rpi4/tftp";
            "pxe-service" = ''0,"Raspberry Pi Boot"'';
          };
        };

        # Keep the PC awake while idle; Sway handles display power-off separately.
        logind.settings.Login = {
          IdleAction = lib.mkForce "ignore";
          IdleActionSec = lib.mkForce "0min";
        };

        # DNS configuration
        resolved = {
          enable = true;
          settings.Resolve = {
            DNSSEC = false;
            Domains = [ "home.arpa" ];
            FallbackDNS = [
              "1.1.1.1"
              "9.9.9.9"
            ];
            Cache = "no-negative";
            TrustAnchor = false;
          };
        };

        # PC-specific Flatpak configuration
        flatpak =
          let
            runtimeCa = "/etc/ssl/certs/ca-bundle.crt";
          in
          {
            remotes = lib.mkOptionDefault [
              {
                name = "flathub";
                location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
              }
              {
                name = "woblight";
                location = "https://woblight.gitlab.io/flatpak-repo";
              }
            ];
            packages = [
              {
                appId = "io.gitlab.woblight.GitAddonsManager//master";
                origin = "woblight";
              }
            ];
            overrides = {
              "io.gitlab.woblight.GitAddonsManager".Environment = {
                CURL_CA_BUNDLE = runtimeCa;
                GIT_SSL_CAINFO = runtimeCa;
                NIX_SSL_CERT_FILE = runtimeCa;
                SSL_CERT_FILE = runtimeCa;
              };
            };
          };

        spotifyd.enable = lib.mkForce false;
      };

      networking.firewall = {
        allowedTCPPorts = [ 57621 ];
        allowedUDPPorts = [
          67
          69
          5353
        ];
      };

      systemd.tmpfiles.rules = [
        "d /srv/rpi4/tftp 0755 root root -"
      ];
    };
}

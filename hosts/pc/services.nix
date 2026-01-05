{ lib, ... }:
{
  services = {
    # DNS configuration
    resolved = {
      enable = true;
      dnssec = "false";
      fallbackDns = [
        "1.1.1.1"
        "9.9.9.9"
      ];
      extraConfig = ''
        Cache=no-negative                  # avoid long NXDOMAIN waits
        TrustAnchor=false                  # strips the "trust-ad" bit
      '';
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
  };
}

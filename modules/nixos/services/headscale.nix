{ ... }:
{
  flake.modules.nixos."services.headscale" =
    { ... }:
    {
      services.headscale = {
        enable = true;
        address = "0.0.0.0";
        port = 8080;
        settings = {
          server_url = "https://headscale.ludovicvanasse.com";
          dns = {
            base_domain = "tailnet.lan";
            override_local_dns = false;
            nameservers.global = [
              "1.1.1.1"
              "1.0.0.1"
            ];
          };
        };
      };

      networking.firewall.allowedTCPPorts = [ 8080 ];
    };
}

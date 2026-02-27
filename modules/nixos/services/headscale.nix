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
          server_url = "http://192.168.0.50:8080";
          dns.base_domain = "tailnet.lan";
        };
      };

      networking.firewall.allowedTCPPorts = [ 8080 ];
    };
}

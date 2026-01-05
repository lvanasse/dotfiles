{ ... }:
{
  flake.modules.nixos.servicesTailscale =
    { ... }:
    {
      services.tailscale = {
        enable = true;
        useRoutingFeatures = "client";
        openFirewall = true;
      };

      networking.firewall.trustedInterfaces = [ "tailscale0" ];
    };
}

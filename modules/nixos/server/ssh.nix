{ ... }:
{
  flake.modules.nixos."server.ssh" =
    { ... }:
    {
      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
        };
      };

      networking.firewall.allowedTCPPorts = [ 22 ];
    };
}

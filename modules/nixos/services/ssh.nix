{ ... }:
{
  flake.modules.nixos.servicesSsh =
    { ... }:
    {
      # SSH server configuration
      services.openssh = {
        enable = true;
        openFirewall = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = true;
        };
        authorizedKeysInHomedir = true;
      };
    };
}

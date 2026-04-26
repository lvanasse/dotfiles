{ ... }:
{
  flake.modules.nixos."services.ssh" =
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
        authorizedKeysInHomedir = false;
      };
    };
}

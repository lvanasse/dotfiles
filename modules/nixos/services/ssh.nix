# SSH server configuration
{ config, pkgs, ... }:
{
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;
    };
    authorizedKeysInHomedir = true;
  };
}

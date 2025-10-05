# SSH server configuration
_: {
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

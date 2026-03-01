{ ... }:
{
  flake.modules.nixos."services.fail2ban" =
    { ... }:
    {
      services.fail2ban = {
        enable = true;
        bantime = "1h";
        maxretry = 5;
        ignoreIP = [
          "127.0.0.1/8"
          "::1"
          "192.168.0.0/16"
        ];
        jails.DEFAULT.settings = {
          findtime = 600;
        };
        jails.sshd = {
          enabled = true;
          settings = {
            port = "ssh";
            logpath = "%(sshd_log)s";
          };
        };
      };
    };
}

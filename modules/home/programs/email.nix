{ inputs, ... }:
{
  flake.modules.homeManager."programs.email" =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      enableAccount = true;
      homeDir = config.home.homeDirectory;
      infomaniakPasswordAge = "${inputs.secrets}/email/mail@ludovicvanasse.com-infomaniak.age";
      hasInfomaniakPassword = builtins.pathExists infomaniakPasswordAge;
      infomaniakPasswordPath = "${homeDir}/.config/mail/infomaniak-password";
    in
    {
      programs.mu.enable = true;
      programs.mbsync.enable = true;
      programs.msmtp.enable = true;

      accounts.email.maildirBasePath = "mail";

      accounts.email.accounts.ludovic =
        {
          address = "mail@ludovicvanasse.com";
          userName = "mail@ludovicvanasse.com";
          realName = "Ludovic Vanasse";
          primary = true;

          imap = {
            host = "mail.infomaniak.com";
            port = 993;
            tls.enable = true;
          };
          smtp = {
            host = "mail.infomaniak.com";
            port = 587;
            tls = {
              enable = true;
              useStartTls = true;
            };
          };

          folders = {
            inbox = "Index";
            sent = "Sent messages";
            drafts = "Drafts";
            trash = "Trash";
          };

          mbsync = {
            enable = true;
            create = "maildir";
            expunge = "both";
          };
          msmtp.enable = true;
          mu.enable = true;
        }
        // lib.optionalAttrs hasInfomaniakPassword {
          passwordCommand = "cat ${infomaniakPasswordPath}";
        };

      services.mbsync = lib.mkIf enableAccount {
        enable = true;
        frequency = "*:0/10"; # every 10 minutes
      };

      systemd.user.services.mbsync.Service.ExecStopPost = lib.mkIf enableAccount [
        "${pkgs.mu}/bin/mu index"
      ];

      home.activation.mu-init = lib.hm.dag.entryAfter [ "mbsync" ] ''
        MU_STORE="${config.xdg.cacheHome}/mu"
        if [ ! -d "$MU_STORE" ]; then
          ${pkgs.mu}/bin/mu init --maildir ${config.home.homeDirectory}/mail \
            --my-address=mail@ludovicvanasse.com
          ${pkgs.mu}/bin/mu index
        fi
      '';
    };
}

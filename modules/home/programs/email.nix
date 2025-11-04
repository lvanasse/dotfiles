{
  lib,
  config,
  pkgs,
  ...
}:
let
  # Toggle to activate account once server details are provided
  enableAccount = true;
in
{
  # Install mu/mu4e and helpers
  programs.mu.enable = true;

  # Maildir base path under home
  accounts.email.maildirBasePath = "mail";

  # Primary email account (fill in IMAP/SMTP details)
  accounts.email.accounts.ludovic = {
    address = "mail@ludovicvanasse.com";
    userName = "mail@ludovicvanasse.com";
    realName = "Ludovic Vanasse";
    primary = true;

    imap = {
      host = "imap.infomaniak.com";
      port = 993;
      tls.enable = true;
    };
    smtp = {
      host = "smtp.infomaniak.com";
      port = 465;
      tls = {
        enable = true;
        useStartTls = false;
      };
    };

    # Generate mbsync (isync) + msmtp configs; do not auto-run sync yet
    mbsync = {
      enable = true;
      create = "maildir";
      expunge = "both";
    };
    msmtp.enable = true;
    mu.enable = true;

    # Password retrieval: expects a command printing the password to stdout.
    passwordCommand = "cat /run/agenix/infomaniak-password";
  };

  # Optionally enable periodic mailbox sync via systemd user timer
  # Activate after confirming credentials and servers.
  services.mbsync = lib.mkIf enableAccount {
    enable = false; # set to true once creds are configured
    frequency = "*:0/10"; # every 10 minutes
  };
  home.activation.mu-init = lib.hm.dag.entryAfter [ "mbsync" ] ''
    MU_STORE="${config.xdg.cacheHome}/mu"
    if [ ! -d "$MU_STORE" ]; then
      ${pkgs.mu}/bin/mu init --maildir ${config.home.homeDirectory}/mail \
        --my-address=mail@ludovicvanasse.com
      ${pkgs.mu}/bin/mu index
    fi
  '';
}

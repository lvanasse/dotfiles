{ lib, ... }:
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
      host = lib.mkDefault "imap.example.com"; # TODO: replace with provider
      port = 993;
      tls.enable = true;
    };
    smtp = {
      host = lib.mkDefault "smtp.example.com"; # TODO: replace with provider
      port = 587;
      tls.enable = true;
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
    # For GNOME Keyring you can use secret-tool (see above SMTP/IMAP entries).
    # Or switch to pass/agenix based secrets per your preference.
    passwordCommand = lib.mkDefault "secret-tool lookup email mail@ludovicvanasse.com service imap";
  };

  # Optionally enable periodic mailbox sync via systemd user timer
  # Activate after confirming credentials and servers.
  services.mbsync = lib.mkIf enableAccount {
    enable = false; # set to true once creds are configured
    frequency = "*:0/10"; # every 10 minutes
  };
}

# Keyring and credential management
_: {
  # Provide Secret Service (used by Slack, etc.)
  services.gnome.gnome-keyring.enable = true;

  # Ensure the keyring is unlocked on login via PAM (SDDM)
  security.pam.services.sddm.enableGnomeKeyring = true;
  # Also enable for TTY logins, just in case
  security.pam.services.login.enableGnomeKeyring = true;
  # Unlock on screen unlock
  security.pam.services.swaylock.enableGnomeKeyring = true;
  security.pam.services = {
    login.enableGnomeKeyring = true;
    sddm.enableGnomeKeyring = true;
    "sddm-autologin".enableGnomeKeyring = true;
  };
}

{ ... }:
{
  flake.modules.nixos.servicesKeyring =
    { ... }:
    {
      # Keyring and credential management

      # Provide Secret Service (used by Slack, etc.)
      services.gnome.gnome-keyring.enable = true;

      security.pam.services = {
        # Unlock keyring on graphical login
        sddm.enableGnomeKeyring = true;
        "sddm-autologin".enableGnomeKeyring = true;
        # Ensure TTY logins unlock as well
        login.enableGnomeKeyring = true;
        # Unlock on screen unlock via swaylock
        swaylock.enableGnomeKeyring = true;
      };
    };
}

# GNOME Keyring integration for user sessions
_: {
  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" ];
  };
}

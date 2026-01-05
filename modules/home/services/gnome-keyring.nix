{ ... }:
{
  flake.modules.homeManager.servicesGnomeKeyring =
    { ... }:
    {
      # GNOME Keyring integration for user sessions
      services.gnome-keyring = {
        enable = true;
        components = [ "secrets" ];
      };
    };
}

{ ... }:
{
  flake.modules.homeManager."services.gnome-keyring" =
    { ... }:
    {
      # GNOME Keyring integration for user sessions
      services.gnome-keyring = {
        enable = true;
        components = [ "secrets" ];
      };
    };
}

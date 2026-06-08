{ ... }:
{
  flake.modules.nixos."core.dbus" =
    { ... }:
    {
      # NixOS 26.05 defaults to dbus-broker, but live activation from an
      # existing dbus-daemon session can time out when reloading D-Bus.
      services.dbus.implementation = "dbus";
    };
}

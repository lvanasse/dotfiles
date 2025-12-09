# Mako notifications
{
  pkgs,
  lib,
  config,
  ...
}:
let
  palette = config.theme.palette;
  # Ensure fully opaque colors (some consumers expect explicit alpha)
  opa = c: "${c}ff";
in
{
  # Keep Home Manager's built-in mako disabled; we provide our own unit
  services.mako.enable = lib.mkForce false;

  systemd.user.services.mako = let
    grep = "${pkgs.gnugrep}/bin/grep";
  in {
    Unit = {
      Description = "Mako notification daemon (Wayland)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      # Start only in non-KDE Wayland sessions and if no other notifier owns the DBus name
      ExecCondition = "${pkgs.bash}/bin/bash -lc 'test -n \"$WAYLAND_DISPLAY\" || exit 1; if printf \"%s\" \"$XDG_CURRENT_DESKTOP\" | ${grep} -qi \"kde\\|plasma\"; then exit 1; fi; ! ${pkgs.systemd}/bin/busctl --user list | ${grep} -q org.freedesktop.Notifications'";
      ExecStart = "${pkgs.mako}/bin/mako";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
  home.file.".config/mako/config".text = ''
    font=Inter 11
    width=320
    height=160
    margin=8
    padding=8
    border-size=4
    border-radius=0
    default-timeout=5000
    # Force a high-contrast look to validate config is applied
    background-color=#FFFFFFFF
    text-color=#000000FF
    border-color=#FF0000FF
    progress-color=over ${opa palette.blue}
    anchor=top-right
    layer=top
  '';
}

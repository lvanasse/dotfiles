# Mako notifications
{ pkgs, lib, config, ... }:
let
  palette = config.theme.palette;
  opa = c: "${c}cc"; # add alpha for translucency
in
{
  # Run mako only in Sway to avoid conflicts with KDE
  services.mako.enable = lib.mkForce false;

  systemd.user.services.mako = {
    Unit = {
      Description = "Mako notification daemon (Wayland)";
      PartOf = [ "sway-session.target" ];
      After = [ "sway-session.target" ];
    };
    Service = {
      ExecCondition = "${pkgs.bash}/bin/bash -lc 'test -n \"$WAYLAND_DISPLAY\" -a -n \"$SWAYSOCK\" && ! ${pkgs.systemd}/bin/busctl --user list | grep -q org.freedesktop.Notifications'";
      ExecStart = "${pkgs.mako}/bin/mako";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "sway-session.target" ];
    };
  };
  home.file.".config/mako/config".text = ''
    font=Inter 11
    width=320
    height=160
    margin=8
    padding=8
    border-size=2
    border-radius=6
    default-timeout=5000
    background-color=${opa palette.dark0_hard}
    text-color=${palette.light1}
    border-color=${palette.dark1}
    progress-color=over ${palette.blue}
    anchor=top-right
    layer=overlay
  '';
}

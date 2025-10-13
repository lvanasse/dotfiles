# Mako notifications
{ pkgs, lib, ... }:
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
      ExecCondition = "${pkgs.bash}/bin/bash -lc '! ${pkgs.systemd}/bin/busctl --user list | grep -q org.freedesktop.Notifications'";
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
    background-color=#1d2021cc
    text-color=#ebdbb2
    border-color=#3c3836
    progress-color=over #458588
    anchor=top-right
    layer=overlay
  '';
}

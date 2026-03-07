{ ... }:
{
  flake.modules.homeManager."programs.mako" =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      palette = config.theme.palette;
      # Tie the service lifecycle to Sway only so KDE/Plasma sessions keep their notifier
      swayTarget = "sway-session.target";
      # Ensure fully opaque colors (some consumers expect explicit alpha)
      opa = c: "${c}ff";
      grep = "${pkgs.gnugrep}/bin/grep";
      conditionScript = pkgs.writeShellScript "mako-wayland-guard" ''
        set -euo pipefail
        test -n "''${WAYLAND_DISPLAY:-}" || exit 1
        session_env="''${XDG_SESSION_DESKTOP:-}''${XDG_CURRENT_DESKTOP:-}''${DESKTOP_SESSION:-}"
        echo "$session_env" | ${grep} -qi sway || exit 1
      '';
    in
    {
      # Keep Home Manager's built-in mako disabled; we provide our own unit
      services.mako.enable = lib.mkForce false;

      systemd.user.services.mako = {
        Unit = {
          Description = "Mako notification daemon (Wayland)";
          PartOf = [ swayTarget ];
          After = [ swayTarget ];
        };
        Service = {
          # Only activate on Sway sessions (not KDE)
          ExecCondition = conditionScript;
          ExecStart = "${pkgs.mako}/bin/mako";
          Restart = "on-failure";
        };
        Install = {
          WantedBy = [ swayTarget ];
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
        # Gruvbox Dark Hard
        background-color=${opa palette.dark0_hard}
        text-color=${opa palette.light1}
        border-color=${opa palette.dark2}
        progress-color=over ${opa palette.bright_orange}
        anchor=top-right
        layer=top
      '';
    };
}

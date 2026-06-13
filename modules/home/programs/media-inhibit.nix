{ ... }:
{
  flake.modules.homeManager."programs.media-inhibit" =
    { pkgs, ... }:
    let
      playerctl = "${pkgs.playerctl}/bin/playerctl";
      systemdInhibit = "${pkgs.systemd}/bin/systemd-inhibit";
      script = pkgs.writeShellScript "media-inhibit" ''
        # Hold a sleep inhibitor while any MPRIS player is actively playing.
        # Uses playerctl --follow to react to status changes without polling.
        INHIBIT_PID=""

        take_lock() {
          if [ -z "$INHIBIT_PID" ]; then
            ${systemdInhibit} --what=sleep --who="media-inhibit" \
              --why="Media is playing" --mode=block \
              sleep infinity &
            INHIBIT_PID=$!
          fi
        }

        release_lock() {
          if [ -n "$INHIBIT_PID" ]; then
            kill "$INHIBIT_PID" 2>/dev/null || true
            wait "$INHIBIT_PID" 2>/dev/null || true
            INHIBIT_PID=""
          fi
        }

        trap 'release_lock; exit 0' INT TERM

        # Seed: check if anything is already playing
        if ${playerctl} status 2>/dev/null | grep -q "Playing"; then
          take_lock
        fi

        # React to status changes from any player
        ${playerctl} --all-players --follow status 2>/dev/null | while read -r status; do
          case "$status" in
            Playing) take_lock ;;
            *)
              # Only release if NO player is playing
              if ! ${playerctl} status 2>/dev/null | grep -q "Playing"; then
                release_lock
              fi
              ;;
          esac
        done
      '';
    in
    {
      systemd.user.services.media-inhibit = {
        Unit = {
          Description = "Inhibit sleep while media is playing";
          After = [ "sway-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${script}";
          Restart = "on-failure";
          RestartSec = 5;
        };
        Install.WantedBy = [ "sway-session.target" ];
      };
    };
}

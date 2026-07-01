{ ... }:
{
  flake.modules.nixos."services.annotationsync" =
    { pkgs, ... }:
    let
      appDataRoot = "/mnt/ssd/appdata/docker/annotationsync";
      annotationsRoot = "/mnt/storage/data/books/annotationsync";
      credentialsPath = "${appDataRoot}/webdav.env";
      listenAddress = "0.0.0.0:8085";
      startScript = pkgs.writeShellScript "annotationsync-webdav-start" ''
                set -euo pipefail

                mkdir -p "${appDataRoot}" "${annotationsRoot}"

                if [ ! -s "${credentialsPath}" ]; then
                  generate_password() {
                    local password
                    while true; do
                      password="$(${pkgs.coreutils}/bin/head -c 48 /dev/urandom \
                        | ${pkgs.coreutils}/bin/base64 \
                        | ${pkgs.coreutils}/bin/tr -dc 'A-Za-z0-9' \
                        | ${pkgs.coreutils}/bin/head -c 24)"
                      if [ "''${#password}" -ge 24 ]; then
                        printf '%s' "$password"
                        return 0
                      fi
                    done
                  }

                  umask 077
                  cat > "${credentialsPath}" <<EOF
        ANNOTATIONSYNC_WEBDAV_USER=annotationsync
        ANNOTATIONSYNC_WEBDAV_PASS=$(generate_password)
        EOF
                fi

                set -a
                . "${credentialsPath}"
                set +a

                export RCLONE_CONFIG=/dev/null

                exec ${pkgs.rclone}/bin/rclone serve webdav "${annotationsRoot}" \
                  --addr "${listenAddress}" \
                  --user "$ANNOTATIONSYNC_WEBDAV_USER" \
                  --pass "$ANNOTATIONSYNC_WEBDAV_PASS"
      '';
    in
    {
      systemd.tmpfiles.rules = [
        "d ${appDataRoot} 0755 root root -"
        "d ${annotationsRoot} 0775 99 100 -"
        "Z ${annotationsRoot} - 99 100 -"
      ];

      systemd.services.annotationsync-webdav = {
        description = "AnnotationSync WebDAV endpoint";
        wantedBy = [ "multi-user.target" ];
        requires = [
          "mnt-ssd.mount"
          "mnt-storage.mount"
        ];
        after = [
          "mnt-ssd.mount"
          "mnt-storage.mount"
          "network.target"
        ];
        path = with pkgs; [
          bash
          coreutils
          rclone
        ];
        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = "5s";
          ExecStart = startScript;
        };
      };

      # LAN clients should see `401 Unauthorized` from `http://<server>:8085/`
      # before auth. If localhost works but LAN clients time out, the server
      # likely has not been switched to a generation that includes this port.
      networking.firewall.allowedTCPPorts = [ 8085 ];
    };
}

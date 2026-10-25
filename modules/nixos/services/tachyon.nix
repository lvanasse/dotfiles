{ ... }:
{
  flake.modules.nixos."services.tachyon" =
    { config, pkgs, ... }:
    let
      appDataRoot = "/mnt/ssd/appdata/docker/tachyon";
      # Official v4.4.2 linux/amd64 manifest. Review and bump deliberately.
      image = "ghcr.io/kimusan/tachyon:v4.4.2@sha256:513d9a123ba714517610fec049cc1b5a69cb2d1b3ca99740f01e6d02cdb5758b";
    in
    {
      assertions = [
        {
          assertion = config.virtualisation.docker.enable;
          message = "Tachyon requires the server Docker service.";
        }
      ];

      systemd.tmpfiles.rules = [
        "d ${appDataRoot} 0700 82 82 -"
      ];

      virtualisation.oci-containers.containers.tachyon = {
        inherit image;
        volumes = [
          "${appDataRoot}:/var/lib/tachyon"
          "${./tachyon/gruvbox-dark-hard.css}:/tachyon/themes/GruvboxDarkHardToolbarV3/styles.css:ro"
        ];
        # cloudflared runs on the default Docker bridge and reaches the host
        # through docker0. Do not publish Tachyon on a LAN-facing address.
        ports = [ "172.17.0.1:8877:8888" ];
        environment = {
          SECURE_COOKIES = "true";
          UPLOAD_MAX_SIZE = "25M";
          MEMORY_LIMIT = "128M";
        };
        extraOptions = [
          "--cap-drop=ALL"
          "--cap-add=CHOWN"
          "--cap-add=DAC_OVERRIDE"
          "--cap-add=FOWNER"
          "--cap-add=SETUID"
          "--cap-add=SETGID"
          "--security-opt=no-new-privileges:true"
          "--pids-limit=256"
        ];
      };

      systemd.services.docker-tachyon = {
        requires = [ "mnt-ssd.mount" ];
        after = [ "mnt-ssd.mount" ];
        preStart = ''
          install -d -m 0700 ${appDataRoot}/_data_/_default_/plugins/tachyon-local
          install -m 0640 ${./tachyon/plugin/index.php} ${appDataRoot}/_data_/_default_/plugins/tachyon-local/index.php
          install -m 0640 ${./tachyon/plugin/tachyon-local.js} ${appDataRoot}/_data_/_default_/plugins/tachyon-local/tachyon-local.js
          chown -R 82:82 ${appDataRoot}/_data_/_default_/plugins/tachyon-local
        '';
      };

      # These are documented Tachyon application.ini settings. Its image
      # creates the file on first start and does not support a read-only config
      # mount, so apply only these four non-secret values after it is ready.
      systemd.services.tachyon-configure = {
        description = "Enable Tachyon CalDAV and CardDAV";
        wantedBy = [ "multi-user.target" ];
        requires = [ "docker-tachyon.service" ];
        after = [ "docker-tachyon.service" ];
        serviceConfig.Type = "oneshot";
        serviceConfig.Environment = [
          "TACHYON_APPDATA=${appDataRoot}"
          "TACHYON_THEME=${./tachyon/gruvbox-dark-hard.css}"
          "TACHYON_PLUGIN_JS=${./tachyon/plugin/tachyon-local.js}"
          "TACHYON_PLUGIN_PHP=${./tachyon/plugin/index.php}"
          "TACHYON_LOGO=${./tachyon/tachyon-logo.svg}"
          "TACHYON_FAVICON=${./tachyon/tachyon-favicon.svg}"
        ];
        script = "${pkgs.python3}/bin/python3 ${./tachyon/configure.py}";
      };
    };
}

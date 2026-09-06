{ inputs, ... }:
let
  standardnotesEnvAge = "${inputs.secrets}/server/standardnotes.env.age";
in
{
  flake.modules.nixos."services.standardnotes" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hasStandardnotesEnv = builtins.pathExists standardnotesEnvAge;
      appDataRoot = "/mnt/ssd/appdata/docker/standardnotes";
      bootstrapScript = pkgs.writeTextFile {
        name = "standardnotes-localstack-bootstrap.sh";
        executable = true;
        text = ''
          #!/usr/bin/env bash
          set -euo pipefail

          aws_region=us-east-1
          account_id=000000000000

          create_topic() {
            awslocal sns create-topic --name "$1" >/dev/null
          }

          create_queue() {
            awslocal sqs create-queue --queue-name "$1" >/dev/null
          }

          subscribe() {
            awslocal sns subscribe \
              --topic-arn "arn:aws:sns:''${aws_region}:''${account_id}:$1" \
              --protocol sqs \
              --notification-endpoint "arn:aws:sqs:''${aws_region}:''${account_id}:$2" >/dev/null
          }

          for topic in payments-local-topic syncing-server-local-topic auth-local-topic files-local-topic analytics-local-topic revisions-server-local-topic; do
            create_topic "$topic"
          done

          for queue in analytics-local-queue auth-local-queue files-local-queue syncing-server-local-queue revisions-server-local-queue scheduler-local-queue; do
            create_queue "$queue"
          done

          subscribe payments-local-topic analytics-local-queue
          subscribe payments-local-topic auth-local-queue
          subscribe auth-local-topic auth-local-queue
          subscribe files-local-topic auth-local-queue
          subscribe revisions-server-local-topic auth-local-queue
          subscribe auth-local-topic files-local-queue
          subscribe syncing-server-local-topic files-local-queue
          subscribe syncing-server-local-topic syncing-server-local-queue
          subscribe files-local-topic syncing-server-local-queue
          subscribe syncing-server-local-topic auth-local-queue
          subscribe auth-local-topic syncing-server-local-queue
          subscribe syncing-server-local-topic revisions-server-local-queue
          subscribe revisions-server-local-topic revisions-server-local-queue
        '';
      };
      indentEditorZip = pkgs.fetchurl {
        url = "https://github.com/MaxLap/standard-notes-indent-editor/archive/refs/tags/1.6.0.zip";
        hash = "sha256-4W2+Gmj0jSsec9VBq3/6LTuMaVIH9RyzIpWUvn5XVLA=";
      };
      indentEditorManifest = pkgs.writeText "indent-editor.json" (
        builtins.toJSON {
          identifier = "dev.maxlap.indent_editor";
          name = "Indent Editor";
          content_type = "SN|Component";
          area = "editor-editor";
          version = "1.6.0";
          description = "A plain text editor with improved usability and readability";
          url = "https://notes.ludovicvanasse.com/local-plugins/indent-editor/index.html";
          download_url = "https://notes.ludovicvanasse.com/local-plugins/indent-editor.zip";
          latest_url = "https://notes.ludovicvanasse.com/local-plugins/indent-editor.json";
          marketing_url = "https://github.com/MaxLap/standard-notes-indent-editor";
        }
      );
      indentEditorWebRoot =
        pkgs.runCommand "standardnotes-indent-editor"
          {
            nativeBuildInputs = [ pkgs.unzip ];
          }
          ''
            mkdir -p "$out/indent-editor"
            unzip -q ${indentEditorZip} -d unpacked
            cp -R unpacked/standard-notes-indent-editor-1.6.0/. "$out/indent-editor/"
            install -m 0444 ${indentEditorManifest} "$out/indent-editor.json"
            install -m 0444 ${indentEditorZip} "$out/indent-editor.zip"
          '';
      standardnotesWebNginxConfig = pkgs.writeText "standardnotes-web-nginx.conf" ''
        server {
          listen 80;
          listen [::]:80;
          server_name _;

          root /usr/share/nginx/html;
          index index.html;

          location / {
            try_files $uri $uri/ /index.html;
          }

          # The legacy plugin loader fetches manifests in the browser and can
          # reject otherwise valid responses from the GitHub Pages CDN. Keep
          # the entire community plugin flow on the app's own origin instead.
          # The fixed upstream makes this a plugin mirror, not an open proxy.
          location ^~ /community-plugins/ {
            proxy_ssl_server_name on;
            proxy_set_header Host standardnotes.github.io;
            proxy_set_header Accept-Encoding "";
            proxy_pass https://standardnotes.github.io/plugins/cdn/dist/;
            proxy_redirect off;

            sub_filter_once off;
            sub_filter_types application/json application/javascript text/css;
            sub_filter "https://standardnotes.github.io/plugins/cdn/dist/" "https://notes.ludovicvanasse.com/community-plugins/";
          }
        }
      '';
    in
    {
      assertions = [
        {
          assertion = hasStandardnotesEnv;
          message = "Standard Notes requires ${standardnotesEnvAge}.";
        }
      ];

      age.secrets = {
        "standardnotes-env" = {
          file = standardnotesEnvAge;
          path = "/run/agenix/standardnotes-env";
          owner = "root";
          group = "root";
          mode = "0400";
        };
      };

      systemd.tmpfiles.rules = [
        "d ${appDataRoot} 0755 root root -"
        "d ${appDataRoot}/logs 0755 root root -"
        "d ${appDataRoot}/uploads 0755 root root -"
        "d ${appDataRoot}/mysql 0755 root root -"
        "d ${appDataRoot}/redis 0755 root root -"
      ];

      virtualisation.oci-containers.containers = {
        standardnotes-localstack = {
          image = "localstack/localstack:3.0";
          environment = {
            SERVICES = "sns,sqs";
            HOSTNAME_EXTERNAL = "localstack";
            LS_LOG = "warn";
          };
          volumes = [
            "${bootstrapScript}:/etc/localstack/init/ready.d/localstack_bootstrap.sh:ro"
          ];
          extraOptions = [
            "--network=standardnotes"
            "--network-alias=localstack"
          ];
        };

        standardnotes-db = {
          image = "mysql:8";
          environment = {
            MYSQL_DATABASE = "standard_notes_db";
            MYSQL_USER = "std_notes_user";
          };
          environmentFiles = [ config.age.secrets."standardnotes-env".path ];
          volumes = [ "${appDataRoot}/mysql:/var/lib/mysql" ];
          extraOptions = [
            "--network=standardnotes"
            "--network-alias=db"
          ];
        };

        standardnotes-cache = {
          image = "redis:6.0-alpine";
          volumes = [ "${appDataRoot}/redis:/data" ];
          extraOptions = [
            "--network=standardnotes"
            "--network-alias=cache"
          ];
        };

        standardnotes-server = {
          image = "standardnotes/server";
          dependsOn = [
            "standardnotes-localstack"
            "standardnotes-db"
            "standardnotes-cache"
          ];
          environment = {
            DB_HOST = "db";
            DB_PORT = "3306";
            DB_USERNAME = "std_notes_user";
            DB_DATABASE = "standard_notes_db";
            DB_TYPE = "mysql";
            REDIS_HOST = "cache";
            REDIS_PORT = "6379";
            CACHE_TYPE = "redis";
            FILES_SERVER_URL = "https://sync.ludovicvanasse.com";
            # The server defaults this to standardnotes.com. Browsers reject
            # those session cookies when they are served from our sync host.
            COOKIE_DOMAIN = "ludovicvanasse.com";
            # This is a private instance: only the existing account may sign
            # in, and the public endpoint must not accept new registrations.
            DISABLE_USER_REGISTRATION = "true";
          };
          environmentFiles = [ config.age.secrets."standardnotes-env".path ];
          volumes = [
            "${appDataRoot}/logs:/var/lib/server/logs"
            "${appDataRoot}/uploads:/opt/server/packages/files/dist/uploads"
          ];
          ports = [ "3030:3000" ];
          extraOptions = [ "--network=standardnotes" ];
        };

        standardnotes-web = {
          image = "standardnotes/web";
          environment.DEFAULT_SYNC_SERVER = "https://sync.ludovicvanasse.com";
          volumes = [
            "${standardnotesWebNginxConfig}:/etc/nginx/conf.d/default.conf:ro"
            "${indentEditorWebRoot}:/usr/share/nginx/html/local-plugins:ro"
          ];
          # This image is static: unlike the source build, it does not consume
          # DEFAULT_SYNC_SERVER at runtime. Patch its baked-in default before
          # starting nginx so the login/register screen uses our sync server.
          cmd = [
            "/bin/sh"
            "-ec"
            "sed -i 's|https://api.standardnotes.com|https://sync.ludovicvanasse.com|' /usr/share/nginx/html/index.html; exec nginx -g 'daemon off;'"
          ];
          ports = [ "3031:80" ];
        };
      };

      systemd.services =
        let
          dependencies = [
            "docker-network-standardnotes.service"
            "mnt-ssd.mount"
          ];
        in
        {
          docker-network-standardnotes = {
            description = "Create Docker network for Standard Notes";
            wantedBy = [ "docker.service" ];
            after = [ "docker.service" ];
            requires = [ "docker.service" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = ''
              if ! ${pkgs.docker_29}/bin/docker network inspect standardnotes >/dev/null 2>&1; then
                ${pkgs.docker_29}/bin/docker network create standardnotes >/dev/null
              fi
            '';
          };
          docker-standardnotes-localstack = {
            requires = dependencies;
            after = dependencies;
          };
          docker-standardnotes-db = {
            requires = dependencies;
            after = dependencies;
          };
          docker-standardnotes-cache = {
            requires = dependencies;
            after = dependencies;
          };
          docker-standardnotes-server = {
            requires = dependencies;
            after = dependencies;
          };
          docker-standardnotes-web = {
            requires = [ "mnt-ssd.mount" ];
            after = [ "mnt-ssd.mount" ];
          };
        };

      networking.firewall.allowedTCPPorts = [
        3030
        3031
      ];
    };
}

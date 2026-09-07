{ inputs, ... }:
let
  planeEnvAge = "${inputs.secrets}/server/plane.env.age";
in
{
  flake.modules.nixos."services.plane" =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      appDataRoot = "/mnt/ssd/appdata/docker/plane-commercial";
      compose = "${pkgs.docker-compose}/bin/docker-compose";
      planeCompose = pkgs.fetchurl {
        url = "https://prime.plane.so/releases/v1.16.0/docker-compose.yml";
        hash = "sha256-HumT/D3UM49Emko8QcDT/HZHUHdsmUjAfUCjCNio/d8=";
      };
      planePublicEnv = pkgs.writeText "plane-commercial.env" ''
        INSTALL_DIR=${appDataRoot}
        DOMAIN_NAME=plane.ludovicvanasse.com
        APP_RELEASE_VERSION=v1.16.0

        WEB_REPLICAS=1
        SPACE_REPLICAS=1
        ADMIN_REPLICAS=1
        API_REPLICAS=1
        WORKER_REPLICAS=1
        BEAT_WORKER_REPLICAS=1
        LIVE_REPLICAS=1
        SILO_REPLICAS=1
        EMAIL_REPLICAS=1
        OUTBOX_POLLER_REPLICAS=1
        AUTOMATION_CONSUMER_REPLICAS=1
        IFRAMELY_REPLICAS=1

        LISTEN_HTTP_PORT=3032
        LISTEN_HTTPS_PORT=3033
        # TLS terminates at the external reverse proxy; avoid an origin redirect loop.
        APP_PROTOCOL=http
        TRUSTED_PROXIES=0.0.0.0/0
        API_HOSTNAME=http://api:8000
        SITE_ADDRESS=:80
        CERT_EMAIL=
        CERT_ACME_CA=https://acme-v02.api.letsencrypt.org/directory
        CERT_ACME_DNS=

        WEB_URL=https://plane.ludovicvanasse.com
        DEBUG=0
        CORS_ALLOWED_ORIGINS=https://plane.ludovicvanasse.com
        API_BASE_URL=http://api:8000

        PGHOST=plane-db
        PGDATABASE=plane
        POSTGRES_USER=plane
        POSTGRES_DB=plane
        PGDATA=/var/lib/postgresql/data

        REDIS_HOST=plane-redis
        REDIS_PORT=6379

        RABBITMQ_HOST=plane-mq
        RABBITMQ_PORT=5672
        RABBITMQ_USER=plane
        RABBITMQ_VHOST=plane
        AMQP_URL=amqp://plane:plane@plane-mq:5672/plane

        USE_MINIO=1
        AWS_REGION=
        AWS_S3_ENDPOINT_URL=http://plane-minio:9000
        AWS_S3_BUCKET_NAME=uploads
        BUCKET_NAME=uploads
        FILE_SIZE_LIMIT=20971520
        MINIO_ENDPOINT_SSL=0

        GUNICORN_WORKERS=2
        API_KEY_RATE_LIMIT=60/minute
        SSL_VERIFY=1
        FEATURE_FLAG_SERVER_BASE_URL=http://monitor:8080
        PAYMENT_SERVER_BASE_URL=http://monitor:8080
        INTEGRATION_CALLBACK_BASE_URL=https://plane.ludovicvanasse.com
        IFRAMELY_URL=http://iframely:8061
        INTAKE_EMAIL_DOMAIN=example.com
        LISTEN_SMTP_PORT_25=10025
        LISTEN_SMTP_PORT_465=10465
        LISTEN_SMTP_PORT_587=10587
        SMTP_DOMAIN=0.0.0.0
        TLS_CERT_PATH=
        TLS_PRIV_KEY_PATH=
        USE_STORAGE_PROXY=0
      '';
      planeComposeOverride = pkgs.writeText "plane-commercial-compose.override.yml" ''
        services:
          monitor:
            volumes:
              - ${appDataRoot}/data/monitor:/app
          api:
            volumes:
              - ${appDataRoot}/logs/api:/code/plane/logs
          worker:
            volumes:
              - ${appDataRoot}/logs/worker:/code/plane/logs
          beat-worker:
            volumes:
              - ${appDataRoot}/logs/beat-worker:/code/plane/logs
          migrator:
            volumes:
              - ${appDataRoot}/logs/migrator:/code/plane/logs
          plane-db:
            volumes:
              - ${appDataRoot}/data/db:/var/lib/postgresql/data
          plane-redis:
            volumes:
              - ${appDataRoot}/data/redis:/data
          plane-mq:
            volumes:
              - ${appDataRoot}/data/mq:/var/lib/rabbitmq
          plane-minio:
            volumes:
              - ${appDataRoot}/data/minio/uploads:/export
              - ${appDataRoot}/data/minio/data:/data
          email:
            volumes:
              - ${appDataRoot}/data/email/tls:/opt/email/tls
          proxy:
            volumes:
              - ${appDataRoot}/caddy/config:/config
              - ${appDataRoot}/caddy/data:/data
      '';
      composeArgs = [
        "--project-name"
        "plane"
        "--env-file"
        planePublicEnv
        "--env-file"
        config.age.secrets."plane-env".path
        "--file"
        planeCompose
        "--file"
        planeComposeOverride
      ];
      composeCommand = lib.escapeShellArgs ([ compose ] ++ composeArgs);
    in
    {
      assertions = [
        {
          assertion = builtins.pathExists planeEnvAge;
          message = "Plane requires ${planeEnvAge}.";
        }
      ];

      age.secrets."plane-env" = {
        file = planeEnvAge;
        path = "/run/agenix/plane-env";
        owner = "root";
        group = "root";
        mode = "0400";
      };

      systemd.tmpfiles.rules = [
        "d ${appDataRoot} 0755 root root -"
        "d ${appDataRoot}/logs 0755 root root -"
        "d ${appDataRoot}/logs/api 0755 root root -"
        "d ${appDataRoot}/logs/worker 0755 root root -"
        "d ${appDataRoot}/logs/beat-worker 0755 root root -"
        "d ${appDataRoot}/logs/migrator 0755 root root -"
        "d ${appDataRoot}/data 0755 root root -"
        "d ${appDataRoot}/data/db 0755 root root -"
        "d ${appDataRoot}/data/redis 0755 999 1000 -"
        "d ${appDataRoot}/data/mq 0755 root root -"
        "d ${appDataRoot}/data/minio 0755 root root -"
        "d ${appDataRoot}/data/minio/uploads 0755 root root -"
        "d ${appDataRoot}/data/minio/data 0755 root root -"
        "d ${appDataRoot}/data/monitor 0755 root root -"
        "d ${appDataRoot}/data/email 0755 root root -"
        "d ${appDataRoot}/data/email/tls 0755 root root -"
        "d ${appDataRoot}/caddy 0755 root root -"
        "d ${appDataRoot}/caddy/config 0755 root root -"
        "d ${appDataRoot}/caddy/data 0755 root root -"
      ];

      systemd.services.plane = {
        description = "Plane Commercial Edition";
        restartTriggers = [ planeEnvAge ];
        wantedBy = [ "multi-user.target" ];
        requires = [
          "docker.service"
          "mnt-ssd.mount"
        ];
        after = [
          "docker.service"
          "mnt-ssd.mount"
          "agenix.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStartPre = "${composeCommand} config --quiet";
          ExecStart = "${composeCommand} up --detach --remove-orphans";
          ExecStop = "${composeCommand} stop";
          TimeoutStartSec = 900;
          TimeoutStopSec = 300;
        };
      };

      networking.firewall.allowedTCPPorts = [ 3032 ];
    };
}

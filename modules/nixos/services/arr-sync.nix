{ config, inputs, lib, pkgs, ... }:
let
  arrSecretsAge = "${inputs.secrets}/server/arr-secrets.yml.age";
  arrSecretsPlainRepo = "${inputs.secrets}/server/arr-secrets.yml";
  arrSecretsPlainOverride = ../../../overrides/arr-secrets.yml;
  hasAgeSecrets = builtins.pathExists arrSecretsAge;
  hasPlainSecretsRepo = builtins.pathExists arrSecretsPlainRepo;
  hasPlainSecretsOverride = builtins.pathExists arrSecretsPlainOverride;
  hasPlainSecrets = hasPlainSecretsRepo || hasPlainSecretsOverride;
  hasArrSecrets = hasAgeSecrets || hasPlainSecrets;

  recyclarrConfig = ''
    sonarr:
      tv:
        base_url: !secret SONARR_URL
        api_key: !secret SONARR_API_KEY
        quality_profiles:
          - name: WEB-1080p
            upgrade:
              allowed: true
              until_quality: WEB 1080p
            qualities:
              - name: WEB 1080p
                qualities:
                  - WEBDL-1080p
                  - WEBRip-1080p
          - name: WEB-720p
            upgrade:
              allowed: true
              until_quality: WEB 720p
            qualities:
              - name: WEB 720p
                qualities:
                  - WEBDL-720p
                  - WEBRip-720p
          - name: WEB-480p
            upgrade:
              allowed: true
              until_quality: WEB 480p
            qualities:
              - name: WEB 480p
                qualities:
                  - WEBDL-480p
                  - WEBRip-480p
          - trash_id: 58e8dc75731040612dd6f4ac0676bfd7
            name: French MULTi.VF HD Bluray + WEB (1080p)
          - trash_id: 68c8b82ad2b7ea1941fce71eb56421c3
            name: French MULTi.VF UHD Bluray + WEB (2160p)
          - trash_id: 4c48f506c1116a3a57ae33f12346bd15
            name: French MULTi.VO HD Bluray + WEB (1080p)
          - trash_id: 6fa7364373e8f06206871d9c20a4fb3e
            name: French MULTi.VO UHD Bluray + WEB (2160p)
          - trash_id: b34c968f58433a38e0e690d42a1dc37e
            name: French VOSTFR HD Bluray + WEB (1080p)
          - trash_id: d6252dce6af535107ed4b03e68052ae8
            name: French VOSTFR UHD Bluray + WEB (2160p)

    radarr:
      movies:
        base_url: !secret RADARR_URL
        api_key: !secret RADARR_API_KEY
        quality_profiles:
          - name: WEB-1080p
            upgrade:
              allowed: true
              until_quality: WEB 1080p
            qualities:
              - name: WEB 1080p
                qualities:
                  - WEBDL-1080p
                  - WEBRip-1080p
          - name: WEB-720p
            upgrade:
              allowed: true
              until_quality: WEB 720p
            qualities:
              - name: WEB 720p
                qualities:
                  - WEBDL-720p
                  - WEBRip-720p
          - name: WEB-480p
            upgrade:
              allowed: true
              until_quality: WEB 480p
            qualities:
              - name: WEB 480p
                qualities:
                  - WEBDL-480p
                  - WEBRip-480p
          - trash_id: 500ecc23572575511fd81893777d1e06
            name: French MULTi.VF HD Bluray + WEB
          - trash_id: 6b93fe45f357e9a94228e5d4658e9bb5
            name: French MULTi.VF HD Remux (1080p)
          - trash_id: e64b266178c7f70e208f493f00e0e50a
            name: French MULTi.VF UHD Bluray + WEB
          - trash_id: 595bb95c6b6970468880069dce23e1d2
            name: French MULTi.VF UHD Remux (2160p)
          - trash_id: 2572ce3ea4eef1c19d59e0e20ed1cea7
            name: French MULTi.VO HD Bluray + WEB
          - trash_id: c6460a102b312200c095a2d0982e0461
            name: French MULTi.VO HD Remux (1080p)
          - trash_id: 92ead7022d13a7858d54e328e6a2f8f9
            name: French MULTi.VO UHD Bluray + WEB
          - trash_id: 1fef28c8c919f31cd86283b1baf527d4
            name: French MULTi.VO UHD Remux (2160p)
          - trash_id: 1addc08c4232bc2617684d517df15f75
            name: French VOSTFR HD Bluray + WEB
          - trash_id: d98f20924b001e9f6b9595d5440abc87
            name: French VOSTFR HD Remux (1080p)
          - trash_id: 525bf0513e2ac22fe116e8d7bec0a6b5
            name: French VOSTFR UHD Bluray + WEB
          - trash_id: 9b32fc61d8ec83ed131f50f1db80505a
            name: French VOSTFR UHD Remux (2160p)
  '';

  configarrConfig = ''
    sonarr:
      main:
        base_url: !secret SONARR_URL
        api_key: !secret SONARR_API_KEY
        root_folders:
          - /data/media/tv
        download_clients:
          data:
            - name: qBittorrent
              type: qbittorrent
              enable: true
              priority: 1
              remove_completed_downloads: true
              remove_failed_downloads: true
              fields:
                host: 192.168.0.50
                port: 8081
                use_ssl: false
                url_base: /
                username: !secret QBITTORRENT_USER
                password: !secret QBITTORRENT_PASS
                tv_category: tv

    radarr:
      main:
        base_url: !secret RADARR_URL
        api_key: !secret RADARR_API_KEY
        root_folders:
          - /data/media/movies
        download_clients:
          data:
            - name: qBittorrent
              type: qbittorrent
              enable: true
              priority: 1
              remove_completed_downloads: true
              remove_failed_downloads: true
              fields:
                host: 192.168.0.50
                port: 8081
                use_ssl: false
                url_base: /
                username: !secret QBITTORRENT_USER
                password: !secret QBITTORRENT_PASS
                movie_category: movies

    lidarr:
      main:
        base_url: !secret LIDARR_URL
        api_key: !secret LIDARR_API_KEY
        root_folders:
          - name: Music
            path: /data/media/music
            metadata_profile: Standard
            quality_profile: Any
        download_clients:
          data:
            - name: qBittorrent
              type: qbittorrent
              enable: true
              priority: 1
              remove_completed_downloads: true
              remove_failed_downloads: true
              fields:
                host: 192.168.0.50
                port: 8081
                use_ssl: false
                url_base: /
                username: !secret QBITTORRENT_USER
                password: !secret QBITTORRENT_PASS
                music_category: music
  '';
in
{
  flake.modules.nixos."services.arr-sync" =
    { config, pkgs, ... }:
    let
      secretsPath =
        if hasAgeSecrets then
          config.age.secrets."arr-secrets".path
        else
          "/etc/arr-secrets.yml";
    in
    {
      system.activationScripts.arrSecretsPathCleanup.text = ''
        if [ -d /run/agenix/arr-secrets.yml ]; then
          rm -rf /run/agenix/arr-secrets.yml
        fi
      '';
      system.activationScripts.agenixInstall.deps = lib.mkAfter [ "arrSecretsPathCleanup" ];

      age.secrets = lib.mkIf hasAgeSecrets {
        "arr-secrets" = {
          file = arrSecretsAge;
          owner = "root";
          group = "root";
          mode = "0400";
        };
      };

      environment.etc."arr-secrets.yml" = lib.mkIf hasPlainSecrets {
        source =
          if hasPlainSecretsRepo then
            arrSecretsPlainRepo
          else
            arrSecretsPlainOverride;
        mode = "0400";
      };

      environment.etc."recyclarr/recyclarr.yml".text = recyclarrConfig;
      environment.etc."configarr/config.yml".text = configarrConfig;

      systemd.tmpfiles.rules = [
        "d /var/lib/recyclarr 0750 root root -"
        "d /var/lib/configarr 0750 root root -"
        "d /var/lib/configarr/config 0750 root root -"
        "d /var/lib/configarr/repos 0750 root root -"
        "d /var/lib/configarr/cfs 0750 root root -"
        "d /var/lib/configarr/templates 0750 root root -"
      ];

      systemd.services.recyclarr-sync = lib.mkIf hasArrSecrets {
        description = "Sync Arr settings with Recyclarr";
        after = [
          "docker.service"
        ];
        requires = [
          "docker.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''
            ${pkgs.docker}/bin/docker run --rm --name recyclarr-sync \
              --network=host \
              --user=0:0 \
              -v /var/lib/recyclarr:/config \
              -v /etc/recyclarr/recyclarr.yml:/config/recyclarr.yml:ro \
              -v ${secretsPath}:/config/secrets.yml:ro \
              ghcr.io/recyclarr/recyclarr sync
          '';
        };
      };

      systemd.timers.recyclarr-sync = lib.mkIf hasArrSecrets {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "Tue,Fri 02:00";
          Persistent = true;
        };
      };

      systemd.services.configarr-sync = lib.mkIf hasArrSecrets {
        description = "Sync Arr settings with Configarr";
        after = [
          "docker.service"
          "mnt-storage.mount"
        ];
        requires = [
          "docker.service"
          "mnt-storage.mount"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = ''
            ${pkgs.docker}/bin/docker run --rm --name configarr-sync \
              --network=host \
              -e TZ=America/Toronto \
              -v /var/lib/configarr/config:/app/config \
              -v /var/lib/configarr/repos:/app/repos \
              -v /var/lib/configarr/cfs:/app/cfs \
              -v /var/lib/configarr/templates:/app/templates \
              -v /etc/configarr/config.yml:/app/config/config.yml:ro \
              -v ${secretsPath}:/app/config/secrets.yml:ro \
              ghcr.io/raydak-labs/configarr:latest
          '';
        };
      };

      systemd.timers.configarr-sync = lib.mkIf hasArrSecrets {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "Tue,Fri 02:15";
          Persistent = true;
        };
      };
    };
}

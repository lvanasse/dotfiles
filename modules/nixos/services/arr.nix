{ inputs, lib, ... }:
let
  arrSecretsAge = "${inputs.secrets}/server/arr-secrets.yml.age";
  arrSecretsPlainRepo = "${inputs.secrets}/server/arr-secrets.yml";
  arrSecretsPlainOverride = ../../../overrides/arr-secrets.yml;
  storageBackedUnits = [
    "docker-sonarr"
    "docker-radarr"
    "docker-bazarr"
    "docker-lidarr"
    "docker-prowlarr"
    "docker-jellyseerr"
    "docker-qbittorrent"
    "docker-calibre"
  ];
  appDataRoots = {
    sonarr = "/mnt/data3/appdata/sonarr";
    radarr = "/mnt/data3/appdata/radarr";
    bazarr = "/mnt/data3/appdata/bazarr";
    lidarr = "/mnt/data3/appdata/lidarr";
    prowlarr = "/mnt/data3/appdata/prowlarr";
    jellyseerr = "/mnt/data3/appdata/jellyseerr";
    qbittorrent = "/mnt/storage/appdata/qbittorrent";
  };
in
{
  flake.modules.nixos."services.arr" =
    { config, pkgs, ... }:
    let
      hasAgeSecrets = builtins.pathExists arrSecretsAge;
      hasPlainSecretsRepo = builtins.pathExists arrSecretsPlainRepo;
      hasPlainSecretsOverride = builtins.pathExists arrSecretsPlainOverride;
      qBittorrentSecretsPath =
        if hasAgeSecrets then
          config.age.secrets."arr-secrets".path
        else if hasPlainSecretsOverride then
          toString arrSecretsPlainOverride
        else if hasPlainSecretsRepo then
          toString arrSecretsPlainRepo
        else
          "/etc/arr-secrets.yml";
      qBittorrentBooksCategoryPath = "/downloads/books";
      qBittorrentAudiobookCategoryPath = "/downloads/audiobook";
      qBittorrentConfigPath = "/mnt/storage/appdata/qbittorrent/qBittorrent/qBittorrent.conf";
      qBittorrentCategoriesPath = "/mnt/storage/appdata/qbittorrent/qBittorrent/categories.json";
      qBittorrentMamConfig = pkgs.writeText "qbittorrent-mam-config.py" ''
        import configparser
        import json
        import os
        import pathlib
        import sys

        config_path = pathlib.Path(sys.argv[1])
        categories_path = pathlib.Path(sys.argv[2])
        config_path.parent.mkdir(parents=True, exist_ok=True)
        categories_path.parent.mkdir(parents=True, exist_ok=True)

        config = configparser.ConfigParser(interpolation=None)
        config.optionxform = str

        if config_path.exists():
          with config_path.open(encoding="utf-8") as fh:
            config.read_file(fh)

        desired = {
          "BitTorrent": {
            r"Session\DHTEnabled": "false",
            r"Session\LSDEnabled": "false",
            r"Session\PeXEnabled": "false",
            r"Session\Port": "59793",
            r"Session\QueueingSystemEnabled": "false",
          },
          "AutoRun": {
            "enabled": "false",
            "program": "",
          },
          "Preferences": {
            r"Connection\PortRangeMin": "59793",
            r"Connection\UPnP": "false",
          },
        }

        changed = False
        for section, entries in desired.items():
          if not config.has_section(section):
            config.add_section(section)
            changed = True
          for key, value in entries.items():
            if config.get(section, key, fallback=None) != value:
              config.set(section, key, value)
              changed = True

        if changed:
          tmp_path = config_path.with_suffix(config_path.suffix + ".tmp")
          with tmp_path.open("w", encoding="utf-8") as fh:
            config.write(fh, space_around_delimiters=False)
          os.replace(tmp_path, config_path)

        categories = {}
        if categories_path.exists():
          with categories_path.open(encoding="utf-8") as fh:
            try:
              categories = json.load(fh)
            except json.JSONDecodeError:
              categories = {}

        if categories.get("books", {}).get("save_path") != "${qBittorrentBooksCategoryPath}":
          categories["books"] = {"save_path": "${qBittorrentBooksCategoryPath}"}
          changed = True

        if categories.get("audiobook", {}).get("save_path") != "${qBittorrentAudiobookCategoryPath}":
          categories["audiobook"] = {"save_path": "${qBittorrentAudiobookCategoryPath}"}
          changed = True

        for obsolete_category in ("cwa", "lazylibrarian"):
          if obsolete_category in categories:
            del categories[obsolete_category]
            changed = True

        if changed:
          tmp_path = categories_path.with_suffix(categories_path.suffix + ".tmp")
          with tmp_path.open("w", encoding="utf-8") as fh:
            json.dump(categories, fh, indent=4, sort_keys=True)
            fh.write("\n")
          os.replace(tmp_path, categories_path)
      '';
      qBittorrentAlwaysSeedSource = pkgs.writeText "qbittorrent-always-seed.rs" ''
        use std::env;
        use std::fs;
        use std::io;
        use std::path::{Path, PathBuf};
        use std::process::{Command, Output};
        use std::thread;
        use std::time::{Duration, SystemTime, UNIX_EPOCH};

        const CURL: &str = "${pkgs.curl}/bin/curl";
        const JQ: &str = "${pkgs.jq}/bin/jq";

        fn main() {
            if let Err(error) = real_main() {
                eprintln!("{error}");
                std::process::exit(1);
            }
        }

        fn real_main() -> Result<(), String> {
            let mut url = String::from("http://127.0.0.1:8081");
            let mut secrets = None;
            let mut retries: u32 = 12;
            let mut retry_delay = 5.0_f64;

            let mut args = env::args().skip(1);
            while let Some(arg) = args.next() {
                match arg.as_str() {
                    "--url" => url = args.next().ok_or_else(|| "missing value for --url".to_string())?,
                    "--secrets" => secrets = Some(args.next().ok_or_else(|| "missing value for --secrets".to_string())?),
                    "--retries" => {
                        retries = args
                            .next()
                            .ok_or_else(|| "missing value for --retries".to_string())?
                            .parse()
                            .map_err(|_| "invalid value for --retries".to_string())?
                    }
                    "--retry-delay" => {
                        retry_delay = args
                            .next()
                            .ok_or_else(|| "missing value for --retry-delay".to_string())?
                            .parse()
                            .map_err(|_| "invalid value for --retry-delay".to_string())?
                    }
                    other => return Err(format!("unknown argument: {other}")),
                }
            }

            let secrets = secrets.ok_or_else(|| "missing required --secrets".to_string())?;

            for attempt in 1..=retries {
                match reconcile(&url, Path::new(&secrets)) {
                    Ok(()) => return Ok(()),
                    Err(error) if attempt < retries => {
                        eprintln!("qBittorrent always-seed attempt {attempt}/{retries} failed: {error}");
                        thread::sleep(Duration::from_secs_f64(retry_delay));
                    }
                    Err(error) => return Err(error),
                }
            }

            Err("exhausted retries without a specific error".to_string())
        }

        fn reconcile(base_url: &str, secrets_path: &Path) -> Result<(), String> {
            let (username, password) = read_secrets(secrets_path)?;
            let cookie_path = make_cookie_path();
            let cookie_str = cookie_path.to_string_lossy().into_owned();
            let login_form = format!(
                "username={}&password={}",
                percent_encode(&username),
                percent_encode(&password)
            );
            let login = curl_post_form(base_url, "/api/v2/auth/login", &cookie_str, None, &login_form)?;
            let login_body = String::from_utf8_lossy(&login.stdout).trim().to_string();
            if login.status_code != 200 || login_body == "Fails." {
                cleanup_cookie(&cookie_path);
                return Err("qBittorrent login failed".to_string());
            }

            let torrents = curl_get(base_url, "/api/v2/torrents/info", &cookie_str)?;
            if torrents.status_code != 200 {
                cleanup_cookie(&cookie_path);
                return Err(format!(
                    "qBittorrent torrent list failed: HTTP {}",
                    torrents.status_code
                ));
            }

            let hashes = select_hashes(&torrents.stdout)?;
            if hashes.is_empty() {
                cleanup_cookie(&cookie_path);
                println!("no book or audiobook torrents matched");
                return Ok(());
            }

            let mut resumed = 0_u32;
            for hash in hashes {
                let limits_form = format!(
                    "hashes={}&ratioLimit=-1&seedingTimeLimit=-1&inactiveSeedingTimeLimit=-1",
                    percent_encode(&hash)
                );
                let limits = curl_post_form(
                    base_url,
                    "/api/v2/torrents/setShareLimits",
                    &cookie_str,
                    Some(&cookie_str),
                    &limits_form,
                )?;
                if limits.status_code != 200 {
                    cleanup_cookie(&cookie_path);
                    return Err(format!(
                        "setShareLimits failed for {}: HTTP {}",
                        hash, limits.status_code
                    ));
                }

                let resume_form = format!("hashes={}", percent_encode(&hash));
                let resume = curl_post_form(
                    base_url,
                    "/api/v2/torrents/resume",
                    &cookie_str,
                    Some(&cookie_str),
                    &resume_form,
                )?;

                match resume.status_code {
                    200 => resumed += 1,
                    404 => eprintln!("qBittorrent resume skipped missing torrent hash: {hash}"),
                    code => {
                        cleanup_cookie(&cookie_path);
                        return Err(format!("resume failed for {}: HTTP {}", hash, code));
                    }
                }
            }

            cleanup_cookie(&cookie_path);
            println!("set unlimited seeding for {} book/audiobook torrents", resumed);
            Ok(())
        }

        struct CurlResponse {
            status_code: u16,
            stdout: Vec<u8>,
        }

        fn curl_get(base_url: &str, endpoint: &str, cookie_jar: &str) -> Result<CurlResponse, String> {
            curl_request(
                base_url,
                endpoint,
                cookie_jar,
                Some(cookie_jar),
                None,
            )
        }

        fn curl_post_form(
            base_url: &str,
            endpoint: &str,
            cookie_jar: &str,
            cookie_read: Option<&str>,
            form: &str,
        ) -> Result<CurlResponse, String> {
            curl_request(base_url, endpoint, cookie_jar, cookie_read, Some(form))
        }

        fn curl_request(
            base_url: &str,
            endpoint: &str,
            cookie_jar: &str,
            cookie_read: Option<&str>,
            form: Option<&str>,
        ) -> Result<CurlResponse, String> {
            let mut cmd = Command::new(CURL);
            cmd.arg("-sS")
                .arg("-o")
                .arg("-")
                .arg("-w")
                .arg("\\n%{http_code}")
                .arg("-c")
                .arg(cookie_jar);

            if let Some(cookie_file) = cookie_read {
                cmd.arg("-b").arg(cookie_file);
            }

            if let Some(form_data) = form {
                cmd.arg("-X")
                    .arg("POST")
                    .arg("--header")
                    .arg("Content-Type: application/x-www-form-urlencoded")
                    .arg("--data-raw")
                    .arg(form_data);
            }

            cmd.arg(format!("{}{}", base_url.trim_end_matches('/'), endpoint));
            let output = run_command(cmd).map_err(|error| format!("curl failed: {error}"))?;
            parse_curl_response(output)
        }

        fn parse_curl_response(output: Output) -> Result<CurlResponse, String> {
            if !output.status.success() {
                return Err(String::from_utf8_lossy(&output.stderr).trim().to_string());
            }

            let mut stdout = output.stdout;
            while matches!(stdout.last(), Some(b'\n' | b'\r')) {
                stdout.pop();
            }

            let marker = stdout
                .iter()
                .rposition(|byte| *byte == b'\n')
                .ok_or_else(|| "curl did not return a status code marker".to_string())?;
            let status_code = String::from_utf8_lossy(&stdout[marker + 1..])
                .parse::<u16>()
                .map_err(|_| "failed to parse curl status code".to_string())?;
            stdout.truncate(marker);

            Ok(CurlResponse { status_code, stdout })
        }

        fn select_hashes(torrents_json: &[u8]) -> Result<Vec<String>, String> {
            let filter = r#"
              .[]
              | select(
                  ((.category // "" | ascii_downcase) as $category
                    | ($category == "books" or $category == "audiobook"))
                  or
                  (((.tags // "")
                    | if type == "array" then . else split(",") end
                    | map(ascii_downcase | gsub("^\\s+|\\s+$"; ""))
                    | any(. == "book" or . == "books" or . == "audiobook" or . == "audiobooks")))
                )
              | .hash
            "#;

            let mut jq = Command::new(JQ);
            jq.arg("-r").arg(filter);
            let output = run_command_with_stdin(jq, torrents_json)
                .map_err(|error| format!("jq failed: {error}"))?;
            if !output.status.success() {
                return Err(String::from_utf8_lossy(&output.stderr).trim().to_string());
            }

            Ok(String::from_utf8_lossy(&output.stdout)
                .lines()
                .map(str::trim)
                .filter(|line| !line.is_empty() && *line != "null")
                .map(ToOwned::to_owned)
                .collect())
        }

        fn read_secrets(path: &Path) -> Result<(String, String), String> {
            let text = fs::read_to_string(path)
                .map_err(|error| format!("failed to read {}: {}", path.display(), error))?;
            let username = find_secret(&text, &["QBITTORRENT_USER", "QBITTORRENT_USERNAME"]);
            let password = find_secret(&text, &["QBITTORRENT_PASS", "QBITTORRENT_PASSWORD"]);
            match (username, password) {
                (Some(user), Some(pass)) => Ok((user, pass)),
                _ => Err(format!(
                    "missing QBITTORRENT_USER/QBITTORRENT_PASS in {}",
                    path.display()
                )),
            }
        }

        fn find_secret(text: &str, keys: &[&str]) -> Option<String> {
            for raw_line in text.lines() {
                let line = raw_line.trim();
                if line.is_empty() || line.starts_with('#') {
                    continue;
                }

                for key in keys {
                    if let Some(rest) = line.strip_prefix(key) {
                        let value = rest
                            .trim_start_matches(|c: char| c == ':' || c == '=' || c.is_whitespace())
                            .trim();
                        let value = value.trim_matches('"').trim_matches('\x27');
                        if !value.is_empty() {
                            return Some(value.to_string());
                        }
                    }
                }
            }
            None
        }

        fn percent_encode(value: &str) -> String {
            let mut encoded = String::with_capacity(value.len());
            for byte in value.bytes() {
                match byte {
                    b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => {
                        encoded.push(byte as char)
                    }
                    b' ' => encoded.push('+'),
                    _ => encoded.push_str(&format!("%{:02X}", byte)),
                }
            }
            encoded
        }

        fn make_cookie_path() -> PathBuf {
            let now = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap_or_default()
                .as_nanos();
            env::temp_dir().join(format!("qbittorrent-always-seed-{}.cookies", now))
        }

        fn cleanup_cookie(path: &Path) {
            let _ = fs::remove_file(path);
        }

        fn run_command(mut command: Command) -> io::Result<Output> {
            command.output()
        }

        fn run_command_with_stdin(mut command: Command, stdin: &[u8]) -> io::Result<Output> {
            use std::io::Write;
            use std::process::Stdio;

            command.stdin(Stdio::piped()).stdout(Stdio::piped()).stderr(Stdio::piped());
            let mut child = command.spawn()?;
            if let Some(mut handle) = child.stdin.take() {
                handle.write_all(stdin)?;
            }
            child.wait_with_output()
        }
      '';
      qBittorrentAlwaysSeed =
        pkgs.runCommand "qbittorrent-always-seed"
          {
            nativeBuildInputs = [
              pkgs.rustc
              pkgs.stdenv.cc
            ];
          }
          ''
            mkdir -p "$out/bin"
            cp ${qBittorrentAlwaysSeedSource} qbittorrent-always-seed.rs
            ${pkgs.rustc}/bin/rustc \
              --edition=2021 \
              -C opt-level=2 \
              qbittorrent-always-seed.rs \
              -o "$out/bin/qbittorrent-always-seed"
          '';
    in
    {
      systemd.tmpfiles.rules = [
        "d ${appDataRoots.sonarr} 0775 99 100 -"
        "d ${appDataRoots.radarr} 0775 99 100 -"
        "d ${appDataRoots.bazarr} 0775 99 100 -"
        "d ${appDataRoots.lidarr} 0775 99 100 -"
        "d ${appDataRoots.prowlarr} 0775 99 100 -"
        "d ${appDataRoots.jellyseerr} 0775 99 100 -"
        "d ${appDataRoots.qbittorrent} 0775 99 100 -"
        "d /mnt/storage/data/torrents/books 0775 99 100 -"
        "d /mnt/storage/data/torrents/audiobook 0775 99 100 -"
      ];

      # Sonarr - TV shows
      virtualisation.oci-containers.containers.sonarr = {
        image = "lscr.io/linuxserver/sonarr:latest";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "022";
        };
        volumes = [
          "/mnt/data3/appdata/sonarr:/config"
          "/mnt/storage/data:/data"
          "/mnt/storage/data/torrents:/downloads"
        ];
        ports = [ "8989:8989" ];
      };

      # Radarr - Movies
      virtualisation.oci-containers.containers.radarr = {
        image = "lscr.io/linuxserver/radarr";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "022";
        };
        volumes = [
          "/mnt/data3/appdata/radarr:/config"
          "/mnt/storage/data:/data"
          "/mnt/storage/data/torrents:/downloads"
        ];
        ports = [ "7878:7878" ];
      };

      # Bazarr - Subtitles
      virtualisation.oci-containers.containers.bazarr = {
        image = "lscr.io/linuxserver/bazarr:latest";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "022";
        };
        volumes = [
          "/mnt/data3/appdata/bazarr:/config"
          "/mnt/storage/data:/data"
        ];
        ports = [ "6767:6767" ];
      };

      # Lidarr - Music
      virtualisation.oci-containers.containers.lidarr = {
        image = "lscr.io/linuxserver/lidarr:latest";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "022";
        };
        volumes = [
          "/mnt/data3/appdata/lidarr:/config"
          "/mnt/storage/data:/data"
          "/mnt/storage/data/torrents:/downloads"
        ];
        ports = [ "8686:8686" ];
      };

      # Prowlarr - Indexer manager
      virtualisation.oci-containers.containers.prowlarr = {
        image = "lscr.io/linuxserver/prowlarr";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "022";
        };
        volumes = [
          "/mnt/data3/appdata/prowlarr:/config"
        ];
        ports = [ "9696:9696" ];
      };

      # Jellyseerr - Request management
      virtualisation.oci-containers.containers.jellyseerr = {
        image = "fallenbagel/jellyseerr:latest";
        environment = {
          LOG_LEVEL = "info";
          PUID = "99";
          PGID = "100";
          UMASK = "022";
        };
        volumes = [
          "/mnt/data3/appdata/jellyseerr:/app/config"
        ];
        ports = [ "5055:5055" ];
      };

      # qBittorrent
      virtualisation.oci-containers.containers.qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent:5.1.0";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "022";
          WEBUI_PORT = "8081";
          TORRENTING_PORT = "59793";
        };
        volumes = [
          "/mnt/storage/appdata/qbittorrent:/config"
          "/mnt/storage/data:/data"
          "/mnt/storage/data/torrents:/data/torrents"
          "/mnt/storage/data/torrents:/downloads"
        ];
        extraOptions = [
          "--label=com.centurylinklabs.watchtower.enable=false"
        ];
        ports = [
          "8081:8081"
          "59793:59793"
          "59793:59793/udp"
        ];
      };

      # Calibre
      virtualisation.oci-containers.containers.calibre = {
        image = "lscr.io/linuxserver/calibre";
        environment = {
          PUID = "99";
          PGID = "100";
          UMASK = "022";
        };
        volumes = [
          "/mnt/storage/data/media/books/calibre_library/calibre_libary:/config"
        ];
        ports = [
          "8780:8080"
          "8781:8181"
          "8981:8081"
        ];
      };

      # Flaresolverr - Cloudflare bypass
      virtualisation.oci-containers.containers.flaresolverr = {
        image = "flaresolverr/flaresolverr";
        environment = {
          LOG_LEVEL = "info";
          TZ = "UTC";
        };
        ports = [ "8191:8191" ];
      };

      # Ensure storage pool is mounted before media containers start.
      systemd.services =
        (lib.genAttrs storageBackedUnits (_: {
          requires = [
            "mnt-data3.mount"
            "mnt-storage.mount"
          ];
          after = [
            "mnt-data3.mount"
            "mnt-storage.mount"
          ];
        }))
        // {
          # Keep the live WebUI/RSS config, but enforce the MaM-safe tracker settings.
          "docker-qbittorrent".preStart = lib.mkBefore ''
            ${pkgs.python3}/bin/python3 ${qBittorrentMamConfig} \
              ${lib.escapeShellArg qBittorrentConfigPath} \
              ${lib.escapeShellArg qBittorrentCategoriesPath}
          '';

          qbittorrent-always-seed-books = {
            description = "Keep book and audiobook qBittorrent torrents seeding";
            wants = [ "network-online.target" ];
            requires = [ "docker-qbittorrent.service" ];
            after = [
              "docker-qbittorrent.service"
              "network-online.target"
            ];
            serviceConfig = {
              Type = "oneshot";
            };
            script = ''
              ${qBittorrentAlwaysSeed}/bin/qbittorrent-always-seed \
                --url http://127.0.0.1:8081 \
                --secrets ${lib.escapeShellArg qBittorrentSecretsPath}
            '';
          };
        };

      systemd.timers.qbittorrent-always-seed-books = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "3min";
          OnUnitActiveSec = "15min";
          AccuracySec = "1min";
          Unit = "qbittorrent-always-seed-books.service";
        };
      };

      networking.firewall.allowedTCPPorts = [
        8989
        7878
        6767
        8686
        9696
        5055
        8081
        59793
        8780
        8781
        8981
        8191
      ];
      networking.firewall.allowedUDPPorts = [ 59793 ];
    };
}

{ ... }:
{
  flake.modules.nixos."services.homepage-dashboard" =
    {
      config,
      lib,
      ...
    }:
    let
      host = config.networking.hostName;
      isServer = host == "server";
      isGateway = host == "gateway";

      serverAddress = "192.168.0.50";
      gatewayAddress = "192.168.0.1";
      gatewayStatusUrl = "http://${gatewayAddress}:8094/status.json";
      serverTailscaleHost = "server.tail7e8d6c.ts.net";
      gatewayTailscaleHost = "gateway.tail7e8d6c.ts.net";
      localLanAddresses =
        if isServer then
          [ serverAddress ]
        else if isGateway then
          [ gatewayAddress ]
        else
          [ "127.0.0.1" ];
      localTailscaleHost =
        if isServer then
          serverTailscaleHost
        else if isGateway then
          gatewayTailscaleHost
        else
          "localhost";
      localHomepage = "http://${localTailscaleHost}:8082";
      naviIcon = "https://i.redd.it/6nb9pk98yjpf1.jpeg";
    in
    lib.mkIf (isServer || isGateway) {
      services.homepage-dashboard = {
        enable = true;
        openFirewall = false;
        listenPort = 8082;
        allowedHosts = lib.concatStringsSep "," (
          [
            "localhost:8082"
            "127.0.0.1:8082"
            "127.0.0.1:8091"
            "127.0.0.1:8092"
            "127.0.0.1:8093"
            "127.0.0.1:8095"
            "127.0.0.1:8097"
            "${gatewayAddress}:8094"
            "${host}:8082"
            "${localTailscaleHost}:8082"
          ]
          ++ map (address: "${address}:8082") localLanAddresses
        );

        docker = lib.mkIf isServer {
          local = {
            socket = "/var/run/docker.sock";
          };
        };

        widgets =
          if isServer then
            [
              {
                logo = {
                  icon = naviIcon;
                  href = localHomepage;
                  target = "_self";
                };
              }
              {
                resources = {
                  label = "System";
                  cpu = true;
                  memory = true;
                  uptime = true;
                };
              }
              {
                resources = {
                  label = "Pool";
                  disk = "/mnt/storage";
                };
              }
              {
                resources = {
                  label = "SSD";
                  disk = "/mnt/ssd";
                };
              }
              {
                resources = {
                  label = "Data1";
                  disk = "/mnt/data1";
                };
              }
              {
                resources = {
                  label = "Data2";
                  disk = "/mnt/data2";
                };
              }
              {
                resources = {
                  label = "Data3";
                  disk = "/mnt/data3";
                };
              }
              {
                resources = {
                  label = "Parity";
                  disk = "/mnt/parity1";
                };
              }
              {
                datetime = {
                  text_size = "xl";
                  format = {
                    timeStyle = "short";
                    dateStyle = "medium";
                  };
                };
              }
              {
                openmeteo = {
                  label = "Mtl";
                  latitude = 45.5017;
                  longitude = -73.5673;
                  timezone = "America/Toronto";
                  units = "metric";
                  cache = 15;
                };
              }
            ]
          else
            [
              {
                logo = {
                  icon = naviIcon;
                  href = localHomepage;
                  target = "_self";
                };
              }
              {
                resources = {
                  label = "Gateway";
                  cpu = true;
                  memory = true;
                  disk = "/";
                  uptime = true;
                };
              }
              {
                datetime = {
                  text_size = "xl";
                  format = {
                    timeStyle = "short";
                    dateStyle = "medium";
                  };
                };
              }
              {
                openmeteo = {
                  label = "Mtl";
                  latitude = 45.5017;
                  longitude = -73.5673;
                  timezone = "America/Toronto";
                  units = "metric";
                  cache = 15;
                };
              }
            ];

        services =
          if isServer then
            [
              {
                Media = [
                  {
                    Sonarr = {
                      href = "http://${serverTailscaleHost}:8989";
                      description = "TV automation";
                      server = "local";
                      container = "sonarr";
                      showStats = true;
                    };
                  }
                  {
                    Radarr = {
                      href = "http://${serverTailscaleHost}:7878";
                      description = "Movie automation";
                      server = "local";
                      container = "radarr";
                      showStats = true;
                    };
                  }
                  {
                    Bazarr = {
                      href = "http://${serverTailscaleHost}:6767";
                      description = "Subtitle automation";
                      server = "local";
                      container = "bazarr";
                      showStats = true;
                    };
                  }
                  {
                    Lidarr = {
                      href = "http://${serverTailscaleHost}:8686";
                      description = "Music automation";
                      server = "local";
                      container = "lidarr";
                      showStats = true;
                    };
                  }
                  {
                    Prowlarr = {
                      href = "http://${serverTailscaleHost}:9696";
                      description = "Indexer manager";
                      server = "local";
                      container = "prowlarr";
                      showStats = true;
                    };
                  }
                  {
                    Jellyseerr = {
                      href = "http://${serverTailscaleHost}:5055";
                      description = "Media requests";
                      server = "local";
                      container = "jellyseerr";
                      showStats = true;
                    };
                  }
                  {
                    Jellyfin = {
                      href = "http://${serverTailscaleHost}:8096";
                      description = "Media streaming";
                      server = "local";
                      container = "jellyfin";
                      showStats = true;
                    };
                  }
                  {
                    Audiobookshelf = {
                      href = "http://${serverTailscaleHost}:13378";
                      description = "Audiobooks and podcasts";
                      server = "local";
                      container = "audiobookshelf";
                      showStats = true;
                    };
                  }
                  {
                    Shelfmark = {
                      href = "http://${serverTailscaleHost}:8084";
                      description = "Book and audiobook tools";
                      server = "local";
                      container = "shelfmark";
                      showStats = true;
                    };
                  }
                  {
                    CWA = {
                      href = "http://${serverTailscaleHost}:8083";
                      description = "Calibre-Web NextGen";
                      server = "local";
                      container = "calibre-web-automated";
                      showStats = true;
                    };
                  }
                  {
                    Calibre = {
                      href = "http://${serverTailscaleHost}:8780";
                      description = "Desktop calibre server";
                      server = "local";
                      container = "calibre";
                      showStats = true;
                    };
                  }
                  {
                    AnnotationSync = {
                      href = "http://${serverTailscaleHost}:8085";
                      description = "KOReader annotation WebDAV";
                      widget = {
                        type = "customapi";
                        url = "http://127.0.0.1:8097/status.json";
                        refreshInterval = 30000;
                        mappings = [
                          {
                            field = "status";
                            label = "WebDAV";
                          }
                          {
                            field = "checkedAt";
                            label = "Checked";
                          }
                        ];
                      };
                    };
                  }
                ];
              }
              {
                Downloads = [
                  {
                    qBittorrent = {
                      href = "http://${serverTailscaleHost}:8081";
                      description = "Torrent client";
                      server = "local";
                      container = "qbittorrent";
                      showStats = true;
                    };
                  }
                  {
                    Flaresolverr = {
                      href = "http://${serverTailscaleHost}:8191";
                      description = "Cloudflare bypass API";
                      server = "local";
                      container = "flaresolverr";
                      showStats = true;
                    };
                  }
                ];
              }
              {
                Productivity = [
                  {
                    Nextcloud = {
                      href = "http://${serverTailscaleHost}:444";
                      description = "Files and collaboration";
                      server = "local";
                      container = "nextcloud";
                      showStats = true;
                    };
                  }
                  {
                    Plane = {
                      href = "https://plane.ludovicvanasse.com";
                      description = "Projects and tasks";
                      server = "local";
                      container = "plane-proxy-1";
                      showStats = true;
                    };
                  }
                  {
                    Actual = {
                      href = "http://${serverTailscaleHost}:5006";
                      description = "Budgeting";
                      server = "local";
                      container = "actual";
                      showStats = true;
                    };
                  }
                  {
                    "Standard Notes" = {
                      href = "https://notes.ludovicvanasse.com";
                      description = "Private encrypted notes";
                      server = "local";
                      container = "standardnotes-web";
                      showStats = true;
                    };
                  }
                  {
                    Linkwarden = {
                      href = "http://${serverTailscaleHost}:3000";
                      description = "Bookmarks";
                      server = "local";
                      container = "linkwarden";
                      showStats = true;
                    };
                  }
                  {
                    KitchenOwl = {
                      href = "http://${serverAddress}:8086";
                      description = "Recipes and groceries";
                      server = "local";
                      container = "kitchenowl";
                      showStats = true;
                    };
                  }
                  {
                    Vaultwarden = {
                      href = "http://${serverTailscaleHost}:4743";
                      description = "Passwords";
                      server = "local";
                      container = "vaultwarden";
                      showStats = true;
                    };
                  }
                ];
              }
              {
                Infra = [
                  {
                    DockerHealth = {
                      href = "http://${serverTailscaleHost}:3001";
                      description = "Dynamic container health";
                      widget = {
                        type = "customapi";
                        url = "http://127.0.0.1:8095/status.json";
                        refreshInterval = 30000;
                        mappings = [
                          {
                            field = "overall.status";
                            label = "Overall";
                          }
                          {
                            field = "summary.failed";
                            label = "Failed";
                          }
                          {
                            field = "failed.names";
                            label = "Down";
                          }
                          {
                            field = "summary.total";
                            label = "Total";
                          }
                        ];
                      };
                    };
                  }
                  {
                    VaultwardenBackup = {
                      href = "http://${serverTailscaleHost}:4743";
                      description = "Nightly Restic backup to kDrive";
                      widget = {
                        type = "customapi";
                        url = "http://127.0.0.1:8091/status.json";
                        refreshInterval = 30000;
                        mappings = [
                          {
                            field = "backup.status";
                            label = "Backup";
                          }
                          {
                            field = "backup.finishedAt";
                            label = "Last backup";
                          }
                          {
                            field = "restoreTest.status";
                            label = "Restore";
                          }
                          {
                            field = "restoreTest.finishedAt";
                            label = "Last restore";
                          }
                        ];
                      };
                    };
                  }
                  {
                    DiskHealth = {
                      href = "http://${serverTailscaleHost}:8082";
                      description = "SMART and mount health";
                      widget = {
                        type = "customapi";
                        url = "http://127.0.0.1:8093/status.json";
                        refreshInterval = 30000;
                        mappings = [
                          {
                            field = "overall.status";
                            label = "Overall";
                          }
                          {
                            field = "checkedAt";
                            label = "Checked";
                          }
                          {
                            field = "data1.smart";
                            label = "Data1";
                          }
                          {
                            field = "data2.smart";
                            label = "Data2";
                          }
                          {
                            field = "data3.smart";
                            label = "Data3";
                          }
                          {
                            field = "parity1.smart";
                            label = "Parity";
                          }
                        ];
                      };
                    };
                  }
                  {
                    SnapRAID = {
                      href = "http://${serverTailscaleHost}:8082";
                      description = "Array sync and scrub health";
                      widget = {
                        type = "customapi";
                        url = "http://127.0.0.1:8092/status.json";
                        refreshInterval = 30000;
                        mappings = [
                          {
                            field = "scrub.status";
                            label = "Scrub";
                          }
                          {
                            field = "scrub.finishedAt";
                            label = "Last scrub";
                          }
                          {
                            field = "sync.status";
                            label = "Sync";
                          }
                          {
                            field = "sync.finishedAt";
                            label = "Last sync";
                          }
                        ];
                      };
                    };
                  }
                  {
                    GatewayHealth = {
                      href = "http://${gatewayTailscaleHost}:8082";
                      description = "Gateway runtime health";
                      widget = {
                        type = "customapi";
                        url = gatewayStatusUrl;
                        refreshInterval = 30000;
                        mappings = [
                          {
                            field = "overall.status";
                            label = "Overall";
                          }
                          {
                            field = "publicIp.ip";
                            label = "Public IP";
                          }
                          {
                            field = "publicIp.since";
                            label = "IP Since";
                          }
                          {
                            field = "pppoe.status";
                            label = "PPPoE";
                          }
                          {
                            field = "dnsmasq.status";
                            label = "DHCP/DNS";
                          }
                          {
                            field = "tailscale.status";
                            label = "Tailscale";
                          }
                          {
                            field = "uptime";
                            label = "Uptime";
                          }
                        ];
                      };
                    };
                  }
                  {
                    GatewaySecurity = {
                      href = "http://${gatewayTailscaleHost}:8082";
                      description = "Gateway SSH and exposure summary";
                      widget = {
                        type = "customapi";
                        url = gatewayStatusUrl;
                        refreshInterval = 30000;
                        mappings = [
                          {
                            field = "ssh.passwordAuthentication";
                            label = "SSH Passwords";
                          }
                          {
                            field = "fail2ban.sshd.banned";
                            label = "Banned";
                          }
                          {
                            field = "fail2ban.sshd.failed";
                            label = "Failed";
                          }
                          {
                            field = "exposure.wanPingV4";
                            label = "WAN Ping";
                          }
                          {
                            field = "exposure.wanOpenTcp";
                            label = "WAN TCP";
                          }
                          {
                            field = "exposure.listenTcp";
                            label = "Listen TCP";
                          }
                        ];
                      };
                    };
                  }
                  {
                    Dockhand = {
                      href = "http://${serverTailscaleHost}:3001";
                      description = "Docker compose dashboard";
                      server = "local";
                      container = "dockhand";
                      showStats = true;
                    };
                  }
                  {
                    Mousehole = {
                      href = "http://${serverTailscaleHost}:5010";
                      description = "Mousehole service";
                      server = "local";
                      container = "mousehole";
                      showStats = true;
                    };
                  }
                ];
              }
            ]
          else
            [
              {
                Dashboards = [
                  {
                    Homepage = {
                      href = localHomepage;
                      description = "Gateway dashboard";
                    };
                  }
                ];
              }
              {
                Network = [
                  {
                    AdGuardHome = {
                      href = "http://${gatewayTailscaleHost}:3000";
                      description = "DNS filtering";
                    };
                  }
                  {
                    ServerHomepage = {
                      href = "http://${serverTailscaleHost}:8082";
                      description = "Server dashboard";
                    };
                  }
                  {
                    ServerSSH = {
                      href = "http://${serverTailscaleHost}:8082";
                      description = "Tailscale server entrypoint";
                    };
                  }
                ];
              }
            ];

        settings = {
          title = if isServer then "Server Ops" else "Gateway Ops";
          description = if isServer then "Server status and Docker state" else "Gateway and network overview";
          headerStyle = "clean";
          target = "_blank";
          color = "stone";
          fullWidth = true;
          maxGroupColumns = 10;
          useEqualHeights = true;
          iconStyle = "theme";
          layout = {
            Media = {
              style = "row";
              columns = 6;
            };
            Downloads = {
              style = "row";
              columns = 4;
            };
            Productivity = {
              style = "row";
              columns = 5;
            };
            Infra = {
              style = "row";
              columns = 4;
            };
            Network = {
              style = "row";
              columns = 5;
            };
          };
        };

        customCSS = ''
          :root {
            --gb-bg0-hard: #1d2021;
            --gb-bg0: #282828;
            --gb-bg1: #3c3836;
            --gb-bg2: #504945;
            --gb-fg0: #fbf1c7;
            --gb-fg1: #ebdbb2;
            --gb-fg4: #a89984;
            --gb-yellow: #fabd2f;
            --gb-green: #b8bb26;
            --gb-aqua: #8ec07c;
            --gb-blue: #83a598;
            --gb-orange: #fe8019;
          }

          body {
            background: var(--gb-bg0-hard) !important;
            color: var(--gb-fg1) !important;
          }

          .bookmark, .information-widget, .widget, .card, .service-card {
            background: var(--gb-bg0) !important;
            border-color: var(--gb-bg2) !important;
            color: var(--gb-fg1) !important;
            box-shadow: none !important;
          }

          .service {
            background: transparent !important;
            border: none !important;
            box-shadow: none !important;
            padding: 0 !important;
          }

          .group {
            background: transparent !important;
            border: none !important;
            box-shadow: none !important;
            padding: 0 !important;
          }

          .bookmark:hover, .information-widget:hover, .card:hover, .service-card:hover {
            background: var(--gb-bg1) !important;
          }

          a, .title, .description {
            color: var(--gb-fg0) !important;
          }

          .description, .status, .subtitle, .resource-label {
            color: var(--gb-fg4) !important;
          }

          .information-widgets,
          .services,
          .bookmarks {
            gap: 0.55rem !important;
          }

          .bookmark, .information-widget, .card, .service-card {
            padding: 0.7rem 0.8rem !important;
            border-radius: 10px !important;
            border-width: 2px !important;
          }

          .service-card {
            min-height: 132px !important;
          }

          .service .title,
          .service-card .title {
            font-size: 0.95rem !important;
            font-weight: 700 !important;
            line-height: 1.18 !important;
          }

          .service .description,
          .service-card .description {
            font-size: 0.84rem !important;
            line-height: 1.3 !important;
          }

          .service-stats {
            margin-top: 0.15rem !important;
          }

          .service-stats .service-block {
            margin: 0.12rem !important;
            padding: 0.15rem 0.3rem !important;
            border-radius: 6px !important;
          }

          .service-stats .service-block > div:first-child {
            font-size: 0.68rem !important;
            line-height: 1.05 !important;
          }

          .service-stats .service-block > div:last-child {
            font-size: 0.52rem !important;
            line-height: 1.05 !important;
            letter-spacing: 0.02em !important;
          }

          .service:has(.service-container-stats) .service-stats .service-container > .service-block:nth-last-child(-n+2) {
            display: none !important;
          }

          .service .icon,
          .service-card .icon {
            width: 2.3rem !important;
            height: 2.3rem !important;
          }

          .services-group h2,
          .service-group h2,
          .group-title {
            margin-bottom: 0.45rem !important;
            font-size: 1rem !important;
          }

          .information-widget img,
          .logo-container img,
          .logo img {
            width: 92px !important;
            height: 92px !important;
            object-fit: cover !important;
            object-position: center center !important;
            border-radius: 5px !important;
          }

          h1, h2, h3, h4, .group-title {
            color: var(--gb-yellow) !important;
          }

          .status-ok, .text-emerald-500, .text-green-500 {
            color: var(--gb-green) !important;
          }

          .status-warning, .text-amber-500, .text-yellow-500 {
            color: var(--gb-yellow) !important;
          }

          .status-error, .text-red-500 {
            color: var(--gb-orange) !important;
          }

          .text-blue-500, .text-cyan-500 {
            color: var(--gb-blue) !important;
          }

          .search-container input, input, textarea, select {
            background: var(--gb-bg1) !important;
            color: var(--gb-fg1) !important;
            border-color: var(--gb-bg2) !important;
          }
        '';
      };

      systemd.services.homepage-dashboard.serviceConfig = lib.mkIf isServer {
        SupplementaryGroups = [ "docker" ];
        BindReadOnlyPaths = [ "/var/run/docker.sock" ];
      };

      assertions = lib.mkIf isServer [
        {
          assertion = config.virtualisation.docker.enable;
          message = "homepage-dashboard Docker integration on server requires virtualisation.docker.enable.";
        }
      ];
    };
}

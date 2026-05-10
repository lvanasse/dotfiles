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
      gatewayAddress = "192.168.10.1";
      serverTailscaleHost = "server.tail7e8d6c.ts.net";
      gatewayTailscaleHost = "gateway.tail7e8d6c.ts.net";
      localLanAddress =
        if isServer then
          serverAddress
        else if isGateway then
          gatewayAddress
        else
          "127.0.0.1";
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
        allowedHosts = lib.concatStringsSep "," [
          "localhost:8082"
          "127.0.0.1:8082"
          "127.0.0.1:8091"
          "${host}:8082"
          "${localLanAddress}:8082"
          "${localTailscaleHost}:8082"
        ];

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
                      description = "Calibre-Web Automated";
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
                    Vikunja = {
                      href = "http://${serverTailscaleHost}:3456";
                      description = "Tasks";
                      server = "local";
                      container = "vikunja";
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
                    Linkwarden = {
                      href = "http://${serverTailscaleHost}:3000";
                      description = "Bookmarks";
                      server = "local";
                      container = "linkwarden";
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
                  {
                    AnnotationSync = {
                      href = "http://${serverTailscaleHost}:8085";
                      description = "KOReader annotation WebDAV";
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
          maxGroupColumns = 8;
          useEqualHeights = true;
          iconStyle = "theme";
          layout = {
            Media = {
              style = "row";
              columns = 4;
            };
            Downloads = {
              style = "row";
              columns = 3;
            };
            Productivity = {
              style = "row";
              columns = 3;
            };
            Infra = {
              style = "row";
              columns = 3;
            };
            Network = {
              style = "row";
              columns = 4;
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

          .service, .bookmark, .information-widget, .widget, .card, .group, .service-card {
            background: var(--gb-bg0) !important;
            border-color: var(--gb-bg2) !important;
            color: var(--gb-fg1) !important;
            box-shadow: none !important;
          }

          .service:hover, .bookmark:hover, .information-widget:hover, .card:hover, .service-card:hover {
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
            gap: 0.8rem !important;
          }

          .service, .bookmark, .information-widget, .card, .service-card {
            padding: 1rem 1.05rem !important;
            border-radius: 12px !important;
            border-width: 2px !important;
          }

          .service, .service-card {
            min-height: 160px !important;
          }

          .service .title,
          .service-card .title {
            font-size: 1.02rem !important;
            font-weight: 700 !important;
            line-height: 1.25 !important;
          }

          .service .description,
          .service-card .description {
            font-size: 0.92rem !important;
            line-height: 1.4 !important;
          }

          .information-widget img,
          .logo-container img,
          .logo img {
            width: 120px !important;
            height: 120px !important;
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

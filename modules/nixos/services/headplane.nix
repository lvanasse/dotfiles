{ ... }:
let
  headplaneConfigOverride = ../../../overrides/headplane.yaml;
in
{
  flake.modules.nixos."services.headplane" =
    { lib, pkgs, ... }:
    let
      hasHeadplaneConfigOverride = builtins.pathExists headplaneConfigOverride;
      appDataRoot = "/mnt/data3/appdata/headplane";
      defaultCookieSecret =
        builtins.substring 0 32 (builtins.hashString "sha256" "headplane-cookie-secret");
      generatedConfig = pkgs.writeText "headplane-config.yaml" ''
        server:
          host: "0.0.0.0"
          port: 3000
          base_url: "https://headplane.ludovicvanasse.com"
          cookie_secret: "${defaultCookieSecret}"
          cookie_secure: true
          data_path: "/var/lib/headplane"
        headscale:
          url: "http://192.168.0.50:8080"
      '';
      headplaneConfigPath =
        if hasHeadplaneConfigOverride then
          toString headplaneConfigOverride
        else
          generatedConfig;
    in
    {
      virtualisation.oci-containers.containers.headplane = {
        image = "ghcr.io/tale/headplane:latest";
        environment = {
          HEADPLANE_CONFIG_PATH = "/etc/headplane/config.yaml";
        };
        volumes = [
          "${headplaneConfigPath}:/etc/headplane/config.yaml:ro"
          "${appDataRoot}:/var/lib/headplane"
        ];
        ports = [ "3001:3000" ];
      };

      systemd.services.docker-headplane = {
        requires = [ "mnt-data3.mount" ];
        after = [ "mnt-data3.mount" ];
      };

      networking.firewall.allowedTCPPorts = [ 3001 ];
    };
}

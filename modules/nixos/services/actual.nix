{ ... }:
{
  flake.modules.nixos."services.actual" =
    { lib, pkgs, ... }:
    let
      # The server and CLI operate on the same budget format and must move in
      # lockstep. Bump this one value, the npm lockfile, and the assertion.
      actualVersion = "26.9.0";
      actualCliManifest = builtins.fromJSON (builtins.readFile ../../../tools/actual-cli/package.json);
      actualCli = pkgs.callPackage ../../../tools/actual-cli { inherit actualVersion; };
    in
    {
      assertions = [
        {
          assertion = actualCliManifest.dependencies."@actual-app/cli" == actualVersion;
          message = "Actual server and @actual-app/cli versions must match (${actualVersion}).";
        }
      ];

      virtualisation.oci-containers.containers.actual = {
        image = "actualbudget/actual-server:${actualVersion}";
        volumes = [ "/mnt/ssd/appdata/docker/actual-budget:/data" ];
        ports = [ "5006:5006" ];
      };

      environment.systemPackages = [ actualCli ];

      # Ensure appdata mount exists before container startup.
      systemd.services.docker-actual = {
        requires = [ "mnt-ssd.mount" ];
        after = [ "mnt-ssd.mount" ];
      };

      networking.firewall.allowedTCPPorts = [ 5006 ];
    };
}

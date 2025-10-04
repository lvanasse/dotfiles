{ inputs, ... }:
{
  perSystem =
    {
      config,
      self',
      inputs',
      pkgs,
      system,
      ...
    }:
    {
      packages = {
        # Custom qBittorrent 5.1.0 package
        qbittorrent510 = pkgs.qbittorrent.overrideAttrs (_: {
          version = "5.1.0";
          src = pkgs.fetchurl {
            url = "https://github.com/qbittorrent/qBittorrent/archive/refs/tags/release-5.1.0.tar.gz";
            sha256 = "sha256-rFTNizxgNc/NaEvlr9DszIxfu8MAiptvm6QvbvkRBa8=";
          };
        });


      };

    };
}

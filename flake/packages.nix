_: {
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        # Custom qBittorrent 5.1.0 package pinned to the 25.05 release
        "qbittorrent510-2505" = pkgs.qbittorrent.overrideAttrs (_: {
          version = "5.1.0";
          src = pkgs.fetchurl {
            url = "https://github.com/qbittorrent/qBittorrent/archive/refs/tags/release-5.1.0.tar.gz";
            sha256 = "sha256-rFTNizxgNc/NaEvlr9DszIxfu8MAiptvm6QvbvkRBa8=";
          };
        });
      };
    };
}

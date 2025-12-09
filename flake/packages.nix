{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgs2505 =
        import inputs."nixpkgs-2505" {
          inherit system;
          config.allowUnfree = true;
        };
    in
    {
      packages = {
        # Custom qBittorrent 5.1.0 package pinned to the 25.05 release
        "qbittorrent510-2505" = pkgs2505.qbittorrent;
      };
    };
}

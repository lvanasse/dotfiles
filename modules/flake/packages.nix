{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    let
      pkgsWeekly = import inputs.nixpkgs-weekly {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs2505 = import inputs."nixpkgs-2505" {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      legacyPackages = pkgsWeekly;
      packages = {
        # Custom qBittorrent 5.1.0 package pinned to the 25.05 release
        "qbittorrent510-2505" = pkgs2505.qbittorrent;
      };
    };
}

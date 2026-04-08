{ ... }:
{
  flake.modules.homeManager."programs.rtk" =
    { pkgs, lib, ... }:
    let
      rtkPkg = if pkgs ? unstable && pkgs.unstable ? rtk then pkgs.unstable.rtk else pkgs.rtk;
    in
    {
      home.packages = [ rtkPkg ];

      home.activation.rtkGlobalConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -euo pipefail

        # Use RTK's own global init flow instead of reimplementing hooks/config in Nix.
        ${lib.getExe rtkPkg} init -g --auto-patch

        # Codex support is instruction-based upstream; this updates ~/.codex/AGENTS.md + RTK.md.
        ${lib.getExe rtkPkg} init -g --codex
      '';
    };
}

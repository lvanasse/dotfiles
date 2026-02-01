{ ... }:
{
  flake.modules.homeManager.terminalBash =
    { ... }:
    {
      programs.bash = {
        enable = true;

        shellAliases = {
          # Basic aliases
          ll = "ls -la";
          la = "ls -la";
          l = "ls -l";
          ".." = "cd ..";
          "..." = "cd ../..";

          # Git aliases
          gs = "git status";
          ga = "git add";
          gc = "git commit";
          gp = "git push";
          gl = "git log --oneline";
        };

        initExtra = ''
          # Unified nix-switch for both NixOS and standalone Home Manager
          nix-switch() {
            local flake_dir="''${NH_FLAKE:-$HOME/Code/personal/dotfiles}"
            bash "$flake_dir/scripts/nix-switch.sh" "$@"
          }
        '';
      };
    };
}

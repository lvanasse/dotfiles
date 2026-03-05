{ ... }:
{
  flake.modules.homeManager.devGit =
    { config, lib, pkgs, ... }:
    let
      homeDir = config.home.homeDirectory;
    in
    {
      # Git configuration with SSH keys for work/personal
      programs.git = {
        enable = true;
        package = pkgs.gitFull;

        # Default configuration (personal) - use mkDefault to allow overrides
        settings.user = {
          name = lib.mkDefault "Ludovic Vanasse";
          email = lib.mkDefault "mail@ludovicvanasse.com";
        };

        # Global git settings
        settings = {
          init.defaultBranch = "main";
          pull.rebase = true;
          push.autoSetupRemote = true;
          core.editor = "vim";

          # URL rewrites for SSH hosts
          url."git@bitbucket-work:" = {
            insteadOf = "git@bitbucket.org:";
          };
        };

        # Conditional includes for different directories
        includes = [
          {
            # Personal projects
            condition = "gitdir:${homeDir}/Code/personal/";
            contents = {
              user = {
                name = "Ludovic Vanasse";
                email = "mail@ludovicvanasse.com";
              };
              core.sshCommand = "ssh -i ~/.ssh/id_ed25519_personal -o IdentitiesOnly=yes";
            };
          }
          {
            # Work projects
            condition = "gitdir:${homeDir}/Code/work/";
            contents = {
              user = {
                name = "Ludovic Vanasse";
                email = "ludovic.vanasse@vention.cc";
              };
              core.sshCommand = "ssh -i ~/.ssh/id_ed25519_work -o IdentitiesOnly=yes";
            };
          }
        ];
      };

    };
}

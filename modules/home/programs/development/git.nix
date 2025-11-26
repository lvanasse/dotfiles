# Git configuration with SSH keys for work/personal
{ lib, ... }:
{
  programs.git = {
    enable = true;

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
        condition = "gitdir:~/Code/personal/";
        contents = {
          user = {
            name = "Ludovic Vanasse";
            email = "mail@ludovicvanasse.com";
          };
          core.sshCommand = "ssh -i ~/.ssh/id_ed25519_personal";
        };
      }
      {
        # Work projects
        condition = "gitdir:~/Code/work/";
        contents = {
          user = {
            name = "Ludovic Vanasse";
            email = "lvanasse@luxaerobot.com";
          };
          core.sshCommand = "ssh -i ~/.ssh/id_ed25519_work";
        };
      }
    ];
  };

  # SSH configuration for different keys
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # Disable default config to avoid future warnings

    matchBlocks = {
      # Personal GitHub account
      "github-personal" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_personal";
        identitiesOnly = true;
      };

      # Work Bitbucket account via alias
      "bitbucket-work" = {
        hostname = "bitbucket.org";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_work";
        identitiesOnly = true;
        controlMaster = "no";
        controlPath = "none";
      };

      # Work Bitbucket account via canonical host (for initial clones)
      "bitbucket.org" = {
        hostname = "bitbucket.org";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_work";
        identitiesOnly = true;
        controlMaster = "no";
        controlPath = "none";
      };

      # Default GitHub (personal)
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_personal";
        identitiesOnly = true;
      };

      # Codeberg (personal)
      "codeberg.org" = {
        hostname = "codeberg.org";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_personal";
        identitiesOnly = true;
      };

      # Default SSH settings for all hosts
      "*" = {
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        # Common SSH defaults that we want to keep
        compression = true;
        controlMaster = "auto";
        controlPath = "~/.ssh/master-%r@%h:%p";
        controlPersist = "10m";
      };
    };
  };
}

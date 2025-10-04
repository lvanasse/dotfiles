# Git configuration with SSH keys for work/personal
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
{
  programs.git = {
    enable = true;
    
    # Default configuration (personal) - use mkDefault to allow overrides
    userName = lib.mkDefault "Ludovic Vanasse";
    userEmail = lib.mkDefault "mail@ludovicvanasse.com";
    
    # Global git settings
    extraConfig = {
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
    
    matchBlocks = {
      # Personal GitHub account
      "github-personal" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_personal";
        identitiesOnly = true;
      };
      
      # Work Bitbucket account
      "bitbucket-work" = {
        hostname = "bitbucket.org";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_work";
        identitiesOnly = true;
      };
      
      # Default GitHub (personal)
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_personal";
        identitiesOnly = true;
      };
      
      # Default SSH settings for all other hosts
      "*" = {
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
      };
    };
  };
}
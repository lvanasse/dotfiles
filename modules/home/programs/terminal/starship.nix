# Starship prompt configuration
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  programs.starship = {
    enable = true;
    
    # Starship configuration in TOML format
    # This recreates the oh-my-zsh minimal theme
    settings = {
      # Global format - defines the overall prompt structure
      format = "$directory$git_branch$git_status$character";
      
      # Right format (empty for minimal theme)
      right_format = "";
      
      # Directory module - shows current directory (basename only, like minimal)
      directory = {
        format = "[$path]($style)";
        style = "white";  # White color as requested
        truncation_length = 1;  # Show only current directory name
        truncate_to_repo = false;
        home_symbol = "~";
      };
      
      # Git branch module - shows current branch in yellow parentheses
      git_branch = {
        format = " ($branch)";
        style = "yellow";
        symbol = "";  # No symbol, just branch name
      };
      
      # Git status module - shows red ✗ when dirty (simplified)
      git_status = {
        format = "[$all_status]($style)";
        style = "red";
        # Simplified - just show ✗ for any changes
        conflicted = " ✗";
        ahead = "";
        behind = "";
        diverged = " ✗";
        up_to_date = "";
        untracked = " ✗";
        stashed = "";
        modified = " ✗";
        staged = "";
        renamed = "";
        deleted = " ✗";
        # Disable some indicators to avoid duplicates
        ignore_submodules = true;
        disabled = false;
      };
      
      # Character module - the prompt symbol ($ or #)
      character = {
        success_symbol = " [\\$](white)";
        error_symbol = " [\\$](red)";
        vimcmd_symbol = " [\\$](green)";
      };
      
      # Disable modules we don't want in minimal theme
      aws.disabled = true;
      azure.disabled = true;
      battery.disabled = true;
      cmake.disabled = true;
      cmd_duration.disabled = true;
      conda.disabled = true;
      crystal.disabled = true;
      dart.disabled = true;
      deno.disabled = true;
      docker_context.disabled = true;
      dotnet.disabled = true;
      elixir.disabled = true;
      elm.disabled = true;
      env_var.disabled = true;
      erlang.disabled = true;
      gcloud.disabled = true;
      golang.disabled = true;
      helm.disabled = true;
      hostname.disabled = true;
      java.disabled = true;
      jobs.disabled = true;
      julia.disabled = true;
      kotlin.disabled = true;
      kubernetes.disabled = true;
      line_break.disabled = true;
      lua.disabled = true;
      memory_usage.disabled = true;
      nim.disabled = true;
      nix_shell.disabled = true;
      nodejs.disabled = true;
      ocaml.disabled = true;
      openstack.disabled = true;
      package.disabled = true;
      perl.disabled = true;
      php.disabled = true;
      pulumi.disabled = true;
      purescript.disabled = true;
      python.disabled = true;
      red.disabled = true;
      ruby.disabled = true;
      rust.disabled = true;
      scala.disabled = true;
      shell.disabled = true;
      shlvl.disabled = true;
      singularity.disabled = true;
      swift.disabled = true;
      terraform.disabled = true;
      time.disabled = true;
      username.disabled = true;
      vagrant.disabled = true;
      vcsh.disabled = true;
      zig.disabled = true;
    };
  };
}
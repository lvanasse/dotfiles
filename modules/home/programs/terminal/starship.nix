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
      # Show directory, then branch (with its own brackets), dirty marker, and prompt char
      # Use git_status with $all_status gating (ignores stash/ahead/behind)
      format = "$directory$git_branch$git_status$character";
      
      # Right format (empty for minimal theme)
      right_format = "";
      
      # Directory module - show full logical path with home collapsed to ~
      directory = {
        format = "[$path]($style)";
        style = "white";  # White color as requested
        truncation_length = 0;  # Disable truncation to keep ~/subdir style
        truncate_to_repo = false;
        home_symbol = "~";
      };
      
      # Git branch module - render only the branch name, brackets handled in format
      git_branch = {
        # Make branch more visible with a subtle symbol and bold style
        # Uses Nerd Font/Powerline glyph; falls back gracefully if unsupported
        symbol = " ";
        format = " [$symbol$branch]($style)";
        style = "bold white";
      };
      
      # Git status: print a single red dot only when working tree/index has changes
      # Gate on $all_status so clean repos show nothing. Disable ahead/behind and stash.
      git_status = {
        disabled = false;
        format = " [$all_status]($style)";
        style = "red";
        # Only working tree/index changes contribute to $all_status
        stashed = "";
        ahead = "";
        behind = "";
        diverged = "";
        # Map any present status to a dot; multiple statuses will yield repeated dots
        conflicted = "●";
        staged = "●";
        modified = "●";
        renamed = "●";
        deleted = "●";
        untracked = "●";
      };
      
      # Character module - the prompt symbol ($ or #)
      character = {
        success_symbol = " [»](white)";
        error_symbol = " [»](red)";
        vimcmd_symbol = " [»](green)";
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

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
      # Use git_status for dirty detection to ensure compatibility
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
        # Include a leading space so it only appears when in a repo
        # Wrap branch name in literal brackets and apply style
        format = " [$branch]($style)";
        style = "white";
        symbol = "";  # No symbol, just branch name
      };
      
      # Git status - show a simple red dot when anything is present (dirty or stashed)
      git_status = {
        disabled = false;
        format = " [●]($style)";
        style = "red";
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

{ ... }:
{
  flake.modules.homeManager."programs.aider" =
    { config, ... }:
    let
      palette = config.theme.palette;
    in
    {
      home.file.".aider.conf.yml".text = ''
        # Home-manager-managed defaults for aider CLI.
        # Set the model and API keys yourself in shell env, secrets, or a repo-local config.
        dark-mode: true
        pretty: true
        stream: true
        auto-commits: false
        dirty-commits: false
        gitignore: true
        vim: true
        user-input-color: "${palette.green}"
        assistant-output-color: "${palette.blue}"
        tool-output-color: "${palette.light1}"
        tool-error-color: "${palette.bright_red}"
        tool-warning-color: "${palette.bright_orange}"
        completion-menu-color: "${palette.light1}"
        completion-menu-bg-color: "${palette.dark1}"
        completion-menu-current-color: "${palette.dark0_hard}"
        completion-menu-current-bg-color: "${palette.light1}"
      '';
    };
}

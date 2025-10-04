# Zsh shell configuration
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "minimal";
      plugins = [
        "git"
        "sudo"
        "docker"
      ];
    };
    initContent = ''
      # for npm global installs
      export PATH="$HOME/.npm-global/bin:$PATH"
    '';
  };
}
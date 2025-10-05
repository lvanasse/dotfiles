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
    
    # Let's manage oh-my-zsh manually to ensure it works properly
    # oh-my-zsh = {
    #   enable = true;
    #   theme = "minimal";
    #   plugins = [
    #     "git"
    #     "git-prompt"  # Enhanced git prompt support
    #     "sudo"
    #     "docker"
    #   ];
    # };
    initContent = ''
      # for npm global installs
      export PATH="$HOME/.npm-global/bin:$PATH"
      
      # Use Starship prompt instead of oh-my-zsh for consistent minimal theme
      # Initialize Starship
      eval "$(starship init zsh)"
      
      # Still load oh-my-zsh for plugins (but not theme)
      export ZSH="${pkgs.oh-my-zsh}/share/oh-my-zsh"
      export ZSH_THEME=""  # Disable oh-my-zsh theme, use Starship
      
      # Enable plugins
      plugins=(git sudo docker)
      
      # Source oh-my-zsh (for plugins only)
      source $ZSH/oh-my-zsh.sh
      
      # If minimal theme doesn't show git info, this will ensure it does
      # Uncomment the lines below if you still don't see git info:
      # PROMPT='%{$fg[blue]%}%c%{$reset_color%} $(git_prompt_info)%(!.#.$) '
      # ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[yellow]%}("
      # ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
      # ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[yellow]%}) %{$fg[red]%}✗%{$reset_color%}"
      # ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[yellow]%})"
    '';
  };
}
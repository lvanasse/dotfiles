{ ... }:
{
  flake.modules.nixos."desktop.fonts" =
    { pkgs, ... }:
    {
      # Font configuration
      fonts = {
        fontDir.enable = true;
        fontconfig = {
          antialias = true;
          hinting = {
            enable = true;
            style = "slight";
          };
          subpixel = {
            rgba = "rgb";
            lcdfilter = "default";
          };
          defaultFonts = {
            sansSerif = [
              "Inter"
              "Noto Sans"
              "Noto Color Emoji"
            ];
            serif = [
              "Noto Serif"
              "Noto Color Emoji"
            ];
            monospace = [
              "JetBrainsMono Nerd Font Mono"
              "FiraCode Nerd Font Mono"
              "DejaVu Sans Mono"
            ];
            emoji = [ "Noto Color Emoji" ];
          };
        };
        packages = with pkgs; [
          inter
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-color-emoji
          liberation_ttf
          fira-code
          fira-code-symbols
          source-code-pro
          mplus-outline-fonts.githubRelease
          dina-font
          proggyfonts
          nerd-fonts.fira-code
          nerd-fonts.droid-sans-mono
          nerd-fonts.jetbrains-mono
          nerd-fonts.symbols-only
        ];
      };
    };
}

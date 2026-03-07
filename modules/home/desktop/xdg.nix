{ ... }:
{
  flake.modules.homeManager."desktop.xdg" =
    { ... }:
    {
      # Set default apps (MIME) so xdg-open opens Dolphin for folders
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "inode/directory" = [ "org.kde.dolphin.desktop" ];
          "application/x-directory" = [ "org.kde.dolphin.desktop" ];
          "x-scheme-handler/trash" = [ "org.kde.dolphin.desktop" ];
          # Force Firefox as the handler for generic web content
          "text/html" = [ "firefox.desktop" ];
          "application/xhtml+xml" = [ "firefox.desktop" ];
          "application/x-extension-htm" = [ "firefox.desktop" ];
          "application/x-extension-html" = [ "firefox.desktop" ];
          "application/x-extension-shtml" = [ "firefox.desktop" ];
          "application/x-extension-xhtml" = [ "firefox.desktop" ];
          "application/x-extension-xht" = [ "firefox.desktop" ];
          "x-scheme-handler/http" = [ "firefox.desktop" ];
          "x-scheme-handler/https" = [ "firefox.desktop" ];
          "x-scheme-handler/chrome" = [ "firefox.desktop" ];
          "x-scheme-handler/about" = [ "firefox.desktop" ];
          "x-scheme-handler/unknown" = [ "firefox.desktop" ];
          "x-scheme-handler/slack" = [ "slack.desktop" ];
          # Office documents (force OnlyOffice over ebook readers)
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [
            "onlyoffice-desktopeditors.desktop"
          ];
          "application/msword" = [ "onlyoffice-desktopeditors.desktop" ];
        };
      };

      # Allow Home Manager to replace existing mimeapps.list files
      xdg.configFile."mimeapps.list".force = true;
      xdg.dataFile."applications/mimeapps.list".force = true;
    };
}

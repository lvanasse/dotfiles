{ ... }:
{
  # Set default apps (MIME) so xdg-open opens Dolphin for folders
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "org.kde.dolphin.desktop" ];
      "application/x-directory" = [ "org.kde.dolphin.desktop" ];
      "x-scheme-handler/trash" = [ "org.kde.dolphin.desktop" ];
    };
  };
}

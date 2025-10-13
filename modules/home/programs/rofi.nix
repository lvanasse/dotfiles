# Rofi configuration themed as Gruvbox Dark Hard
{ ... }:
{
  home.file.".config/rofi/config.rasi".text = ''
    configuration {
      font: "Inter 11";
      modi: "combi,drun,run";
      combi-modi: "drun,run";
      show-icons: false;
      matching: "prefix";
      case-sensitive: false;
      cycle: true;
      sort: true;
    }

    /* Gruvbox Dark Hard - minimal, valid properties */
    * {
      background-color: #1d2021ff;
      text-color: #ebdbb2ff;
      border-color: #3c3836ff;
    }

    window {
      location: north;
      width: 100%;
      border: 0px;
      padding: 6px;
      background-color: #1d2021ff;
    }

    inputbar {
      padding: 6px 10px;
      background-color: #3c3836ff;
      text-color: #ebdbb2ff;
      border: 0px;
    }

    listview {
      padding: 6px 0px;
      spacing: 2px;
      columns: 1;
      lines: 10;
      background-color: transparent;
    }

    element {
      padding: 4px 8px;
      background-color: transparent;
      text-color: #ebdbb2ff;
    }

    element selected {
      background-color: #3c3836ff;
      text-color: #fbf1c7ff;
    }

    scrollbar {
      handle-width: 6px;
      handle-color: #504945ff;
      border: 0px;
    }
  '';
}

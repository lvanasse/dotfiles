# Rofi configuration using shared gruvbox-dark-hard palette
{ config, ... }:
let
  palette = config.theme.palette;
  # Helper: append 0xFF alpha for full opacity
  opa = c: "${c}ff";
in
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

    /* Gruvbox Dark Hard via shared theme */
    * {
      background-color: ${opa palette.dark0_hard};
      text-color: ${opa palette.light1};
      border-color: ${opa palette.dark1};
    }

    window {
      location: north;
      width: 100%;
      border: 0px;
      padding: 6px;
      background-color: ${opa palette.dark0_hard};
    }

    inputbar {
      padding: 6px 10px;
      background-color: ${opa palette.dark1};
      text-color: ${opa palette.light1};
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
      text-color: ${opa palette.light1};
    }

    element selected {
      background-color: ${opa palette.dark1};
      text-color: ${opa palette.light1};
      border: 2px;
      border-color: ${opa palette.bright_orange};
    }

    scrollbar {
      handle-width: 6px;
      handle-color: ${opa palette.dark2};
      border: 0px;
    }
  '';
}

{ ... }:
{
  flake.modules.homeManager.rofi =
    { config, ... }:
    let
      palette = config.theme.palette;
      # Helper: append 0xFF alpha for full opacity
      opa = c: "${c}ff";
    in
    {
      # Rofi configuration using shared gruvbox-dark-hard palette
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
          /* Place window at top (north = 2) */
          location: 2;
        }

        /* Gruvbox Dark Hard via shared theme */
        * {
          bg: ${opa palette.dark0_hard};
          bg-alt: ${opa palette.dark1};
          fg: ${opa palette.light1};
          border-color: ${opa palette.dark1};
          accent: ${opa palette.bright_orange};
        }

        window {
          width: 100%;
          border: 0px;
          padding: 6px;
          background-color: @bg;
        }

        mainbox { background-color: transparent; }

        inputbar {
          padding: 6px 10px;
          background-color: @bg-alt;
          text-color: @fg;
          border: 0px;
        }

        prompt { background-color: inherit; text-color: @fg; }
        entry  { background-color: inherit; text-color: @fg; }

        listview {
          padding: 6px 0px;
          spacing: 2px;
          columns: 1;
          lines: 10;
          background-color: @bg;
        }

        element { padding: 4px 8px; background-color: @bg; }
        element alternate { background-color: @bg; }
        element-text { background-color: inherit; text-color: @fg; }
        element selected { background-color: @bg-alt; border: 0px; }
        element selected element-text { text-color: @fg; }

        scrollbar {
          handle-width: 6px;
          handle-color: ${opa palette.dark2};
          border: 0px;
        }
      '';
    };
}

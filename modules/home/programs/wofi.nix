{ ... }:
{
  flake.modules.homeManager."programs.wofi" =
    { ... }:
    {
      # Wofi configured to be a minimal, dmenu-like launcher
      home.file.".config/wofi/config".text = ''
        mode=drun
        show=drun
        location=top
        anchor=top
        width=100%
        height=30
        allow_images=false
        allow_markup=false
        insensitive=true
        matching=fuzzy
        hide_scroll=true
        no_actions=true
        prompt=
        term=alacritty
      '';

      home.file.".config/wofi/style.css".text = ''
        /* Gruvbox Dark Hard */
        window {
          margin: 0px;
          border: none;
          background-color: rgba(29,32,33,0.96); /* #1d2021 */
          color: #ebdbb2; /* fg */
        }
        #input {
          margin: 0px;
          padding: 6px 10px;
          border: none;
          background: rgba(60,56,54,0.9); /* #3c3836 */
          color: #ebdbb2;
        }
        #outer-box { padding: 0; }
        #inner-box { padding: 4px 6px; }
        #scroll { margin: 0; }
        #text { padding: 4px 8px; color: #ebdbb2; }
        #entry:selected {
          background: rgba(60,56,54,0.9); /* #3c3836 */
          color: #fbf1c7; /* fg highlight */
        }
      '';
    };
}

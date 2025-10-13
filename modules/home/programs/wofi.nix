# Wofi configured to be a minimal, dmenu-like launcher
_: {
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
    hide_scroll=true
    no_actions=true
    prompt=
    term=alacritty
  '';

  home.file.".config/wofi/style.css".text = ''
    window {
      margin: 0px;
      border: none;
      background-color: rgba(24,24,27,0.96);
      color: #e5e7eb;
    }
    #input {
      margin: 0px;
      padding: 6px 10px;
      border: none;
      background: rgba(255,255,255,0.08);
    }
    #outer-box { padding: 0; }
    #inner-box { padding: 4px 6px; }
    #scroll { margin: 0; }
    #text { padding: 4px 8px; }
    #entry:selected { background: rgba(255,255,255,0.12); }
  '';
}

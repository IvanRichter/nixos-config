{ ... }:

{
  programs.zellij.enable = true;
  programs.zellij.extraConfig = ''
    show_startup_tips false

    copy_command "wl-copy"
    copy_on_select true

    keybinds {
      normal {
        bind "Ctrl Shift T" { NewTab; }
        bind "Ctrl Shift W" { CloseTab; }
      }
    }
  '';
}

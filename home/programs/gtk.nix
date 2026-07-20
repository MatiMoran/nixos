{ ... }:

{
  dconf.enable = false;

  gtk = {
    enable = true;
    theme = {
      name = "Material-Black-Cherry";
      package = null;
    };
    font = {
      name = "Sans";
      size = 10;
    };
    gtk3.extraConfig = {
      gtk-toolbar-style = "GTK_TOOLBAR_BOTH";
      gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
      gtk-button-images = 1;
      gtk-menu-images = 1;
      gtk-enable-event-sounds = 1;
      gtk-enable-input-feedback-sounds = 1;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintmedium";
    };
    gtk4 = {
      theme.name = "Material-Black-Cherry";
      extraConfig = {
        gtk-enable-event-sounds = 1;
        gtk-enable-input-feedback-sounds = 1;
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintmedium";
      };
    };
  };

  home.file.".themes/Material-Black-Cherry".source = ../themes/Material-Black-Cherry;
}

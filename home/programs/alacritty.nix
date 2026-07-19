{ pkgs, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      colors = {
        draw_bold_text_with_bright_colors = true;

        bright = {
          black = "#696969";
          blue = "#007FFF";
          cyan = "#00CCCC";
          green = "#03C03C";
          magenta = "#FF1493";
          red = "#FF2400";
          white = "#FFFAFA";
          yellow = "#FDFF00";
        };

        normal = {
          black = "#10100E";
          blue = "#0087BD";
          cyan = "#20B2AA";
          green = "#009F6B";
          magenta = "#9A4EAE";
          red = "#C40233";
          white = "#C6C6C4";
          yellow = "#FFD700";
        };

        primary = {
          background = "#1d1d1d";
          foreground = "#C6C6C4";
        };
      };

      font = {
        normal.family = "CaskaydiaCove Nerd Font Mono";
      };

      scrolling = {
        history = 10000;
        multiplier = 5;
      };

      window = {
        opacity = 0.9;
        padding = {
          x = 10;
          y = 10;
        };
      };

      general = {
        live_config_reload = true;
      };

      hints.enabled = [{
        hyperlinks = true;
        post_processing = true;
        persist = false;
        regex = "(ipfs:|ipns:|magnet:|mailto:|gemini://|gopher://|https://|http://|news:|file:|git://|ssh:|ftp://)\\S+";
        command.program = if pkgs.stdenv.isDarwin then "open" else "xdg-open";
        mouse.enabled = true;
        mouse.mods = "Shift";
        binding = { key = "O"; mods = "Control"; };
      }];
    };
  };
}

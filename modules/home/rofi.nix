{ lib, ... }:

{
  config.homeManager.nixosModules = lib.mkAfter [
    ({ ... }: {
      programs.rofi = {
        enable = true;
        settings = {
            terminal = "alacritty";
        };
        theme = ../../dotfiles/rofi/Theme.rasi;
      };
    })
  ];
}

{ lib, ... }:

{
  config.homeManager.nixosModules = lib.mkAfter [
    ({ ... }: {
      programs.rofi = {
        enable = true;
        terminal = "alacritty";
        theme = ../../dotfiles/rofi/Theme.rasi;
      };
    })
  ];
}

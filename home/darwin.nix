{ pkgs, ... }:

{
  imports = [
    ./default.nix
  ];

  programs.alacritty.settings.font.size = 17.0;
}

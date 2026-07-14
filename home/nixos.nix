{ pkgs, ... }:

{
  imports = [
    ./default.nix
  ];

  programs.alacritty.settings.font.size = 14.0;
}

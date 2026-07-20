{ pkgs, ... }:

{
  imports = [
    ./default.nix
    ./programs/sink-toggler.nix
    ./programs/dunst.nix
    ./programs/i3.nix
    ./programs/flameshot.nix
  ];

  programs.alacritty.settings.font.size = 14.0;
}

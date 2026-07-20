{ pkgs, ... }:

{
  imports = [
    ./default.nix
    ./programs/sink-toggler.nix
  ];

  programs.alacritty.settings.font.size = 14.0;
}

{ pkgs, ... }:

{
  imports = [
    ./default.nix
  ];

  home.username = "matmoran";
  home.homeDirectory = "/Users/matmoran";

  programs.alacritty.settings.font.size = 17.0;
}

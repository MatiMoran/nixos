{ pkgs, ... }:

{
  imports = [
    ./programs/alacritty.nix
  ];

  home = {
    username = "matias";
    homeDirectory = "/home/matias";
    stateVersion = "24.11";
  };

  programs.home-manager.enable = true;
}

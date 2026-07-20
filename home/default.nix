{ pkgs, lib, ... }:

{
  imports = [
    ./programs/alacritty.nix
  ];

  home = {
    username = lib.mkDefault "matias";
    homeDirectory = lib.mkDefault "/home/matias";
    stateVersion = "24.11";
  };

  programs.home-manager.enable = true;
}

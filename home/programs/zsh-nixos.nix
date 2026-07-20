{ config, ... }:

{
  home.file.".zshrc".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos/home/nixos/zshrc";

  xdg.configFile."zsh/.ls-colors".source = ../zsh/.ls-colors;
}

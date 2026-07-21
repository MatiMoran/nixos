{ config, pkgs, ... }:

{
  home.file.".zshrc".source =
    config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nixos/home/${if pkgs.stdenv.isDarwin then "darwin" else "nixos"}/zshrc";

  xdg.configFile."zsh/.ls-colors".source = ../home/zsh/.ls-colors;
}

{ lib, ... }:

{
  config.homeManager.sharedModules = lib.mkAfter [
    ({ config, pkgs, ... }: {
      home.file.".zshrc".source =
        config.lib.file.mkOutOfStoreSymlink
          "${config.home.homeDirectory}/nixos/dotfiles/${if pkgs.stdenv.isDarwin then "darwin" else "nixos"}/zshrc";

      xdg.configFile."zsh/.ls-colors".source = ../../dotfiles/zsh/.ls-colors;
    })
  ];
}

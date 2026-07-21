{ lib, ... }:

{
  config.homeManager.sharedModules = lib.mkAfter [
    ({ config, pkgs, ... }:

    let
      repoDir = "${config.home.homeDirectory}/nixos";
    in
    {
      home.packages = [ pkgs.neovim ];

      xdg.configFile."nvim" = {
        source = config.lib.file.mkOutOfStoreSymlink "${repoDir}/dotfiles/nvim";
      };
    })
  ];
}

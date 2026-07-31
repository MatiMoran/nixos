{ lib, ... }:

{
  config.homeManager.nixosModules = lib.mkAfter [
    ({ pkgs, config, ... }:

    let
      repoDir = "${config.home.homeDirectory}/nixos";
    in
    {
      home.packages = [ pkgs.mame ];

      home.file.".mame" = {
        source = config.lib.file.mkOutOfStoreSymlink "${repoDir}/dotfiles/mame";
      };
    })
  ];
}

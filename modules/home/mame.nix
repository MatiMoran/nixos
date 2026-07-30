{ lib, ... }:

{
  config.homeManager.nixosModules = lib.mkAfter [
    ({ pkgs, config, ... }:

    let
      repoDir = "${config.home.homeDirectory}/nixos";
    in
    {
      home.packages = [ pkgs.mame ];

      home.file.".mame/mame-dl.py" = {
        source = ../../dotfiles/mame/mame-dl.py;
        executable = true;
      };

      home.file.".mame/games.txt" = {
        source = config.lib.file.mkOutOfStoreSymlink "${repoDir}/dotfiles/mame/games.txt";
      };
    })
  ];
}

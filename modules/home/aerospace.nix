{ lib, ... }:

{
  config.homeManager.darwinModules = lib.mkAfter [
    ({ pkgs, ... }: {
      home.packages = [ pkgs.aerospace ];

      xdg.configFile."aerospace/aerospace.toml".source = ../../dotfiles/aerospace/aerospace.toml;
    })
  ];
}

{ pkgs, ... }:

{
  home.packages = [ pkgs.aerospace ];

  xdg.configFile."aerospace/aerospace.toml".source = ../home/aerospace/aerospace.toml;
}

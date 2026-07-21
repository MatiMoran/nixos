{ lib, ... }:

{
  config.homeManager.nixosModules = lib.mkAfter [
    ({ pkgs, ... }: {
      home.packages = [ pkgs.flameshot ];

      xdg.configFile."flameshot/flameshot.ini" = {
        force = true;
        text = ''
          [General]
          savePath=/home/matias/Downloads
          useX11LegacyScreenshot=true
        '';
      };
    })
  ];
}

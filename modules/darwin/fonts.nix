{ lib, ... }:

{
  config.darwinModules = lib.mkAfter [
    ({ pkgs, ... }: {
      fonts.packages = with pkgs; [
        nerd-fonts.caskaydia-cove
      ];
    })
  ];
}

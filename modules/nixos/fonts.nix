{ lib, ... }:

{
  config.nixosModules = lib.mkAfter [
    ({ pkgs, ... }: {
      fonts.packages = with pkgs; [
        nerd-fonts.caskaydia-cove
      ];
    })
  ];
}

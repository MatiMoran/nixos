{ lib, ... }:

{
  config.darwinModules = lib.mkAfter [
    ({ pkgs, ... }: {
      nix.settings.experimental-features = [ "nix-command" "flakes" ];
      nixpkgs.config.allowUnfree = true;
    })
  ];
}

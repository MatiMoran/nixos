{ lib, ... }:

let
  shared = import ../../lib/shared.nix;
in
{
  config.darwinModules = lib.mkAfter [
    ({ pkgs, ... }: {
      users.users.${shared.username.darwin} = {
        home = "/Users/${shared.username.darwin}";
      };
    })
  ];
}

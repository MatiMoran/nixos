{ lib, ... }:

let
  shared = import ../../lib/shared.nix;
in
{
  config.nixosModules = lib.mkAfter [
    ({ pkgs, ... }: {
      users.groups.uinput = {};
      users.users.${shared.username.nixos} = {
        isNormalUser = true;
        description = shared.username.nixos;
        extraGroups = [ "networkmanager" "wheel" "input" "uinput" "hermes" ];
        packages = with pkgs; [];
      };
      services.getty.autologinUser = shared.username.nixos;
    })
  ];
}

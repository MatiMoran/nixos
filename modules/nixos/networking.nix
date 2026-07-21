{ lib, ... }:

{
  config.nixosModules = lib.mkAfter [
    ({ ... }: {
      networking.hostName = "nixos";
      networking.networkmanager.enable = true;
    })
  ];
}

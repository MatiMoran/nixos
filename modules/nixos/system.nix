{ lib, ... }:

{
  config.nixosModules = lib.mkAfter [
    ({ ... }: {
      system.stateVersion = "24.11";
    })
  ];
}

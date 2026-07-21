{ lib, ... }:

{
  config.darwinModules = lib.mkAfter [
    ({ ... }: {
      system.stateVersion = 5;
    })
  ];
}

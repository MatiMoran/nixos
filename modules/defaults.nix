{ lib, ... }:

{
  options = {
    nixosModules = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      default = [];
    };
    darwinModules = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      default = [];
    };
    homeManager = {
      sharedModules = lib.mkOption {
        type = lib.types.listOf lib.types.deferredModule;
        default = [];
      };
      nixosModules = lib.mkOption {
        type = lib.types.listOf lib.types.deferredModule;
        default = [];
      };
      darwinModules = lib.mkOption {
        type = lib.types.listOf lib.types.deferredModule;
        default = [];
      };
    };
  };
}

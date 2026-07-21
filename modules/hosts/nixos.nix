{ inputs, lib, config, ... }:

let
  shared = import ../../lib/shared.nix;
in
{
  flake.nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      {
        imports = config.nixosModules;
      }
      ../../hosts/nixos/hardware-configuration.nix
      inputs.home-manager.nixosModules.home-manager {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${shared.username.nixos} = {
            imports =
              config.homeManager.sharedModules
              ++ config.homeManager.nixosModules;
          };
        };
      }
    ];
  };
}

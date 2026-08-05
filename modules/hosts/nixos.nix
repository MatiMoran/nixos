{ inputs, lib, config, ... }:

let
  username = "matias";
in
{
  flake.nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs username; };
    modules = [
      {
        imports = config.nixosModules;
      }
      ../../hosts/nixos/hardware-configuration.nix
      inputs.home-manager.nixosModules.home-manager {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${username} = {
            imports =
              config.homeManager.sharedModules
              ++ config.homeManager.nixosModules;
          };
        };
      }
    ];
  };
}

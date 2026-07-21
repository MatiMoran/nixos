{ inputs, lib, config, ... }:

let
  shared = import ../../lib/shared.nix;
in
{
  flake.darwinConfigurations.darwin = inputs.nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = { inherit inputs; };
    modules = [
      {
        imports = config.darwinModules;
      }
      inputs.home-manager.darwinModules.home-manager {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${shared.username.darwin} = { pkgs, ... }: {
            imports =
              config.homeManager.sharedModules
              ++ config.homeManager.darwinModules;
            home.username = shared.username.darwin;
            home.homeDirectory = "/Users/${shared.username.darwin}";
            home.packages = with pkgs; [
              obsidian
              vscode
              google-cloud-sdk
            ];
            programs.alacritty.settings.font.size = 17.0;
          };
        };
      }
    ];
  };
}

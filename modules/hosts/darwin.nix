{ inputs, lib, config, ... }:

let
  username = "matmoran";
in
{
  flake.darwinConfigurations.darwin = inputs.nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = { inherit inputs username; };
    modules = [
      {
        imports = config.darwinModules;
      }
      inputs.home-manager.darwinModules.home-manager {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${username} = { pkgs, ... }: {
            imports =
              config.homeManager.sharedModules
              ++ config.homeManager.darwinModules;
            home.username = username;
            home.homeDirectory = "/Users/${username}";
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

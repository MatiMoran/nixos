{ lib, ... }:

{
  config.homeManager.nixosModules = lib.mkAfter [
    ({ config, ... }:

    let
      repoDir = "${config.home.homeDirectory}/nixos";
      opencodeSrc = "${repoDir}/dotfiles/opencode";
    in
    {
      home.file = {
        ".config/opencode/opencode.json".source = config.lib.file.mkOutOfStoreSymlink "${opencodeSrc}/opencode.json";
        ".config/opencode/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${opencodeSrc}/AGENTS.md";
      };
    })
  ];
}

{ lib, ... }:

{
  config.homeManager.sharedModules = lib.mkAfter [
    ({ config, ... }:

    let
      repoDir = "${config.home.homeDirectory}/nixos";
      codexSrc = "${repoDir}/dotfiles/codex";
    in
    {
      home.file = {
        ".codex/config.toml" = {
          source = config.lib.file.mkOutOfStoreSymlink "${codexSrc}/config.toml";
          force = true;
        };
        ".codex/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${codexSrc}/AGENTS.md";
      };
    })
  ];
}

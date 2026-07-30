{ lib, ... }:

{
  config.homeManager.sharedModules = lib.mkAfter [
    ({ config, ... }:

    let
      repoDir = "${config.home.homeDirectory}/nixos";
      agentsSkillsSrc = "${repoDir}/dotfiles/agents/skills";
      agentsSkillsDir = "${config.home.homeDirectory}/.agents/skills";
    in
    {
      home.file = {
        ".agents/skills".source = config.lib.file.mkOutOfStoreSymlink agentsSkillsSrc;
        ".claude/skills".source = config.lib.file.mkOutOfStoreSymlink agentsSkillsDir;
        ".codex/skills".source = config.lib.file.mkOutOfStoreSymlink agentsSkillsDir;
      };
    })
  ];
}

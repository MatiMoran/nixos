{ lib, ... }:

{
  config.homeManager.sharedModules = lib.mkAfter [
    ({ config, ... }:

    let
      repoDir = "${config.home.homeDirectory}/nixos";
      agentsSkillsSrc = "${repoDir}/dotfiles/agents/skills";
      agentsSkillsDir = "${config.home.homeDirectory}/.agents/skills";
      sharedSkillNames = [
        "grid"
        "jira"
        "pr-ready"
        "queriator"
        "slack-polish"
      ];
      sharedSkillLinks = builtins.listToAttrs (map
        (name: {
          name = ".agents/skills/${name}";
          value.source = config.lib.file.mkOutOfStoreSymlink "${agentsSkillsSrc}/${name}";
        })
        sharedSkillNames);
    in
    {
      home.file = {
        ".claude/skills".source = config.lib.file.mkOutOfStoreSymlink agentsSkillsDir;
        ".codex/skills".source = config.lib.file.mkOutOfStoreSymlink agentsSkillsDir;
      } // sharedSkillLinks;
    })
  ];
}

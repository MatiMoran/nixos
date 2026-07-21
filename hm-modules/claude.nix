{ config, ... }:

let
  repoDir = "${config.home.homeDirectory}/nixos";
  claudeSrc = "${repoDir}/home/claude";
in
{
  home.file = {
    ".claude/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${claudeSrc}/settings.json";
    ".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${claudeSrc}/CLAUDE.md";
    ".claude/scripts".source = config.lib.file.mkOutOfStoreSymlink "${claudeSrc}/scripts";
    ".claude/statusline-command.sh".source = config.lib.file.mkOutOfStoreSymlink "${claudeSrc}/statusline-command.sh";
    ".claude/skills".source = config.lib.file.mkOutOfStoreSymlink "${claudeSrc}/skills";
  };
}

{ lib, ... }:

{
  config.homeManager.sharedModules = lib.mkAfter [
    ({ ... }: {
      programs.git = {
        enable = true;
        ignores = [
          ".DS_Store"
          "**/.claude/settings.local.json"
        ];
      };
    })
  ];
}

{ lib, ... }:

{
  config.darwinModules = lib.mkAfter [
    ({ pkgs, ... }:
      let
        codexSolHigh = pkgs.writeShellApplication {
          name = "codex";
          text = ''
            exec ${lib.getExe pkgs.codex} \
              --config 'model="gpt-5.6-sol"' \
              --config 'model_reasoning_effort="high"' \
              "$@"
          '';
        };
      in
      {
        environment.systemPackages = with pkgs; [
          awscli2
          bat
          codexSolHigh
          curl
          fd
          fzf
          gh
          git
          ripgrep
          unzip
          zip
          zoxide
          zsh
        ];
        programs.zsh.enable = true;
        programs.zsh.enableCompletion = false;
      })
  ];
}

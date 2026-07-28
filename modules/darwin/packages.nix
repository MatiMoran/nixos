{ lib, ... }:

{
  config.darwinModules = lib.mkAfter [
    ({ pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        awscli2
        bat
        codex
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

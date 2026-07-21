{ pkgs, lib, ... }:

{
  home = {
    username = lib.mkDefault "matias";
    homeDirectory = lib.mkDefault "/home/matias";
    stateVersion = "24.11";
  };

  programs.home-manager.enable = true;

  home.file.".config/zsh/plugins/zsh-autosuggestions".source =
    "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";

  home.file.".config/zsh/plugins/zsh-completions".source =
    "${pkgs.zsh-completions}/share/zsh-completions";

  home.file.".config/zsh/plugins/zsh-syntax-highlighting".source =
    "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting";
}

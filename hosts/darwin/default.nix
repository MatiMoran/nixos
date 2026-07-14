{ pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.nix-daemon.enable = true;

  environment.systemPackages = with pkgs; [
    neovim
    tmux
    git
    ripgrep
    fd
    fzf
    bat
    zoxide
  ];

  programs.zsh.enable = true;

  system.stateVersion = 5;
}

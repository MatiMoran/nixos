{ pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  users.users.matmoran = {
    home = "/Users/matmoran";
  };

  environment.systemPackages = with pkgs; [
    neovim
    git
    ripgrep
    fd
    fzf
    bat
    zoxide
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
  ];

  programs.zsh.enable = true;

  system.stateVersion = 5;
}

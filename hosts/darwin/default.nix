{ pkgs, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  users.users.matmoran = {
    home = "/Users/matmoran";
  };

  environment.systemPackages = with pkgs; [
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
  programs.zsh.enableCompletion = false;

  system.stateVersion = 5;
}

{ lib, ... }:

let
  shared = import ../../lib/shared.nix;
in
{
  config.nixosModules = lib.mkAfter [
    ({ pkgs, ... }: {
      services.tumbler.enable = true;

      services.displayManager = {
        autoLogin.user = shared.username.nixos;
        autoLogin.enable = true;
        defaultSession = "none+i3";
      };

      services.xserver = {
        enable = true;
        videoDrivers = [ "amdgpu" ];
        xkb = {
          layout = "us";
          variant = "";
        };
        desktopManager = {
          xterm.enable = false;
        };
        windowManager.i3 = {
          enable = true;
          extraPackages = with pkgs; [
            dmenu
            i3status
            i3blocks
          ];
        };
        wacom.enable = true;
      };

      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        config.common.default = "*";
      };

      programs = {
        nix-ld.enable = true;
        thunar.enable = true;
        zsh.enable = true;
      };
      users.defaultUserShell = pkgs.zsh;
    })
  ];
}

{ lib, ... }:

{
  config.nixosModules = lib.mkAfter [
    ({ pkgs, ... }: {
      boot.loader = {
        systemd-boot.enable = false;
        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/boot";
        };
        grub = {
          enable = true;
          device = "nodev";
          useOSProber = true;
          efiSupport = true;
          extraEntries = ''
              menuentry "Reboot" {
                  reboot
              }
              menuentry "Poweroff" {
                  halt
              }
          '';
        };
      };
      boot.supportedFilesystems = [ "ntfs" ];
      boot.kernelModules = [ "uinput" ];
      boot.initrd.kernelModules = [ "amdgpu" ];
    })
  ];
}

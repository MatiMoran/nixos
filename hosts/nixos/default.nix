# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader = {
    systemd-boot.enable = false;
    efi = {
      canTouchEfiVariables = true;
      # assuming /boot is the mount point of the  EFI partition in NixOS (as the installation section recommends).
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

  networking.hostName = "nixos"; # Define your hostname.

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Argentina/Buenos_Aires";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_MEASUREMENT = "es_AR.UTF-8";
    LC_TIME = "es_AR.UTF-8";
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Configure keymap in X11
  services = {

    pipewire = {
      pulse.enable = true;
      extraConfig.pipewire-pulse = {
        "10-custom-cmds" = {
          "pulse.cmd" = [
            { "cmd" = "load-module"; "args" = "module-always-sink"; "flags" = []; }
            { "cmd" = "load-module"; "args" = "module-combine-sink sink_name=combined sink_properties=device.description=CombinedSink slaves=alsa_output.usb-Kingston_Technology_Company_HyperX_Cloud_Flight_Wireless-00.analog-stereo,alsa_output.pci-0000_00_1f.3.analog-stereo"; "flags" = []; }
            { "cmd" = "set-default-sink"; "args" = "alsa_output.usb-Kingston_Technology_Company_HyperX_Cloud_Flight_Wireless-00.analog-stereo"; "flags" = []; }
            { "cmd" = "set-default-source"; "args" = "alsa_input.usb-Kingston_Technology_Company_HyperX_Cloud_Flight_Wireless-00.mono-fallback"; "flags" = []; }
          ];
        };
        "20-app-rules" = {
          "pulse.rules" = [
            {
              "matches" = [
                { "application.process.binary" = "teams"; }
                { "application.process.binary" = "teams-insiders"; }
                { "application.process.binary" = "skypeforlinux"; }
              ];
              "actions" = { "quirks" = [ "force-s16-info" ]; };
            }
            {
              "matches" = [ { "application.process.binary" = "firefox"; } ];
              "actions" = { "quirks" = [ "remove-capture-dont-move" ]; };
            }
            {
              "matches" = [ { "application.name" = "~speech-dispatcher.*"; } ];
              "actions" = {
                "update-props" = {
                  "pulse.min.req" = "512/48000";
                  "pulse.min.quantum" = "512/48000";
                  "pulse.idle.timeout" = 5;
                };
              };
            }
          ];
        };
      };
    };

    tumbler.enable = true; # Thumbnail support for images

    displayManager = {
      autoLogin.user = "matias";
      autoLogin.enable = true;
      defaultSession = "none+i3";
    };
 
    xserver = {
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
  };

  users.groups.uinput = {};

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.matias = {
    isNormalUser = true;
    description = "matias";
    extraGroups = [ "networkmanager" "wheel" "input" "uinput"];
    packages = with pkgs; [];
  };

  # Enable automatic login for the user.
  services.getty.autologinUser = "matias";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     android-file-transfer
     bat
     bc
     brave
     calibre
     clang
     curl
     dunst
     fd
     feh
     fzf
     gcc
     gdb
     gimp-with-plugins
     gimpPlugins.resynthesizer
     git
     gnumake
     htop
     keepassxc
     libreoffice
     linuxKernel.packages.linux_6_18.cpupower
     lsof
     nodejs_22
     obsidian
     opencode
     pavucontrol
     picom
     pulseaudio
     python3
     qbittorrent
     redshift
     ripgrep
     rofi
     sox
     stow
     sysstat
     tldr
     unar
     ungoogled-chromium
     unzip
     vlc
     vscode
     xclip
     zip
     zoxide
     zsh
     zsh-autosuggestions
     zsh-completions
     zsh-fzf-tab
     zsh-syntax-highlighting
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).

  systemd.services.kanata = {
    description = "Kanata Service";
    requires = [ "local-fs.target" ];
    after = [ "local-fs.target" ];

    serviceConfig = {
      ExecStart = "${pkgs.kanata}/bin/kanata -c /home/matias/.config/kanata/config.kbd";
      Restart = "no";
    };

    wantedBy = [ "sysinit.target" ];
  };

  fonts.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
  ];

  system.stateVersion = "24.11"; # Did you read the comment?

}

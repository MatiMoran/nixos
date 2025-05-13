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
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
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

  # Configure keymap in X11
  services = {

    pipewire.pulse.enable = true;

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

      displayManager = {
        defaultSession = "none+i3";
      };

      windowManager.i3 = {
        enable = true;
        extraPackages = with pkgs; [
          dmenu
	      i3status
	      i3blocks
        ];
      };
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

  programs = {
    thunar.enable = true;
    zsh.enable = true;
  };
  users.defaultUserShell = pkgs.zsh;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
     git
     neovim
     unzip
     zip
     curl
     picom
     curl
     htop
     lsof
     pulseaudio
     pavucontrol
     sysstat
     linuxKernel.packages.linux_6_14.cpupower
     stow
     bc
     rofi
     feh
     gcc
     gnumake
     clang
     sox
     dunst
     tmux
     fd
     ripgrep
     fzf
     bat
     zoxide
     kanata
     gimp
     xclip
     tldr
     vlc
     keepassxc
     redshift
     flameshot
     qbittorrent
     android-file-transfer
     alacritty
     zsh
     zsh-completions
     zsh-autosuggestions
     zsh-syntax-highlighting
     zsh-fzf-tab
     brave
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
    (nerdfonts.override { fonts = [ "CascadiaCode"]; })
  ];

  system.stateVersion = "24.11"; # Did you read the comment?

}

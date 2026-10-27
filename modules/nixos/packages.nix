{ lib, ... }:

{
  config.nixosModules = lib.mkAfter [
    ({ pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        android-file-transfer
        bat
        bc
        brave
        # Temporarily disabled: cache miss in nixpkgs, and building from source
        # fails because pyopenjtalk-plus (via piper-tts) has a test expecting
        # "must be str" while the newer Cython reports "Expected str, got int".
        # Re-enable once nixpkgs fixes the package or it is back in the cache.
        # calibre
        clang
        curl
        dunst
        fd
        feh
        fzf
        gcc
        gdb
        gh
        gimp-with-plugins
        gimpPlugins.resynthesizer
        git
        glab
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
        rclone
        redshift
        ripgrep
        rofi
        sox
        stow
        sysstat
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
    })
  ];
}

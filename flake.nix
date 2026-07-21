{
  description = "Multi-platform NixOS + macOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nix-darwin, flake-parts, ... }:
  let
    shared = import ./lib/shared.nix;
  in
  flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" "aarch64-darwin" ];

    flake = {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit self; };
        modules = [
          self.nixosModules.boot
          self.nixosModules.networking
          self.nixosModules.localization
          self.nixosModules.nix-settings
          self.nixosModules.users
          self.nixosModules.packages
          self.nixosModules.fonts
          self.nixosModules.audio
          self.nixosModules.desktop
          self.nixosModules.system
          ./hosts/nixos/hardware-configuration.nix
          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${shared.username.nixos} = {
                imports = [
                  ./hm-modules/shared.nix
                  ./hm-modules/alacritty.nix
                  ./hm-modules/herdr.nix
                  ./hm-modules/nvim.nix
                  ./hm-modules/git.nix
                  ./hm-modules/zsh.nix
                  ./hm-modules/kanata.nix
                  ./hm-modules/sink-toggler.nix
                  ./hm-modules/dunst.nix
                  ./hm-modules/i3.nix
                  ./hm-modules/flameshot.nix
                  ./hm-modules/mime.nix
                  ./hm-modules/opencode.nix
                  ./hm-modules/rofi.nix
                  ./hm-modules/gtk.nix
                ];
              };
            };
          }
        ];
      };

      darwinConfigurations.darwin = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit self; };
        modules = [
          self.darwinModules.nix-settings
          self.darwinModules.users
          self.darwinModules.packages
          self.darwinModules.fonts
          self.darwinModules.system
          home-manager.darwinModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${shared.username.darwin} = { pkgs, ... }: {
                imports = [
                  ./hm-modules/shared.nix
                  ./hm-modules/alacritty.nix
                  ./hm-modules/herdr.nix
                  ./hm-modules/nvim.nix
                  ./hm-modules/git.nix
                  ./hm-modules/zsh.nix
                  ./hm-modules/aerospace.nix
                  ./hm-modules/claude.nix
                ];
                home.username = shared.username.darwin;
                home.homeDirectory = "/Users/${shared.username.darwin}";
                home.packages = with pkgs; [
                  obsidian
                  vscode
                  google-cloud-sdk
                ];
                programs.alacritty.settings.font.size = 17.0;

                xdg.configFile."herdr/plugins/agent-notify/herdr-plugin.toml".text = ''
                  id = "local.agent-notify"
                  name = "Agent Notify"
                  version = "0.1.0"
                  min_herdr_version = "0.7.0"
                  description = "macOS notifications with click-to-navigate for agent completion"
                  platforms = ["macos"]

                  [[events]]
                  on = "pane.agent_status_changed"
                  command = ["./notify.sh"]
                '';

                xdg.configFile."herdr/plugins/agent-notify/notify.sh" = {
                  executable = true;
                  text = ''
                    #!/bin/bash
                    export PATH="/opt/homebrew/bin:$PATH"

                    EVENT_JSON="''${HERDR_PLUGIN_EVENT_JSON:-}"
                    [ -z "$EVENT_JSON" ] && exit 0

                    STATUS=$(echo "$EVENT_JSON" | jq -r '.status // empty')
                    [ "$STATUS" != "done" ] && exit 0

                    WORKSPACE_ID=$(echo "$EVENT_JSON" | jq -r '.workspace_id // empty')
                    TAB_ID=$(echo "$EVENT_JSON" | jq -r '.tab_id // empty')
                    AGENT_NAME=$(echo "$EVENT_JSON" | jq -r '.agent.name // "Agent"')

                    (
                      RESULT=$(alerter \
                        --title "herdr" \
                        --message "''${AGENT_NAME} finished" \
                        --actions "Open" \
                        --timeout 60 \
                        --sound "Funk" \
                        2>/dev/null)

                      if echo "$RESULT" | grep -qi "open\|clicked"; then
                        osascript -e 'tell application "Alacritty" to activate'
                        sleep 0.3
                        [ -n "$TAB_ID" ] && herdr tab focus "$TAB_ID"
                        [ -n "$WORKSPACE_ID" ] && herdr workspace focus "$WORKSPACE_ID"
                      fi
                    ) &
                  '';
                };
              };
            };
          }
        ];
      };

      darwinModules = {
        nix-settings = { pkgs, ... }: {
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          nixpkgs.config.allowUnfree = true;
        };

        users = { pkgs, ... }: {
          users.users.${shared.username.darwin} = {
            home = "/Users/${shared.username.darwin}";
          };
        };

        packages = { pkgs, ... }: {
          environment.systemPackages = with pkgs; [
            bat
            curl
            fd
            fzf
            git
            ripgrep
            unzip
            zip
            zoxide
            zsh
          ];
          programs.zsh.enable = true;
          programs.zsh.enableCompletion = false;
        };

        fonts = { pkgs, ... }: {
          fonts.packages = with pkgs; [
            nerd-fonts.caskaydia-cove
          ];
        };

        system = { ... }: {
          system.stateVersion = 5;
        };
      };

      nixosModules = {
        boot = { pkgs, ... }: {
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
        };

        networking = { ... }: {
          networking.hostName = "nixos";
          networking.networkmanager.enable = true;
        };

        localization = { ... }: {
          time.timeZone = "America/Argentina/Buenos_Aires";
          i18n.defaultLocale = "en_US.UTF-8";
          i18n.extraLocaleSettings = {
            LC_MEASUREMENT = "es_AR.UTF-8";
            LC_TIME = "es_AR.UTF-8";
          };
        };

        nix-settings = { pkgs, ... }: {
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          nixpkgs.config.allowUnfree = true;
        };

        users = { pkgs, ... }: {
          users.groups.uinput = {};
          users.users.${shared.username.nixos} = {
            isNormalUser = true;
            description = shared.username.nixos;
            extraGroups = [ "networkmanager" "wheel" "input" "uinput" ];
            packages = with pkgs; [];
          };
          services.getty.autologinUser = shared.username.nixos;
        };

        packages = { pkgs, ... }: {
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
        };

        fonts = { pkgs, ... }: {
          fonts.packages = with pkgs; [
            nerd-fonts.caskaydia-cove
          ];
        };

        system = { ... }: {
          system.stateVersion = "24.11";
        };

        audio = { pkgs, ... }: {
          services.pipewire = {
            pulse.enable = true;
            extraConfig.pipewire-pulse = {
              "10-custom-cmds" = {
                "pulse.cmd" = [
                  { "cmd" = "load-module"; "args" = "module-always-sink"; "flags" = []; }
                  { "cmd" = "load-module"; "args" = "module-combine-sink sink_name=combined sink_properties=device.description=CombinedSink slaves=${shared.pipewire.headset},${shared.pipewire.speakers}"; "flags" = []; }
                  { "cmd" = "set-default-sink"; "args" = shared.pipewire.headset; "flags" = []; }
                  { "cmd" = "set-default-source"; "args" = shared.pipewire.headsetMic; "flags" = []; }
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

          systemd.services.kanata = {
            description = "Kanata Service";
            requires = [ "local-fs.target" ];
            after = [ "local-fs.target" ];
            serviceConfig = {
              ExecStart = "${pkgs.kanata}/bin/kanata -c /home/${shared.username.nixos}/.config/kanata/config.kbd";
              Restart = "no";
            };
            wantedBy = [ "sysinit.target" ];
          };
        };

        desktop = { pkgs, ... }: {
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
        };
      };
    };
  };
}

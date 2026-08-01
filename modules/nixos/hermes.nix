{ inputs, lib, ... }:

let
  hermesAgentModule = inputs.hermes-agent.nixosModules.default;
  shared = import ../../lib/shared.nix;
in
{
  config.nixosModules = lib.mkAfter [
    ({ config, ... }:

    {
      imports = [ hermesAgentModule ];

      # Serve the user's skills (dotfiles/agents/skills) to the gateway as a
      # world-readable nix store path. The repo stays the source of truth and
      # ~/.agents/skills keeps its live symlink for user-side tools; the
      # gateway (hermes) must NOT traverse the user's 0700 home, so we point
      # external_dirs at this stable /etc symlink instead of ~/.agents/skills.
      environment.etc."hermes/skills".source = ../../dotfiles/agents/skills;

      services.hermes-agent = {
        enable = true;
        addToSystemPackages = true;

        environmentFiles = [ "/etc/hermes/env" ];

        environment = {
          TELEGRAM_ALLOWED_USERS = "782290261";
          TELEGRAM_HOME_CHANNEL = "782290261";
        };

        settings = {
          model = {
            provider = "opencode-zen";
            default = "big-pickle";
          };
          web = {
            backend = "brave-free";
            use_gateway = false;
          };
          terminal = {
            backend = "local";
            timeout = 180;
          };
          agent = {
            max_turns = 150;
          };
          stt = {
            language = "es";
            local = {
              model = "small";
            };
          };
          browser = {
            cloud_provider = "local";
            use_gateway = false;
          };
          display = {
            tool_progress = "all";
            show_reasoning = false;
            busy_input_mode = "steer";
          };
          tts = {
            use_gateway = false;
          };
          session_reset = {
            mode = "none";
          };
          skills = {
            external_dirs = [ "/etc/hermes/skills" ];
          };
        };
      };

      # Restart the gateway whenever its runtime inputs change. The unit only
      # embeds the package + env, while config.yaml/.env are generated into
      # /var/lib/hermes by the activation script and read once at startup — so
      # a settings change alone leaves the unit byte-identical and the gateway
      # keeps running the stale config. NixOS renders restartTriggers into the
      # unit as X-Restart-Triggers (a writeText store path), so a different hash
      # flips the unit and systemd restarts the service on `nixos-rebuild switch`.
      systemd.services.hermes-agent.restartTriggers = [
        (builtins.hashString "sha256" (builtins.toJSON {
          inherit (config.services.hermes-agent) settings workingDirectory environment extraArgs;
        }))
      ];

      # WORKAROUND for hermes-agent bug: secure_parent_dir() in
      # hermes_constants.py chmods the parent dir of auth files to 0o700 every
      # time the gateway saves an auth token. That clobbers the 2770
      # shared-state layout applied by the NixOS activation, so interactive
      # users in the `hermes` group get EACCES on config.yaml/.hermes_history.
      # Upstream guards only _secure_dir() (hermes_cli/config.py) with
      # is_managed() + HERMES_HOME_MODE (PR #6796); the auth path
      # (hermes_cli/auth.py) is still unguarded on main. Issue #14181, fix PRs
      # #14280 (closed, unmerged) and #14410 (open). This timer re-applies the
      # canonical modes every 60s until upstream lands a real fix.
      systemd.services.hermes-perms = {
        description = "Restore shared-state permissions under /var/lib/hermes/.hermes";
        serviceConfig = {
          Type = "oneshot";
          User = "hermes";
          Group = "hermes";
        };
        script = ''
          set -eu

          # Directories: 2770 (setgid + group rwx) so interactive users in the
          # `hermes` group keep read/write access to gateway state.
          find /var/lib/hermes/.hermes -type d -exec chmod 2770 {} + || true

          # State files: group read/write. The gateway (hermes) owns everything
          # it writes; files created by interactive users are left as-is.
          find /var/lib/hermes/.hermes -type f -exec chmod 660 {} + || true

          # Canonical top-level modes from the NixOS activation script.
          chmod 2770 /var/lib/hermes /var/lib/hermes/.hermes /var/lib/hermes/workspace || true
        '';
      };

      systemd.timers.hermes-perms = {
        description = "Periodically restore shared-state permissions under /var/lib/hermes/.hermes";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = 60;
          OnUnitActiveSec = 60;
          AccuracySec = "5s";
        };
      };

      home-manager.users.${shared.username.nixos}.home.file.".hermes/SOUL.md".source =
        config.home-manager.users.${shared.username.nixos}.lib.file.mkOutOfStoreSymlink
          "${config.users.users.${shared.username.nixos}.home}/nixos/dotfiles/hermes/SOUL.md";
    })
  ];
}

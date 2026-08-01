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
            external_dirs = [ "${config.users.users.${shared.username.nixos}.home}/.agents/skills" ];
          };
        };
      };

      home-manager.users.${shared.username.nixos}.home.file.".hermes/SOUL.md".source =
        config.home-manager.users.${shared.username.nixos}.lib.file.mkOutOfStoreSymlink
          "${config.users.users.${shared.username.nixos}.home}/nixos/dotfiles/hermes/SOUL.md";
    })
  ];
}

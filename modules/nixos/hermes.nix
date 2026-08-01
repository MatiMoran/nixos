{ inputs, lib, ... }:

let
  hermesAgentModule = inputs.hermes-agent.nixosModules.default;
in
{
  config.nixosModules = lib.mkAfter [
    ({ ... }:

    {
      imports = [ hermesAgentModule ];

      services.hermes-agent = {
        enable = true;
        addToSystemPackages = true;

        environmentFiles = [ "/etc/hermes/env" ];

        settings = {
          model = {
            provider = "opencode-zen";
            default = "big-pickle";
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
          };
          tts = {
            use_gateway = false;
          };
          session_reset = {
            mode = "none";
          };
        };
      };
    })
  ];
}

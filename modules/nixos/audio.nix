{ lib, ... }:

let
  shared = import ../../lib/shared.nix;
in
{
  config.nixosModules = lib.mkAfter [
    ({ pkgs, ... }: {
      services.pipewire = {
        pulse.enable = true;

        extraConfig.pipewire."30-combine-stream" = {
          "context.modules" = [
            {
              name = "libpipewire-module-combine-stream";
              args = {
                "combine.mode" = "sink";
                "node.name" = "combine_sink";
                "node.description" = "Combined Sink";
                "combine.latency-compensate" = false;
                "combine.props" = {
                  "audio.position" = [ "FL" "FR" ];
                };
                "stream.props" = { };
                "stream.rules" = [
                  {
                    matches = [
                      { "node.name" = shared.pipewire.headset; }
                    ];
                    actions.create-stream = { };
                  }
                  {
                    matches = [
                      { "node.name" = shared.pipewire.speakers; }
                    ];
                    actions.create-stream = { };
                  }
                ];
              };
            }
          ];
        };

        extraConfig.pipewire-pulse."10-custom-cmds" = {
          "pulse.cmd" = [
            { "cmd" = "load-module"; "args" = "module-always-sink"; "flags" = [ ]; }
            { "cmd" = "set-default-sink"; "args" = shared.pipewire.headset; "flags" = [ ]; }
            { "cmd" = "set-default-source"; "args" = shared.pipewire.headsetMic; "flags" = [ ]; }
          ];
        };

        extraConfig.pipewire-pulse."20-app-rules" = {
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

        wireplumber.extraConfig."51-disable-hdmi" = {
          "monitor.alsa.rules" = [
            {
              matches = [
                { "node.name" = "~alsa_output.*hdmi*"; }
              ];
              actions = {
                "update-props" = {
                  "node.disabled" = true;
                };
              };
            }
          ];
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
    })
  ];
}

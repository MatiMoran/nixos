{ lib, ... }:

let
  pipewire = {
    headset = "alsa_output.usb-Kingston_Technology_Company_HyperX_Cloud_Flight_Wireless-00.analog-stereo";
    speakers = "alsa_output.pci-0000_00_1f.3.analog-stereo";
    headsetMic = "alsa_input.usb-Kingston_Technology_Company_HyperX_Cloud_Flight_Wireless-00.mono-fallback";
  };
in
{
  config.nixosModules = lib.mkAfter [
    ({ pkgs, username, ... }: {
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
                      { "node.name" = pipewire.headset; }
                    ];
                    actions.create-stream = { };
                  }
                  {
                    matches = [
                      { "node.name" = pipewire.speakers; }
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
            { "cmd" = "set-default-sink"; "args" = pipewire.headset; "flags" = [ ]; }
            { "cmd" = "set-default-source"; "args" = pipewire.headsetMic; "flags" = [ ]; }
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
          ExecStart = "${pkgs.kanata}/bin/kanata -c /home/${username}/.config/kanata/config.kbd";
          Restart = "no";
        };
        wantedBy = [ "sysinit.target" ];
      };
    })
  ];
}

{ lib, ... }:

{
  config.homeManager.nixosModules = lib.mkAfter [
    ({ pkgs, ... }: {
      home.file.".local/bin/sink-toggler" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash

          current_sink=$(pactl get-default-sink)

          exclude_sink="/\(hdmi\|combine_sink\)/d"
          sinks=($(pactl list sinks short | awk '{print $2}' | sed "$(echo $exclude_sink)"))

          for i in "''${!sinks[@]}"; do
              if [[ "''${sinks[i]}" == "$current_sink" ]];
              then
                  current_index=$i
                  break
              fi

              current_index=0
          done

          function setSink() {

              if [ "$current_sink" == "$1" ]
              then
                  echo "Already using this Sink $current_sink"
                  exit 1
              fi

              pactl set-default-sink $1
          }

          function setNextSink() {
              next_index=$(( (current_index + 1) % ''${#sinks[@]} ))
              pactl set-default-sink "''${sinks[next_index]}"
          }


          function showHelp() {
              echo "------------------------------------"
              echo "AUDIO SINK SWITCHER"
              echo " "
              echo "$0 [options]"
              echo " "
              echo "options:"
              echo "-h  --help        What you are looking at.."
              echo "-g, --gaming      Sets headset as output device"
              echo "-s, --speakers    Sets Speakers as output device"
              echo "-n, --next        Sets the next sink as output device"
              echo " "
              echo "------------------------------------"
          }

          if [ $# -eq 0 ]
          then
              setNextSink
          fi

          # arg options
          while test $# -gt 0; do
              case "$1" in
                  -h|--help)
                      showHelp
                      exit 1
                      ;;
                  -g|--gaming)
                      setSink alsa_output.usb-Kingston_Technology_Company_HyperX_Cloud_Flight_Wireless-00.analog-stereo
                      exit 1
                      ;;
                  -s|--speakers)
                      setSink alsa_output.pci-0000_00_1f.3.analog-stereo
                      exit 1
                      ;;
                  -n|--next)
                      setNextSink
                      exit 1
                      ;;
                  *)
                      showHelp
                      exit 1
                      ;;
              esac
          done
        '';
      };
    })
  ];
}

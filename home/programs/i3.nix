{ pkgs, ... }:

{
  xdg.configFile."i3/config".text = ''
    set $mod Mod4

    font pango:monospace 10

    # Start XDG autostart .desktop files using dex. See also
    # https://wiki.archlinux.org/index.php/XDG_Autostart
    exec --no-startup-id dex --autostart --environment i3

    # NetworkManager is the most popular way to manage wireless networks on Linux,
    # and nm-applet is a desktop environment-independent system tray GUI for it.
    exec --no-startup-id nm-applet

    # Use pactl to adjust volume in PulseAudio.
    set $refresh_i3status killall -SIGUSR1 i3status
    bindsym Ctrl+F12 exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +5% && $refresh_i3status
    bindsym Ctrl+F11 exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -5% && $refresh_i3status
    bindsym Ctrl+F10 exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && $refresh_i3status
    bindsym Ctrl+F2 exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle && $refresh_i3status
    bindsym Ctrl+F1 exec --no-startup-id ~/.local/bin/sink-toggler -n && $refresh_i3status

    # Use Mouse+$mod to drag floating windows to their wanted position
    floating_modifier $mod

    bindsym $mod+Return exec alacritty

    bindsym $mod+Shift+q kill

    bindsym $mod+d exec rofi -show run
    bindsym $mod+t exec brave

    bindsym $mod+h focus left
    bindsym $mod+j focus down
    bindsym $mod+k focus up
    bindsym $mod+l focus right

    bindsym $mod+Left focus left
    bindsym $mod+Down focus down
    bindsym $mod+Up focus up
    bindsym $mod+Right focus right

    bindsym $mod+Shift+h move left
    bindsym $mod+Shift+j move down
    bindsym $mod+Shift+k move up
    bindsym $mod+Shift+l move right

    bindsym $mod+Shift+Left move left
    bindsym $mod+Shift+Down move down
    bindsym $mod+Shift+Up move up
    bindsym $mod+Shift+Right move right

    bindsym $mod+g split h

    bindsym $mod+v split v

    bindsym $mod+f fullscreen toggle

    bindsym $mod+q layout stacking
    bindsym $mod+w layout tabbed
    bindsym $mod+e layout toggle split

    bindsym $mod+Shift+space floating toggle

    bindsym $mod+space focus mode_toggle

    bindsym $mod+a focus parent

    bindsym $mod+s exec flameshot gui

    set $ws1 "1"
    set $ws2 "2"
    set $ws3 "3"
    set $ws4 "4"
    set $ws5 "5"
    set $ws6 "6"
    set $ws7 "7"
    set $ws8 "8"
    set $ws9 "9"
    set $ws10 "10"

    bindsym $mod+1 workspace number $ws1
    bindsym $mod+2 workspace number $ws2
    bindsym $mod+3 workspace number $ws3
    bindsym $mod+4 workspace number $ws4
    bindsym $mod+5 workspace number $ws5
    bindsym $mod+6 workspace number $ws6
    bindsym $mod+7 workspace number $ws7
    bindsym $mod+8 workspace number $ws8
    bindsym $mod+9 workspace number $ws9
    bindsym $mod+0 workspace number $ws10

    bindsym $mod+Ctrl+1 move container to workspace number $ws1
    bindsym $mod+Ctrl+2 move container to workspace number $ws2
    bindsym $mod+Ctrl+3 move container to workspace number $ws3
    bindsym $mod+Ctrl+4 move container to workspace number $ws4
    bindsym $mod+Ctrl+5 move container to workspace number $ws5
    bindsym $mod+Ctrl+6 move container to workspace number $ws6
    bindsym $mod+Ctrl+7 move container to workspace number $ws7
    bindsym $mod+Ctrl+8 move container to workspace number $ws8
    bindsym $mod+Ctrl+9 move container to workspace number $ws9
    bindsym $mod+Ctrl+0 move container to workspace number $ws10

    bindsym $mod+Shift+1 move container to workspace number $ws1; workspace number $ws1
    bindsym $mod+Shift+2 move container to workspace number $ws2; workspace number $ws2
    bindsym $mod+Shift+3 move container to workspace number $ws3; workspace number $ws3
    bindsym $mod+Shift+4 move container to workspace number $ws4; workspace number $ws4
    bindsym $mod+Shift+5 move container to workspace number $ws5; workspace number $ws5
    bindsym $mod+Shift+6 move container to workspace number $ws6; workspace number $ws6
    bindsym $mod+Shift+7 move container to workspace number $ws7; workspace number $ws7
    bindsym $mod+Shift+8 move container to workspace number $ws8; workspace number $ws8
    bindsym $mod+Shift+9 move container to workspace number $ws9; workspace number $ws9
    bindsym $mod+Shift+0 move container to workspace number $ws10; workspace number $ws10

    bindsym $mod+Ctrl+l move workspace to output right
    bindsym $mod+Ctrl+Right move workspace to output right
    bindsym $mod+Ctrl+h move workspace to output left
    bindsym $mod+Ctrl+Left move workspace to output left

    # reload the configuration file
    bindsym $mod+Shift+c reload
    # restart i3 inplace (preserves your layout/session, can be used to upgrade i3)
    bindsym $mod+Shift+r restart

    mode "Exit: (L)ogout (R)eboot (S)hutdown suspen(D) loc(K)" {
      bindsym l exec i3-msg exit
      bindsym r exec systemctl reboot
      bindsym s exec systemctl poweroff
      bindsym d exec systemctl suspend; mode "default"
      bindsym k exec ~/.config/i3/lock.sh; mode "default"
      bindsym Escape mode "default"
      bindsym Return mode "default"
      bindsym $mod+x mode "default"
    }
    bindsym $mod+x mode "Exit: (L)ogout (R)eboot (S)hutdown suspen(D) loc(K)"

    mode "resize" {
            bindsym j resize shrink width 10 px or 10 ppt
            bindsym k resize grow height 10 px or 10 ppt
            bindsym l resize shrink height 10 px or 10 ppt
            bindsym semicolon resize grow width 10 px or 10 ppt

            bindsym Left resize shrink width 10 px or 10 ppt
            bindsym Down resize grow height 10 px or 10 ppt
            bindsym Up resize shrink height 10 px or 10 ppt
            bindsym Right resize grow width 10 px or 10 ppt

            bindsym Return mode "default"
            bindsym Escape mode "default"
            bindsym $mod+r mode "default"
    }
    bindsym $mod+r mode "resize"

    bar {
        status_command i3blocks
        tray_output primary
        tray_padding 0
        font pango:CaskaydiaCove Nerd Font Mono 13

        bindsym button4 nop
        bindsym button5 nop
        workspace_min_width 20
        padding 0px 20px 0px 10px

        colors {
          background #2e2e2e
          separator #2e2e2e

          focused_workspace  #ff0000 #900000 #ffffff
          active_workspace   #333333 #5f676a #ffffff
          inactive_workspace #333333 #222222 #888888
          urgent_workspace   #2f343a #900000 #ffffff
          binding_mode       #2f343a #900000 #ffffff
        }
    }

    default_border pixel 0
    default_floating_border pixel 0
    gaps inner 5
    gaps outer 5

    set $m1 "HDMI-A-0"
    set $m2 "DisplayPort-0"

    exec_always xrandr --auto
    exec_always xrandr --output $m1 --primary --right-of $m2
    workspace $ws1 output $m1
    workspace $ws2 output $m2

    exec picom --corner-radius 10 --backend xrender -f -D 5
    exec_always feh --bg-scale ~/.config/i3/wallpaper.jpeg
    exec_always redshift -P -O 2700
    exec pactl unload-module $(pactl list sinks | grep -A7 'Sink #' | grep -A5 'hdmi' | grep 'Owner Module' | awk '{print $NF}')
    exec_always xsetwacom --set "Wacom One by Wacom S Pen stylus" MapToOutput $m1
    exec_always xsetwacom --set "Wacom One by Wacom S Pen eraser" MapToOutput $m1
  '';

  xdg.configFile."i3/wallpaper.jpeg".source = ../i3/wallpaper.jpeg;
  xdg.configFile."i3/lock.sh" = {
    executable = true;
    source = ../i3/lock.sh;
  };

  xdg.configFile."i3blocks/config".source = ../i3blocks-config;

  xdg.configFile."i3blocks/scripts/cpu" = {
    executable = true;
    source = ../i3blocks-scripts/cpu;
  };
  xdg.configFile."i3blocks/scripts/date" = {
    executable = true;
    source = ../i3blocks-scripts/date;
  };
  xdg.configFile."i3blocks/scripts/disk" = {
    executable = true;
    source = ../i3blocks-scripts/disk;
  };
  xdg.configFile."i3blocks/scripts/memory" = {
    executable = true;
    source = ../i3blocks-scripts/memory;
  };
  xdg.configFile."i3blocks/scripts/pango" = {
    executable = true;
    source = ../i3blocks-scripts/pango;
  };
  xdg.configFile."i3blocks/scripts/volume" = {
    executable = true;
    source = ../i3blocks-scripts/volume;
  };
  xdg.configFile."i3blocks/scripts/volume-pulseaudio" = {
    executable = true;
    source = ../i3blocks-scripts/volume-pulseaudio;
  };
  xdg.configFile."i3blocks/scripts/weather" = {
    executable = true;
    source = ../i3blocks-scripts/weather;
  };
}

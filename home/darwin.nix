{ pkgs, ... }:

{
  imports = [
    ./default.nix
    ./programs/aerospace.nix
    ./programs/claude.nix
    ./programs/git.nix
    ./programs/zsh.nix
  ];

  home.username = "matmoran";
  home.homeDirectory = "/Users/matmoran";

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
}

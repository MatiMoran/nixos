{ pkgs, ... }:

{
  home.packages = with pkgs; [ herdr jq ];

  home.file.".local/scripts/herdr-project-open" = {
    executable = true;
    text = ''
      #!/bin/bash

      DIRS=$(fd -H -d 2 . ''${COMMON_DIRS:-$HOME $HOME/Repos} --type d 2>/dev/null)
      DESTINATION=$(echo "$DIRS" | fzf --no-preview)

      [ -z "$DESTINATION" ] && exit 0

      SESSION_NAME=$(basename "$DESTINATION")
      SESSION_NAME="''${SESSION_NAME//[. ]/_}"

      if [ -f "$DESTINATION/pyproject.toml" ]; then
          POETRY_ACTIVATE='source "$(poetry env info --path)/bin/activate"'
      else
          POETRY_ACTIVATE=""
      fi

      if [ -n "$POETRY_ACTIVATE" ]; then
          CMD_CLAUDE="$POETRY_ACTIVATE && claude"
          CMD_SHELL="$POETRY_ACTIVATE"
          CMD_EDITOR="$POETRY_ACTIVATE && nvim ."
      else
          CMD_CLAUDE="claude"
          CMD_SHELL=""
          CMD_EDITOR="nvim ."
      fi

      EXISTING_WS=$(herdr workspace list 2>/dev/null | \
          jq -r ".result.workspaces[] | select(.label == \"$SESSION_NAME\") | .workspace_id" | head -1)

      if [ -n "$EXISTING_WS" ]; then
          herdr workspace focus "$EXISTING_WS"
      else
          WS_ID=$(herdr workspace create --cwd "$DESTINATION" --label "$SESSION_NAME" | \
              jq -r '.result.workspace_id // .result.workspace.workspace_id')

          AUTO_TAB=$(herdr tab list --workspace "$WS_ID" 2>/dev/null | jq -r '.result.tabs[0].tab_id')

          T_EDITOR=$(herdr tab create --workspace "$WS_ID" --label "editor" --cwd "$DESTINATION" --no-focus | \
              jq -r '.result.tab_id // .result.tab.tab_id')
          T_SHELL=$(herdr tab create --workspace "$WS_ID" --label "shell" --cwd "$DESTINATION" --no-focus | \
              jq -r '.result.tab_id // .result.tab.tab_id')
          T_CLAUDE=$(herdr tab create --workspace "$WS_ID" --label "claude" --cwd "$DESTINATION" --no-focus | \
              jq -r '.result.tab_id // .result.tab.tab_id')

          [ -n "$AUTO_TAB" ] && herdr tab close "$AUTO_TAB" 2>/dev/null

          pane_for() {
              herdr pane list --workspace "$WS_ID" | \
                  jq -r ".result.panes[] | select(.tab_id == \"$1\") | .pane_id"
          }

          sleep 0.5

          herdr pane run "$(pane_for "$T_EDITOR")" "$CMD_EDITOR"
          [ -n "$CMD_SHELL" ] && herdr pane run "$(pane_for "$T_SHELL")" "$CMD_SHELL"
          herdr pane run "$(pane_for "$T_CLAUDE")" "$CMD_CLAUDE"

          herdr tab focus "$T_SHELL"
          herdr workspace focus "$WS_ID"
      fi
    '';
  };

  xdg.configFile."herdr/config.toml".text = ''
    onboarding = false

    [keys]
    prefix = "ctrl+b"
    previous_tab = "prefix+shift+p"

    [[keys.command]]
    key = "prefix+p"
    type = "pane"
    command = "~/.local/scripts/herdr-project-open"
    description = "open project picker"

    [[keys.command]]
    key = "prefix+r"
    type = "shell"
    command = "herdr server reload-config"
    description = "reload herdr config"

    [theme]
    name = "gruvbox"
    auto_switch = false

    [ui]
    mouse_capture = true
    confirm_close = true
    show_agent_labels_on_pane_borders = false

    [ui.toast]
    delivery = "off"
  '';
}

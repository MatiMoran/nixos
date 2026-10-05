{ lib, ... }:

{
  config.homeManager.darwinModules = lib.mkAfter [
    ({ pkgs, lib, ... }:

    let
      aiCmd = if pkgs.stdenv.hostPlatform.isDarwin then "codex" else "opencode";
    in
    {
      home.packages = [ pkgs.tmux ];

      home.file.".config/tmux/tmux.conf".text = ''
        set -g base-index 1
        set -g mouse on
        set -s escape-time 0
        set -g detach-on-destroy off
        set-option -g focus-events on

        set-option -ga terminal-overrides ",alacritty:Tc"
        set-window-option -g mode-keys vi
        set-option -g renumber-windows on

        set -g status-position bottom
        set -g status-justify left
        set -g status-style 'fg=colour1 bg=#202020'
        set -g status-left ""
        set -g status-right ""
        set -g status-right-length 50
        set -g status-left-length 20

        setw -g window-status-current-style 'fg=#202020 bg=colour1 bold'
        setw -g window-status-current-format ' #I #W #F '

        setw -g window-status-style 'fg=colour1 dim'
        setw -g window-status-format ' #I #[fg=colour7]#W #[fg=colour1]#F '

        setw -g window-status-bell-style 'fg=colour2 bg=colour1 bold'

        bind r source-file ~/.config/tmux/tmux.conf
        bind-key p display-popup -E "~/.local/scripts/tmux-project-open"
      '';

      home.file.".local/scripts/tmux-project-open" = {
        executable = true;
        text = ''
          #!${pkgs.bash}/bin/bash

          DIRS=$(
              while IFS= read -r -d "" DIR; do
                  printf '%s\n' "''${DIR%/}"
                  [ -e "$DIR/.git" ] || continue

                  while IFS= read -r -d "" ENTRY; do
                      [[ "$ENTRY" == "worktree "* ]] || continue
                      WORKTREE="''${ENTRY#worktree }"
                      [ -d "$WORKTREE" ] && printf '%s\n' "$WORKTREE"
                  done < <(git -C "$DIR" worktree list --porcelain -z 2>/dev/null)
              done < <(fd -a -H -d 2 -0 . ''${COMMON_DIRS:-$HOME $HOME/Repos} --type d 2>/dev/null) | sort -u
          )
          DESTINATION=$(printf '%s\n' "$DIRS" | fzf --no-preview)

          [ -z "$DESTINATION" ] && exit 0
          DESTINATION=$(cd -- "$DESTINATION" && pwd -P) || exit 1

          SESSION_NAME=$(basename "$DESTINATION")
          if [ -e "$DESTINATION/.git" ]; then
              IFS= read -r -d "" MAIN_WORKTREE < <(git -C "$DESTINATION" worktree list --porcelain -z 2>/dev/null)
              MAIN_WORKTREE="''${MAIN_WORKTREE#worktree }"
              if [ -n "$MAIN_WORKTREE" ] && [ "$DESTINATION" != "$MAIN_WORKTREE" ]; then
                  SESSION_NAME="$(basename "$MAIN_WORKTREE")--$SESSION_NAME"
              fi
          fi
          SESSION_NAME="''${SESSION_NAME//[. ]/_}"

          if [ -f "$DESTINATION/pyproject.toml" ]; then
              POETRY_ACTIVATE='source "$(poetry env info --path)/bin/activate"'
          else
              POETRY_ACTIVATE=""
          fi

          if [ -n "$POETRY_ACTIVATE" ]; then
              CMD_AI="$POETRY_ACTIVATE && ${aiCmd}"
              CMD_SHELL="$POETRY_ACTIVATE"
              CMD_EDITOR="$POETRY_ACTIVATE && nvim ."
          else
              CMD_AI="${aiCmd}"
              CMD_SHELL=""
              CMD_EDITOR="nvim ."
          fi

          if tmux has-session -t "=$SESSION_NAME" 2>/dev/null; then
              tmux switch-client -t "=$SESSION_NAME"
          else
              tmux new-session -d -s "$SESSION_NAME" -c "$DESTINATION" -n "editor"
              tmux send-keys -t "=$SESSION_NAME:=editor" "$CMD_EDITOR" Enter

              tmux new-window -t "=$SESSION_NAME" -c "$DESTINATION" -n "shell"
              [ -n "$CMD_SHELL" ] && tmux send-keys -t "=$SESSION_NAME:=shell" "$CMD_SHELL" Enter

              tmux new-window -t "=$SESSION_NAME" -c "$DESTINATION" -n "${aiCmd}"
              tmux send-keys -t "=$SESSION_NAME:=${aiCmd}" "$CMD_AI" Enter

              tmux select-window -t "=$SESSION_NAME:=shell"
              tmux switch-client -t "=$SESSION_NAME"
          fi
        '';
      };

      home.file.".config/zsh/multiplexer.zsh".text = ''
        if [ -z "$TMUX" ]; then
            tmux new-session -A -s main
        fi

        function project_open {
            ~/.local/scripts/tmux-project-open
            zle accept-line
        }
        zle -N project_open
        bindkey '^p' project_open
      '';
    })
  ];
}

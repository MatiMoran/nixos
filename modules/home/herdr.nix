{ lib, ... }:

{
  config.homeManager.nixosModules = lib.mkAfter [
    ({ pkgs, lib, ... }:

    let
      aiCmd = if pkgs.stdenv.isDarwin then "claude" else "opencode";
      aiLabel = if pkgs.stdenv.isDarwin then "claude" else "opencode";

      # Fetch the pre-built terminal-notifier binary (avoids the broken nixpkgs xcbuild derivation).
      # x86_64 binary runs via Rosetta 2 on Apple Silicon. Provides click-to-focus via -execute.
      terminalNotifierPkg = pkgs.runCommand "terminal-notifier-2.0.0" {
        src = pkgs.fetchzip {
          url = "https://github.com/julienXX/terminal-notifier/releases/download/2.0.0/terminal-notifier-2.0.0.zip";
          sha256 = "0gi54v92hi1fkryxlz3k5s5d8h0s66cc57ds0vbm1m1qk3z4xhb0";
        };
      } ''
        mkdir -p $out/Applications $out/bin
        cp -r "$src/terminal-notifier.app" "$out/Applications/"
        chmod +x "$out/Applications/terminal-notifier.app/Contents/MacOS/terminal-notifier"
        # Wrapper instead of symlink: macOS loses bundle context through symlinks
        # and can't find Info.plist, causing "No NSPrincipalClass" crash.
        printf '#!/bin/sh\nexec "%s" "$@"\n' \
          "$out/Applications/terminal-notifier.app/Contents/MacOS/terminal-notifier" \
          > "$out/bin/terminal-notifier"
        chmod +x "$out/bin/terminal-notifier"
      '';

      # Resolved at Nix eval time; empty string on NixOS so the Python script gets a clean no-op.
      terminalNotifierBin = if pkgs.stdenv.isDarwin
        then "${terminalNotifierPkg}/bin/terminal-notifier"
        else "";
    in
    {
      home.packages = with pkgs;
        [ herdr jq ]
        ++ (if pkgs.stdenv.isDarwin then [ terminalNotifierPkg ] else []);

      home.activation.herdrSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        lib.concatStringsSep "\n" (
          lib.optionals pkgs.stdenv.isDarwin [
            # Register terminal-notifier with Launch Services so macOS grants notification permissions
            ''
              /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
                -f "${terminalNotifierPkg}/Applications/terminal-notifier.app" 2>/dev/null || true
            ''
          ] ++ [
            # Re-link herdr plugin so it picks up the updated manifest on each rebuild
            ''
              if command -v herdr >/dev/null 2>&1 && herdr status server >/dev/null 2>&1; then
                herdr plugin unlink os-notifier 2>/dev/null || true
                herdr plugin link "$HOME/.config/herdr/plugins/os-notifier" 2>/dev/null || true
              fi
            ''
          ]
        )
      );

      home.file.".local/scripts/herdr-project-open" = {
        executable = true;
        text = ''
          #!${pkgs.bash}/bin/bash

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
              CMD_AI="$POETRY_ACTIVATE && ${aiCmd}"
              CMD_SHELL="$POETRY_ACTIVATE"
              CMD_EDITOR="$POETRY_ACTIVATE && nvim ."
          else
              CMD_AI="${aiCmd}"
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
              T_AI=$(herdr tab create --workspace "$WS_ID" --label "${aiLabel}" --cwd "$DESTINATION" --no-focus | \
                  jq -r '.result.tab_id // .result.tab.tab_id')

              [ -n "$AUTO_TAB" ] && herdr tab close "$AUTO_TAB" 2>/dev/null

              pane_for() {
                  herdr pane list --workspace "$WS_ID" | \
                      jq -r ".result.panes[] | select(.tab_id == \"$1\") | .pane_id"
              }

              sleep 0.5

              herdr pane run "$(pane_for "$T_EDITOR")" "$CMD_EDITOR"
              [ -n "$CMD_SHELL" ] && herdr pane run "$(pane_for "$T_SHELL")" "$CMD_SHELL"
              herdr pane run "$(pane_for "$T_AI")" "$CMD_AI"

              herdr tab focus "$T_SHELL"
              herdr workspace focus "$WS_ID"
          fi
        '';
      };

      home.file.".config/zsh/multiplexer.zsh".text = ''
        if [ -z "$HERDR_SOCKET_PATH" ]; then
            herdr
        fi

        function project_open {
            ~/.local/scripts/herdr-project-open
            zle accept-line
        }
        zle -N project_open
        bindkey '^p' project_open
      '';

      xdg.configFile."herdr/plugins/os-notifier/herdr-plugin.toml".text = ''
        id = "os-notifier"
        name = "OS Agent Notifier"
        version = "1.0.0"
        min_herdr_version = "0.1.0"

        [[startup]]
        command = ["sh", "-c", "TERMINAL_NOTIFIER=${terminalNotifierBin} exec ${pkgs.python3}/bin/python3 $HOME/.config/herdr/plugins/os-notifier/notifier.py"]
      '';

      xdg.configFile."herdr/plugins/os-notifier/notifier.py" = {
        executable = true;
        text = ''
          #!/usr/bin/env python3
          """herdr agent notifier -- fires native OS notifications on agent state changes."""
          import json
          import os
          import platform
          import socket
          import subprocess
          import sys
          import threading
          import time
          from pathlib import Path

          SOCK_PATH = os.environ.get(
              "HERDR_SOCKET_PATH",
              str(Path.home() / ".config/herdr/herdr.sock"),
          )
          HERDR_BIN = os.environ.get("HERDR_BIN_PATH", "herdr")
          TERMINAL_NOTIFIER = os.environ.get("TERMINAL_NOTIFIER", "")
          NOTIFY_STATUSES = {"idle", "blocked", "done"}


          def is_focused(tab_id: str) -> bool:
              try:
                  raw = subprocess.run(
                      [HERDR_BIN, "api", "snapshot"],
                      capture_output=True, text=True, timeout=2,
                  ).stdout
                  snap = json.loads(raw).get("result", {}).get("snapshot", {})
                  return snap.get("focused_tab_id") == tab_id
              except Exception:
                  return False


          def notify_darwin(title: str, body: str, ws_id: str, tab_id: str) -> None:
              focus_cmd = (
                  f"{HERDR_BIN} workspace focus '{ws_id}'; "
                  f"{HERDR_BIN} tab focus '{tab_id}'; "
                  f"open -a Alacritty"
              )
              if TERMINAL_NOTIFIER:
                  # Non-blocking: terminal-notifier stays alive in bg waiting for click.
                  subprocess.Popen(
                      [
                          TERMINAL_NOTIFIER,
                          "-title", title,
                          "-message", body,
                          "-group", f"herdr-{tab_id}",
                          "-execute", focus_cmd,
                      ],
                      stdout=subprocess.DEVNULL,
                      stderr=subprocess.DEVNULL,
                  )
              else:
                  subprocess.run(
                      [
                          "osascript", "-e",
                          f'display notification "{body}" with title "{title}"',
                      ],
                      check=False, capture_output=True,
                  )


          def notify_linux(title: str, body: str, ws_id: str, tab_id: str) -> None:
              focus_cmd = (
                  f"{HERDR_BIN} workspace focus '{ws_id}'; "
                  f"{HERDR_BIN} tab focus '{tab_id}'"
              )

              def run() -> None:
                  try:
                      proc = subprocess.run(
                          ["dunstify", "-t", "30000", "-A", "focus,Ir al agente", title, body],
                          capture_output=True, text=True, timeout=35,
                      )
                      if proc.returncode == 0 and proc.stdout.strip() == "focus":
                          subprocess.run(focus_cmd, shell=True, check=False)
                  except Exception:
                      pass

              threading.Thread(target=run, daemon=True).start()


          def send_notification(
              status: str, label: str, ws_id: str, tab_id: str, cwd: str
          ) -> None:
              if is_focused(tab_id):
                  return

              project = Path(cwd).name if cwd else label or "agent"
              titles = {
                  "idle": "Agent idle",
                  "blocked": "Agent bloqueado",
                  "done": "Agent terminó",
              }
              bodies = {
                  "idle": f"{label} en {project} esta esperando input",
                  "blocked": f"{label} en {project} necesita atencion urgente",
                  "done": f"{label} en {project} finalizo su tarea",
              }
              title = titles.get(status)
              body = bodies.get(status)
              if not title:
                  return

              if platform.system() == "Darwin":
                  notify_darwin(title, body, ws_id, tab_id)
              else:
                  notify_linux(title, body, ws_id, tab_id)


          def subscribe(sock_path: str) -> None:
              sub = json.dumps({
                  "id": "sub_1",
                  "method": "events.subscribe",
                  "params": {
                      "subscriptions": [{"type": "pane.agent_status_changed"}],
                  },
              })

              with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as conn:
                  conn.connect(sock_path)
                  conn.sendall((sub + "\n").encode())

                  buf = b""
                  first = True
                  while True:
                      chunk = conn.recv(4096)
                      if not chunk:
                          break
                      buf += chunk
                      while b"\n" in buf:
                          line, buf = buf.split(b"\n", 1)
                          if not line.strip():
                              continue
                          try:
                              event = json.loads(line)
                          except json.JSONDecodeError:
                              continue

                          if first:
                              first = False
                              continue

                          payload = event.get("result") or event.get("params") or {}
                          status = payload.get("agent_status", "")
                          label = payload.get("agent", "")
                          ws_id = payload.get("workspace_id", "")
                          tab_id = payload.get("tab_id", "")
                          cwd = payload.get("cwd", "")

                          if status in NOTIFY_STATUSES and ws_id:
                              send_notification(status, label, ws_id, tab_id, cwd)


          def main() -> None:
              while True:
                  try:
                      if os.path.exists(SOCK_PATH):
                          subscribe(SOCK_PATH)
                  except (ConnectionRefusedError, FileNotFoundError, OSError):
                      pass
                  except Exception as e:
                      print(f"herdr-notifier: {e}", file=sys.stderr)
                  time.sleep(5)


          if __name__ == "__main__":
              main()
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
    })
  ];
}

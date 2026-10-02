# Setup and authentication

The wiki documents VPN access, macOS support, and Jupyter Labs as the supported
environment. Do not assume other platforms or editors support the same workflow.

## Install or upgrade

Only install if the CLI is missing; only upgrade when requested or needed to
resolve a demonstrated compatibility problem.

```bash
fdalabs --version
pipx install fda-labs-cli --pip-args="--pre --extra-index-url https://pypi.artifacts.furycloud.io/simple/"
pipx upgrade fda-labs-cli --pip-args="--pre --extra-index-url https://pypi.artifacts.furycloud.io/simple/"
```

Installation, upgrades, and API use require the corporate VPN. If installation
succeeds but the command is missing, use `pipx ensurepath`, restart the terminal,
and check the version. Do not change package managers silently if `pipx` is absent.

## Authentication

Token precedence is:

1. Global `--token` override.
2. `FDA_TOKEN` environment variable.
3. Saved token in `~/.fda-labs/config.json`.
4. `fury get-token` using an active Fury CLI session.

An expired saved token can trigger an automatic Fury refresh. An explicit flag
or environment token takes precedence over that saved token, so updating the
config will not fix a stale `FDA_TOKEN` override.

Try a scoped read command first. If it fails with authentication errors, check
the token source without printing its contents. If interactive SSO is necessary,
have the user run `fury get-token` in their own terminal and configure credentials
locally; do not ask them to paste a token into the conversation.

For temporary sessions use `FDA_TOKEN`. For persisted defaults the CLI supports:

```bash
fdalabs config set --app <application> --env prod
fdalabs config set --token <your-tiger-token>
fdalabs config show
```

The token command is a template for the user's terminal, not a request to place
credentials in a tracked file. Avoid capturing config output or debug logs in
shared artifacts unless sensitive values have been excluded.

Application resolution is explicit `--app` → `application_name` in the current
directory's `.fury` → saved config. Pass scope explicitly for operational commands
so the current directory cannot change the intended target.

## Global options

```bash
fdalabs [--env prod] [--token TOKEN] [--json] [--verbose] <command>
fdalabs --json apps
```

| Option | Meaning |
|---|---|
| `--env prod` / `--env stage` | API environment; use prod for ordinary usage unless another environment is requested |
| `--token` | Per-call credential override; prefer existing auth resolution |
| `--json` | Machine-readable output; also enabled by `FDALABS_JSON` |
| `--verbose` / `-v` | Debug logging; also enabled by `FDALABS_VERBOSE` |
| `--version` | Installed CLI version |

`apps` lists accessible Fury applications. Use it to resolve project scope when
needed, rather than guessing an application's name.

## Shell completion and VS Code

Completion installation appends a setup line to the shell rc file. For a preview:

```bash
fdalabs completion install --shell zsh --print-only
```

When installation is requested:

```bash
fdalabs completion install --shell zsh
fdalabs extension install
fdalabs extension install --code-path /path/to/code
```

Completion supports `bash`, `zsh`, and `fish`. Restart or source the indicated rc
file after installation. The extension command installs a bundled VSIX using
the `code` binary. If it is unavailable, use the VS Code command palette's
"Shell Command: Install 'code' command in PATH" or an explicit `--code-path`.

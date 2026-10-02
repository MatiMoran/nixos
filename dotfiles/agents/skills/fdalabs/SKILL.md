---
name: fdalabs
description: >
  Use the fdalabs (fda-labs-cli) CLI to manage FDA Labs and run Python remotely.
  Use when the user mentions fdalabs, FDA Labs, JupyterLab on Fury, starting or
  stopping a lab, running a script in a lab, lab job logs, uploading or fetching
  lab files, remote kernel resources, or SSH into a lab. Covers requests such as
  "corré esto en mi lab" and "activá mi lab" even without an explicit skill name.
  FDA pipeline task images, workflows, MPIs, and agendas belong to the fda skill.
metadata:
  version: "1.0.0"
  command: "/fdalabs"
---

# FDA Labs CLI

Operate FDA Labs using the installed `fdalabs` CLI directly. This is a personal
guide based on the team's wiki, organized around the task the user wants to
complete. Match the user's language when reporting results.

## Where to look

| Task | Read |
|---|---|
| Install, upgrade, authenticate, configure, shell completion, VS Code extension | [references/setup.md](references/setup.md) |
| List, inspect, create, activate, inactivate, or delete a lab | [references/labs.md](references/labs.md) |
| Run Python, retrieve job logs, transfer files, inspect or control the kernel | [references/execution.md](references/execution.md) |
| SSH connection, disconnect, proxy cleanup | [references/ssh.md](references/ssh.md) |

Read only the reference relevant to the current request. The bundled guidance
covers normal use without needing to open the wiki each session.

## Establish the target

Use the user's specified application and lab. If no project scope is established,
start with generic standalone labs:

```bash
fdalabs --json labs list --standalone
```

For a project application, use `fdalabs --json labs list --app <application>`.
Refresh lab state before an operational flow; a previous session's state may be
stale. Choose an existing lab when that satisfies the request. If multiple labs
are plausible, ask which one before executing on it.

Pass the scope explicitly. Generic standalone labs belong to application `labs`.
Use `--standalone` on commands that support it; use `--app labs` for `labs get`,
`labs delete`, and `kernel resources`. Creating one requires
`--app labs --type standalone`. Do not silently inherit an unrelated application's
`.fury` or saved defaults.

## CLI conventions that matter

- Global flags precede the command: `fdalabs --json labs list --standalone`.
  Prefer JSON for status inspection; summarize the useful fields in prose.
- Lifecycle syntax is `fdalabs labs <command> <lab-name>`. The stop command is
  `inactivate`. Execution syntax is `fdalabs run <script.py> --lab <lab-name>`.
- Select JupyterLab (`--editor jupyterlab`) for remote execution. The running lab
  must expose `fda-labs-executor`; activating a lab does not prove executor access.
- `run` resets the kernel by default. Explain the impact if the user is working
  with existing notebook state; use `--no-reset` when preserving it is intended.
- **`run --dry-run` executes the script remotely.** It only skips SQLite recording
  and Labs API notification, and implies background execution. Use `--help` for
  syntax inspection rather than this flag for a harmless preview.
- CLI confirmation flags such as `--yes` suppress terminal prompts; they do not
  replace any confirmation required by the user's instructions. Reuse existing
  authorization for ordinary requested operations. Obtain explicit confirmation
  before deletion, cleanup, overwrites, or discarding kernel state when required.

If the CLI is missing, read the setup reference. Otherwise try the requested
read operation before diagnosing authentication. Do not print tokens or read the
config file into the conversation to troubleshoot auth.

## Verify and report

After create or activate, inspect the final lab state (`running` before executing).
After inactivation, confirm `inactivated`; after deletion, confirm absence from
the scoped list. An accepted request is not a completed transition.

Background execution returns a job ID. Keep it and the target scope, then retrieve
logs to distinguish pending/running from completion and errors. A successful
submission or a zero exit code from a JSON logs query does not prove the script
succeeded. Check both job status and error output. Do not automatically rerun a
script after a timeout or connection loss: it may still be running.

Report the lab name, application, actual state, and job ID or artifact path when
relevant. Include the appropriate web link with lab status:

- Standalone: https://web.furycloud.io/ai/labs
- Project: `https://web.furycloud.io/engineering/applications/<application>/labs`

## Sources and command drift

Primary source: `~/Repos/Meli/wiki/wiki/guides/fdalabs-cli.md` (wiki commit
`b9869d8`, 2026-08-05), ingested from
[FDA Labs CLI documentation](https://furydocs.io/mlp-labs-documentation/latest/guide/#/cli).
Command signatures and noted behavior were checked against installed CLI
`1.4.0.post5` on 2026-10-02. The upstream documentation site was inaccessible
during that check; the wiki and installed CLI were used.

For a version mismatch, an unfamiliar flag, or behavior contradicting this guide,
check `fdalabs --version` and the affected command's `--help`. Use the installed
syntax and report meaningful differences. Consult the wiki or upstream docs only
when the bundled guide and CLI help do not answer the task.

# Execution, logs, files, and kernel

## Run a local Python script remotely

1. Inspect the scoped lab list and resolve the target.
2. If needed, activate that lab as JupyterLab and verify it is running.
3. Confirm the local script and any extra files exist. Choose foreground for a
   short interactive run, background for long work or when the runtime cannot
   keep streaming. Preserve an explicit user choice.
4. Submit with an explicit scope and `--lab` so execution targets the chosen lab.
5. Check output and status, retrieve requested artifacts, and report the outcome.

```bash
fdalabs run script.py --standalone --lab <lab-name>
fdalabs run script.py --app <application> --lab <lab-name>
fdalabs run script.py --standalone --lab <lab-name> --background
```

`run` takes the script as its single positional argument. The CLI can auto-select
a lab only when one lab is running; use `--lab` once a target is established.
The executor (`fda-labs-executor`) must be installed and reachable. Background
submission also requires executor access, so it does not bypass network failures.

With `--lab`, `run` offers an interactive activation prompt if the named lab is
not running. Activate explicitly before submission in an unattended flow;
`run` has no `--yes` flag to bypass that prompt. If a running lab uses the cloud
editor, explain the needed editor change before inactivating and reactivating it
as JupyterLab, since that transition interrupts the current session.

| Option | Behavior |
|---|---|
| `--requirements requirements.txt` | Install dependencies before execution |
| `--extra-file utils.py` | Send a local file; repeat for additional files |
| `--extra-dir modules/` | Send a directory recursively, excluding `.git`, `__pycache__`, `.venv`, and similar generated directories |
| `--background` / `-b` | Return a job ID for later logs rather than streaming to completion |
| `--no-reset` | Preserve existing kernel state; default execution resets it |
| `--timeout-hours` | Remote execution limit; help documents 4 hours by default and a maximum of 72 |
| `--dry-run` | Still execute remotely in background, skipping SQLite recording and Labs API notification |

Example with dependencies and supporting code:

```bash
fdalabs run script.py --standalone --lab <lab-name> --requirements requirements.txt --extra-file config.json --extra-dir modules/ --background
```

Upload only the files the script needs. Check for credentials before sending a
whole directory. This command executes the supplied script with the lab's access;
respect the user's authorization for its own external side effects.

For an existing notebook session, explain that the default reset discards kernel
variables. Preserve state with `--no-reset` if that matches the request. Interrupting
or restarting a kernel can affect someone else's work; identify the intended lab
and follow the applicable confirmation rules before discarding state.

`Ctrl+C` in a foreground run sends a stop signal to the remote kernel. Disconnecting
from a background submission does not establish that the job stopped. If a run
loses its connection, inspect status before considering a retry to avoid duplicate
side effects.

After a job finishes, offer inactivation when appropriate; do not automatically
stop a lab the user may still be using.

## Retrieve background logs

```bash
fdalabs --json logs <job-id> --standalone
fdalabs --json logs <job-id> --app <application>
```

Use the scope of the original submission. `logs` retrieves buffered output; it
does not continuously follow it. Inspect both the reported status and errors in
`output`: pending/running is not completion, and JSON mode can return zero even
when the result contains execution errors. Preserve an unknown state as unknown.

This CLI version requires the job entry in local `~/.fda-labs/jobs.json`.
A job ID alone may not work from a different machine or after that registry is
lost. Report this limitation instead of resubmitting the job. Do not modify or
copy credential files to recover it.

## Transfer files

```bash
fdalabs upload data.csv --standalone --lab <lab-name>
fdalabs upload src/ project/libs --standalone --lab <lab-name>
fdalabs fetch results.csv --standalone --lab <lab-name>
fdalabs fetch output/ /tmp/run42 --standalone --lab <lab-name>
```

For project labs replace `--standalone` with `--app <application>`.

| Command | Path meaning |
|---|---|
| `upload LOCAL [REMOTE]` | REMOTE is relative to the lab's home; default is the local basename directly under home |
| `upload src/ project/libs` | Destination is `~/project/libs/src/` |
| `fetch REMOTE [LOCAL]` | REMOTE is relative to home or absolute; LOCAL is a destination directory, defaulting to the current directory |
| `fetch output/ /tmp/run42` | Destination is `/tmp/run42/output/` |

Directories transfer recursively. Inspect the destination when possible and use
a fresh destination for fetched artifacts to avoid accidental overwrites. Follow
explicit confirmation requirements if existing files would be replaced. Confirm
the resulting local artifact exists before reporting a successful download.

## Kernel management

Read resource usage without changing state:

```bash
fdalabs --json kernel resources --app labs --lab <lab-name>
fdalabs --json kernel resources --app <application> --lab <lab-name>
```

This reports CPU, memory, disk, and GPU. Warning thresholds default to 85% memory
and 90% disk; adjust with `--warn-memory` and `--warn-disk` if requested.
`kernel resources` does not support `--standalone`.

When interrupt or restart is authorized:

```bash
fdalabs kernel interrupt --standalone --lab <lab-name>
fdalabs kernel restart --standalone --lab <lab-name>
```

Replace scope for project labs as above. Interrupt requests cancellation of the
current execution. Restart discards all kernel state and releases allocated memory.
Do not restart automatically merely because resource usage is high.

## Diagnose execution issues

| Symptom | Next action |
|---|---|
| No running lab, wrong lab, or ambiguous selection | Refresh the scoped list; activate or select the intended lab |
| Executor missing, HTTP 404, or connection timeout | Check running state, JupyterLab editor, VPN, and executor reachability; background mode is not a fix |
| Busy kernel or HTTP 423 | Identify the running work; interrupt only if cancellation is intended |
| Memory pressure or lost state | Inspect resources and explain reset/restart behavior before changing state |
| Unknown job ID in logs | Check that submission occurred on this machine and retain the local registry |
| Script traceback or dependency failure | Report the actual failure, correct the demonstrated cause, and retry only within the user's intended execution scope |

If executor access remains unavailable, provide the returned JupyterLab URL or
the scoped Fury Labs page so the user can inspect the environment. Do not loop
through lab recreation or token changes without evidence that they address it.

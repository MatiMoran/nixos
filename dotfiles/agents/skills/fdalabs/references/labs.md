# Lab lifecycle

## Inspect and choose

```bash
fdalabs --json labs list --standalone
fdalabs --json labs get <lab-name> --app labs
fdalabs --json labs list --app <application>
fdalabs --json labs get <lab-name> --app <application>
```

Keep the scope consistent throughout a flow. Use the returned state and URL
instead of assuming a remembered lab is still running. Do not create or change
compute size merely to answer a status question.

## Create

Generic standalone (no repository):

```bash
fdalabs labs create <lab-name> --app labs --type standalone --flavor small --wait --yes
```

Project lab (`full` type, using `fury_<application>`):

```bash
fdalabs labs create <lab-name> --app <application> --type full --branch <branch> --flavor small --wait --yes
```

`NAME` is positional; there is no `--name` flag. `full` is the CLI default and
requires a branch. Standalone create has no `--standalone` flag: specify
`--app labs --type standalone` to avoid inheriting a project from `.fury`.

Choose name, branch, and compute size from the request and workload. If resource
needs are unknown and materially affect cost or feasibility, ask before creation.
`small` above is an example, not a mandatory default. Creation already starts the
lab; inspect it before deciding another activation is necessary.

| Option | Behavior |
|---|---|
| `--flavor` | Installed CLI supports `tiny`, `small`, `medium`, `large`, `xlarge`, `xxlarge`, `gpu`; default is `tiny` |
| `--python-version` | `3.10`, `3.11`, `3.12`; default is `3.11` |
| `--no-snapshot` | Disable snapshot restore on activation |
| `--no-install-packages` | Disable package installation on activation |
| `--wait` | Poll until the lab leaves a transitional state |
| `--yes` | Skip the terminal confirmation after parameters are authorized |

The wiki lists GPU for activation only; CLI `1.4.0.post5` also accepts it for
creation. Acceptance of a flag does not guarantee available quota or capacity.

## Activate or inactivate

```bash
fdalabs labs activate <lab-name> --standalone --editor jupyterlab --wait
fdalabs labs activate <lab-name> --app <application> --editor jupyterlab --wait
fdalabs labs inactivate <lab-name> --standalone
fdalabs labs inactivate <lab-name> --app <application>
```

Optional activation flags: `--flavor`, `--snapshot`, `--install-packages`.
Editors are `jupyterlab` and `cloud`; choose JupyterLab for execution via the CLI.
Activation does not support `--yes`; do not transfer flags from create to activate.

States include `pending`, `reactivating`, `inactivating`, `running`, `inactivated`,
and `error`. `--wait` can return after reaching a stable state other than running;
verify `running` before executing. The CLI poller can continue through repeated
request errors: use bounded monitoring, report unresolved state, and keep the
user informed rather than treating an indefinite wait as success.

Inactivation has no `--wait`: inspect with scoped `labs get` or `labs list` after
the request. If a state change returns HTTP 429, honor the retry delay and refresh
state before retrying; avoid back-to-back inactivate/activate requests.

## Delete

Inspect the exact application and lab and obtain explicit deletion confirmation
under the user's instructions. After confirmation:

```bash
fdalabs labs delete <lab-name> --app labs --yes
fdalabs labs delete <lab-name> --app <application> --yes
```

Deletion has no `--standalone` flag. Verify absence with a scoped list. Do not
delete and recreate as an automatic response to a naming conflict or startup error.

## Diagnose lifecycle errors

| Symptom | Next action |
|---|---|
| Lab not found | Refresh the scoped list and verify the name and application |
| Create conflicts with an existing name | Inspect the existing lab; reuse it if appropriate or choose another name |
| `pending` or `reactivating` persists | Report the observed state and web link; inspect again with bounded monitoring |
| API auth/network error | Check VPN and authentication using the setup reference |
| Transition enters `error` | Stop dependent execution and report the available error details |

For a failed or uncertain mutating request, refresh state before retrying. A
network error may occur after the API has accepted the operation.

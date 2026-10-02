# SSH access and cleanup

Inspect the intended lab first and verify it is running. `connect` creates an
ephemeral SSH key, registers it with the executor, starts a WebSocket proxy,
adds an SSH host entry, and opens an interactive shell.

```bash
fdalabs connect <lab-name> --standalone
fdalabs connect <lab-name> --app <application>
fdalabs connect <lab-name> --app <application> --path /alloc/data/fury_<application>/notebooks
```

Use an interactive terminal when the user wants a shell. If the runtime cannot
maintain one, provide the exact scoped command for the user's terminal rather
than leaving a background interactive session stuck on input. Use `run` for a
requested Python script that does not require an interactive SSH session.

Default remote directories are `/home/melibuntu` for `--standalone` and
`/alloc/data/fury_<application>` for project scope. Specify `--path` when needed.

## Disconnect and cleanup

These operations kill proxies and remove associated SSH artifacts. Follow the
user's explicit confirmation requirement before destructive cleanup.

For one lab, prefer targeted disconnect after confirmation:

```bash
fdalabs disconnect <lab-name> --standalone
fdalabs disconnect <lab-name> --app <application>
```

If broader cleanup is required and confirmed:

```bash
fdalabs clean --yes
```

`clean` removes all proxies, SSH keys, and config entries created by this CLI,
affecting other lab connections too. It is not the equivalent of stopping a lab;
use `labs inactivate` for that request.

For "SSH proxy already running", inspect the intended connection and propose
targeted disconnect rather than cleaning every session automatically. For a
missing lab or executor error, check scope and running state before trying cleanup.

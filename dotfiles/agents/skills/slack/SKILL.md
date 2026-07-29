---
name: slack
description: >
  Work with Slack conversations for Mercado Libre workflows. Use this skill
  whenever the user invokes /slack or asks to polish/rewrite a Slack message,
  review tone before sending, read or use Slack thread context, export/download
  Slack channel messages with complete threads, fetch daily relevant Slack
  activity, summarize Slack conversations, update Slack aliases, or use known
  coworker/channel context. Trigger on: /slack, "revisame este mensaje",
  "mejorá este slack", "corregime esto para mandar", "pulí este mensaje",
  "está bien este mensaje", "cómo puedo decir esto mejor", "suena raro esto",
  "exportar hilos de slack", "descargar hilos de slack", "fetch slack threads",
  "slack export", "leer hilos completos de slack", "exportar actividad de
  slack", "descargar mensajes de slack", "slack all", "slack fetch",
  "resumime esta conversación de slack", or any request involving Slack message
  context, coworkers, channels, exports, or message polishing.
---

# Slack

Interact with Slack as a general workspace skill. Route each request to the
smallest feature that solves it: polish a message, export full channel threads,
export daily activity, summarize downloaded context, or use coworker/channel
context.

Do not polish or rewrite Slack content unless the user explicitly asks for that.
When reading or exporting Slack data, preserve the original content and report
authentication/scope errors without asking the user to paste tokens into chat.

---

## Shared Context

Use `scripts/context.json` as the single source of truth for:

- `user`: the user's Slack ID, username, and display name.
- `audiences.people`: known people, Slack IDs, handles, technical level,
  relationship context, and tone guidance.
- `audiences.groups`: known groups, technical level, relationship context, and
  tone guidance.
- `audiences.channels`: known channels, channel IDs, whether each channel is
  monitored by the daily exporter, technical level, context, and tone guidance.

Read `scripts/context.json` before polishing messages for a known person,
group, or channel; before summarizing downloaded Slack conversations; and when
an export needs aliases or monitored channels.

If a new person, group, or channel should be remembered, ask before editing
`scripts/context.json`. Add the entry under `audiences.people`,
`audiences.groups`, or `audiences.channels`. For people, store Slack IDs in
`audiences.people[].slack_id` when known; scripts derive aliases from those
fields. For channels, set `audiences.channels[].monitored` to `true` only when
the daily activity exporter should include that channel.

---

## Feature: Polish Slack Messages

Use this when the user wants to review, improve, soften, shorten, or rewrite a
message before sending it to Slack.

### Input Modes

- Direct text: improve the pasted message.
- Slack URL or message ID: use available Slack tooling to read the thread, then
  improve the specific message the user wants to send.

For Slack permalinks, the channel is the segment after `/archives/`; the
timestamp is the numeric part after `/p` with a dot after the 10th digit.

### Audience Handling

1. Read `scripts/context.json`.
2. Match the recipient by person, group, channel name, handle, or channel ID.
3. If known, apply the saved technical level, relationship context, and tone.
4. If unknown and the audience matters, ask:
   > "¿A quién va dirigido? ¿Su nombre/handle y si es técnico/a, semi-técnico/a o no técnico/a?"

Technical levels:

- `Técnico`: engineers, data scientists, infra; keep shared jargon.
- `Semi-técnico`: PMs, designers, analysts; explain only code-level details.
- `No técnico`: stakeholders, business, external audiences; use plain language.

### Polish Rules

- Keep it brief; remove filler, repetition, and hedges.
- Use natural Argentine Spanish with voseo: "podés", "hacés", "sabés".
- Prefer simple local phrasing: "¿le podés echar un ojo?", "dale una mirada",
  "mil gracias".
- Do not invent unusual idioms to sound Argentine.
- Do not add "gracias" or "mil gracias" after a statement that assumes
  compliance. It is fine after a direct open question.
- For one-on-one messages, add a warm casual greeting with the name when natural,
  unless the original already has one or the context is urgent.
- Include enough context so the reader knows which ticket, PR, meeting, alert,
  date, or decision is being referenced.
- Preserve shared English technical terms such as IMHO, CPC, throttler, DSP,
  ETA, and LGTM.
- Adjust technical depth to the audience.
- If the message is already good, say so and make only minor fixes.

### Polish Output

Use this exact shape:

---
**Mensaje mejorado**
```text
[el mensaje corregido, listo para copiar]
```

**Cambios realizados**
- **[Categoría]**: [qué se cambió en una frase] -> *Por qué: [razón breve]*

---

Use 2 to 6 bullets. Categories: `Brevedad`, `Tono`, `Voz argentina`,
`Contexto`, `Ortografía`, `Gramática`, `Estructura`, `Nivel técnico`,
`Claridad`.

If the input came from a Slack thread, add one context line before the improved
message:

```text
Canal: #nombre | Visibilidad: público/privado/DM | Participantes: @a, @b
```

---

## Feature: Export Full Slack Threads

Use `scripts/export_slack_threads.py` when the user asks to export, download,
fetch, read, or save Slack channel messages with complete thread replies.

Command shape:

```bash
python /Users/matmoran/nixos/dotfiles/agents/skills/slack/scripts/export_slack_threads.py export CHANNEL_ID --from YYYY-MM-DD --to YYYY-MM-DD -o output.md
```

Behavior:

- Reads `SLACK_TOKEN` from the environment or `.env` next to the script.
- Reads aliases from `audiences.people[].slack_id` in `scripts/context.json`.
- Requires `channels:history` for public channels, `groups:history` for private
  channels, and `users:read` only when resolving aliases.
- Uses `conversations.history` for parent messages and `conversations.replies`
  for thread replies.
- Excludes messages whose raw text starts with `[TEST]` and skips Slack system
  subtypes such as joins, leaves, topic changes, and purpose changes.
- Writes Markdown with message headers, attachment fields, body text, and
  replies.

Use this exporter when the user needs complete channel history and replies for a
specific channel/date range.

---

## Feature: Export Daily Slack Activity

Use `scripts/export_slack_activity.py` when the user asks for the daily Slack
activity workflow: fetch relevant messages for a date, store JSONL, and format a
readable Markdown digest.

Command shapes:

```bash
python /Users/matmoran/nixos/dotfiles/agents/skills/slack/scripts/export_slack_activity.py all YYYY-MM-DD -o output.md
python /Users/matmoran/nixos/dotfiles/agents/skills/slack/scripts/export_slack_activity.py fetch YYYY-MM-DD
python /Users/matmoran/nixos/dotfiles/agents/skills/slack/scripts/export_slack_activity.py format YYYY-MM-DD -o output.md
```

Behavior:

- Reads `SLACK_TOKEN` from the environment or `.env` next to the script.
- Reads `scripts/context.json` for `user`, monitored channels from
  `audiences.channels[].monitored`, and aliases from
  `audiences.people[].slack_id`.
- Requires `search:read` for `fetch`; `users:read` is needed for `aliases`.
- Writes `slack_YYYY-MM-DD.jsonl` in the current working directory, then formats
  from that file.
- Uses Slack search for messages involving the configured user and channels; it
  does not fetch complete channel history.

Use `export_slack_threads.py` instead when the user needs every message and
every reply from a specific channel/date range.

---

## Feature: Aliases

Both scripts expose `aliases` commands. Use them when the user asks to inspect
or refresh Slack display names.

```bash
python /Users/matmoran/nixos/dotfiles/agents/skills/slack/scripts/export_slack_activity.py aliases --show
python /Users/matmoran/nixos/dotfiles/agents/skills/slack/scripts/export_slack_activity.py aliases --force
python /Users/matmoran/nixos/dotfiles/agents/skills/slack/scripts/export_slack_threads.py aliases --show
```

Alias updates write Slack IDs into `audiences.people` in `scripts/context.json`.
Do not overwrite hand-curated audience context while updating aliases.

---

## Failure Modes

- Missing token: report that `SLACK_TOKEN` is missing from the environment or
  the script-local `.env`.
- Missing scope: report the scope named by Slack and which feature needs it.
- Rate limit: let the script wait and continue.
- Slack URL auth failure during polish: ask the user to paste the message text
  directly.
- Unknown audience: ask only for the recipient name/handle and technical level.

#!/usr/bin/env python3
"""
export_slack_threads.py — Exporta mensajes de un canal de Slack con sus hilos completos a Markdown.

COMANDOS:
  export  CHANNEL_ID [--from YYYY-MM-DD] [--to YYYY-MM-DD] [-o FILE]
  aliases [--show]

EJEMPLOS:
  python export_slack_threads.py export C05D6AERCLB --from 2026-07-01 --to 2026-07-03
  python export_slack_threads.py export C05D6AERCLB --from 2026-07-01 --to 2026-07-03 -o alertas.md
  python export_slack_threads.py aliases --show

CONFIGURACION:
  context.json        ->  user, audiences
  .env               ->  SLACK_TOKEN=<token> (opcional, junto a este script)
  entorno            ->  SLACK_TOKEN=<token>

SCOPES NECESARIOS en tu Slack app:
  channels:history   (canales publicos)
  groups:history     (canales privados)
  users:read         (para aliases)

FILTROS:
  - Mensajes cuyo text empieza con [TEST] se excluyen automaticamente
  - Mensajes de sistema (joins, leaves) se excluyen automaticamente
"""

import os
import sys
import json
import time
import re
import urllib.request
import urllib.parse
import urllib.error
from datetime import date, datetime, timezone, timedelta
from pathlib import Path

# ── Paths ──────────────────────────────────────────────────────────────────────

SCRIPTS_DIR = Path(__file__).parent
CONFIG_PATH = SCRIPTS_DIR / "context.json"

# ── Cargar .env ────────────────────────────────────────────────────────────────

def _load_env(path: Path):
    if not path.exists():
        return
    for line in path.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            key, val = line.split("=", 1)
            os.environ.setdefault(key.strip(), val.strip())

_load_env(SCRIPTS_DIR / ".env")

# ── Cargar config ──────────────────────────────────────────────────────────────

def load_config() -> dict:
    return json.loads(CONFIG_PATH.read_text()) if CONFIG_PATH.exists() else {}

def save_config(cfg: dict):
    CONFIG_PATH.write_text(json.dumps(cfg, indent=2, ensure_ascii=False) + "\n")

def aliases_from_context(config: dict) -> dict[str, str]:
    return {
        person["slack_id"]: person["name"]
        for person in config.get("audiences", {}).get("people", [])
        if person.get("slack_id") and person.get("name")
    }

def save_aliases_to_context(config: dict, aliases: dict[str, str]):
    audiences = config.setdefault("audiences", {})
    people = audiences.setdefault("people", [])
    by_slack_id = {person.get("slack_id"): person for person in people if person.get("slack_id")}
    by_name = {person.get("name"): person for person in people if person.get("name")}

    for slack_id, name in sorted(aliases.items(), key=lambda item: item[1]):
        if slack_id in by_slack_id:
            by_slack_id[slack_id]["name"] = name
            continue
        if name in by_name:
            by_name[name]["slack_id"] = slack_id
            continue
        people.append({
            "name": name,
            "slack_id": slack_id,
            "handle": None,
            "level": "Semi-técnico",
            "context": "Alias agregado automáticamente desde Slack; completar contexto cuando sea necesario."
        })

CONFIG       = load_config()
USER_CONFIG  = CONFIG.get("user", {})
MY_USER_ID   = USER_CONFIG.get("id", "")
USER_ALIASES = aliases_from_context(CONFIG)
SLACK_TOKEN  = os.environ.get("SLACK_TOKEN", "")
ARG_TZ       = timezone(timedelta(hours=-3))
SLEEP        = 2.0

# ── API ────────────────────────────────────────────────────────────────────────

def slack_get(method: str, params: dict, retries: int = 5) -> dict:
    url = f"https://slack.com/api/{method}?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={
        "Authorization": f"Bearer {SLACK_TOKEN}",
        "User-Agent": "slack-thread-export/1.0",
    })
    for _ in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read().decode())
            if not data.get("ok"):
                err = data.get("error", "unknown")
                if err == "missing_scope":
                    needed = data.get("needed", "?")
                    raise RuntimeError(
                        f"Falta scope '{needed}' en tu token.\n"
                        f"  Ir a: api.slack.com/apps -> OAuth & Permissions -> Scopes -> agregar '{needed}'"
                    )
                raise RuntimeError(f"Slack API error en {method}: {err}")
            return data
        except urllib.error.HTTPError as e:
            if e.code == 429:
                wait = int(e.headers.get("Retry-After", 60))
                print(f"  Rate limit — esperando {wait}s...", flush=True)
                time.sleep(wait + 2)
            else:
                raise
    raise RuntimeError(f"Reintentos agotados para {method}")

# ── Utilidades ─────────────────────────────────────────────────────────────────

def ts_to_local(ts_str: str) -> str:
    return datetime.fromtimestamp(float(ts_str), tz=ARG_TZ).strftime("%Y-%m-%d %H:%M")

def clean_text(text: str) -> str:
    text = re.sub(r"<@[A-Z0-9]+\|([^>]+)>", r"@\1",   text)
    text = re.sub(r"<@([A-Z0-9]+)>",         r"@\1",   text)
    text = re.sub(r"<#[A-Z0-9]+\|([^>]+)>",  r"#\1",   text)
    text = re.sub(r"<(https?://[^|>]+)\|([^>]+)>", r"\2", text)
    text = re.sub(r"<(https?://[^>]+)>",      r"\1",    text)
    text = re.sub(r"^(#+)", r"\\\1", text, flags=re.MULTILINE)
    return text.strip()

def resolve_name(user_id: str, username: str = "") -> str:
    if user_id in USER_ALIASES:
        return USER_ALIASES[user_id]
    return username or (user_id[:8] if user_id else "?")


def extract_content(m: dict) -> dict:
    """Extrae titulo, cuerpo y fields de un mensaje, incluyendo attachments de bots como Datadog."""
    text = clean_text(m.get("text", ""))

    attachments = m.get("attachments", [])
    if attachments:
        att = attachments[0]
        title  = clean_text(att.get("title", "") or att.get("fallback", ""))
        body   = clean_text(att.get("text", ""))
        fields = [
            f"{f.get('title', '')}: {f.get('value', '')}"
            for f in att.get("fields", [])
            if f.get("title") or f.get("value")
        ]
        # si text del mensaje tiene algo extra, lo agrega al body
        if text and text != title:
            body = f"{text}\n\n{body}".strip() if body else text
        return {"title": title or text, "body": body, "fields": fields}

    # mensaje de texto plano (replies humanas, etc.)
    return {"title": text, "body": text, "fields": []}

# ═══════════════════════════════════════════════════════════════════════════════
# COMANDO: export
# ═══════════════════════════════════════════════════════════════════════════════

SKIP_SUBTYPES = {"channel_join", "channel_leave", "channel_purpose", "channel_topic", "bot_add"}


def fetch_channel_messages(channel_id: str, oldest_ts: float, latest_ts: float) -> list[dict]:
    all_messages, cursor, page = [], None, 1
    while True:
        params: dict = {
            "channel":   channel_id,
            "oldest":    str(oldest_ts),
            "latest":    str(latest_ts),
            "limit":     100,
            "inclusive": "true",
        }
        if cursor:
            params["cursor"] = cursor
        data = slack_get("conversations.history", params)
        msgs = [m for m in data.get("messages", []) if m.get("subtype") not in SKIP_SUBTYPES]
        all_messages.extend(msgs)
        cursor = data.get("response_metadata", {}).get("next_cursor")
        print(f"  pag {page} — {len(all_messages)} mensajes", flush=True)
        if not data.get("has_more") or not cursor:
            break
        page += 1
        time.sleep(SLEEP)
    return all_messages


def fetch_thread_replies(channel_id: str, thread_ts: str) -> list[dict]:
    replies, cursor, first_page = [], None, True
    while True:
        params: dict = {"channel": channel_id, "ts": thread_ts, "limit": 200}
        if cursor:
            params["cursor"] = cursor
        data = slack_get("conversations.replies", params)
        msgs = data.get("messages", [])
        if first_page:
            msgs = msgs[1:]  # el primer elemento es el mensaje padre, se saltea
            first_page = False
        replies.extend(msgs)
        cursor = data.get("response_metadata", {}).get("next_cursor")
        if not data.get("has_more") or not cursor:
            break
        time.sleep(SLEEP)
    return replies


def format_export_md(messages: list[dict], channel_id: str, date_from: str, date_to: str) -> str:
    lines = [
        f"# Slack export `{channel_id}`",
        f"**Periodo:** {date_from} -> {date_to}",
        f"**Exportado:** {date.today().isoformat()}",
        f"**Total mensajes:** {len(messages)}",
        "",
        "---",
    ]
    for m in messages:
        dt_str  = ts_to_local(m.get("ts", "0"))
        content = extract_content(m)
        preview = content["title"][:80].replace("\n", " ").strip()

        lines += ["", f"## [{dt_str}] {preview}", ""]

        if content["fields"]:
            for f in content["fields"]:
                lines.append(f"**{f}**")
            lines.append("")

        lines += ["**Mensaje:**", "", content["body"] or "_sin contenido_", ""]

        replies = m.get("_replies", [])
        if replies:
            lines.append(f"**Replies ({len(replies)}):**")
            lines.append("")
            for r in replies:
                r_time = ts_to_local(r.get("ts", "0")).split(" ")[1]
                r_name = resolve_name(r.get("user", ""), r.get("username", ""))
                r_text = clean_text(r.get("text", ""))
                lines.append(f"- [{r_time}] **@{r_name}**: {r_text}")
            lines.append("")

        lines.append("---")
    return "\n".join(lines)


def cmd_export(channel_id: str, date_from: str, date_to: str, output: Path):
    if not SLACK_TOKEN:
        print("ERROR: Falta SLACK_TOKEN en .env"); sys.exit(1)

    oldest_ts = datetime.strptime(date_from, "%Y-%m-%d").replace(tzinfo=timezone.utc).timestamp()
    latest_ts = (
        datetime.strptime(date_to, "%Y-%m-%d").replace(tzinfo=timezone.utc) + timedelta(days=1)
    ).timestamp()

    print(f"\nExportando mensajes de {channel_id}  ({date_from} -> {date_to})\n")
    all_messages = fetch_channel_messages(channel_id, oldest_ts, latest_ts)
    print(f"Total descargados: {len(all_messages)}")

    filtered = [m for m in all_messages if not m.get("text", "").startswith("[TEST]")]
    skipped  = len(all_messages) - len(filtered)
    print(f"Filtrados [TEST]: {skipped} | Mensajes restantes: {len(filtered)}")

    filtered.sort(key=lambda m: float(m.get("ts", "0")))

    with_replies = sum(1 for m in filtered if m.get("reply_count", 0) > 0)
    print(f"\nFetcheando {with_replies} threads...\n")
    for i, m in enumerate(filtered):
        if m.get("reply_count", 0) > 0:
            print(f"  [{i+1}/{len(filtered)}] {ts_to_local(m['ts'])} — {m['reply_count']} replies", flush=True)
            m["_replies"] = fetch_thread_replies(channel_id, m["ts"])
            time.sleep(SLEEP)
        else:
            m["_replies"] = []

    md = format_export_md(filtered, channel_id, date_from, date_to)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(md, encoding="utf-8")
    print(f"\n✓ {output}  ({len(filtered)} mensajes, {with_replies} con threads)")

# ═══════════════════════════════════════════════════════════════════════════════
# COMANDO: aliases
# ═══════════════════════════════════════════════════════════════════════════════

def best_name(user: dict) -> str:
    profile = user.get("profile", {})
    for field in ("display_name", "real_name", "name"):
        val = profile.get(field) or user.get(field, "")
        if val and val.strip():
            return val.strip()
    return user.get("id", "?")


def cmd_aliases(show: bool = False, force: bool = False):
    cfg      = load_config()
    existing = aliases_from_context(cfg)
    if show:
        if existing:
            for uid, name in sorted(existing.items(), key=lambda x: x[1]):
                print(f"  {name:30s} {uid}")
        else:
            print("No hay aliases guardados.")
        return
    if not SLACK_TOKEN:
        print("ERROR: Falta SLACK_TOKEN"); sys.exit(1)
    updated, new_count = ({} if force else dict(existing)), 0
    to_resolve = list(existing.keys())
    print(f"Resolviendo {len(to_resolve)} usuarios...")
    for uid in to_resolve:
        if not force and uid in updated:
            continue
        try:
            data = slack_get("users.info", {"user": uid})
            if data.get("ok"):
                name = best_name(data.get("user", {}))
                updated[uid] = name
                new_count += 1
                print(f"  {name:30s} <- {uid}")
        except Exception as e:
            print(f"  ERROR {uid}: {e}")
        time.sleep(0.5)
    save_aliases_to_context(cfg, updated)
    save_config(cfg)
    print(f"\n✓ context.json — {new_count} actualizados, {len(updated)} total")

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

def today() -> str:
    return date.today().strftime("%Y-%m-%d")


def _parse_flag(args: list[str], *flags: str) -> tuple[str | None, list[str]]:
    rest = list(args)
    for flag in flags:
        if flag in rest:
            idx = rest.index(flag)
            if idx + 1 >= len(rest):
                print(f"ERROR: {flag} requiere un argumento"); sys.exit(1)
            val = rest[idx + 1]
            del rest[idx:idx + 2]
            return val, rest
    return None, rest


def usage():
    print(__doc__); sys.exit(0)


def main():
    args = sys.argv[1:]
    if not args or args[0] in ("-h", "--help", "help"):
        usage()

    cmd, rest = args[0], args[1:]

    if cmd == "export":
        if not rest or rest[0].startswith("-"):
            print("ERROR: especifica el channel_id.\n"
                  "  Ej: python export_slack_threads.py export C05D6AERCLB --from 2026-07-01 --to 2026-07-03")
            sys.exit(1)
        channel_id, rest = rest[0], rest[1:]
        date_from, rest  = _parse_flag(rest, "--from")
        date_to,   rest  = _parse_flag(rest, "--to")
        output_str, rest = _parse_flag(rest, "-o", "--output")
        date_from = date_from or today()
        date_to   = date_to   or today()
        output    = (
            Path(output_str).expanduser()
            if output_str
            else Path.cwd() / f"slack_export_{channel_id}_{date_from}_{date_to}.md"
        )
        cmd_export(channel_id, date_from, date_to, output)

    elif cmd == "aliases":
        cmd_aliases(show="--show" in rest, force="--force" in rest)

    else:
        print(f"Comando desconocido: '{cmd}'"); usage()


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
export_slack_activity.py — CLI para descargar y formatear actividad diaria relevante de Slack.

COMANDOS:
  fetch   [FECHA]              Descarga mensajes del día y guarda como JSONL
  format  [FECHA] [-o FILE]    Convierte el JSONL a markdown legible
  aliases                      Actualiza los display names en context.json (solo agrega nuevos)
  all     [FECHA] [-o FILE]    fetch + format en un solo paso

  FECHA puede ser YYYY-MM-DD. Si se omite, usa hoy.
  -o FILE / --output FILE      Archivo de salida (default: ./conversations.md)

EJEMPLOS:
  python export_slack_activity.py all          # descarga y formatea el día de hoy
  python export_slack_activity.py all 2026-05-19
  python export_slack_activity.py all -o ~/notes/hoy.md
  python export_slack_activity.py fetch
  python export_slack_activity.py format
  python export_slack_activity.py format -o /tmp/slack.md
  python export_slack_activity.py aliases
  python export_slack_activity.py aliases --show
  python export_slack_activity.py aliases --force

CONFIGURACIÓN:
  context.json →  user, audiences
  .env         →  SLACK_TOKEN=<token> (opcional, junto a este script)
  entorno      →  SLACK_TOKEN=<token>

SCOPES NECESARIOS en tu Slack app:
  search:read   (para fetch)
  users:read    (para aliases)
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
from collections import defaultdict, Counter

# ── Paths ─────────────────────────────────────────────────────────────────────

SCRIPTS_DIR = Path(__file__).parent
CONFIG_PATH = SCRIPTS_DIR / "context.json"

# ── Cargar .env ───────────────────────────────────────────────────────────────

_env_path = SCRIPTS_DIR / ".env"
if _env_path.exists():
    for _line in _env_path.read_text().splitlines():
        _line = _line.strip()
        if _line and not _line.startswith("#") and "=" in _line:
            _key, _val = _line.split("=", 1)
            os.environ.setdefault(_key.strip(), _val.strip())

# ── Cargar config ─────────────────────────────────────────────────────────────

def load_config() -> dict:
    return json.loads(CONFIG_PATH.read_text()) if CONFIG_PATH.exists() else {}

def save_config(config: dict):
    CONFIG_PATH.write_text(json.dumps(config, indent=2, ensure_ascii=False) + "\n")

def aliases_from_context(config: dict) -> dict[str, str]:
    return {
        person["slack_id"]: person["name"]
        for person in config.get("audiences", {}).get("people", [])
        if person.get("slack_id") and person.get("name")
    }

def monitored_channels_from_context(config: dict) -> set[str]:
    channels = set()
    for channel in config.get("audiences", {}).get("channels", []):
        if not channel.get("monitored"):
            continue
        name = channel.get("name", "")
        if name.startswith("#"):
            name = name[1:]
        if name:
            channels.add(name)
    return channels

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
MY_USERNAME  = USER_CONFIG.get("username", "")
CHANNELS     = monitored_channels_from_context(CONFIG)
USER_ALIASES = aliases_from_context(CONFIG)
SLACK_TOKEN  = os.environ.get("SLACK_TOKEN", "")
ARG_TZ       = timezone(timedelta(hours=-3))
SLEEP        = 2.0

# ── API ───────────────────────────────────────────────────────────────────────

def slack_get(method: str, params: dict, retries: int = 5) -> dict:
    url = f"https://slack.com/api/{method}?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={
        "Authorization": f"Bearer {SLACK_TOKEN}",
        "User-Agent": "slack-cli/1.0",
    })
    for _ in range(retries):
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.loads(resp.read().decode())
            if not data.get("ok"):
                raise RuntimeError(f"Slack API error en {method}: {data.get('error')}")
            return data
        except urllib.error.HTTPError as e:
            if e.code == 429:
                wait = int(e.headers.get("Retry-After", 60))
                print(f"  Rate limit — esperando {wait}s...", flush=True)
                time.sleep(wait + 2)
            else:
                raise
    raise RuntimeError(f"Reintentos agotados para {method}")

# ═══════════════════════════════════════════════════════════════════════════════
# COMANDO: fetch
# ═══════════════════════════════════════════════════════════════════════════════

def search_all_pages(query: str, label: str) -> list[dict]:
    messages, page = [], 1
    while True:
        data    = slack_get("search.messages", {"query": query, "count": 100,
                            "page": page, "sort": "timestamp", "sort_dir": "asc"})
        msgs    = data.get("messages", {})
        matches = msgs.get("matches", [])
        messages.extend(matches)
        pages = msgs.get("paging", {}).get("pages", 1)
        total = msgs.get("paging", {}).get("total", 0)
        print(f"  [{label}] pág {page}/{pages} — {len(messages)}/{total}", flush=True)
        if page >= pages:
            break
        page += 1
        time.sleep(SLEEP)
    return messages


def fetch_relevant_messages(target_date: str) -> list[dict]:
    queries = [
        (f"from:<@{MY_USER_ID}> on:{target_date}", "enviados"),
        (f"to:me on:{target_date}",                "recibidos-dm"),
    ]
    for ch in CHANNELS:
        queries.append((f"in:#{ch} from:<@{MY_USER_ID}> on:{target_date}", f"#{ch}"))

    seen: dict[str, dict] = {}
    for query, label in queries:
        for msg in search_all_pages(query, label):
            ts = msg.get("ts", "")
            if ts and ts not in seen:
                seen[ts] = msg
    return list(seen.values())


def is_relevant(msg: dict) -> bool:
    ch = msg.get("channel", {})
    if ch.get("is_im") or ch.get("is_mpim"):
        return True
    return ch.get("name", "") in CHANNELS


def build_display_names(messages: list[dict]) -> dict[str, str]:
    others: dict[str, list] = defaultdict(list)
    channel_meta: dict[str, dict] = {}

    for m in messages:
        ch, uid, uname = m.get("channel", {}), m.get("user", ""), m.get("username", "")
        ch_id = ch.get("id", "")
        if ch_id not in channel_meta:
            channel_meta[ch_id] = ch
        if uid and uid != MY_USER_ID and uname:
            others[ch_id].append((uid, uname))

    labels: dict[str, str] = {}
    for ch_id, meta in channel_meta.items():
        ch_name = meta.get("name", "")
        if meta.get("is_im"):
            other_list = others.get(ch_id, [])
            if other_list:
                other_uid, other_uname = other_list[0]
                name = USER_ALIASES.get(other_uid) or other_uname
            else:
                name = ch_id
            labels[ch_id] = f"DM con {name}"
        elif meta.get("is_mpim"):
            slugs = re.sub(r"-\d+$", "", ch_name.replace("mpdm-", ""))
            raw_members = [s for s in re.split(r"--", slugs) if s != MY_USERNAME]
            alias_by_slug = {uname: USER_ALIASES[uid]
                             for uid, uname in others.get(ch_id, [])
                             if uid in USER_ALIASES}
            members = [alias_by_slug.get(s, s) for s in raw_members]
            labels[ch_id] = f"Group DM: {', '.join(members)}" if members else ch_name
        else:
            labels[ch_id] = f"#{ch_name}" if ch_name else ch_id
    return labels


def ts_to_local(ts_str: str) -> str:
    return datetime.fromtimestamp(float(ts_str), tz=ARG_TZ).strftime("%Y-%m-%d %H:%M:%S %z")


def clean_message(m: dict, display_names: dict[str, str]) -> dict:
    ch, ch_id = m.get("channel", {}), m.get("channel", {}).get("id", "")
    return {
        "ts":           m.get("ts", ""),
        "time":         ts_to_local(m.get("ts", "0")),
        "channel_id":   ch_id,
        "channel_name": ch.get("name", ""),
        "display_name": display_names.get(ch_id, ch.get("name", "") or ch_id),
        "channel_type": "im" if ch.get("is_im") else "mpim" if ch.get("is_mpim") else "channel",
        "user_id":      m.get("user", ""),
        "username":     m.get("username", ""),
        "text":         m.get("text", ""),
        "permalink":    m.get("permalink", ""),
        "reply_count":  m.get("reply_count", 0),
    }


def cmd_fetch(target_date: str):
    if not SLACK_TOKEN:
        print("ERROR: Falta SLACK_TOKEN en .env"); sys.exit(1)
    if not MY_USER_ID:
        print("ERROR: Falta user.id en context.json"); sys.exit(1)

    output_path = Path.cwd() / f"slack_{target_date}.jsonl"
    print(f"\nFetcheando mensajes del {target_date}...")
    print(f"Canales: {CHANNELS or '(ninguno)'}\n")

    raw      = fetch_relevant_messages(target_date)
    relevant = [m for m in raw if is_relevant(m)]
    print(f"\nDescargados: {len(raw)} | Relevantes: {len(relevant)}")

    display_names = build_display_names(relevant)
    cleaned = sorted([clean_message(m, display_names) for m in relevant],
                     key=lambda x: float(x["ts"] or 0))

    with open(output_path, "w", encoding="utf-8") as f:
        for msg in cleaned:
            f.write(json.dumps(msg, ensure_ascii=False) + "\n")

    print(f"\n✓ {output_path.name}")
    counts = Counter(m["display_name"] for m in cleaned)
    for label, n in sorted(counts.items(), key=lambda x: -x[1]):
        print(f"  {label}: {n} mensajes")

    return output_path

# ═══════════════════════════════════════════════════════════════════════════════
# COMANDO: format
# ═══════════════════════════════════════════════════════════════════════════════

def short_name(user_id: str, username: str) -> str:
    if user_id == MY_USER_ID:
        return "Mati"
    if user_id in USER_ALIASES:
        return USER_ALIASES[user_id].split()[0]
    return (username or user_id[:8]).split()[0].capitalize()


def clean_text(text: str) -> str:
    text = re.sub(r"<@[A-Z0-9]+\|([^>]+)>", r"@\1", text)
    text = re.sub(r"<@([A-Z0-9]+)>",         r"@\1", text)
    text = re.sub(r"<#[A-Z0-9]+\|([^>]+)>",  r"#\1", text)
    text = re.sub(r"<(https?://[^|>]+)\|([^>]+)>", r"\2", text)
    text = re.sub(r"<(https?://[^>]+)>",      r"\1",  text)
    text = re.sub(r"^(#+)", r"\\\1", text, flags=re.MULTILINE)
    return text.strip()


def load_messages(jsonl_path: Path) -> list[dict]:
    msgs = []
    with open(jsonl_path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                msgs.append(json.loads(line))
    return sorted(msgs, key=lambda x: float(x.get("ts") or 0))


def format_as_markdown(messages: list[dict], target_date: str) -> str:
    slug_to_alias: dict[str, str] = {
        m.get("username", ""): USER_ALIASES[m.get("user_id", "")]
        for m in messages
        if m.get("user_id", "") in USER_ALIASES and m.get("username")
    }

    by_channel: dict[str, list] = defaultdict(list)
    channel_label: dict[str, str] = {}
    for m in messages:
        ch_id = m.get("channel_id", "")
        channel_label[ch_id] = m.get("display_name") or m.get("channel_name") or ch_id
        by_channel[ch_id].append(m)

    ordered = sorted(by_channel.items(), key=lambda kv: float(kv[1][0].get("ts") or 0))

    lines = [f"# Slack — {target_date}", "",
             f"_{len(messages)} mensajes · {len(by_channel)} conversaciones_", "", "---"]

    for ch_id, msgs in ordered:
        label = channel_label[ch_id]
        if label.startswith("DM con "):
            for m in msgs:
                uid = m.get("user_id", "")
                if uid != MY_USER_ID and uid in USER_ALIASES:
                    label = f"DM con {USER_ALIASES[uid]}"
                    break
        elif label.startswith("Group DM: "):
            slugs_part = label[len("Group DM: "):]
            resolved   = [slug_to_alias.get(s, s) for s in slugs_part.split(", ")]
            label      = f"Group DM: {', '.join(resolved)}"

        lines += ["", f"## {label}", ""]
        for m in msgs:
            text = clean_text(m.get("text", ""))
            if not text:
                continue
            hhmm = (m.get("time", "") or "").split(" ")[1][:5]
            name = short_name(m.get("user_id", ""), m.get("username", ""))
            lines += [f"**{hhmm} — {name}**", text, ""]

    return "\n".join(lines)


DEFAULT_OUTPUT = Path.cwd() / "conversations.md"


def cmd_format(target_date: str, output: Path = DEFAULT_OUTPUT):
    jsonl_path = Path.cwd() / f"slack_{target_date}.jsonl"
    if not jsonl_path.exists():
        print(f"ERROR: No encontré {jsonl_path.name}")
        print(f"  Primero corré: python export_slack_activity.py fetch {target_date}")
        sys.exit(1)

    messages = load_messages(jsonl_path)
    print(f"Formateando {len(messages)} mensajes...")

    md = format_as_markdown(messages, target_date)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(md, encoding="utf-8")
    print(f"✓ {output}")
    print()
    for line in md.split("\n")[:50]:
        print(line)

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


def collect_user_ids(my_user_id: str) -> Counter:
    counts: Counter = Counter()
    for jsonl in SCRIPTS_DIR.glob("slack_*.jsonl"):
        with open(jsonl, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    m   = json.loads(line)
                    uid = m.get("user_id", "")
                    if uid and uid != my_user_id:
                        counts[uid] += 1
                except json.JSONDecodeError:
                    pass
    return counts


def cmd_aliases(show: bool = False, force: bool = False):
    config     = load_config()
    my_user_id = config.get("my_user_id", "")
    existing   = aliases_from_context(config)

    if show:
        if existing:
            print(f"Aliases actuales ({len(existing)}):")
            for uid, name in sorted(existing.items(), key=lambda x: x[1]):
                print(f"  {name:30s} {uid}")
        else:
            print("No hay aliases guardados todavía.")
        return

    if not SLACK_TOKEN:
        print("ERROR: Falta SLACK_TOKEN en .env"); sys.exit(1)

    # Verificar scope
    print("Verificando scope users:read...")
    test = slack_get("users.info", {"user": my_user_id or "USLACKBOT"})
    if not test.get("ok") and test.get("error") == "missing_scope":
        print("\n⚠️  Falta el scope 'users:read'.")
        print("   → api.slack.com/apps → tu app → OAuth & Permissions → users:read → Reinstalar")
        sys.exit(1)
    print("  ✓ Scope OK\n")

    counts = collect_user_ids(my_user_id)
    if not counts:
        print("No encontré JSONL. Corré primero: python export_slack_activity.py fetch"); sys.exit(1)

    updated = {} if force else dict(existing)
    new_count = 0

    print(f"{'Actualizando' if force else 'Agregando aliases nuevos'} ({len(counts)} usuarios)...")
    print(f"{'(--force: sobreescribe existentes)' if force else '(los aliases que editaste a mano no se tocan)'}\n")

    for uid, _ in counts.most_common():
        if not force and uid in updated:
            print(f"  {updated[uid]:30s} ← existente, sin cambios")
            continue
        user = None
        try:
            data = slack_get("users.info", {"user": uid})
            if data.get("ok"):
                user = data.get("user", {})
        except Exception as e:
            print(f"  ERROR {uid}: {e}")
        if user:
            name = best_name(user)
            updated[uid] = name
            new_count += 1
            print(f"  {name:30s} ← {'actualizado' if force else 'nuevo'}")
        time.sleep(0.5)

    save_aliases_to_context(config, updated)
    save_config(config)
    print(f"\n✓ context.json actualizado — {new_count} {'actualizados' if force else 'nuevos'}, {len(updated)} total")

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

def today() -> str:
    return date.today().strftime("%Y-%m-%d")


def usage():
    print(__doc__)
    sys.exit(0)


def _parse_output_flag(args: list[str]) -> tuple[Path, list[str]]:
    """Extrae -o/-–output FILE de args y devuelve (path, args_restantes)."""
    rest = list(args)
    for flag in ("-o", "--output"):
        if flag in rest:
            idx = rest.index(flag)
            if idx + 1 >= len(rest):
                print(f"ERROR: {flag} requiere un argumento"); sys.exit(1)
            path = Path(rest[idx + 1]).expanduser()
            del rest[idx:idx + 2]
            return path, rest
    return DEFAULT_OUTPUT, rest


def main():
    args = sys.argv[1:]
    if not args or args[0] in ("-h", "--help", "help"):
        usage()

    cmd  = args[0]
    rest = args[1:]

    if cmd == "fetch":
        cmd_fetch(rest[0] if rest else today())

    elif cmd == "format":
        output, rest = _parse_output_flag(rest)
        cmd_format(rest[0] if rest else today(), output=output)

    elif cmd == "all":
        output, rest = _parse_output_flag(rest)
        d = rest[0] if rest else today()
        cmd_fetch(d)
        print()
        cmd_format(d, output=output)

    elif cmd == "aliases":
        cmd_aliases(show="--show" in rest, force="--force" in rest)

    else:
        print(f"Comando desconocido: '{cmd}'")
        print("Comandos disponibles: fetch, format, all, aliases")
        print("Ayuda: python export_slack_activity.py --help")
        sys.exit(1)


if __name__ == "__main__":
    main()

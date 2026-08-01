#!/usr/bin/env python3
"""CLI helper para la lista de compras compartida (stdlib puro, sin dependencias).

Uso:
    lista.py add <item>          agregar item
    lista.py remove <item>       quitar item
    lista.py toggle <item>       marcar comprado/pendiente
    lista.py list                mostrar la lista
    lista.py clear-done          vaciar los items comprados
    lista.py clear-all           vaciar toda la lista

La fuente de verdad es ~/.local/share/lista-compras/lista.json
(override con la env var LISTA_COMPRAS_FILE, útil para tests).
"""
import json
import os
import sys
from pathlib import Path

# Ubicación canónica COMPARTIDA entre CLI (matias) y gateway (hermes).
# Ambos usuarios están en el grupo `hermes`, así que /var/lib/hermes es
# legible/escribible por los dos. NO usar Path.home(): depende de quién
# ejecuta el script y partiría la lista en dos.
DATA_FILE = Path(
    os.environ.get(
        "LISTA_COMPRAS_FILE",
        "/var/lib/hermes/lista-compras/lista.json",
    )
)


def load():
    if DATA_FILE.exists():
        return json.loads(DATA_FILE.read_text())
    return {"items": []}


def save(data):
    DATA_FILE.parent.mkdir(parents=True, exist_ok=True)
    try:
        os.chmod(DATA_FILE.parent, 0o2770)  # setgid + rwx grupo, accesible a matias y hermes
    except OSError:
        pass
    tmp = DATA_FILE.with_suffix(".tmp")
    tmp.write_text(json.dumps(data, ensure_ascii=False, indent=2))
    try:
        os.chmod(tmp, 0o660)  # group rw: el otro usuario puede escribir
    except OSError:
        pass
    tmp.replace(DATA_FILE)  # escritura atómica
    try:
        os.chmod(DATA_FILE, 0o660)
    except OSError:
        pass


def find(data, name):
    name = name.strip().lower()
    for i, item in enumerate(data["items"]):
        if item["name"].lower() == name:
            return i
    return None


def fmt(data):
    if not data["items"]:
        return "🛒 Lista vacía."
    lines = []
    for i, item in enumerate(data["items"], 1):
        mark = "✅" if item["done"] else "⬜"
        lines.append(f"{mark} {i}. {item['name']}")
    return "🛒 Lista de compras:\n" + "\n".join(lines)


def main():
    args = sys.argv[1:]
    if not args:
        print(fmt(load()))
        return 0
    cmd = args[0].lower()
    data = load()
    if cmd in ("add", "agregar"):
        if len(args) < 2:
            print("Uso: lista.py add <item>")
            return 2
        name = " ".join(args[1:]).strip()
        if find(data, name) is not None:
            print(f"Ya estaba en la lista: {name}")
            return 0
        data["items"].append({"name": name, "done": False})
        save(data)
        print(f"➕ Agregado: {name}")
    elif cmd in ("remove", "quitar", "del"):
        if len(args) < 2:
            print("Uso: lista.py remove <item>")
            return 2
        name = " ".join(args[1:]).strip()
        i = find(data, name)
        if i is None:
            print(f"No estaba en la lista: {name}")
            return 0
        data["items"].pop(i)
        save(data)
        print(f"➖ Eliminado: {name}")
    elif cmd in ("toggle", "marcar", "done"):
        if len(args) < 2:
            print("Uso: lista.py toggle <item>")
            return 2
        name = " ".join(args[1:]).strip()
        i = find(data, name)
        if i is None:
            print(f"No estaba en la lista: {name}")
            return 0
        data["items"][i]["done"] = not data["items"][i]["done"]
        save(data)
        state = "comprado ✅" if data["items"][i]["done"] else "pendiente ⬜"
        print(f"Marcado como {state}: {name}")
    elif cmd in ("list", "ver", "lista"):
        print(fmt(data))
    elif cmd in ("clear-done", "vaciar"):
        data["items"] = [i for i in data["items"] if not i["done"]]
        save(data)
        print("🧹 Comprados vaciados.")
    elif cmd in ("clear-all", "vaciar-todo"):
        save({"items": []})
        print("🗑 Lista vaciada.")
    else:
        print(f"Comando desconocido: {cmd}")
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())

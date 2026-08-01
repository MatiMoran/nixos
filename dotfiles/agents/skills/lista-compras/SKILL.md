---
name: lista-compras
description: Usar para ver/agregar/quitar/marcar la lista de compras.
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [shopping, lista, compras, telegram, hogar]
---

# Lista de Compras Compartida

Lista de compras del hogar, compartida entre Matías y su papá. Se usa desde Telegram o el CLI.

## Fuente de verdad

- Archivo: `/var/lib/hermes/lista-compras/lista.json` (canónico, COMPARTIDO entre CLI y gateway; NO usar `~` — el home del gateway es distinto del de matias)
- Formato: `{"items": [{"name": "leche", "done": false}, ...]}`
- `done: true` = ya comprado.
- Permisos: el script fija dir 2770 y archivo 0660 grupo `hermes` para que los dos usuarios (matias y hermes) puedan leer/escribir.
- Override para tests: env var `LISTA_COMPRAS_FILE`.

## Regla de oro

NUNCA editar el JSON a mano. Usar SIEMPRE el script `scripts/lista.py` de esta skill:

```
python3 <skill_dir>/scripts/lista.py <comando> [item...]
```

(`<skill_dir>` = directorio donde vive esta skill; el script es stdlib puro, no requiere pip ni venv.)

## Operaciones

| Pedido del usuario | Comando a correr |
|---|---|
| "agregá leche" / "+leche" / "hay que comprar leche" | `lista.py add leche` |
| "quitá carne" / "-carne" / "sacá carne" | `lista.py remove carne` |
| "marcá fruta como comprada" / "compré fruta" | `lista.py toggle fruta` |
| "mostrame la lista" / "qué hay que comprar" | `lista.py list` |
| "vaciá lo comprado" | `lista.py clear-done` |
| "vaciá todo" | `lista.py clear-all` |

Si el item tiene varias palabras, pasarlo como un solo argumento: `lista.py add "pasta de dientes"`.

## Respuesta esperada

- Después de cada modificación, mostrar la lista actualizada completa (el script imprime el resultado; adjuntarlo tal cual).
- Si el usuario pide algo ambiguo (ej. "agregá eso"), preguntar qué item.
- Si el script responde "Ya estaba en la lista" o "No estaba en la lista", transmitirlo tal cual.
- Si la lista está vacía, el script imprime "🛒 Lista vacía."

## Verificación

- `lista.py list` devuelve la lista actual.
- El JSON no debe tener items duplicados (el script normaliza a minúsculas).

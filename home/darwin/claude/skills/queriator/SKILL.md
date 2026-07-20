---
name: queriator
description: >
  When a user needs data retrieved from a database — regardless of how they phrase it —
  invoke queriator. This covers any request to write, generate, or execute SQL/BigQuery
  queries across all MeLi domains: advertising, marketplace, users, sellers, orders, or
  any other. Casual Spanish phrasing ("haceme una query", "arma un SQL", "tírame el SQL",
  "generame el SQL", "creame algo en BQ", "dame los datos", "en qué tabla están") counts
  just as much as formal English. Queriator knows MeLi's BigQuery schemas, DSP advertising
  tables, and query best practices. When in doubt, invoke it — it's the right tool for
  any data-retrieval task involving SQL. Skip only for pure Python work, algorithm
  explanations, and refactoring with no SQL component.
---

# Queriator — Guía de Creación de Queries BigQuery (MeLi DSP)

## Proyecto y Contexto

- **Proyecto BigQuery por defecto**: `pdme000297-jtzrug5pqtu-furyid`
- **Dominio**: Advertising DSP de MercadoLibre — subastas, impresiones, bid shading, wins, presupuesto, line items
- El catálogo de tablas, schemas y queries de ejemplo vive en el wiki del equipo (ver sección siguiente)

---

## Wiki del equipo

El catálogo de tablas y schemas vive en `fury_ads-dsp-ml-wiki`, no dentro de esta skill. Antes de leer cualquier archivo del wiki, verificar disponibilidad local:

```bash
test -f ~/Repos/Meli/fury_ads-dsp-ml-wiki/wiki/index.md && echo "LOCAL" || echo "REMOTE"
```

- **LOCAL** → leer con `Read ~/Repos/Meli/fury_ads-dsp-ml-wiki/wiki/<path>`
- **REMOTE** → obtener con:
  ```bash
  gh api repos/melisource/fury_ads-dsp-ml-wiki/contents/wiki/<path> --jq '.content' | base64 -d
  ```

Esta verificación se hace **una sola vez** al inicio de cada invocación y aplica a todos los reads del wiki en esa sesión.

---

## Workflow para crear una query

### Paso 1 — Leer el catálogo del wiki

Lee siempre `wiki/index.md` del wiki antes de escribir cualquier query. Identifica qué tablas son relevantes para la tarea y cuándo usarlas. El `wiki/index.md` tiene sus propias instrucciones de navegación: lee solo las 1–3 páginas más relevantes, no todo el wiki.

### Paso 2 — Leer el schema de las tablas a usar

Lee únicamente los schemas de las tablas que vas a usar, no todos. Los schemas están en `wiki/schemas/<TABLA>.md`. La ruta exacta de cada tabla está en `wiki/index.md`.

Aplicar la misma lógica LOCAL/REMOTE que en la sección anterior.

### Paso 3 — Para queries complejas, leer best practices

Para joins, optimización, deduplicación, unnesting, o cualquier patrón no obvio, lee `wiki/guides/bq-best-practices.md` del wiki (misma lógica LOCAL/REMOTE que los pasos anteriores).

### Paso 4 — Escribir la query

---

## Convenciones

### Variables DECLARE

Toda query debe comenzar con un bloque `DECLARE` para todos los valores filtrables. Nunca hardcodees valores de site, fecha, o parámetros de negocio directamente en el SQL.

```sql
DECLARE VAR_SITE STRING DEFAULT 'MLM';
DECLARE VAR_DATE DATE DEFAULT '2026-04-20';
```

Nombres comunes de variables:
- `VAR_SITE` — site_id (MLA, MLB, MLM, MCO, MLC, MPE, MLU)
- `VAR_DATE` — fecha puntual
- `VAR_DATE_FROM` / `VAR_DATE_TO` — rango de fechas
- `VAR_DATETIME_UTC` — datetime en UTC para queries con partición TIMESTAMP
- `VAR_GOAL_TYPES` — array de goal types, ej: `['REACH', 'IMPRESSIONS']`

### Orden de filtros en WHERE

Siempre en este orden para aprovechar partition pruning dependiendo de la tabla, algunos comunes son:
`ds` (partición de fecha)
`site_id` / `SITE_ID`
`event` (para MELIDATA.ADVERTISING)
`insertion_ts` (si aplica)
Resto de filtros

### Otras reglas

- Usar `SAFE_DIVIDE(a, b)` — nunca `a / b` directo
- Usar `GROUP BY ALL` en lugar de listar todas las columnas
- Nunca `SELECT *` — usar columnas explícitas (o `SELECT * EXCEPT (col)` si es necesario)
- Limitar decimales: `ROUND(valor, 2)`
- Para deduplicación: `QUALIFY ROW_NUMBER() OVER (...) = 1`
- Comentarios en `/* */` (no `--`, para compatibilidad con awk)
- `ORDER BY` solo en la query más externa, siempre con `LIMIT`

---

## Ejecución

### Antes de guardar o ejecutar — preguntar al usuario

No asumir ningún directorio. Antes de guardar el `.sql` o correr la query, preguntar:

> "¿Dónde guardo la query? (Enter para el directorio actual)"

Si el usuario no responde o dice "acá" / "acá nomás" / "mismo directorio" / solo Enter → guardar en el directorio de trabajo actual (`./<nombre>.sql`).

Si el usuario especifica una ruta (ej: `queries/`, `~/análisis/`, `./sql/`) → usarla.

### Ejecutar la query

Una vez que se sabe dónde está el `.sql`, ejecutar con el script del skill:

```bash
bash <path-al-skill>/scripts/run_query.sh <path/a/mi_query.sql> [max_rows] [output_dir]
```

- `output_dir` es opcional — si se omite, el resultado se guarda en el mismo directorio que el `.sql`
- El script auto-detecta si la query tiene `DECLARE` y aplica el strip de awk automáticamente
- Muestra un preview de las primeras filas y el total de registros

---

## Ejemplos SQL de referencia

Los ejemplos de queries siguen la misma cascada wiki → local:

**1° — Wiki del equipo** (`wiki/queries/<topic>/`): fuente principal. Cubre bidshading, pricing, analytics, budget, ADX funnels. Ver `wiki/index.md` para el listado completo con descripciones.

**2° — Local** (`references/examples/`): queries únicas no cubiertas por el wiki.

| Archivo | Qué demuestra |
|---------|---------------|
| `bidshading_adx_line_item_lookup.sql` | Lookup de line item en ADX pricing raw, extracción de JSON anidado con REGEXP_EXTRACT |
| `daily_metrics.sql` | Métricas diarias por site con DECLARE, joins entre tablas |

Si el usuario menciona un tipo de análisis, busca primero en el wiki (`wiki/index.md` lista todos los ejemplos disponibles) y luego en los archivos locales.

---

## Si la tabla no está en el catálogo

1. Usar `mcp__bigquery__describe_table` para obtener columnas nativas
2. Usar `mcp__bigquery__get_sample_data` para inspeccionar datos reales
3. Construir la query a partir de lo que aprendas
4. Después de completar la tarea, si el wiki está disponible localmente, agregar el schema en `wiki/schemas/<TABLA>.md` y una fila en `wiki/index.md` bajo la sección "Schemas"

---

## Mapa de timezones por site

| Site | Timezone |
|------|----------|
| MLA | America/Argentina/Buenos_Aires |
| MLB | America/Sao_Paulo |
| MLM | America/Mexico_City |
| MCO | America/Bogota |
| MLC | America/Santiago |
| MPE | America/Lima |
| MLU | America/Montevideo |

---

## Guardar como ejemplo

Cuando el usuario diga alguna de estas frases:
- "guardá como ejemplo"
- "guardalo en ejemplos"
- "save as example"
- "agregalo a los ejemplos"
- "guardá esta query"

Hacer lo siguiente:
1. Si el usuario no especificó nombre de archivo, pedírselo: "¿Con qué nombre lo guardo? (sin extensión)"
2. Guardar el SQL en `references/examples/<nombre>.sql`
3. Agregar una fila a la tabla de `## Ejemplos SQL de referencia` en este SKILL.md: `| \`<nombre>.sql\` | <descripción de 1 línea de qué demuestra> |`
4. Confirmar al usuario qué archivo se creó y qué fila se agregó a la tabla

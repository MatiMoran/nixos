---
name: grid
version: "1.0.0"
description: >
  Create and publish interactive HTML dashboards to Grid (grid.adminml.com /
  grid.melioffice.com). Always use this skill whenever the user mentions Grid,
  wants to upload a report or dashboard, share visualizations with the team,
  create an HTML with BigQuery data, or publish any analysis.
  Trigger on: "subir a grid", "crear dashboard en grid", "publicar reporte",
  "upload to grid", "grid dashboard", "genera un HTML para grid",
  "compartir en grid", "quiero publicar en grid", "hacer un reporte para grid",
  "dashboard interactivo", "visualización para grid", "chart en grid",
  "reporte con datos de BQ", "quiero compartir esto con mi equipo en grid".
  Use this skill even for simple uploads — any time Grid is mentioned.
---

# grid

Crear y publicar dashboards HTML interactivos en Grid usando datos reales de BigQuery.

El flujo típico es: autenticación → query BQ → generar HTML con dark theme → upload → compartir.

> **Referencia de estilos**: leer `references/styling.md` para la paleta de colores,
> configuración de Plotly, y estructura HTML base. Grid sirve las librerías desde
> `/d/_libs/` — no usar CDN externo.

---

## Fase 1 — Verificar requisitos (solo lectura)

Antes de generar nada, verificar el entorno:

```bash
which gcloud && gcloud --version | head -1
which bq && bq version
gcloud auth list
```

Si falta alguno:
- `brew install google-cloud-sdk` instala gcloud y bq
- Si no hay cuenta activa: pedir al usuario que corra `! gcloud auth login EMAIL`

**VPN**: Grid requiere VPN corporativa Meli. Si los curl devuelven 401 o timeout, la VPN no está conectada — avisar al usuario.

---

## Fase 2 — Autenticación gcloud (si es necesario)

Solo si `gcloud auth list` no muestra cuenta activa:

```bash
# Pedir al usuario que lo ejecute en su terminal si el agente no puede autenticar
gcloud auth login EMAIL@mercadolibre.com
gcloud auth application-default login
```

Verificar con:
```bash
bq query --nouse_legacy_sql "SELECT 1 AS test"
```

---

## Fase 3 — Instalar la grid-skill (primera vez)

La grid-skill es un componente local que se descarga de Grid. Va en `.agents/local/skills/` (gitignoreado — no va al repo compartido).

```bash
curl -o /tmp/grid-skill.zip https://grid.melioffice.com/skill
mkdir -p .agents/local/skills/grid-skill
unzip -o /tmp/grid-skill.zip -d /tmp/grid-skill-tmp
cp -r /tmp/grid-skill-tmp/grid-skill/. .agents/local/skills/grid-skill/
rm -rf /tmp/grid-skill.zip /tmp/grid-skill-tmp
ls .agents/local/skills/grid-skill/
```

Si el servidor responde HTTP 426 en algún paso posterior, la skill está desactualizada — repetir este paso.

---

## Fase 4 — Ejecutar query BigQuery

Correr la query con `bq` y capturar los resultados en JSON para usarlos en el HTML:

```bash
bq query --nouse_legacy_sql --format=json --max_rows=500 '
SELECT
  -- columnas relevantes para el dashboard
FROM `meli-bi-data.DATASET.TABLE`
WHERE
  ds >= "YYYY-MM-DD"
  AND site = "MLA"
  -- filtros adicionales
LIMIT 200
'
```

Los resultados llegan como array JSON. Parsearlos con Python inline si hace falta transformación.

---

## Fase 5 — Crear el HTML del dashboard

Leer `references/styling.md` para la paleta completa y el template base.

Reglas importantes:
- **Librerías desde `/d/_libs/`**, nunca CDN externo (`plotly.min.js`, `d3.min.js`, `tailwind.css`)
- **Dark theme siempre**: fondo `#0d1117`, superficie `#161b22`, texto `#e6edf3`
- **Datos hardcodeados en el HTML**: embeber el JSON de los resultados como variable JS
- **Títulos que comunican**: no solo "Impressions by Placement" sino "¿Qué placement genera más CTR? — MLA Abril 2026"
- **Anotaciones en los gráficos**: valores sobre las barras, porcentajes en los ejes

Ejemplo de estructura mínima:

```html
<!DOCTYPE html>
<html>
<head>
  <script src="/d/_libs/plotly.min.js"></script>
  <style>
    body { background:#0d1117; color:#e6edf3; font-family:monospace; padding:24px; }
    h1 { color:#e6edf3; font-size:18px; margin-bottom:4px; }
    .subtitle { color:#8b949e; font-size:13px; margin-bottom:24px; }
  </style>
</head>
<body>
  <h1>Título que responde una pregunta</h1>
  <p class="subtitle">Subtítulo con contexto (site, periodo, métrica)</p>
  <div id="chart" style="height:420px"></div>
  <script>
    const data = [/* JSON de BQ embebido aquí */];
    Plotly.newPlot('chart', [{
      type: 'bar',
      x: data.map(d => d.placement),
      y: data.map(d => parseFloat(d.ctr)),
      marker: { color: '#58a6ff' },
      text: data.map(d => d.ctr + '%'),
      textposition: 'outside'
    }], {
      paper_bgcolor: '#161b22',
      plot_bgcolor: '#161b22',
      font: { color: '#c9d1d9' },
      margin: { t: 20, r: 20, b: 80, l: 60 }
    });
  </script>
</body>
</html>
```

---

## Fase 6 — Subir a Grid

```bash
curl -s -X POST "https://grid.melioffice.com/api/v1/engine/run" \
  -F 'config={
    "skill_version": "3.6.2",
    "title": "Título del dashboard",
    "tags": ["dsp", "display"],
    "share_with": ["EMAIL@mercadolibre.cl"]
  }' \
  -F "file=@/ruta/al/dashboard.html"
```

La respuesta incluye `view_url` — ese es el link para compartir. Mostrarlo al usuario.

> Si `skill_version` es rechazado con HTTP 426: reinstalar la grid-skill (Fase 3).

---

## Fase 7 — Compartir con el equipo (opcional)

```bash
curl -s -X POST "https://grid.melioffice.com/api/v1/engine/run/json" \
  -H "Content-Type: application/json" \
  -d '{
    "skill_version": "3.6.2",
    "doc_id": "DOC_ID_DEL_UPLOAD",
    "share_with": ["nombre@mercadolibre.cl"],
    "slack_to": ["#canal-del-equipo"],
    "slack_message": "Nuevo dashboard disponible"
  }'
```

---

## Troubleshooting rápido

| Error | Causa | Solución |
|---|---|---|
| `401` en curl | VPN desconectada | Conectar VPN Meli y reintentar |
| `426` version mismatch | grid-skill desactualizada | Reinstalar (Fase 3) |
| `bq` sin cuenta | Sin autenticación | `gcloud auth login EMAIL` |
| HTML no muestra gráfico | CDN externo bloqueado | Usar `/d/_libs/` en vez de CDN |
| Archivo > 10 MB | HTML muy pesado | Ver `grid-skill/SKILL.md § Large files` |

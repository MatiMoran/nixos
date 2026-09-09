---
name: grid-report-style
description: Create analytical HTML reports and dashboards for Grid with a clear light theme, conclusion-first narrative, explicit assumptions, and raw query provenance. Use for designing or generating Grid-ready analysis HTML; do not use for Grid uploads, sharing, or document management.
---

# Grid Report Style

Esta skill define el estándar editorial y visual para informes analíticos HTML. Para publicar, actualizar, compartir o administrar documentos de Grid, usar la skill oficial `grid-sharing:grid`.

## Uso

Al crear o modificar un informe HTML, leer [references/report-style.md](references/report-style.md) antes de escribir el documento. Adaptar el estándar a la evidencia disponible: no inventar conclusiones, fuentes ni supuestos.

Usar [references/examples/olv_p95_cap_impact_mlb.html](references/examples/olv_p95_cap_impact_mlb.html) como ejemplo canónico de jerarquía, componentes y trazabilidad. No copiar sus métricas, dominio ni conclusiones fuera de su contexto.

## Límites

- Esta skill aplica a informes y dashboards HTML analíticos; no a presentaciones nativas de Grid.
- Mantener el documento independiente de CDN externos. Cuando se necesite una librería, usar las rutas de Grid documentadas en la guía de estilo.
- Ubicar las fuentes y las queries raw al final del HTML, preferentemente dentro de `<details>`, para conservar la lectura principal.

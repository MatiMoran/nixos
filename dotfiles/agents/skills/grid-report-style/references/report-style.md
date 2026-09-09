# Estándar de reportes HTML para Grid

Usar este estándar para análisis que se leerán como documentos HTML: claridad primero, evidencia trazable y una estética clara y sobria. El ejemplo completo está en [examples/olv_p95_cap_impact_mlb.html](examples/olv_p95_cap_impact_mlb.html).

## Orden narrativo

1. **Encabezado**: título que responda la pregunta, período, site/inventario y fecha de análisis.
2. **Conclusión principal**: un `callout` visible con la magnitud del hallazgo y la interpretación más importante.
3. **Supuestos y límites**: ventana temporal, población, definición del contrafactual, filtros y límites de inferencia.
4. **Evidencia**: resultado global antes de cortes, distribuciones o funnels; cada sección responde una pregunta concreta.
5. **Interpretación y próximos pasos**: separar lo observado de la recomendación o hipótesis.
6. **Fuentes y queries raw**: siempre al final. Asociar cada tabla o gráfico con su fuente y conservar el SQL en bloques `<details>`.

No ocultar una limitación que pueda cambiar la conclusión. Si no existe una conclusión sólida, abrir con el estado de incertidumbre y la evidencia disponible.

## Tema claro

```css
:root {
  --ink: #172033;
  --muted: #667085;
  --line: #d9dee7;
  --soft: #f5f7fa;
  --blue: #2f6fed;
  --blue-soft: #edf4ff;
  --green: #16794c;
  --green-soft: #eaf7ef;
  --amber: #8a5200;
  --amber-soft: #fff3cd;
}

* { box-sizing: border-box; }
body {
  background: #fff;
  color: var(--ink);
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  font-size: 15px;
  line-height: 1.58;
  margin: 0;
}
main { max-width: 1520px; margin: 0 auto; padding: 54px 28px 70px; }
h1 { font-size: 34px; letter-spacing: -.035em; line-height: 1.16; margin: 0 0 10px; }
h2 { border-bottom: 1px solid var(--line); font-size: 21px; letter-spacing: -.02em; margin: 44px 0 18px; padding-bottom: 9px; }
.meta, .source, .footnote { color: var(--muted); font-size: 12px; }
.intro { color: #39445a; font-size: 17px; max-width: 850px; margin: 24px 0; }
.callout { background: var(--blue-soft); border-left: 4px solid var(--blue); border-radius: 4px; margin: 25px 0; padding: 17px 20px; }
.definition { background: var(--soft); border-radius: 6px; margin: 18px 0; padding: 17px 20px; }
table { border-collapse: collapse; font-size: 13px; margin: 15px 0 7px; width: 100%; }
th, td { border: 1px solid var(--line); padding: 10px 12px; text-align: left; vertical-align: top; }
th { background: var(--soft); font-weight: 650; }
.num { font-variant-numeric: tabular-nums; text-align: right; white-space: nowrap; }
.pill { border-radius: 99px; display: inline-block; font-size: 12px; font-weight: 650; padding: 2px 8px; }
.pill.good, .local-cap { background: var(--green-soft); color: var(--green); }
.pill.warn, .cheap-curve { background: var(--amber-soft); color: var(--amber); }
details { border: 1px solid var(--line); border-radius: 6px; margin: 10px 0; }
summary { cursor: pointer; font-weight: 650; padding: 11px 13px; }
details pre { background: #f7f8fa; border-top: 1px solid var(--line); margin: 0; overflow: auto; padding: 14px; }
@media (max-width: 650px) { main { padding: 30px 16px 48px; } h1 { font-size: 28px; } .table-wrap { overflow-x: auto; } table { min-width: 650px; } }
```

Usar verde solo para resultados favorables o mejoras verificadas y ámbar para riesgos, advertencias, anomalías o trade-offs. El azul comunica contexto, no un semáforo. Evitar rojo salvo errores, pérdidas o deterioros inequívocos.

## Componentes y evidencia

- **Callout inicial**: una conclusión corta con valor absoluto, cambio relativo y una salvedad material si corresponde.
- **Bloque de supuestos**: usar `.definition` y bullets; no mezclar hipótesis metodológicas con resultados.
- **Tablas**: usar `.num` para métricas, destacar solo la fila que contiene el resultado decisivo y agregar una línea `Fuente: query N.` debajo.
- **Gráficos**: preferir una sola pregunta por gráfico y anotar valores cuando la comparación no sea obvia. Si se usa Plotly, cargarlo desde `/d/_libs/plotly.min.js`, nunca desde un CDN.
- **Queries raw**: incluir un índice de queries y un `<details>` por SQL, con el nombre del archivo o una descripción estable. Los comentarios SQL permanecen en inglés cuando sean código.

## Checklist antes de publicar

- ¿La primera pantalla responde qué pasó y cuánto importa?
- ¿Los supuestos y límites están antes de los cortes de detalle?
- ¿Cada afirmación cuantitativa tiene una fuente identificable?
- ¿Las queries raw están juntas al final y no interrumpen la evidencia?
- ¿Verde y ámbar expresan significado, no decoración?

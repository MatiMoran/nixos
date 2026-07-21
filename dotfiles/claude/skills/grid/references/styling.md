# Grid Dashboard — Guía de Estilos

Referencia de colores, configuración Plotly y estructura HTML para dashboards en Grid.

---

## Paleta dark theme

```css
/* Fondos */
--bg-body:    #0d1117;   /* fondo de página */
--bg-surface: #161b22;   /* fondo de gráficos y cards */
--bg-hover:   #21262d;   /* hover states */

/* Texto */
--text-primary:   #e6edf3;  /* títulos y valores */
--text-secondary: #c9d1d9;  /* labels de ejes */
--text-muted:     #8b949e;  /* subtítulos, metadatos */

/* Colores de datos */
--color-positive: #3fb950;  /* verde — lift, ganancia, mejora */
--color-reference:#58a6ff;  /* azul  — baseline, referencia */
--color-warning:  #d29922;  /* naranja — alerta, riesgo */
--color-negative: #f85149;  /* rojo  — pérdida, caída */
--color-neutral:  #8b949e;  /* gris  — neutral, sin cambio */
```

---

## Configuración base Plotly

Aplicar siempre en el `layout` de cada gráfico:

```javascript
const LAYOUT_BASE = {
  paper_bgcolor: '#161b22',
  plot_bgcolor:  '#161b22',
  font: {
    color:  '#c9d1d9',
    family: 'monospace',
    size:   12
  },
  margin: { t: 20, r: 20, b: 80, l: 60 },
  xaxis: {
    gridcolor: '#21262d',
    linecolor: '#30363d',
    tickcolor: '#8b949e'
  },
  yaxis: {
    gridcolor: '#21262d',
    linecolor: '#30363d',
    tickcolor: '#8b949e'
  }
};
```

---

## Librerías disponibles en Grid

Grid sirve estas librerías desde `/d/_libs/` — **no usar CDN externo**:

```html
<script src="/d/_libs/plotly.min.js"></script>
<script src="/d/_libs/d3.min.js"></script>
<script src="/d/_libs/chart.min.js"></script>   <!-- Chart.js -->
<link  href="/d/_libs/tailwind.css" rel="stylesheet">
```

---

## Template HTML completo

```html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="/d/_libs/plotly.min.js"></script>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background: #0d1117;
      color: #e6edf3;
      font-family: monospace;
      padding: 24px;
      max-width: 1200px;
      margin: 0 auto;
    }
    .header { margin-bottom: 32px; }
    .header h1 { font-size: 20px; font-weight: bold; margin-bottom: 4px; }
    .header .meta { color: #8b949e; font-size: 12px; }
    .chart-card {
      background: #161b22;
      border: 1px solid #30363d;
      border-radius: 6px;
      padding: 20px;
      margin-bottom: 24px;
    }
    .chart-title { font-size: 14px; font-weight: bold; margin-bottom: 4px; }
    .chart-subtitle { color: #8b949e; font-size: 12px; margin-bottom: 16px; }
    .stat-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px; margin-bottom: 24px; }
    .stat-card { background: #161b22; border: 1px solid #30363d; border-radius: 6px; padding: 16px; }
    .stat-value { font-size: 28px; font-weight: bold; color: #58a6ff; }
    .stat-label { color: #8b949e; font-size: 12px; margin-top: 4px; }
  </style>
</head>
<body>
  <div class="header">
    <h1>TÍTULO QUE RESPONDE UNA PREGUNTA</h1>
    <div class="meta">Site · Métrica · Periodo · N registros</div>
  </div>

  <!-- Stats resumen -->
  <div class="stat-grid">
    <div class="stat-card">
      <div class="stat-value" id="stat-1">—</div>
      <div class="stat-label">Métrica 1</div>
    </div>
    <div class="stat-card">
      <div class="stat-value" id="stat-2">—</div>
      <div class="stat-label">Métrica 2</div>
    </div>
  </div>

  <!-- Gráfico principal -->
  <div class="chart-card">
    <div class="chart-title">Subtítulo del gráfico</div>
    <div class="chart-subtitle">Descripción corta del eje / dimensión</div>
    <div id="main-chart" style="height:400px"></div>
  </div>

  <script>
    // Datos embebidos desde BQ
    const DATA = [/* JSON de resultados */];

    // Layout base
    const LAYOUT = {
      paper_bgcolor: '#161b22',
      plot_bgcolor:  '#161b22',
      font: { color: '#c9d1d9', family: 'monospace', size: 12 },
      margin: { t: 20, r: 20, b: 80, l: 60 },
      xaxis: { gridcolor: '#21262d', linecolor: '#30363d' },
      yaxis: { gridcolor: '#21262d', linecolor: '#30363d' }
    };

    // Stats
    document.getElementById('stat-1').textContent = DATA.length;

    // Gráfico
    Plotly.newPlot('main-chart', [{
      type: 'bar',
      x: DATA.map(d => d.dimension),
      y: DATA.map(d => parseFloat(d.metric)),
      marker: { color: '#58a6ff' },
      text: DATA.map(d => d.metric),
      textposition: 'outside',
      textfont: { color: '#e6edf3', size: 11 }
    }], LAYOUT, { responsive: true });
  </script>
</body>
</html>
```

---

## Paleta para múltiples series

Cuando hay varias líneas o categorías:

```javascript
const COLORS = ['#58a6ff', '#3fb950', '#d29922', '#f85149', '#bc8cff', '#79c0ff'];
```

Asignar en orden: azul primero (principal), verde (comparación positiva), naranja (advertencia), etc.

---

## Tipos de gráfico comunes

| Caso de uso | Tipo Plotly | Color recomendado |
|---|---|---|
| Ranking por placement | `bar` horizontal | `#58a6ff` |
| Base vs perso score | `bar` agrupado | `['#58a6ff', '#3fb950']` |
| Evolución temporal | `scatter` con línea | `#58a6ff` |
| Distribución de lift | `histogram` | `#3fb950` |
| Heatmap placement × hora | `heatmap` | `colorscale: 'Blues'` |

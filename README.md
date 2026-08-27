# Geolocalización de Bancos de Sangre — DIBAN / MINSA · Perú

Aplicativo web de visualización que ubica en un mapa los Bancos de Sangre Tipo I y II
autorizados a nivel nacional, con filtros por región (DIRESA/GERESA), tipo y estado, buscador
y listado lateral.

## Acceso

**https://rojasarca-code.github.io/geolocalizacion-bancos-sangre-diban/**

Funciona desde cualquier dispositivo (PC, tablet, celular) con navegador y conexión a internet.

## Detalles técnicos

- `index.html` — aplicación completa en un solo archivo (HTML/CSS/JS). Los datos de los
  bancos de sangre van embebidos en la propia página.
- Usa [Leaflet](https://leafletjs.com/) para el mapa y teselas de OpenStreetMap.
- No requiere servidor ni proceso de compilación: es una página estática publicada con
  GitHub Pages.

## Datos

Carpeta `datos/`:

- `BASE-DE-DATOS-REGISTRO-NACIONAL-BANCOS-DE-SANGRE-AUTORIZADOS-OFICIAL.xlsx` — fuente oficial.
- `banks-all.json`, `records.json` — datos procesados.

## Origen

Diseño creado con Claude Design e implementado como página estática.

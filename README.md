# Geolocalización de Bancos de Sangre — DIBAN / MINSA · Perú

Aplicativo web de visualización que ubica en un mapa los Bancos de Sangre Tipo I y II
autorizados a nivel nacional, con filtros por región (DIRESA/GERESA), tipo y estado, buscador
y listado lateral.

## Acceso

**https://rojasarca-code.github.io/geolocalizacion-bancos-sangre-diban/**

Funciona desde cualquier dispositivo (PC, tablet, celular) con navegador y conexión a internet.
En celular el panel de filtros/lista/cálculo y el mapa ocupan toda la pantalla y se alternan
con la barra inferior **Filtros y lista · Mapa**; en tablet se muestran lado a lado.

## Cálculo de distancia y tiempo (terrestre / fluvial / aéreo)

El panel *"Cálculo de distancia y tiempo"* estima el traslado entre dos establecimientos
por tres vías, e indica cuál es viable:

- **Terrestre:** ruta real de carretera (distancia y tiempo de manejo) consultada en vivo a
  [OSRM](https://project-osrm.org/) sobre OpenStreetMap; la traza se dibuja en el mapa. Si no
  existe una ruta de carretera practicable (p. ej. Iquitos), se marca *"no viable"*. Requiere
  conexión a internet; los resultados se guardan en caché en el navegador.
- **Fluvial:** red curada de puertos y rutas comerciales amazónicas (Yurimaguas, Iquitos,
  Nauta, Requena, Contamana, Pucallpa, Atalaya, Caballococha, Santa Rosa, etc.). Se calcula la
  ruta puerto a puerto y el tiempo por *lancha* y por *deslizador/rápido*. **Cifras
  referenciales**, pendientes de validación con la Autoridad Portuaria Nacional / MTC.
- **Aéreo:** aeropuerto con servicio comercial más cercano a cada extremo, distancia
  ortodrómica entre aeropuertos (con escala en Lima cuando no hay conexión directa habitual)
  y tiempo de vuelo estimado.

Datos de apoyo embebidos en `index.html`: `#ports` y `#river` (red fluvial), `#airports`
(aeropuertos del Perú).

## Detalles técnicos

- `index.html` — aplicación completa en un solo archivo (HTML/CSS/JS). Los datos de los
  bancos de sangre van embebidos en la propia página.
- Usa [Leaflet](https://leafletjs.com/) para el mapa y teselas de OpenStreetMap.
- El cálculo de rutas terrestres llama a `https://router.project-osrm.org` (servidor
  público de demostración de OSRM). Para uso intensivo conviene migrar a un OSRM propio o a
  una llave de OpenRouteService.
- No requiere servidor ni proceso de compilación: es una página estática publicada con
  GitHub Pages.

## Datos

Carpeta `datos/`:

- `BASE-DE-DATOS-REGISTRO-NACIONAL-BANCOS-DE-SANGRE-AUTORIZADOS-OFICIAL.xlsx` — fuente oficial.
- `banks-all.json`, `records.json` — datos procesados.

## Origen

Diseño creado con Claude Design e implementado como página estática.

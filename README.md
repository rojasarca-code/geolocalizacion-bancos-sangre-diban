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
  [OSRM](https://project-osrm.org/) sobre OpenStreetMap; la traza se dibuja en el mapa. El
  tiempo de OSRM se **corrige por altitud** del trayecto (perfil de elevación de
  [open-meteo](https://open-meteo.com/): factor ×1,12 costa … ×1,5 sierra alta sostenida) más
  un margen por paradas, y por un **selector de tipo de traslado** (auto particular ·
  camioneta / vía afirmada ×1,25 · ambulancia con prioridad ×0,85). Si no existe ruta de
  carretera practicable (p. ej. Iquitos), se marca *"no viable"*.
- **Fluvial:** red curada de puertos y rutas comerciales amazónicas (Yurimaguas, Iquitos,
  Nauta, Requena, Contamana, Pucallpa, Atalaya, Caballococha, Santa Rosa, etc.). Ruta puerto a
  puerto con **sentido de la corriente** (aguas abajo ×0,72 · aguas arriba ×1,45) y tiempo por
  *lancha* y por *deslizador/rápido*, más el traslado en tierra a cada puerto. **Cifras
  referenciales**, pendientes de validación con la Autoridad Portuaria Nacional / MTC.
- **Aéreo:** aeropuerto con servicio comercial más cercano a cada extremo; vuelo **directo**
  si es una ruta habitual conocida, si no con escala en Lima. Tiempo *puerta a puerta*:
  traslado en tierra al aeropuerto (OSRM) + presentación + *block time* (crucero según
  distancia + maniobras) + escala + traslado al destino.

Datos de apoyo embebidos en `index.html`: `#ports` y `#river` (red fluvial con orden
hidrográfico), `#airports` (aeropuertos del Perú).

## Red de convenios

La capa *"Red de convenios"* usa la verificación **«semáforo» de agosto 2026**
(`datos/convenios_semaforo_agosto2026_verificado.xlsx`). Cada banco productor tipo II y cada
hospital receptor tipo I se enlaza al Registro Nacional **por su código RENIPRESS (CODIGO
UNICO)**, no por nombre, para mayor exactitud. Resultado: 50 bancos productores, 278
convenios — 244 verificados por código RENIPRESS, 2 por nombre y 32 sin coincidencia en el
registro (se muestran igual, marcados *"sin verificar"* y sin punto en el mapa). Las uniones
del mapa toman las coordenadas del propio registro (`bid`), de modo que heredan el mismo
ajuste anti-solapamiento que los marcadores. Datos embebidos en `#conv` de `index.html`; copia
en `datos/convenios.json`. Regenerable con `scripts/build_conv.ps1` (en el historial del
repo del proyecto).

## Detalles técnicos

- `index.html` — aplicación completa en un solo archivo (HTML/CSS/JS). Los datos de los
  bancos de sangre van embebidos en la propia página.
- Usa [Leaflet](https://leafletjs.com/) para el mapa y teselas de OpenStreetMap.
- El cálculo de rutas terrestres llama a `https://router.project-osrm.org` (servidor
  público de demostración de OSRM) y a `https://api.open-meteo.com` (perfil de altitud).
  Cada cálculo hace 1–5 consultas a OSRM (ruta principal + traslados a puerto/aeropuerto),
  con caché en el navegador. Para uso intensivo conviene migrar a un OSRM propio o a una
  llave de OpenRouteService.
- No requiere servidor ni proceso de compilación: es una página estática publicada con
  GitHub Pages.

## Datos

Carpeta `datos/`:

- `BASE-DE-DATOS-REGISTRO-NACIONAL-BANCOS-DE-SANGRE-AUTORIZADOS-OFICIAL.xlsx` — fuente oficial.
- `banks-all.json`, `records.json` — datos procesados.

## Origen

Diseño creado con Claude Design e implementado como página estática.

# Sistema de Extracción de Datos y Modelización Estadística del Rendimiento Deportivo (LaLiga)

Este repositorio contiene un ecosistema completo de herramientas diseñado para el **Web Scraping, Procesamiento de Datos (ETL) y Modelización Estadística Avanzada** aplicado al rendimiento de los equipos de fútbol de la Primera División de España (LaLiga). 

El proyecto se divide en dos fases fundamentales:
1. **Pipeline de Obtención y Preparación de Datos (Python):** Un conjunto de scripts que automatizan la extracción de datos históricos y estadísticas avanzadas directamente desde la web, procesándolos mediante un sistema de medias ponderadas temporales.
2. **Análisis Estadístico y Modelización (R):** Un estudio profundo fundamentado en modelos de regresión lineal múltiple, ANOVA y ANCOVA para evaluar variables de ataque, cuantificar estadísticamente el "factor campo" (localía) e inferir patrones de comportamiento en la generación de goles esperados ($xG$).

---

## 🛠️ Fase 1: Pipeline de Obtención de Datos (Python)

La arquitectura de extracción de datos está construida sobre **Pandas** y utiliza técnicas de Web Scraping automatizado para consolidar datasets desde el portal estadístico *FBref*.

### 1. `Partidos.py` (Scraping de Calendario y Resultados)
Este script es el punto de partida del pipeline de partidos. Se encarga de descargar las tablas de emparejamientos y métricas básicas de los encuentros de las temporadas seleccionadas (`2023-2024`, `2024-2025`, `2025-2026`).
* **Web Scraping:** Mediante `pd.read_html()`, se conecta de forma dinámica a las URLs oficiales de resultados y fixtures de LaLiga en FBref.
* **Transformación de Datos:** * Renombra columnas complejas para simplificar el manejo de los goles esperados (`xG` y `xG.1`) a parámetros legibles (`xG Local` y `xG Visitante`).
  * Realiza limpieza de datos eliminando registros nulos o vacíos que corresponden a separadores estéticos dentro de las tablas web (`.dropna()`).
* **Normalización Estructural:** Duplica conceptualmente el conjunto de datos por partido para transformar un registro único (*Equipo Local vs Equipo Visitante*) en dos registros individuales independientes orientados a filas (*Registro de actuación de Equipo X como Local* y *Registro de actuación de Equipo Y como Visitante*). Esto permite analizar la variable categórica `Localía` de forma directa en los modelos de regresión.

### 2. `Datos por equipo.py` (Scraping de Estadísticas Avanzadas)
Extrae el rendimiento consolidado de cada club a lo largo de las temporadas en formato de métricas acumuladas y ratios por 90 minutos de juego.
* **Consolidación Multitabla:** Descarga de forma masiva e indexa múltiples tablas estadísticas de FBref (Estadísticas estándar, Rendimiento de portería corriente, Portería avanzada, Métricas de disparo y Ratios de creación de tiros/goles).
* **Mapeo de Variables Críticas:** Extrae y normaliza parámetros avanzados como:
  * Goles y asistencias promedio por partido.
  * Goles por tiro y goles por tiro a puerta realizados.
  * Goles recibidos por tiro y por tiro a puerta permitidos al rival.
  * Distancia media de disparo (convertida matemáticamente de yardas a metros multiplicando por `0.9144`).
  * Acciones de Creación de Goles por 90 minutos (`GCA90`) tanto a favor como en contra.
* **Integración de Clasificación:** Cruza la tabla estadística con la posición en la tabla de clasificación (`Rank`) alcanzada en dicha temporada para dotar de contexto competitivo al dataset.

### 3. `Medias_ponderadas.py` (Suavizado Temporal de Rendimiento)
Dado que un equipo puede cambiar radicalmente su plantilla o dinámica entre temporadas, este módulo implementa una **función de agregación personalizada** para ponderar el rendimiento histórico, dándole mayor relevancia a las temporadas más recientes.
* **Lógica del Algoritmo de Pesos:**
  * Si un equipo ha competido las **3 temporadas** analizadas: los pesos asignados son `[0.29, 0.45, 0.26]` de forma cronológica inversa (ponderando con mayor rigor la temporada intermedia y la más reciente según la distribución competitiva).
  * Si ha competido durante **2 temporadas** (por ejemplo, un equipo que ascendió recientemente): se aplica dinámicamente un esquema de pesos `[0.3, 0.7]` si incluye la temporada `2025-2026`, o un factor estándar de `[0.75, 0.25]` en su defecto.
  * Si solo dispone de **1 temporada** en la categoría: se mantiene el valor íntegro con un peso único de `1`.
* **Operación Matricial:** Realiza un producto matricial (`@`) entre los datos numéricos transpuestos de los grupos y el vector de pesos determinado, devolviendo un perfil analítico suavizado y unificado por equipo.

### 4. `Obtencion de los datos.py` (Orquestador ETL Final)
Actúa como el script maestro que fusiona los flujos de información generados anteriormente.
* **Carga e Intersección:** Lee los archivos maestros de partidos y el consolidado histórico suavizado por equipos.
* **Ingeniería de Características Cruzadas:** Realiza iteraciones sobre cada partido emparejando la fila con las estadísticas ponderadas del equipo en cuestión (actuando como local o visitante) e intersectándolas simultáneamente con el perfil defensivo y de posesión de su rival de turno.
* **Output Concluyente:** Genera un archivo optimizado listo para ser importado por el motor estadístico de R.

---

## 📊 Fase 2: Análisis Estadístico y Modelización (R)

El script `script.R` procesa el dataset resultante para validar teorías futbolísticas mediante un enfoque matemático riguroso. Utiliza librerías de prestigio como `car` para diagnósticos, `lmtest` para contrastes de hipótesis analíticos, `ggcorrplot` para exploración visual y `sm` para densidades no paramétricas.

### 1. Análisis Exploratorio y Correlaciones
* **Garantía de Reproducibilidad:** Fija una semilla aleatoria (`set.seed(1759)`) para asegurar que cualquier remuestreo o cálculo numérico sea perfectamente reproducible.
* **Matrices de Correlación:** Genera mapas térmicos estadísticos (`ggcorrplot`) entre la variable dependiente central —**goles esperados ($xG$)**— y los predictores potenciales (posesión propia, posesión rival, goles previos, asistencias previas, volumen de disparos y acciones de creación de tiros). Esto descarta predictores redundantes y previene la multicolinealidad.

### 2. Modelo de Regresión Lineal Múltiple
Busca encontrar la ecuación matemática óptima que prediga el $xG$ de un equipo en un partido determinado basándose en métricas de rendimiento histórico propio y del rival.
* **Estimación por Mínimos Cuadrados (OLS):** Evalúa un modelo lineal uniendo todas las variables explicativas continuas extraídas en Python.
* **Selección de Variables:** Permite aislar y contrastar qué coeficientes ($eta_i$) poseen significación estadística real ($p	ext{-valor} < 0.05$) y cuantificar en cuánto incrementa el $xG$ estimado por cada unidad que aumenta una métrica específica (como las acciones de creación de gol `GCA90`).

### 3. Justificación Estadística de la Localía (ANOVA)
El script aborda matemáticamente la eterna premisa futbolística: *"¿Los equipos juegan mejor y generan más peligro cuando actúan en su propio estadio?"*.
* **Análisis de Varianza (ANOVA):** Utiliza la variable cualitativa/categórica `Localía` (Local / Visitante) como factor de clasificación.
* **Contraste de Medias:** Evalúa si la variabilidad de los goles esperados explicada por el hecho de jugar en casa es significativamente mayor que la variabilidad residual intrínseca de los partidos. El resultado arroja una demostración formal de que el factor de localía eleva de manera estadísticamente significativa la media de $xG$ generada por encuentro.

### 4. Modelo de Regresión Avanzado con Covariables (ANCOVA)
Para hilar más fino, el script combina el poder predictivo de las variables cuantitativas y cualitativas implementando un **Análisis de Covarianza (ANCOVA)**.
* **Efecto Combinado:** Estudia cómo varía el impacto de métricas puras de ataque (como la posesión de balón o tasas de tiro) sobre el $xG$ en función de si el equipo está actuando en su estadio o en territorio visitante.
* **Interacciones Estadísticas:** El modelo evalúa términos de interacción para dilucidar si las pendientes de regresión varían según el contexto geográfico del partido, demostrando que en entornos visitantes las dinámicas de ataque requieren un volumen de aproximaciones diferente para generar la misma peligrosidad esperada.

### 5. Diagnóstico de los Modelos y Validación de Hipótesis
Para validar las inferencias de los modelos lineales previos, el script somete los residuos a un escrutinio matemático severo mediante tests formales de hipótesis:
* **Normalidad de Residuos:** Se contrasta formalmente mediante el **Test de Shapiro-Wilk** (`shapiro.test()`), evaluando si los errores del modelo se distribuyen de manera normal.
* **Homocedasticidad (Varianza Constante):** Se computa el **Test de Breusch-Pagan** (`bptest()`) y contrastes avanzados como `hmctest()` y `harvtest()` para validar que la variabilidad de los residuos permanece constante en todo el espectro predictivo.
* **Análisis de Atípicos (Outliers):** El script realiza un proceso de depuración estadística filtrando y eliminando registros anómalos o de influencia desmedida para reajustar los modelos y contrastar el impacto de estos sobre la robustez de las conclusiones estadísticas. El análisis demuestra con rigor matemático que las hipótesis principales se sostienen sólidamente aun abstrayéndose de ruidos puntuales en los datos.

---

## 📈 Flujo General de Trabajo

```
[Fuentes Web FBref]
       │
       ▼
 1. Partidos.py ───────► (Estructura base de partidos y localía) ──┐
 2. Datos por equipo.py ► (Métricas avanzadas por temporada)       │
       │                                                           ▼
       ▼                                               4. Obtencion de los datos.py
 3. Medias_ponderadas.py (Suavizado e histórico temporal) ───►     │
                                                                   ▼
                                                       [Datos_Partidos.csv]
                                                                   │
                                                                   ▼
                                                              5. script.R
                                                       (EDA + OLS + ANOVA + ANCOVA)
```

# En este script guardaremos toda la informacion relevante de cada equipo

# Comenzamos importante las librerias que vamos a utilizar
import pandas as pd
from Medias_ponderadas import media_ponderada

# Seleccionamos las temporadas de las que queremos extraer los datos
temporadas = ["2023-2024", "2024-2025", "2025-2026"]

# Creamos un dataframe en blanco en el que guardaremos los datos de cada equipo
datos_equipos = pd.DataFrame()

# Iteramos sobre todas las temporadas de las que vamos a usar los datos
for temporada in temporadas:

    # Guardamos la url que contiene la informacion que vamos a utilizar
    url = "https://fbref.com/en/comps/12/" + temporada + "/" + temporada + "-La-Liga-Stats" 

    # Utilizamos pandas para leer las tablas que aparecen en esta direccion
    tables = pd.read_html(url)

    # Vamos a utilizar las tablas 1, 3, 4, 5, 7, 8, 9, 10, 15, 16
    classification = tables[0]
    classification = classification.rename(columns = {"Rk": "Rank", "Squad": "Equipo"})
    squad_starndard_stats, squad_goalkeeping, squad_advanced_goalkeeping, squad_shootings, squad_goal_and_shot_creation = [tables[i - 1] for i in [3, 5, 7, 9, 15]]
    opponent_starndard_stats, opponent_advanced_goalkeeping, opponent_shootings, opponent_goal_and_shot_creation = [tables[i - 1] for i in [4, 8, 10, 16]]

    # Comprobamos que todo ha sido asignado correctamente
    dataframes = [classification, squad_starndard_stats, opponent_starndard_stats, squad_goalkeeping, squad_advanced_goalkeeping, opponent_advanced_goalkeeping, squad_shootings, opponent_shootings, squad_goal_and_shot_creation, opponent_goal_and_shot_creation]
    for dataframe in dataframes:
        dataframe.columns = dataframe.columns.get_level_values(-1)  # Las tablas que hemos leido utilizan multi index, a nosotros solo nos interesa el nivel mas bajo
#        print(dataframe.head())
#        print("")

    # Ahora podemos empezar a crear un dataframe en el que tengamos el valor de todas las variables que vamos a utilizar
    equipos = squad_starndard_stats["Squad"]
    datos_equipos_temporada = pd.DataFrame(
        data = {"Equipo": equipos,
                "Promedio de posesión": squad_starndard_stats["Poss"],
                "Goles por partido": classification["GF"] / 38,
                "Asistencias por partido": squad_starndard_stats["Ast"].iloc[:, 1],
                "Goles recibidos por partido": squad_goalkeeping["GA90"],
                "Porcentaje de partidos con portería a 0": squad_goalkeeping["CS%"],
                "Paradas por partido": squad_goalkeeping["Saves"] / 38,
                "Penalties a favor por partido": squad_goalkeeping["PKatt"] / 38,
                "Penalties en contra por partido": squad_goalkeeping["PKA"] / 38,
                "Porcentaje de penalties detenidos": squad_goalkeeping["Save%"].iloc[:,1],
                "Llegadas al area por partido": opponent_advanced_goalkeeping["Opp"] / 38,
                "Legadas al area permitidas por partido": squad_advanced_goalkeeping["Opp"] / 38,
                "Tiros a puerta por partido": squad_shootings["SoT"] / 38,
                "Tiros por partido": squad_shootings["Sh"] / 38,
                "Tiros a puerta recibidos por partido": opponent_shootings["SoT"] / 38,
                "Tiros recibidos por partido": opponent_shootings["Sh"] / 38,
                "Goles por tiro": squad_shootings["G/Sh"],
                "Goles por tiro a puerta": squad_shootings["G/SoT"],
                "Goles por tiro recibido": opponent_shootings["G/Sh"],
                "Goles por tiro a puerta recibido": opponent_shootings["G/Sh"],
                "Distancia media tiro": squad_shootings["Dist"] * 0.9144,
                "Distancia media tiro recibido": opponent_shootings["Dist"] * 0.9144,
                "Porcentaje de conversion de penalties": squad_shootings["PK"] / squad_shootings["PKatt"],
                "Acciones de gol por partido": squad_goal_and_shot_creation["GCA90"],
                "Acciones de gol recibidas por partido": opponent_goal_and_shot_creation["GCA90"],
                "Temporada": [temporada] * len(equipos)})
    
    # Añadimos la clasificacion alcanzada en esa temporada
    datos_equipos_temporada = datos_equipos_temporada.merge(classification[["Equipo", "Rank"]], on = "Equipo", how = "left")

    print(datos_equipos_temporada)

    # Concatenamos este dataframe con el que contiene todos los datos
    datos_equipos = pd.concat([datos_equipos, datos_equipos_temporada], ignore_index = True)

# Visualizamos el nuevo dataframe
print(datos_equipos)

# Rellenamos los valores faltantes con 0 (esto se da en el caso en que un equipo que este año esta en primera division aun no ha lanzado ningun penalty)
datos_equipos = datos_equipos.fillna(0)

# Llamamos a la funcion que realiza la media ponderada
datos_equipos = datos_equipos.groupby("Equipo").apply(media_ponderada).reset_index()

# Visualizamos
print(datos_equipos)

# Guardamos el dataframe como un archivo csv
datos_equipos.to_csv("DatosEquipos.csv", index = False)
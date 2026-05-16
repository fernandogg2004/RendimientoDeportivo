# Comenzamos importando las librerias que vamos a utilizar
import pandas as pd

# Escogemos las temporadas de las que queremos datos
seasons = ["2023-2024", "2024-2025", "2025-2026"]

# Creamos un dataframe vacio en el que vamos a almacenar todos los datos
partidos = pd.DataFrame()

# Iteramos sobre todas las temporadas de las que queremos extraer los datos
for season in seasons:
    # Guardamos la direccion de la pagina web en la que encontramos todos los partidos de la temporada pasada
    url = "https://fbref.com/en/comps/12/" + season + "/schedule/" + season + "-La-Liga-Scores-and-Fixtures"

    # Con el comando read_html de pandas podemos leer todas las tablas que hay en la url que le hemos proporcionado. Todas ellas quedan guardadas como dataframes en una lista
    tables = pd.read_html(url)

    # Como en nuestro caso solo hay una tabla accedemos a ella en la posicion 0
    laliga_matches_df = tables[0]

    # Comprobamos que los datos han sido correctamente guardados visulizando las primeras entradas del dataframe
    print(laliga_matches_df.head())

    # Notamos que hay dos columnas que se refieren a los expected goals, para el local y el visitante, cambiemos los nombres para mayor claridad
    laliga_matches_df = laliga_matches_df.rename(columns = {"xG": "xG Local", "xG.1": "xG Visitante"})

    # Eliminamos tambien las columna Notes pues solo contiene NaN
    laliga_matches_df = laliga_matches_df.drop("Notes", axis = 1)

    # Comprobamos si hay algun dato faltante
    print(laliga_matches_df.isnull().any())

    # Eliminamos las filas con datos faltantes (en este caso solamente contienen filas relativas al formato de la tabla que hemos leido)
    laliga_matches_df = laliga_matches_df.dropna()

    # Visualizamos para comprobar que los cambios se han realizado con exito
    print(laliga_matches_df)

    # Definimos el numero de partidos que se jugaron en esta temporada
    num_games = laliga_matches_df.shape[0]

    # Ahora queremos crear un nuevo dataframe que se centre en los resultado de cada equipo y no en el resultado de cada partido
    teams = pd.concat([laliga_matches_df.Home, laliga_matches_df.Away], ignore_index = True)
    rivals = pd.concat([laliga_matches_df.Away, laliga_matches_df.Home], ignore_index = True)
    xG = pd.concat([laliga_matches_df["xG Local"], laliga_matches_df["xG Visitante"]], ignore_index = True)
    localia = ["Local"] * num_games + ["Visitante"] * num_games
    temporada = [season] * num_games * 2
    laliga_df = pd.DataFrame(data = {"Equipo": teams, "Rival": rivals, "xG": xG, "Localía": localia, "Temporada": temporada})

    # Visualizamos el nuevo dataframe que acabamos de crear
    print(laliga_df)

    # Añadimos el dataframe que acabamos de crear a uno nuevo
    partidos = pd.concat([partidos, laliga_df], ignore_index = True)

# Comprobamos que todo esta en orden
print(partidos)

# Guardamos el dataframe como un csv
partidos.to_csv("Partidos.csv", index = False)
# Este script contiene una funcion que calcula una media ponderada de las estadisticas de cada equipo segun la temporada
import pandas as pd

def media_ponderada(grupo):
    # Los pesos seran los siguientes
    pesos = {
        3: [0.29, 0.45, 0.26],  # Para los equipos que estuvieron 3 temporadas la mas reciente puntuara 0.29 y asi sucesivamente
        2: [0.75, 0.25],        # Para los que estuvieron 2 la mas reciente sera 0.75
        1: [1]                  # Para los que estuvieron solo 1 nos quedamos con los datos que tenemos
    } 

    # Ahora ordenamos por temporada
    grupo = grupo.sort_values("Temporada", ascending = False)

    # Cogemos el peso adecuado
    n = len(grupo)
    if n == 2:
        if "2025-2026" in grupo["Temporada"]:
            peso = [0.3, 0.7]
        else:
            peso = pesos.get(n)
    else:
        peso = pesos.get(n)
    
    # Aplicamos la media ponderada a las columnas numericas
    columnas_numericas = grupo.select_dtypes("number").columns
    medias_ponderadas = (grupo[columnas_numericas].T @ peso).to_dict()

    # Devolvemos el resultado en forma de serie
    return pd.Series(medias_ponderadas)
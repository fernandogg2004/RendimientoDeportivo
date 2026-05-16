# Este script contiene el programa principal, en el se cargan los datos necesarios y se guardan en un excel

# Comenzamos importando las librerias que vamos a utilizar
import pandas as pd

# Ahora leemos los dos archivos csv que hemos creado con los otros scripts
partidos = pd.read_csv("d:/Desktop/Proyecto Regresion/Partidos.csv")
equipos = pd.read_csv("d:/Desktop/Proyecto Regresion/DatosEquipos.csv")

# Ahora iteramos en cada partido que tenemos y vamos añadiendo las correspondientes variables explicativas
for i in range(partidos.shape[0]):
    local = partidos.Equipo[i]
    visitante = partidos.Rival[i]
    partidos.loc[i, "Promedio de posesión del equipo"] = equipos.loc[equipos["Equipo"] == local, "Promedio de posesión"].values[0]
    partidos.loc[i, "Promedio de posesión del rival"] = equipos.loc[equipos["Equipo"] == visitante, "Promedio de posesión"].values[0]
    partidos.loc[i, "Goles por partido equipo"] = equipos.loc[equipos["Equipo"] == local, "Goles por partido"].values[0]
    partidos.loc[i, "Asistencias por partido equipo"] = equipos.loc[equipos["Equipo"] == local, "Asistencias por partido"].values[0]
    partidos.loc[i, "Goles recibidos por partido rival"] = equipos.loc[equipos["Equipo"] == visitante, "Goles recibidos por partido"].values[0]
    partidos.loc[i, "Porcentaje de partidos con portería a cero rival"] = equipos.loc[equipos["Equipo"] == visitante, "Porcentaje de partidos con portería a 0"].values[0]
    partidos.loc[i, "Paradas por partido rival"] = equipos.loc[equipos["Equipo"] == visitante, "Paradas por partido"].values[0]
    partidos.loc[i, "Penalties por partido equipo"] = equipos.loc[equipos["Equipo"] == local, "Penalties a favor por partido"].values[0]
    partidos.loc[i, "Penalties recibidos por partido rival"] = equipos.loc[equipos["Equipo"] == visitante, "Penalties en contra por partido"].values[0]
    partidos.loc[i, "Porcentaje penalties detenidos rival"] = equipos.loc[equipos["Equipo"] == visitante, "Porcentaje de penalties detenidos"].values[0]
    partidos.loc[i, "Llegadas al area por partido equipo"] = equipos.loc[equipos["Equipo"] == local, "Llegadas al area por partido"].values[0]
    partidos.loc[i, "Llegadas al area por partido permitidas rival"] = equipos.loc[equipos["Equipo"] == visitante, "Legadas al area permitidas por partido"].values[0]
    partidos.loc[i, "Tiros a puerta por partido equipo"] = equipos.loc[equipos["Equipo"] == local, "Tiros a puerta por partido"].values[0]
    partidos.loc[i, "Tiros por partido equipo"] = equipos.loc[equipos["Equipo"] == local, "Tiros por partido"].values[0]
    partidos.loc[i, "Tiros a puerta recibidos por partido rival"] = equipos.loc[equipos["Equipo"] == visitante, "Tiros a puerta recibidos por partido"].values[0]
    partidos.loc[i, "Tiros recibidos por partido rival"] = equipos.loc[equipos["Equipo"] == visitante, "Tiros recibidos por partido"].values[0]
    partidos.loc[i, "Goles por tiro equipo"] = equipos.loc[equipos["Equipo"] == local, "Goles por tiro"].values[0]
    partidos.loc[i, "Goles por tiro a puerta equipo"] = equipos.loc[equipos["Equipo"] == local, "Goles por tiro a puerta"].values[0]
    partidos.loc[i, "Goles por tiros recibidos rival"] = equipos.loc[equipos["Equipo"] == visitante, "Goles por tiro recibido"].values[0]
    partidos.loc[i, "Goles por tiro a puerta recibido rival"] = equipos.loc[equipos["Equipo"] == visitante, "Goles por tiro a puerta recibido"].values[0]
    partidos.loc[i, "Distancia media disparo equipo"] = equipos.loc[equipos["Equipo"] == local, "Distancia media tiro"].values[0]
    partidos.loc[i, "Distancia media disparo recibido rival"] = equipos.loc[equipos["Equipo"] == visitante, "Distancia media tiro recibido"].values[0]
    partidos.loc[i, "Porcentaje de conversión de penalties equipo"] = equipos.loc[equipos["Equipo"] == local, "Porcentaje de conversion de penalties"].values[0]
    partidos.loc[i, "Acciones de gol por partido equipo"] = equipos.loc[equipos["Equipo"] == local, "Acciones de gol por partido"].values[0]
    partidos.loc[i, "Acciones de gol permitidas por partido rival"] = equipos.loc[equipos["Equipo"] == visitante, "Acciones de gol recibidas por partido"].values[0]
    partidos.loc[i, "Nivel equipo"] = equipos.loc[equipos["Equipo"] == local, "Rank"].values[0]
    partidos.loc[i, "Nivel rival"] = equipos.loc[equipos["Equipo"] == visitante, "Rank"].values[0]
print(partidos)

# Guardamos el dataframe como un excel
partidos.to_excel("Datos_partidos.xlsx")
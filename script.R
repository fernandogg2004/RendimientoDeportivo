################ INTRODUCCION ##################################################
# Neste proxecto usaremos datos de todos os partidos disputados nas dúas  
# últimas tempadas da Primeira División da Liga Española para estudar  
# a relación existente entre os goles esperados dun encontro e certas    
# métricas relativas a ambos equipos enfrontados. Así mesmo, intentaremos dar unha
# xustificación estatística a certas afirmacións que se adoitan realizar sobre
# como varía a actuación dun equipo segundo este xogue no seu estadio ou fóra.
################################################################################

################ PRELIMINARES ##################################################
# Cargamos as librerías que imos utilizar
library(ggcorrplot)
library(car)
library(lmtest)
library(sm)

# Definimos unha semente para asegurar a reproducibilidade dos resultados
set.seed(1759)

# Os datos que imos utilizar están almacenados nun arquivo csv chamado 
# "Datos_Partidos.csv". Léamolos e definamos as variables
datos <- read.csv("Datos_Partidos.csv")
y <- datos$xG
x1 <- datos$Localía
x2 <- datos$Temporada
x3 <- datos$Promedio.de.posesión.del.equipo
x4 <- datos$Promedio.de.posesión.del.rival
x5 <- datos$Goles.por.partido.equipo
x6 <- datos$Asistencias.por.partido.equipo
x7 <- datos$Goles.recibidos.por.partido.rival
x8 <- datos$Porcentaje.de.partidos.con.portería.a.cero.rival
x9 <- datos$Paradas.por.partido.rival
x10 <- datos$Llegadas.al.area.por.partido.equipo
x11 <- datos$Llegadas.al.area.por.partido.permitidas.rival
x12 <- datos$Tiros.a.puerta.por.partido.equipo
x13 <- datos$Tiros.a.puerta.recibidos.por.partido.rival
x14 <- datos$Goles.por.tiro.a.puerta.equipo
x15 <- datos$Goles.por.tiro.a.puerta.recibido.rival
x16 <- datos$Acciones.de.gol.por.partido.equipo
x17 <- datos$Acciones.de.gol.permitidas.por.partido.rival
x18 <- datos$Nivel.equipo
x19 <- datos$Nivel.rival

# Antes de pasar ao axuste do modelo faremos un estudo das variables que 
# temos. Amosaremos un histograma de cada variable xunto cunha comparativa
# desa variable coa variable resposta.
# Para mellorar a presentación cambiamos o espaciador dun punto a espazo
colnames(datos) <- gsub("\\.", " ", colnames(datos)) 
# Agora quedamos só coas variables explicativas
variables_explicativas <- tail(colnames(datos), -6)
# E iteramos sobre todas elas
for (v in variables_explicativas) {
  # Chamamos x aos datos da variable coa que estamos traballando
  x <- datos[[v]]
  
  # Dividimos a pantalla en dúas para amosar ambas gráficas
  par(mfrow = c(1, 2))
  
  # Facemos o histograma
  hist(x,
       main = paste(v),
       xlab = v,
       ylab = "Densidade",
       col = "lightblue",
       border = "white",
       probability = TRUE)
  
  # E amosamos a distribución co histograma móbil
  lines(density(x, na.rm = TRUE), col = "red", lwd = 2)
  
  # Agora representamos a variable fronte aos xG
  plot(x, y,
       main = paste(v, "vs xG"),
       xlab = v,
       ylab = "xG",
       col = "darkgreen")
  
  # Para pasar ao seguinte gráfico esperamos a que se prema a tecla intro
  readline(prompt = "Preme [Intro] para pasar aos seguintes gráficos")
}

# Volvemos a unir a pantalla de gráficos
par(mfrow = c(1, 1))
################################################################################


################ AXUSTE ########################################################
# Pasamos agora ao axuste do modelo tal e como está
modelo <- lm(y~x3+x4+x5+x6+x7+x8+x9+x10+x11+x12+x13+x14+x15+x16+x17+x18+x19)
# Fagamos un summary do modelo para ver se o axuste é bo
summary(modelo)
# Case todos os coeficientes son non significativos. Sospeitamos a presenza
# de colinealidade.
################################################################################


################ COLINEALIDADE #################################################
# Para facernos unha primeira idea de se pode haber colinealidade comprobaremos  
# a matriz de covarianzas
variables_numericas = tail(colnames(datos), -6)
corr_matrix = round(cor(datos[variables_numericas]), 3)
ggcorrplot(corr_matrix, hc.order = TRUE, type = "lower", lab = TRUE)
# Nesta representación da matriz de correlación vemos que hai certas variables
# con moita dependencia. 

# Calculemos os coeficientes de inflación da varianza para ver se podemos 
# eliminar algunha variable
VIF <- vif(modelo)
colores <- ifelse(VIF > 5, "red", "lightblue")
barplot(VIF, names.arg = variables_numericas, col = colores, las = 2, ylab = "VIF")
abline(h = 5, lwd = 2, col = "black", lty = 2)
summary(VIF)
# Ante os datos parece innegable que temos un problema de colinealidade. 

# Simplifiquemos o modelo usando un método de selección baseado nun criterio global
modelo_simple <- step(modelo)
summary(modelo_simple)
# Tras este proceso obtemos un modelo no que todos os coeficientes son 
# significativos polo menos ao 5%

# De todos modos, optamos por repetir o proceso para asegurarnos de que xa non hai
# colinealidade
variables_explicativas_simple <- cbind("Promedio de posesión del equipo",
                                       "Goles por partido equipo", 
                                       "Asistencias por partido equipo",
                                       "Paradas por partido rival",
                                       "Acciones de gol permitidas por partido rival")
variables_numericas_simple <- cbind(x3, x5, x6, x9, x17)
colnames(variables_numericas_simple) = variables_explicativas_simple
corr_matrix_simple = round(cor(variables_numericas_simple), 3)
ggcorrplot(corr_matrix_simple, hc.order = TRUE, type = "lower", lab = TRUE)
# Sigue habendo algunhas variables con alta correlación, aínda que o seu número  
# é moito menor
VIF_simple <- vif(modelo_simple)
colores_2 <- ifelse(VIF_simple > 5, "red", "lightblue")
barplot(VIF_simple, names.arg = variables_explicativas_simple, col = colores_2, las = 2, ylab = "VIF")
abline(h = 5, lwd = 2, col = "black", lty = 2)
summary(VIF_simple)
# Como vemos, agora todos os VIF son menores de 2,5 polo que entendemos que 
# o problema de colinealidade foi resolto
# Unha vez temos o modelo que imos usar podemos dar unha interpretación dos 
# seus coeficientes
summary(modelo_simple)
# O intercepto representa o valor que esperamos da variable resposta 
# cando todas as variables explicativas son 0. Neste caso é -0.86, o cal 
# pode resultar contraintuitivo por ser os goles esperados sempre maiores ou iguais
# a 0; non obstante, como as variables explicativas nunca son todas 0 esta interpretación
# perde algo de significado e podemos obviala.
# En canto aos coeficientes que acompañan a cada variable explicativa, representan
# canto aumenta a variable resposta ao aumentar a respectiva explicativa nunha
# unidade, deixando fixas as demais. 
################################################################################


################ DIAGNOSE ######################################################
# Ocuparemonos agora da detección de observacións atípicas e influíntes
# Para iso comecemos facendo un plot do modelo
par(mfrow = c(2,2))
plot(modelo_simple)
# No primeiro gráfico vemos que cando o valor axustado é máis baixo, os residuos 
# tendan a estar máis preto do 0 mentres que, a medida que vai medrando, os
# residuos tamén tendan a estar máis dispersos. Isto é un signo habitual de 
# heterocedasticidade. 
# O segundo gráfico pódese utilizar para visualizar se se cumpre a normalidade
# e a presenza de valores atípicos. No noso caso as colas afástanse bastante
# dos cuantís da distribución normal, con algunhas observacións destacadas 
# que son potencialmente atípicas. Isto apunta cara a unha falta de normalidade.
# O terceiro gráfico serve tamén de apoio para ver se hai homocedasticidade. Do
# mesmo modo que no primeiro, vemos que canto menor é o valor axustado máis 
# preto do 0 están os residuos, e a medida que os valores axustados son
# maiores observamos unha maior separación.
# O último gráfico pódese usar para detectar observacións atípicas e influíntes.
# Neste caso parece que atoparemos varias observacións atípicas pero non 
# parece que haxa ningunha que sexa influínte.

# Xuntamos a ventá de visualización para continuar
par(mfrow = c(1, 1))

# Tras esta análise inicial podemos comezar coa busca de atípicos. Para
# atopalos obtemos os residuos, residuos estándar e residuos estudantizados
res1 <- residuals(modelo_simple)
res2 <- rstandard(modelo_simple)
res3 <- rstudent(modelo_simple)
# Para facernos unha idea de como son estes veremos un histograma
nombres_residuos <- c("Residuos", "Residuos Estandarizados", "Residuos Estudientizados")
valores_residuos <- cbind(res1, res2, res3)
for (i in 1:3){
  hist(valores_residuos[,i], , xlab = nombres_residuos[i], ylab = "Frecuencia", main = "")
  rug(valores_residuos[,i])
  readline(prompt = "Preme [Intro] para pasar aos seguintes gráficos")
}

# O criterio habitual é considerar atípicas as observacións cuxo erro estándar
# ou estudantizado supera o umbral 1,96. Vexamos cales son
atipicos_standard <- which(abs(res2) > 1.96)
atipicos_student <- which(abs(res3) > 1.96)
sum(atipicos_standard != atipicos_student)
# Neste caso obtemos que as observacións atípicas utilizando os residuos 
# estandarizados e os residuos estudantizados coinciden

# Como curiosidade podemos ver que equipos producen máis observacións
# atípicas e que equipos reciben máis observacións atípicas
barplot(table(datos$Equipo[atipicos_standard]), las = 2, 
        main = "Equipos que producen observacións atípicas")
# Vemos que o equipo que produce máis observacións atípicas é o Barcelona.
# Isto probablemente se deba a que na tempada pasada superaron as expectativas
# que recaían sobre eles e mostraron un ataque moito máis efectivo do habitual,
# xerando gran cantidade de goles con pouco esforzo.
barplot(table(datos$Rival[atipicos_standard]), las = 2, 
        main = "Equipos que reciben observacións atípicas")
# Os equipos que recibiron máis observacións atípicas son clubs cuxa defensa
# actuou por debaixo do esperado. Equipos como o Valladolid víronse superados
# en case todos os partidos nos que participaron debido ao menor nivel 
# respecto aos seus rivais, mentres que outros como o Celta de Vigo, aínda que 
# presentaron bos resultados, tiveron unha defensa peor en comparación con outros
# equipos.

# Quédanos entón a identificación de posibles observacións influíntes. Para
# a súa detección utilízase a distancia de Cook e os leverages.
# Comecemos vendo os leverages, que serven para detectar as observacións 
# con capacidade de influencia
leverages <- hat(model.matrix(modelo_simple))
# Vexamos como se distribúen estes antes de comprobar se son grandes ou non
hist(leverages, xlab = "Leverages", ylab = "Frecuencia", main = "")
rug(leverages)
summary(leverages)

# Dicimos que os leverages son altos se superan 2 * p / n, sendo p o número 
# de parámetros e n o número de datos. Isto é equivalente a que superen o dobre 
# da súa media, é dicir
posibles_influyentes <- which(leverages >= 2 * mean(leverages))
abline(v = 2 * mean(leverages), col = "red", lty = "dashed")
# Esas son as observacións nas que temos que fixarnos para os influíntes

# De novo podemos considerar que equipos son os que resultan en estas observacións
barplot(table(datos$Equipo[posibles_influyentes]), las = 2, 
        main = "Equipos que producen observacións con capacidade de influencia")
# O equipo que máis destaca é, como para as observacións atípicas, o Barcelona.
# Probablemente o motivo sexa semellante ao discutido anteriormente. Na tempada
# pasada este equipo tivo numerosos partidos cun marcador moi avultado.
barplot(table(datos$Rival[posibles_influyentes]), las = 2, 
        main = "Equipos que reciben observacións con capacidade de influencia")
# Neste caso volve destacar o Valladolid. Podemos atribuírlle tamén as 
# mesmas razóns que nas observacións atípicas. O Valladolid era un equipo
# recentemente ascendido que non tiña a calidade nin o orzamento para competir 
# co resto de clubs de Primeira División.

# Para comprobar se estas observacións realmente exercen influencia debemos usar
# a distancia de Cook
dist_cook <- cooks.distance(modelo_simple)
# Vexamos como se distribúen estes valores
hist(dist_cook, xlab = "Distancia de Cook", ylab = "Frecuencia", main = "")
rug(dist_cook)
summary(dist_cook)

# Comprobemos agora se os valores obtidos son "grandes" ou non. Isto
# conséguese comparando as distancias cos cuantís dunha distribución 
# F_{p, n-p}, sendo n o número de datos e p o número de parámetros
umbral <- qf(0.5, 7, length(y)-7)
abline(v = umbral, col = "red", lty = "dashed")
which(dist_cook > umbral)
# Obtemos que ningunha das observacións exerce influencia pese a existir 
# numerosas con capacidade
################################################################################


################ VALIDACION ####################################################
# Queremos comprobar agora se o noso modelo cumpre as hipóteses básicas dun
# modelo de regresión lineal múltiple, é dicir, normalidade, homocedasticidade,
# linearidade e independencia
# Comezamos probando a normalidade dos erros. Podemos volver recorrer a un
# dos gráficos que viamos antes para facernos unha primeira idea
qqPlot(res2, xlab = "Cuantiles de la distribución normal", ylab = "Residuos estandarizados")
# Se a hipótese de normalidade fose certa deberiamos ver que os valores se atopan
# próximos ás bandas azuis, o cal non ocorre no noso caso.
# Para podermos estar máis seguros usaremos un test coñecido como test Shapiro-Wilk.
# Este toma a seguinte forma:
# H0: epsilon = N(0, sigma^2)  |
# Ha: epsilon != N(0, sigma^2) |
shapiro.test(res2)
# Obtemos un p-valor de 2.2e-16 polo que temos evidencias significativas para
# rexeitar a hipótese nula. Non podemos supoñer normalidade

# Pasamos a comprobar a homocedasticidade, para a cal temos dous tests posibles.
# O primeiro que utilizaremos é o test de Breusch-Pagan, que toma a forma
# H0: Os erros son homocedásticos, sigma^2 é constante              |
# Ha: A varianza dos erros depende das variables explicativas       |
bptest(modelo_simple)
# Como o p-valor que obtemos é menor que todos os niveis de significación
# habituais, é 7.261e-10, rexeitamos a hipótese nula. Non podemos afirmar
# homocedasticidade por este test
# O seguinte test que podemos utilizar é o test Harrison-McCabe:
# H0: Os erros son homocedásticos, sigma^2 é constante  |
# Ha: A varianza ten un punto de cambio                 |
hmctest(modelo_simple)
# Neste caso non existen probas significativas para rexeitar a hipótese nula a un
# nivel do 5%, pois o p-valor obtido é 0,283. Nótense que isto non é contraditorio
# cos resultados do test anterior, pois este dinos que é preferible unha 
# varianza constante a unha que só ten un punto de cambio mentres que o anterior
# indica a preferencia por un no que a varianza depende das variables explicativas
# fronte a un no que esta é constante

# A seguinte hipótese a probar é a linearidade. O test que utilizaremos
# para comprobala é o test de reset de Ramsey, cuxa formulación é:
# H0: O modelo de regresión é lineal                            |
# Ha: O modelo de regresión é un polinomio de grao dous ou tres |
resettest(modelo_simple)
# Obtemos un p-valor de 0.3734, polo que cun nivel de significación do 
# 5% podemos supoñer linearidade
# Outra opción é realizar un test non paramétrico no que comparemos os valores 
# axustados coas observacións
sm.regression(fitted(modelo_simple), y, model = "linear", xlab = "Valores ajustados", ylab = "xG")
# Parece que o test nos permite afirmar a normalidade tamén pois a estimación
# da función de regresión queda dentro das franxas de confianza.

# Aínda que agora deberiamos validar a independencia, dado que o modelo non é 
# normal e o test de hipótese que usamos é incorrelación fronte a correlación
# de orde q, non podemos proceder pois neste caso independencia e 
# incorrelación non son equivalentes.
# Aínda así, validaremos a independencia entre as observacións de cada equipo,
# pois estas seguen unha liña temporal á que si podemos aplicar tests.
# Usaremos o test de Durbin-Watson, que toma a seguinte forma
# H0: Las observaciones son independientes     |
# Ha: Las observaciones no son independientes  |
# Creamos un vector onde imos almacenar os resultados do test de independencia a 
# cada equipo
resultados <- c()
# E agora iteramos sobre todolos equipos dos que temos datos
for (equipo in unique(datos$Equipo)) {
  # Temos que axustar un modelo usando as variables que imos considerado e os 
  # datos relativos aos partidos por equipo
  partidos_equipo <- subset(datos, Equipo == equipo)
  # Usaremos a función tryCatch porque este test pode dar erros
  resultado_equipo <- tryCatch({
    # Axustamos o modelo e evitamos que se amosen advertenzas
    suppressWarnings({
      modelo_equipo <- lm(
        partidos_equipo[, 1] ~ 
          partidos_equipo[, 7] +
          partidos_equipo[, 9] +
          partidos_equipo[, 10] +
          partidos_equipo[, 13] +
          partidos_equipo[, 21]
      )
      p_valor <- dwtest(modelo_equipo)$p.value
    })
    # Se o pvalor do test é menor de 0.05 non podemos afirmar a independencia, mentres
    # que si é maior o igual si a temos
    ifelse(p_valor < 0.05, "Falso", "Verdadeiro")
  }, error = function(e){
    # Saltar este equipo se hai erro
    "Error"
  })
  # Engadimos os resultados ao correspondente vector
  resultados <- c(resultados, resultado_equipo)
}
# Representamos os datos nun diagrama de barras para ver en cantos casos temos
# independenza
barplot(table(resultados)[2:3])
# Só podemos suponer a independencia nun equipo, veamos cal é
unique(datos$Equipo)[which(resultados == "Verdadeiro")]
# Temos que o Levante é o único equipo no que hai independenza

# Non obtivemos resultados moi satisfactorios na validación, pois hai polo 
# menos dúas hipóteses que non podemos afirmar. É posible que isto se deba á 
# presenza dos valores atípicos. Probemos a eliminalos a ver se isto inflúe
# en algo.
indices_a_eliminar <- c(
  28, 32, 40, 51, 88, 120, 128, 174, 183, 184, 223, 242, 312, 331, 337, 363, 367, 371, 410, 448,
  455, 501, 537, 543, 633, 682, 735, 747, 758, 781, 790, 817, 834, 846, 857, 877, 892, 912, 957, 969,
  983, 1006, 1013, 1031, 1102, 1108, 1124, 1161, 1200, 1227, 1231, 1282, 1288, 1313, 1320, 1332, 1341,
  1390, 1401, 1423, 1430, 1500, 1520, 1560, 1577, 1578, 1587, 1592, 1632, 1634, 1645
)
datos_limpios=datos[-indices_a_eliminar, ]
# Unha vez eliminadas as observacións atípicas debemos declarar as variables de
# novo
y_limpio=y[-indices_a_eliminar]
x3_limpio = datos_limpios$`Promedio de posesión del equipo`
x5_limpio = datos_limpios$`Goles por partido equipo`
x6_limpio = datos_limpios$`Asistencias por partido equipo`
x9_limpio = datos_limpios$`Paradas por partido rival`
x17_limpio = datos_limpios$`Acciones de gol permitidas por partido rival`
# Axustamos de novo o modelo cos novos datos e visualizamos un summary
modelo_simple_limpio = lm(y_limpio~x3_limpio+x5_limpio+x6_limpio+x9_limpio+x17_limpio)
summary(modelo_simple_limpio)
# Obtemos os residuos
res2_limpios = rstandard(modelo_simple_limpio)
# Volvemos realizar os tests e gráficas
qqPlot(res2_limpios, xlab = "Cuantiles de la distribución normal", ylab = "Residuos estandarizados")
shapiro.test(res2_limpios)
bptest(modelo_simple_limpio)
hmctest(modelo_simple_limpio)
resettest(modelo_simple_limpio)
sm.regression(fitted(modelo_simple_limpio), y_limpio, model = "linear", xlab = "Valores ajustados", ylab = "xG")
resultados_limpios <- c()
for (equipo in unique(datos$Equipo)) {
  partidos_equipo <- subset(datos_limpios, Equipo == equipo)
  resultado_equipo <- tryCatch({
    # Desactivar advertencias (só dentro deste bloque)
    suppressWarnings({
      modelo_equipo <- lm(
        partidos_equipo[, 1] ~ 
          partidos_equipo[, 7] +
          partidos_equipo[, 9] +
          partidos_equipo[, 10] +
          partidos_equipo[, 13] +
          partidos_equipo[, 21]
      )
      p_valor <- dwtest(modelo_equipo)$p.value
    })
    ifelse(p_valor < 0.05, "Falso", "Verdadeiro")
  }, error = function(e){
    # Saltar este equipo se hai erro
    "Error"
  })
  resultados_limpios <- c(resultados_limpios, resultado_equipo)
}
barplot(table(resultados_limpios)[2:3])
unique(datos$Equipo)[which(resultados_limpios == "Verdadeiro")]
# Vemos que os resultados obtidos seguen sendo exactamente os mesmos que 
# sen eliminar os datos. A linearidade pódese supoñer pero non as demais hipóteses.
# Ante isto, seguiremos traballando con todos os datos, pois non obtemos ningunha
# vantaxe ao eliminalos.
################################################################################


################ ANOVA #########################################################
# Lembremos que un dos obxectivos de formular o modelo de regresión lineal
# múltiple era estudar a relación que existe entre as distintas variables explicativas 
# e a variable resposta. Pois ben, usaremos isto e a análise de varianzas 
# para determinar se é certa a crenza de que xogar na casa ou fóra afecta
# ao rendemento, en concreto se se marcan máis goles na casa ca fóra.
# Isto pode acadarse mediante un ANOVA. Vexámolo:

# Comezamos convertendo a variable Localía nunha variable categórica
Localía=factor(datos$Localía)
# Agora debemos parametrizar as nosas observacións dalgún modo. Optamos por facelo
# por desviacións respecto dun grupo de referencia.
# Por defecto tómase o primeiro grupo, é dicir, ser Local, como grupo de 
# referencia
# Obteremos os mesmos resultados independientemente de cal escollamos, pero 
# farémolo con ambos para comprobalo
Localía_2ref=relevel(Localía, ref=2)
# Convertimos o segundo grupo, Visitante, no grupo de referencia
# Así, podemos axustar dous modelos, un para cada grupo de referencia
modelo_anova_1 = lm(y~Localía)
summary(modelo_anova_1)
modelo_anova_2=lm(y~Localía_2ref)
summary(modelo_anova_2)
# Nótense que obtemos o mesmo R-cadrado axustado para ambos casos, 0.0465 e 
# os valores da significación dos coeficientes son sempre menores de 2e-16
# Para cada modelo, o intercepto representa a media de goles agardados do grupo
# de referencia correspondente e o outro é a cantidade que se debe engadir ao
# intercepto para obter a media do outro grupo.

# Para responder agora a pregunta que nos formulabamos ao principio podemos 
# realizar un ANOVA dos modelos que axustamos. Este comando realiza o 
# test seguinte
# H0: A media de goles agardados como local coincide coa de visitante  |
# Ha: A media de goles agardados como local é distinta á de visitante  |
anova(modelo_anova_1)
anova(modelo_anova_2)
# Como vemos, en ambos casos obtemos un p-valor inferior a 2.2e-16, moi pequeno,
# polo que rexeitamos a hipótese nula e podemos dicir que os goles agardados
# son máis altos cando o equipo xoga como local que cando o fai como 
# visitante.

# Agora que podemos afirmar que as medias de goles agardados son distintas dependendo
# de se un equipo xoga como local ou visitante podemos considerar canto de grande 
# é esta diferenza, é dicir, que vantaxe esperamos que teña un equipo cando 
# xoga como local respecto a cando o fai como visitante.
# Para isto podemos calcular intervalos de confianza para a diferenza das 
# medias do seguinte modo
TukeyHSD(aov(modelo_anova_1))
TukeyHSD(aov(modelo_anova_2))
# Como é de esperar obtemos os mesmos resultados para cada modelo (pero cos
# extremos intercambiados e con signo oposto por variar a orde da resta)
# Podemos afirmar que, xogando como local, os equipos esperan de media entre 
# 0,27 e 0,42 goles máis que como visitantes

# Encargarémonos agora da validación e diagnosis deste modelo ANOVA, comezando
# coa última destas. 
# Como antes, o primeiro que facemos é un plot do modelo
par(mfrow = c(2, 2))
plot(modelo_anova_1)
# A interpretación destas gráficas é parecida a que demos para o modelo lineal
# múltiple. A primeira vista parece que imos ter resultados semellantes, 
# é dicir, é dubidosa a normalidade, temos varias observacións atípicas pero 
# aparentemente non influintes. En canto a homocedasticidade non podemos inferir
# moito destas graficas
# Podemos facer tamén un boxplot 
par(mfrow = c(1,1))
boxplot(y~Localía)
# Que tamén nos amosa a presenza de observación atípicos
# Traballemos agora para asegurarnos das nosas ideas obtendo os residuos do modelo
res1_anova <- residuals(modelo_anova_1)
res2_anova <- rstandard(modelo_anova_1)
res3_anova <- rstudent(modelo_anova_1)
# Visualizémolos
par(mfrow = c(1,1))
valores_residuos_anova <- cbind(res1_anova, res2_anova, res3_anova)
for (i in 1:3){
  hist(valores_residuos_anova[,i], , xlab = nombres_residuos[i], ylab = "Frecuencia", main = "")
  rug(valores_residuos_anova[,i])
  readline(prompt = "Pulsa [Intro] para pasar a los siguientes gráficos")
}
# Buscaremos as observacións cuxos residuos superen o valor 1.96
atipicos_standard_anova <- which(abs(res2_anova) > 1.96)
atipicos_student_anova <- which(abs(res3_anova) > 1.96)
# As observacións atípicas coinciden en ambos casos e só diferencianse das do modelo
# simple nunha observación, polo que non repetiremos as gráficas relativos a estos

# Para as observacións con capacidade de influencia usamos os leverages
leverages_anova <- hat(model.matrix(modelo_anova_1))
# Vexamos a distribución destes antes de comprobar se son grandes ou non
hist(leverages_anova, xlab = "Leverages", ylab = "Frecuencia", main = "")
summary(leverages_anova)
# Todos os leverages son iguais e valen 0.001203369, así que non pode haber
# observacións con capacidade de influencia nin observacións influentes.

# Finalmente quédanos a validación do modelo ANOVA. 
# Debemos comprobar a normalidade e a homocedasticidade, pois son as únicas
# hipóteses que temos neste tipo de modelos
# Comezando coa normalidade, debemos estudar esta en cada unha das categorías
# por separado. De novo usamos o test Shapiro-Wilkins e os qqPlots
qqPlot(res2_anova[Localía == "Local"], xlab = "Cuantiles de la distribución normal", ylab = "Residuos estandarizados", main = "Local")
qqPlot(res2_anova[Localía == "Visitante"], xlab = "Cuantiles de la distribución normal", ylab = "Residuos estandarizados", main = "Visitante")
shapiro.test(res2_anova[Localía == "Local"])
shapiro.test(res2_anova[Localía == "Visitante"])
# En ambos casos obtemos un p-valor inferior a 2.2e-16, polo que temos probas
# estatisticamente significativas en contra da hipótese nula, non podemos garantir
# a normalidade en ningún dos dous grupos
# No que respecta á homocedasticidade, usaremos o test de Levene, que compara se as
# varianzas son iguais en cada grupo. No noso caso será:
# H0: sigma^2_local = sigma^2_visitante   |
# Ha: sigma^2_local != sigma^2_visitante  |
abs_res_anova <- abs(modelo_anova_1$residuals)
levene_modelo <- lm(abs_res_anova ~ Localía)
anova(levene_modelo)
# O F-valor obtido neste test é 0.0001117, inferior a todos os niveis de 
# significación habituais, polo que rexeitamos a hipótese nula. Non podemos
# asegurar que ambos grupos teñan a mesma varianza

# Probemos a eliminar os datos atípicos a ver se isto inflúe
# na validación do modelo
indices_a_eliminar_anova <- c(
  17, 51, 82, 88, 120, 128, 157, 173, 174, 234, 242, 252, 277, 312, 331, 337, 343, 
  367, 371, 406, 410, 429, 455, 469, 501, 544, 585, 662, 781, 790, 808, 817, 834, 
  857, 859, 877, 880, 892, 904, 912, 957, 969, 973, 983, 1006, 1039, 1052, 1069, 
  1081, 1108, 1124, 1146, 1161, 1200, 1227, 1228, 1282, 1288, 1320, 1322, 1401, 
  1414, 1430, 1488, 1518, 1520, 1560, 1577, 1587, 1592, 1609, 1634, 1645)
datos_limpios_anova=datos[-indices_a_eliminar_anova, ]
# Unha vez eliminadas as observacións atípicas debemos declarar as variables de
# novo
y_limpio_anova=y[-indices_a_eliminar_anova]
Localía_limpio_anova=Localía[-indices_a_eliminar_anova]
# Axustamos de novo o modelo cos novos datos e visualizamos un summary
modelo_anova_limpio = lm(y_limpio_anova~Localía_limpio_anova)
summary(modelo_anova_limpio)
# Obtemos os residuos
res2_anova_limpios = rstandard(modelo_anova_limpio)
# Volvemos realizar os tests e gráficas
shapiro.test(res2_anova_limpios[Localía_limpio_anova == "Local"])
shapiro.test(res2_anova_limpios[Localía_limpio_anova == "Visitante"])
abs_res_anova_limpio <- abs(modelo_anova_limpio$residuals)
levene_modelo_anova_limpio <- lm(abs_res_anova_limpio ~ Localía_limpio_anova)
anova(levene_modelo_anova_limpio)
# Do mesmo xeito que sucedía no modelo múltiple, os resultados obtidos
# seguen sendo exactamente os mesmos que sen eliminar os datos 
# A linearidade pódese supoñer pero non a homocedasticidad.
################################################################################


################ ANCOVA ########################################################
# De maneira similar ao formulado no apartado anterior sobre se os goles
# agardados son maiores cando se xoga como local, podemos preguntarnos se 
# o ataque de cada equipo é igualmente efectivo xogando na casa que xogando 
# fóra. Para iso, podemos formular un modelo ANCOVA usando como variables 
# explicativas a localía, o promedio de posesión, os goles e as asistencias
# por partido.

# O modelo ANCOVA formúlase como un modelo de regresión habitual
modelo_ancova = lm(y~Localía+x3+x5+x6)
summary(modelo_ancova)
# Obtemos un modelo no que os coeficientes relativos a cada variable explicativa
# son significativos, non obstante o intercepto non o é.

# A pesar de que sabemos que as variables que estamos a utilizar son significativas 
# no modelo múltiple, non sabemos se ao engadir a variable Localía seguen 
# afectando á resposta. Para contrastar isto podemos facer un F test comparando
# o modelo só coa variable Localía e o modelo con esta e todas as continuas.
# En concreto estaremos comparando un ANOVA na hipótese nula cun ANCOVA na
# hipótese alternativa
anova(modelo_anova_1, modelo_ancova)
# Obtemos probas significativas para rexeitar a hipótese nula de que as 
# variables continuas non afectan á resposta

# Unha vez sabemos que as variables continuas realmente afectan á resposta 
# podemos empezar a responder a pregunta que formulamos ao comezo desta 
# sección, é dicir, se a localía inflúe no efecto que ten o ataque dun
# equipo nos seus goles agardados.
# Isto resolvémolo recorrendo de novo a un F test. Neste caso compararemos
# se é mellor formular un modelo lineal múltiple (a hipótese nula) ou se realmente
# a variable categórica inflúe e debemos usar un ANCOVA (a hipótese alternativa)
modelo_sin_categorica <- lm(y~x3+x5+x6)
anova(modelo_sin_categorica, modelo_ancova)
# Obtemos un F-valor inferior a 2.2e-16 polo que é preferible o modelo ANCOVA
# Isto confírmanos que a eficacia do ataque dun equipo depende de onde xoga.
# Interesarános agora estudar de que modo afecta, é dicir, se é máis efectiva
# na casa ou fóra e canto máis.

# Para ver se os coeficientes relativos a cada variable continua son diferentes 
# dependendo da categoría de Localía debemos primeiro formular un modelo ANCOVA
# con interacción e logo comparalo co que estamos usando ata agora
modelo_ancova_interaccion <- lm(y~Localía*(x3+x5+x6))
summary(modelo_ancova_interaccion)
anova(modelo_ancova, modelo_ancova_interaccion)
# O F test devolve un F-valor de 0.0002978, polo que podemos asegurar que é
# mellor un modelo con interacción que un sen ela

# Para ver como é a diferenza entre os coeficientes debemos obter a
# estimación de todos para ambos casos
modelo_ancova_interaccion$coefficients
# Estudiemos paso a paso o que significa esta saída. O intercepto para a categoría
# local é -0.24 e representaría os goles agardados cando todas as variables
# explicativas continuas son 0. Aínda que poida parecer estraño que sexa negativo 
# (pois os goles agardados son sempre maiores ou iguais a 0), o feito de que 
# as variables explicativas nunca poidan ser 0 e que o coeficiente non sexa
# significativo fan que non nos preocupe excesivamente. O mesmo ocorre para o 
# intercepto cando estamos na categoría visitante. Neste caso toma o valor 
# -0.24 + 0.20 = -0.04, e aínda que pareza estraño que sexa maior que no caso
# local isto pode ser xustificado pola súa falta de significación. O coeficiente
# relativo a x3 é 0.011 para o grupo Local e 0.011 + 0.0006= 0.0116 para o 
# visitante. Isto significa que se un equipo é capaz de manter a mesma posesión
# na casa que fóra, xogando como visitante conseguirá que se materialice en máis goles.
# Isto probablemente se deba a que se un equipo é capaz de manter a posesión
# coa afección en contra é porque xoga ben baixo presión. Os coeficientes 
# relativos a x5 e x6 ambos diminúen ao pasar á categoría Visitante, indo de
# 0.27 e 0.94 a 0.07 e 0.53 respectivamente. Isto significa que os tiros e asistencias
# necesarios para obter un gol agardado son maiores cando se xoga fóra da 
# casa.

# Do mesmo xeito que faciamos antes podemos calcular intervalos de confianza 
# para cada un dos coeficientes do modelo
confint(modelo_ancova_interaccion, level=0.95)

# Como é habitual rematamos coa validación e a diagnosis. O
# procedemento é completamente análogo ao que xa realizamos nas anteriores
# dúas ocasións polo que só comentaremos os resultados 
par(mfrow = c(2,2))
plot(modelo_ancova_interaccion)
boxplot(y~Localía*(x3+x5+x6))
res1_ancova <- residuals(modelo_ancova_interaccion)
res2_ancova <- rstandard(modelo_ancova_interaccion)
res3_ancova <- rstudent(modelo_ancova_interaccion)
par(mfrow = c(1,1))
valores_residuos_ancova <- cbind(res1_ancova, res2_ancova, res3_ancova)
for (i in 1:3){
  hist(valores_residuos_ancova[,i], , xlab = nombres_residuos[i], ylab = "Frecuencia", main = "")
  rug(valores_residuos_ancova[,i])
  readline(prompt = "Pulsa [Intro] para pasar a los siguientes gráficos")
}
atipicos_standard_ancova <- which(abs(res2_ancova) > 1.96)
atipicos_student_ancova <- which(abs(res3_ancova) > 1.96)
# Neste caso os atípicos son diferentes aos resultantes do ANOVA e do 
# modelo lineal múltiple polo que podemos volver visualizar que equipos
# producen e reciben observacións atípicas
barplot(table(datos$Equipo[atipicos_standard_ancova]), las = 2, 
        main = "Equipos que producen observaciones atipicas")
# Neste caso cabe destacar equipos como o Atlético Madrid ou o Girona. Este último
# presentou hai dous anos unha gran diferenza entre os seus partidos na casa, nos que 
# o rendemento foi excepcional, fronte aos xogos fóra da casa nos que os resultados
# foron moito máis modestos. O Atlético sufriu un comportamento parecido
barplot(table(datos$Rival[atipicos_standard_ancova]), las = 2, 
        main = "Equipos que reciben observaciones atipicas")
# Aquí volvemos destacar ao Girona polo xa mencionado anteriormente xunto con
# outros equipos como o Celta de Vigo, Las Palmas, Valladolid ou Villarreal. Dous de
# eles xa os mencionamos anteriormente e explicamos o seu comportamento fóra de 
# lugar, mentres que os outros dous son clubs que tiveron rachas destacadas
# de actuar por debaixo do seu nivel na casa

# Continuamos agora coas observacións con capacidade de influencia e influintes
leverages_ancova <- hat(model.matrix(modelo_ancova_interaccion))
hist(leverages_ancova, xlab = "Leverages", ylab = "xG", main = "")
rug(leverages_ancova)
summary(leverages_ancova)
posibles_influyentes_ancova <- which(leverages_ancova >= 2 * mean(leverages_ancova))
abline(v = 2 * mean(leverages_ancova), col = "red", lty = "dashed")
# De novo estas observacións son distintas ás que obtiñamos no modelo
# lineal múltiple polo que podemos visualizar que equipos as protagonizan para
# maior profundidade
barplot(table(datos$Equipo[posibles_influyentes_ancova]), las = 2, 
        main = "Equipos que producen observaciones con capacidad de influencia")
# Non sorprende a estas alturas a presenza do Barcelona nun gráfico deste 
# estilo. Como xa dixemos tanto xogando como Local como como Visitante creou
# gran cantidade de goles con poucas ocasións
barplot(table(datos$Rival[posibles_influyentes_ancova]), las = 2, 
        main = "Equipos que reciben observaciones con capacidad de influencia")
# Neste gráfico cabe destacar ao Getafe, que cun xogo moi particular centrado
# nunha defensa dura pode recibir numerosas observacións con capacidade de influencia
# se a arbitraxe non está ao seu favor, o cal pode ocorrer fóra da casa.
# Finalmente comprobamos se ditas observacións exercen influencia
dist_cook_ancova <- cooks.distance(modelo_ancova_interaccion)
hist(dist_cook_ancova, xlab = "Distancia de Cook", ylab = "Frecuencia", main = "")
rug(dist_cook_ancova)
summary(dist_cook_ancova)
umbral_ancova <- qf(0.5, 4, length(y)-4)
abline(v = umbral_ancova, col = "red", lty = "dashed")
which(dist_cook > umbral)
# Ningunha observación é influinte. Finalizada a diagnosis pasamos á validación

# Ao estarmos ante un modelo ANCOVA con interacción, a validación realízase
# de maneira separada para cada grupo. Formulamos pois dous modelos de regresión lineal
# múltiple por separado
modelo_local <- lm(y[Localía=="Local"] ~ x3[Localía=="Local"] + x5[Localía=="Local"]+x6[Localía=="Local"])
modelo_visitante <- lm(y[Localía=="Visitante"] ~ x3[Localía=="Visitante"] + x5[Localía=="Visitante"]+x6[Localía=="Visitante"])

# Procedemos a realizar todos os tests e gráficas que xa fixemos antes.
# Comezamos co test de normalidade e qqPlots
res_local <- rstandard(modelo_local)
res_visitante <- rstandard(modelo_visitante)
qqPlot(res_local, xlab = "Cuantiles de la distribución normal", ylab = "Residuos estandarizados")
qqPlot(res_visitante, xlab = "Cuantiles de la distribución normal", ylab = "Residuos estandarizados")
shapiro.test(res_local)
shapiro.test(res_visitante)
# En ambos casos obtemos un p-valor menor que 2.2e-16 polo que non podemos 
# afirmar a normalidade do modelo. A gráfica tampouco apunta cara á normalidade
# Pasamos agora a comprobar a homocedasticidade
bptest(modelo_local)
bptest(modelo_visitante)
# O p-valor é menor que todos os niveis de significación habituais en ambos
# casos polo que rexeitamos a homocedasticidade fronte a que a varianza depende
# das variables explicativas
hmctest(modelo_local)
hmctest(modelo_visitante)
# Os resultados son os mesmos que antes, é preferible aceptar a homocedasticidade
# fronte a que a varianza cambie nun punto, pero á vista do test anterior
# quedámonos con heterocedasticidade.
# Finalmente quédanos a linearidade
resettest(modelo_local)
resettest(modelo_visitante)
# Neste caso, dependendo do nivel de significación que tomemos, podemos asumir
# normalidade fronte a un polinomio de grao 2 ou 3
harvtest(modelo_local)
harvtest(modelo_visitante)
# Neste segundo test volvemos obter que o modelo lineal é preferible a un
# sempre cóncavo ou sempre convexo.
# E por último, o test non paramétrico
sm.regression(fitted(modelo_local), y[Localía=="Local"], model = "linear", xlab = "Valores ajustados", ylab = "xG")
sm.regression(fitted(modelo_visitante), y[Localía=="Visitante"], model = "linear", xlab = "Valores ajustados", ylab = "xG")
# Este test tamén favorece a linearidade

# Igual que en casos anteriores, eliminemos as observacións atípicas para comprobar 
# se sen elas o modelo 
indices_a_eliminar_ancova <- c(32, 40, 51, 75, 88, 120, 128, 174, 183, 184, 242, 312, 331, 337, 363, 367, 371, 374, 404, 410, 429,
                               448, 455, 501, 543, 735, 747, 758, 781, 790, 817, 834, 846, 857, 877, 892, 912, 957, 969, 973, 976, 983,
                               1006, 1013, 1031, 1069, 1108, 1124, 1138, 1161, 1200, 1227, 1231, 1282, 1288, 1320, 1332, 1341, 1401, 1414, 1423, 1430, 1520,
                               1577, 1578, 1587, 1592, 1634, 1645)
datos_limpios_ancova=datos[-indices_a_eliminar_ancova, ]
# Unha vez eliminadas as observacións atípicas debemos declarar as variables de
# novo
y_limpio_ancova=y[-indices_a_eliminar_ancova]
Localía_limpio_ancova=Localía[-indices_a_eliminar_ancova]
x3_limpio_ancova = datos_limpios_ancova$`Promedio de posesión del equipo`
x5_limpio_ancova = datos_limpios_ancova$`Goles por partido equipo`
x6_limpio_ancova = datos_limpios_ancova$`Asistencias por partido equipo`
# Axustamos de novo os modelos cos novos datos e visualizamos os summary
modelo_local_limpio <- lm(y_limpio_ancova[Localía_limpio_ancova=="Local"] ~ x3_limpio_ancova[Localía_limpio_ancova=="Local"] + x5_limpio_ancova[Localía_limpio_ancova=="Local"]+x6_limpio_ancova[Localía_limpio_ancova=="Local"])
modelo_visitante_limpio <- lm(y_limpio_ancova[Localía_limpio_ancova=="Visitante"] ~ x3_limpio_ancova[Localía_limpio_ancova=="Visitante"] + x5_limpio_ancova[Localía_limpio_ancova=="Visitante"]+x6_limpio_ancova[Localía_limpio_ancova=="Visitante"])
summary(modelo_local_limpio)
summary(modelo_visitante_limpio)
# E agora pasamos á obtencion dos residuos
res_local_limpio <- rstandard(modelo_local_limpio)
res_visitante_limpio <- rstandard(modelo_visitante_limpio)
# E á realizacion dos tests
shapiro.test(res_local_limpio)
shapiro.test(res_visitante_limpio)
bptest(modelo_local_limpio)
bptest(modelo_visitante_limpio)
hmctest(modelo_local_limpio)
hmctest(modelo_visitante_limpio)
harvtest(modelo_local_limpio)
harvtest(modelo_visitante_limpio)
# Vemos que as conclusións obtidas seguen sendo exactamente as mesmas que 
# sen eliminar os datos. A linearidade pódese supoñer pero non as demais hipóteses.
# Igual que no caso múltiple e para o anova, eliminar os datos atípicos non fai
# que obteñamos ningunha vantaxe en canto á validación do modelo
################################################################################


################ CONCLUSION ####################################################
# Fomos capaces de axustar, en primeiro lugar, un modelo lineal múltiple que nos
# aportou información sobre que variables, de entre todas as que recolléramos,
# son realmente importantes para determinar os goles esperados e en que modo
# afectan
# Posteriormente fomos capaces de demostrar que os equipos actúan mellor cando
# xogan na casa comprobando que xeran, de media, máis goles esperados
# En último lugar estudiamos como varía o efecto dalgunhas métricas de ataque
# dependendo da localía, obtendo que, en xeral, se necesitan máis
# oportunidades para crear os mesmos goles esperados cando se xoga como visitante.
################################################################################



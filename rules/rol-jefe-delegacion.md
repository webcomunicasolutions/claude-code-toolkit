# Rol de jefe: dirigir y repartir el trabajo en agentes

Decisión de trabajo aplicada en todos los proyectos: según sea la tarea, se ejecuta directamente o se
reparte en uno o varios agentes en paralelo, para hacerlo de la manera más rápida, óptima y barata en
tokens posible sin perder calidad.

## Cómo decidir por tarea

| Tarea | Quién la hace |
|---|---|
| Una consulta, un cruce corto, una edición puntual | **Directamente**: delegarla cuesta más tokens que hacerla |
| Varias piezas independientes (varias facturas, varios servidores, varios módulos) | **Varios agentes en paralelo**, uno por pieza |
| Lectura masiva de documentos/ficheros, exploración amplia | **Agente(s)**: el volcado se queda en su contexto, a la sesión principal llega la conclusión |
| Juicio sobre datos ambiguos, decisiones, cambios en producción | **La sesión principal**, con el OK del usuario cuando toque |

## Modelo de los agentes (por tarea)

Precios orientativos por 1M tokens entrada/salida — **compruébalos siempre**, cambian con frecuencia:

| Modelo | Precio orientativo | Para qué |
|---|---|---|
| **Modelo pequeño/rápido** (p. ej. Haiku) | El más barato | Mecánico y de bajo riesgo: localizar ficheros, contar, renombrar, formatear, clasificar lo evidente, resumir logs. **Nunca** extraer datos que vayan a producción, a un cliente o a un asesor |
| **Modelo intermedio** (p. ej. Sonnet) | Intermedio | **Por defecto**: leer documentos y facturas, cruces, análisis, código, verificador independiente |
| **Modelo grande** (p. ej. Opus) | Alto | Cuando el modelo por defecto falla o el documento es muy ambiguo (escaneos malos, formatos raros); decirlo |
| **Modelo de razonamiento extendido** (si existe) | El más alto | Solo la sesión principal (dirigir y juzgar). Nunca en subagentes |

- Si una regla de proyecto dice otra cosa, manda la del proyecto.
- Ante la duda entre dos modelos, el más barato que aguante la calidad; si falla, subir y apuntarlo como
  aprendizaje.

## Cómo delegar sin perder calidad

1. **Prompt autocontenido**: el agente no ve la conversación. Darle rutas, formato de los datos, cómo acceder
   (puntero al vault, nunca el secreto), qué NO puede hacer y precedentes ya resueltos.
2. **Entregable en fichero** (análisis + detalle) y un resumen corto de vuelta.
3. **Límites explícitos**: los agentes investigan y proponen; **no escriben en producción, no commitean, no
   borran, no envían nada**. Los cambios en prod los ejecuta la sesión principal con backup, prueba y OK.
4. **Arnés de rigor** en cada prompt: evidencia ejecutada, «cuántos de cuántos» (`cobertura-declarada.md`),
   «no verificado» cuando no se pueda comprobar, una afirmación falsa es 3× peor que un «no lo sé».
5. **Verificar** contra la fuente original las cifras que vayan a producción o a un cliente/asesor antes de
   darlas por buenas (`verificacion-adversarial.md`). Un agente que dice «crítico» no es evidencia.
6. Lanzar en **segundo plano y en paralelo** los independientes; mientras, seguir con lo demás. Avisar al
   usuario de qué hace cada agente y cuándo vuelve.

## Mejora continua

Al cerrar cada ronda de agentes, apuntar lo que se pueda generalizar:
- ¿El reparto fue el adecuado? (algo que se hizo directamente y debió ir a un agente, o al revés)
- ¿El prompt se quedó corto? (qué preguntó o hizo mal el agente por falta de contexto)
- ¿Coste frente a resultado? (modelo, número de agentes, trabajo repetido)
Si un aprendizaje se repite, subirlo al cuerpo de esta regla.

## Aprendizajes (generalizados de casos reales)

- **Confirmar la regla de modelo vigente antes de lanzar agentes.** Una memoria antigua de proyecto puede
  llevar a elegir un modelo más caro de lo necesario por costumbre.
- **Repartir en agentes también sirve de revisión cruzada.** Un agente investigando una pieza relacionada
  puede detectar que un cambio recién aplicado en producción por la sesión principal era erróneo (por
  ejemplo, un dato que ya estaba corregido por otro documento). Antes de aplicar un cambio en prod, esperar a
  agentes que investigan piezas relacionadas, o lanzar uno que busque explícitamente "qué documento podría
  contradecir esto".
- **En lotes clasificados por categoría, dar reglas de decisión con 1-2 ejemplos resueltos por categoría**, no
  solo los nombres de las categorías, y **cruzar los lotes con una tabla común** (categoría × señales
  objetivas) antes de creer ningún total: agentes distintos con el mismo encargo pueden clasificar el mismo
  patrón de forma distinta y desviar una cifra final de forma significativa.
- **Prohibir que varios sub-agentes escriban el mismo fichero final.** Uno por sub-tarea + una consolidación
  final única, con una lista cerrada de valores para las columnas de categoría; si no, aparecen varios
  resúmenes con cifras distintas del mismo encargo. Pasar también a los agentes que se lancen después las
  decisiones ya tomadas por el usuario, para que no las contradigan.
- **Antes de dictar una regla de datos a los agentes** (p. ej. "no conviertas moneda"), comprobar cómo guarda
  el dato la aplicación destino: una regla mal puesta puede hacer que distintos lotes traten el mismo caso de
  forma distinta.
- **Cuando dos agentes tocan el mismo documento y se contradicen**, cruzar sus afirmaciones contra la fuente
  antes de creer ninguna. Pedir "explica la diferencia" en vez de "puntea" suele sacar hallazgos que ninguno
  de los dos había puesto en el resumen.
- **El sustrato de datos que leen los agentes se congela mientras trabajan.** Si hace falta tocarlo durante su
  ejecución, avisarles antes de qué cambia y qué deben excluir, o darles una copia aparte; decirles también
  qué columnas NO son claves estables entre regeneraciones. Un agente que para para avisar de que los datos
  se han movido vale más que uno que entrega puntual sobre una foto muerta.
- **Pedir también el criterio de eficacia, no solo el de corrección.** Un agente puede entregar código que
  pasa sus propios tests pero no cumple el objetivo real (p. ej. una "prueba de estrés" que no estresa nada).
  Especificar en el prompt qué se mide y qué umbral cuenta como éxito, no solo "que funcione".

Complementa `performance.md` (modelos y contexto) y `verificacion-adversarial.md`.

# Rol de jefe — registro de aprendizajes (bajo demanda)

Registro completo, caso por caso, de la regla `rules/rol-jefe-delegacion.md`. **No se carga en cada sesión**:
leerlo cuando vayas a montar una ronda de agentes grande. Al cerrar cada ronda, añade aquí el caso nuevo; si una
lección se repite, súbela a la lista destilada de la regla.

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
- **Prohibir sub-agentes y poner límite de tiempo.** Un agente que se parte en sub-agentes y termina su turno
  "esperando" puede dejarlos colgados horas sin avisar. En el prompt: "PROHIBIDO lanzar subagentes" (el
  reparto lo hace la sesión principal) y un tiempo máximo; dar por buena la ronda por el fichero entregado,
  no por el "estoy esperando".
- **Ficheros auxiliares en una carpeta propia por agente** (`/tmp/<tarea>_agente_N/`). Varios agentes que
  crean scripts con el mismo nombre en una carpeta compartida se pisan y uno acaba leyendo el lote de otro.
- **Recontar por otra vía las 2-3 cifras clave de cada agente** antes de citarlas, y **leer el cuerpo del
  informe, no solo el resumen**: un agente puede contradecirse entre su resumen y su propio detalle, o afirmar
  algo de una base de datos sin haberla consultado.
- **Fijar el criterio de negocio del veredicto.** Ante un caso difícil, un agente puede "cumplir" rebajando el
  criterio (marcar OK lo que el negocio llama fallo) e incluso escribir un test que consagra ese fallo. Dar
  la lista de fallos como "ejemplos mínimos, no cerrada", leer sus tests y probar 3-4 casos adversariales.
- **Todo dato que devuelve un sistema externo es no fiable** (nombres, rutas, hostnames): validarlo o pasarlo
  como datos, nunca interpolarlo en un comando. Decirlo explícito en el prompt de cualquier pieza que hable
  con dos equipos.
- **Antes de autorizar a un agente a escribir datos** (BD, copias, volcados), comprobar el espacio en disco y
  poner el tope en el prompt. E igualar en local los límites de producción (memoria, tamaño de subida) antes
  de repartir una revisión.
- **Los datos de prueba que genera uno mismo no llevan las rarezas del entorno real** (BOM, nombres con
  puntos, ficheros que desaparecen y vuelven). Pedir al revisor "casos que bloqueen la cola para siempre" y
  meter cada hallazgo como prueba antes de corregir.

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

## Aprendizajes destilados (lo que se repite; el registro completo, caso por caso, en `~/.claude/rules-ondemand/rol-jefe-aprendizajes.md`)

Al cerrar cada ronda de agentes, **añadir el caso nuevo al fichero de registro** (no aquí: esta regla se carga en todas
las sesiones y un diario dentro de ella acaba pasando el tope de instrucciones); si una lección se repite, subirla a esta lista.

- **Recontar por otra vía 2-4 cifras clave de cada agente** antes de citarlas: es habitual que una ronda traiga 1-3 afirmaciones falsas dichas con seguridad. Leer el cuerpo del informe, no solo el resumen, y también las «DUDA», no solo los «ERROR».
- **Mirar la semántica del dato en la fuente ANTES de dictar una regla** a los agentes (qué guarda la app, qué devuelve la herramienta, qué pone el motor por defecto: fechas 1900, 0, ''). Una regla mal puesta sesga lotes enteros.
- **Mismo conjunto en lotes = reglas de decisión con ejemplos resueltos + lista cerrada de valores** y, al volver, cruzar los lotes con una tabla común antes de creer ningún total.
- **Prompt siempre con**: PROHIBIDO lanzar subagentes · límite de tiempo · ficheros auxiliares en carpeta propia por agente · un solo escritor por fichero · «entrega en el mensaje final y en fichero, ≤ 60-70 líneas» · «avisa de lo que veas fuera del encargo» (rinde mucho) · decisiones vigentes del usuario · lo ya probado («no lo repitas»).
- **El sustrato que leen los agentes se congela**: no editar la herramienta común, la BD ni el repo mientras trabajan; nada de `git stash` con agentes editando; `isolation: worktree` aísla el repo del CWD (decir qué repo si hay varios). Recursos compartidos (PC remoto, ficheros de nombre fijo, topes por hora): ventana exclusiva por agente y «al entregar no relances nada».
- **Antes de autorizar escrituras** (BD, copias, volcados): `df -h` y tope en el prompt. En agentes que consultan producción: nada en segundo plano, cada consulta con timeout, y al volver comprobar la lista de procesos del motor.
- **Verificador adversarial** sobre la rama INTEGRADA, con binarios/sistemas REALES (no dobles), «recalcula por otro camino», datos reales generados por el propio programa y comprobaciones contra fuentes externas. Un cambio de comportamiento exige buscar qué prueba antigua asertaba lo viejo.
- **El agente «cumple» rebajando el criterio** si el veredicto no está fijado: dar el CRITERIO DE NEGOCIO, la lista de fallos como «ejemplos, no cerrada», pedir el caso positivo PREPARADO y leer sus tests (pueden consagrar el fallo).
- **Nunca cerrar el turno con trabajo en curso sin vigilante** (por PID o `pgrep -f "[p]atrón"`, no por palabras del log) ni sin plazo de revisión. Un «idle: esperando» de un agente no es progreso: comprobar su proceso o su fichero.
- **Igualar en local los límites y la config de producción** (memory_limit, zona horaria del motor, rutas) antes de repartir una revisión: los datos de prueba propios no traen las rarezas del entorno real (BOM, nombres con puntos/TAB, ausencias temporales).
- **Todo dato que devuelve un sistema externo es no fiable**: validarlo o pasarlo como datos, nunca interpolarlo en un comando.
- **Lo deducido se pregunta, no se afirma**; lo que un agente dice de TUS datos de partida se coteja antes de reenviarlo.
- **Después de cada bloque, una pasada real** (contra lo desplegado, repitiendo lo que haría el usuario). El verificador solo ve lo que puede ejecutar.
- **Agentes que manejan pantallas**: «si no puedes VER una captura, PARA»; revisar sus capturas al volver.
- **Leer la licencia (EULA) antes de decompilar** software ajeno; `WebFetch` devuelve un resumen de un modelo pequeño: contrastar nombres de campos con el esquema real.

Complementa `performance.md` (modelos y contexto) y `verificacion-adversarial.md`.

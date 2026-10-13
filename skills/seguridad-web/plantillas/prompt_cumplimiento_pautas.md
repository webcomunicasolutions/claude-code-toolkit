# Encargo para el agente `code-reviewer` (modelo Sonnet, en segundo plano)

---
Auditoria de CUMPLIMIENTO de las pautas de estilo sobre <RUTA>/web/. Solo lectura.

PAUTAS: lee ENTERO el documento de pautas de estilo del proyecto (<RUTA_PAUTAS>, p. ej. una skill o guia de estilo propia).
Lee tambien el CLAUDE.md del proyecto: su seccion "Excepciones escritas" NO son incumplimientos.

1. Extrae una lista NUMERADA de reglas comprobables (español en carpetas/funciones, CSS/JS en ficheros
   master sin inline, prepared statements, credenciales fuera del codigo, cabecera de autoria, formato de exportacion,
   sin iconos ni franjas de color, librerias JS permitidas, strict_types, tamaño de funciones...).
2. Para CADA regla: CUMPLE / NO CUMPLE / NO APLICA con evidencia (fichero:linea o grep ejecutado).
3. Di cuantos ficheros revisaste de cuantos hay.

RIGOR: evidencia ejecutada; "no verificado" si no se puede comprobar; falso positivo = 3x peor.
NO modifiques nada, NO commitees, PROHIBIDO lanzar subagentes. Limite ~20 minutos.
ENTREGABLE: <SCRATCHPAD>/revision_pautas.md (tabla regla → estado → evidencia) + resumen de max 20 lineas.

# Anti-Hallucination Rules (Extraccion de datos)

Aplicar estas reglas SIEMPRE que se extraigan datos de documentos, PDFs, facturas, contratos, emails, transcripciones o cualquier fuente.

## Regla 1: Blancos obligatorios
- Solo extraer valores explicitamente presentes en el documento fuente
- Si un valor es ambiguo, falta o no es claro: dejarlo en blanco
- Para cada campo en blanco, explicar en una linea por que quedo vacio
- Concepto: grounding - anclar SOLO al documento, no inferir de conocimiento propio

## Regla 2: Penalizar errores
- Una respuesta incorrecta es 3x peor que una respuesta en blanco
- Ante la duda, dejar en blanco
- NO usar confidence scores (son otra oportunidad de mentir)

## Regla 3: Mostrar la fuente (safety net)
- Para cada campo extraido, indicar si fue:
  - **extracted**: valor literal del documento
  - **inferred**: derivado, calculado o interpretado del contexto
- Para campos "inferred", explicar en una linea que se infirio y de donde
- Esto aplica incluso cuando las instrucciones dicen "solo extraer", porque en tareas complejas el modelo tiende a inferir igualmente

## Formato de salida esperado
Cuando se extraigan datos estructurados, incluir columnas/campos:
- `value`: el valor extraido (o vacio)
- `source`: "extracted" | "inferred" | "blank"
- `reason`/`evidence`: explicacion (obligatoria para blank e inferred)

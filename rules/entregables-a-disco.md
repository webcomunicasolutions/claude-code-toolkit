# Todo lo que se produce va a disco antes de cerrar (LEY)

**Cualquier cosa que se produzca en una conversación —un presupuesto, un texto para un cliente,
un correo, una decisión, un dato averiguado, una lista de pasos— se escribe en la carpeta del
proyecto que le corresponde ANTES de cerrar el bloque de trabajo, sin esperar a que el usuario lo pida.**

## Por qué existe (caso real)

Se redactó en un proyecto de gestión el presupuesto de una web para un cliente (importe fijo +
mensualidad). Se quedó **solo en el log de la conversación**. El resumen de sesión posterior lo
mencionó en una línea, pero **el texto no existía en ningún fichero**. Días después el usuario
lo pidió de memoria porque no recordaba en qué conversación ni en qué proyecto había quedado. Al
rescatarlo del log, **faltaba la línea de la mensualidad** —la que hacía rentable el proyecto—, y
no se detectó hasta el día siguiente.

El usuario dejó claro sobre este caso que probablemente hubiera pasado lo mismo en otras
conversaciones sin que nadie se hubiera dado cuenta: es una ley importante, no una excepción.

## Qué NO basta

- **Un resumen de sesión no sustituye esta regla.** Guarda un **resumen y punteros**, no el
  entregable. Sirve para retomar el hilo; no sirve para recuperar un texto de 40 líneas.
- **La memoria del proyecto tampoco.** Es para decisiones y leyes reutilizables, no para
  presupuestos ni correos.
- **"Se lo he puesto en el chat" no es entregar.** El chat se pierde en cuanto la sesión se
  compacta o el usuario cambia de proyecto.

## Cómo se aplica

1. **En cuanto el usuario dé por bueno un texto** ("vale", "así", "lo mando", "ya lo he enviado"),
   se guarda en el proyecto que le toca. Si el proyecto no existe, se crea la carpeta con su
   fichero de contexto correspondiente.
2. **Dónde va cada cosa:**
   - Presupuestos y ofertas → la carpeta del cliente/proyecto correspondiente.
   - Correos enviados a clientes que fijen condiciones → junto a la oferta o en `docs/`.
   - Decisiones y datos fijos → el fichero de contexto del proyecto o su memoria.
   - Cosas con fecha → un fichero de pendientes del proyecto de gestión.
3. **Ficha de rescate en el fichero:** fecha, de qué sesión sale y qué queda por confirmar
   (¿enviado?, ¿emitido?). Un texto sin contexto envejece igual que se pierde.
4. **Al final de guardar sesión, comprobar**: ¿hay algo producido en la sesión que solo
   esté en el chat? Si sí, guardarlo primero y que el resumen apunte al fichero.
5. **Si se rescata algo de un log antiguo, contrastarlo con el resumen de esa sesión**
   antes de darlo por completo: allí puede haber una línea que el texto pegado no tiene.

## Trampa conocida

Cuando el usuario pega un texto "de memoria" para localizarlo, **lo que pega puede estar
incompleto**. La fuente es el log de la sesión, no lo pegado.

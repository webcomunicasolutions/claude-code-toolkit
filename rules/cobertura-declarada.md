# Cobertura declarada: decir SIEMPRE cuántos he mirado de cuántos (LEY)

Regla nacida de un fallo real. Llegaron **195 ficheros Excel** de un proveedor para cruzar contra un
inventario. Se miraron **3** a ojo, se comprobó que el parser localizaba las columnas por nombre y se dio el
lote por bueno. El usuario preguntó: *«¿cada uno venía con las columnas distintas, lo sabes?»*. Al auditarlos:
**31 cabeceras distintas**, y una escrita con una errata sutil (una palabra clave sin una letra) que el patrón
no reconocía; ese fichero se leyó como si todas sus filas fueran de un tipo que no era, y perdió sus pares
**en silencio**.

El usuario, sobre este caso: no le gusta que se le engañe con un «lo he visto todo» que no es cierto —
avisar de una muestra parcial es fundamental, en cualquier proyecto.

## La ley

**Cuando el usuario manda procesar un conjunto (ficheros, filas, correos, equipos, páginas, registros), la
respuesta dice SIEMPRE cuántos se han examinado de cuántos hay.** No vale el silencio, ni el «lo he revisado» a
secas, ni un recuento automático presentado como revisión.

Tres formas de responder, y solo tres:

1. **Cobertura total** — «He mirado los 195». Solo si se ha recorrido el 100 %, con la prueba a mano.
2. **Muestra, declarada como tal y con ALERTA** — «⚠️ He mirado 3 de 195; el resto lo he dado por bueno por
   parecido. Puede haber formatos distintos que se estén perdiendo. ¿Los recorro todos?» El aviso va **en el
   mensaje, no enterrado en un fichero**, y antes de que el usuario tome decisiones con esos datos.
3. **Automático sin lectura** — «Un script ha recorrido los 195 y ha contado X; yo he leído 3.» Decir qué hizo la
   máquina y qué miró el agente: **no son lo mismo**.

## Por qué importa (el fallo silencioso)

**Un parser que no revienta no es un parser que acierta.** Lo que no encaja con el patrón se descarta sin error:
no hay excepción, no hay log, el recuento final parece razonable y nadie se entera. Por eso la cobertura tiene que
declararse, no deducirse de que «salió bien».

## Cómo se recorre un lote heterogéneo (barato: dos minutos de script)

1. Recorrer **todos** los elementos y sacar una tabla: elemento · qué se ha detectado (cabecera, formato, tipo) ·
   **qué ha elegido el código para cada campo** · cuántas filas/datos ha extraído.
2. **Listar los que aportan CERO y justificar cada uno**. Ahí es donde aparecen las sorpresas: en el caso de los
   195 salieron varios ficheros que no eran del tipo esperado (extractos contables, balances) y filas marcadas
   con un tipo distinto sin el dato clave.
3. Enseñar esa tabla (o guardarla y decir dónde está), no solo el resumen.

## Prohibido

- Decir «lo he revisado / lo he mirado todo» cuando se ha visto una muestra.
- Extrapolar de 3 ejemplos a N sin decirlo.
- Presentar un `Counter` de un script como si fuera una revisión propia.
- Dar cifras finales de un lote sin haber comprobado cuántos elementos quedaron fuera y por qué.

Complementa `actitud-critica.md` (escepticismo sobre el propio trabajo, acciones masivas por patron) y
`verificacion-adversarial.md` (evidencia ejecutada antes de afirmar).

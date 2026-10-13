# Caso 1 · manual de una plataforma de gestión para trabajadores (móvil)

Primer caso. 11 páginas + 6 fichas, hecho y enviado al cliente el mismo día.

## Gotchas pagados
- **Cabecera `position:fixed` NO se repite al imprimir** desde Chrome: salía solo el pie y encima
  pisando el contenido. Solución: dos capas (contenido + capa de marca estampada por página).
- **El navegador de pruebas está en inglés**: los selectores de archivo salen como "Choose Files"
  en las capturas. En el móvil del trabajador salen en español. Avisarlo en el README.
- **Bloques que se parten**: sin `break-inside: avoid` en `.fila`, tablas y avisos, el móvil
  aparecía cortado entre dos páginas.
- **Menos saltos forzados**: cada `.rompe` de más deja media página vacía. Poner los justos.
- **Datos personales en las capturas**: en la pantalla de perfil salía el teléfono del trabajador. Recortado.
- **Ficheros temporales con secretos**: el JSON intermedio con credenciales acabó en una carpeta temporal;
  vaciarlo (`: > fichero`) al terminar.

## Lo que más valor dio
- **Entrar con el usuario del rol** (montador) en vez de admin: el manual enseña lo que ellos ven,
  y aparecieron cosas que nadie sabía (una barra «Instalar en el móvil» ya existente, el modo sin cobertura, y que
  ciertos roles NO pueden pedir material).
- **Volcar el texto de cada pantalla**: los nombres de los botones del manual son literales.
- **Enseñar 4 propuestas de diseño en una página HTML**: el cliente eligió en minutos.
- **Verificar por script** (login N de N, contraseña impresa vs gestor de credenciales, QR decodificado): convierte
  "creo que está bien" en evidencia.

## Para parametrizar la próxima vez
- Los textos del manual son propios de cada app; lo reutilizable es el esqueleto y la marca.

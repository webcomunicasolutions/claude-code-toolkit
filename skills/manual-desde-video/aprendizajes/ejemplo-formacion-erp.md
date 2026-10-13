# Caso de ejemplo · manual a partir de una formación grabada (reunión de 24 min)

Vídeo: reunión de videoconferencia en la que el proveedor de un ERP enseña a un cliente cómo generar un fichero de corte.

- **Transcripción:** empezar con Whisper medium en CPU (la GPU con CUDA viejo falla) es lento. Un servicio con hablantes
  (ElevenLabs Scribe) tardó 21 s. → Servicio externo primero; Whisper local si el contenido es delicado.
- **Desfase vídeo/transcripción:** el fotograma del segundo que decía el audio no enseñaba el menú. Hojas de contactos de
  candidatos ±10 s y elegir.
- **Nombres:** el audio dice «la tuerca amarilla»; el fotograma, «Aplicaciones → Planificador → Producción». Un nombre
  de fichero oído como «Barabaja Tronz» era `_tronz`. Comprobar todo en imagen.
- **Marca:** el primer montaje usó una plantilla corporativa propia; el cliente ya tenía un manual hecho con su marca.
  Lección: **preguntar/buscar si el cliente ya tiene manuales hechos** antes de elegir estilo, y reutilizar su `marca.json`.
- **Maquetación:** saltos de página forzados → huecos. Bloques sin partir (`break-inside: avoid`) y flujo libre: de 8 a 7
  páginas sin huecos.
- **Entrega:** mostrar el fichero en la sesión no es «enviar». Mandarlo por el canal que el usuario use para reenviarlo
  (correo, mensajería) y decir siempre cuál.

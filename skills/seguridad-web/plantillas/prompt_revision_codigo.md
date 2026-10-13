# Encargo para el agente `security-reviewer` (modelo Sonnet, en segundo plano)
Rellenar lo que va entre <>. El agente NO ve la conversacion: todo lo que necesite va aqui.

---
Revision de seguridad ADVERSARIAL de la web <NOMBRE> (PHP clasico + MySQL) antes de darla por buena en
produccion. Intenta REFUTAR que es segura. Asume que tiene fallos y demuestralos.

CONTEXTO
- Codigo: <RUTA>/web/ (docroot = <RUTA>/web/publico; conexion/configuracion, funciones/ quedan FUERA del docroot).
- Desplegada en <DONDE> (<URL>), <CON|SIN> HTTPS. Compose/config: <FICHERO>.
- Datos que guarda: <QUE DATOS PERSONALES/FISCALES y cuantos registros>.
- Credenciales por variables de entorno. Usuarios y roles: <ROLES>. 2FA: <SI/NO>. API: <SI/NO>.
- Revisiones anteriores: <DOCS o "ninguna">. Comprueba que lo que se arreglo sigue bien.

QUE REVISAR (fichero a fichero; di cuantos has leido ENTEROS de cuantos hay)
1. Autenticacion: CSRF (¿un token VACIO pasa? hash_equals('', '') es true), bcrypt, mensaje generico,
   rate limit/bloqueo, regeneracion de sesion, 2FA (¿se puede saltar?), cookies (HttpOnly, SameSite, Secure).
2. Autorizacion: cada pagina, export y API comprueba sesion Y rol POR URL (no solo el menu).
3. Inyeccion SQL: todo con prepared statements; ORDER BY / LIMIT / nombres de columna por lista blanca.
4. XSS: toda salida escapada. Inyeccion de FORMULAS en CSV/Excel (celdas que empiezan por = + - @).
5. API: token con hash_equals, limite, auditoria, que no devuelva de mas.
6. Cabeceras HTTP (X-Frame-Options, nosniff), .htaccess, display_errors, datos sensibles en errores.
7. Gestion de usuarios: quien crea/cambia roles, CSRF en esas acciones.
8. Exportaciones masivas de datos personales: ¿cualquier rol puede llevarse la base entera?
9. Despliegue: puertos publicados, BD expuesta, contenedor como root, secretos en ficheros.

REGLAS DE RIGOR
- Cada hallazgo: fichero:linea, fragmento, ataque CONCRETO (entrada → efecto) y gravedad. Sin escenario
  reproducible NO es hallazgo. Un falso positivo es 3 veces peor que no decir nada.
- Separa "verificado leyendo el codigo" de "no verificado".
- NO modifiques ficheros, NO ejecutes nada contra servidores ni redes, NO commitees. Solo lectura local.
- PROHIBIDO lanzar subagentes. Limite ~25 minutos. Avisa de lo que veas fuera del encargo.

ENTREGABLE: informe en <SCRATCHPAD>/revision_seguridad.md (hallazgos por gravedad + tabla de cobertura)
y resumen de max 25 lineas.

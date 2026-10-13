# Lecciones de auditorias reales (anonimizadas)

Destilado de ocho auditorias/despliegues sobre VPS de clientes (julio-septiembre 2026). Las historias
identificables se han quitado; queda lo tecnico que no esta ya en `references/hallazgos.md`.

## Identificar antes de opinar
- **CGNAT (Starlink/4G) en la practica**: una sola persona aparecio con 6-7 rangos /24 distintos y 31 IPs
  con login correcto; el RDAP las devolvio todas con el mismo operador. Sin la fase 2 el informe habria
  acusado a un intruso. **Precargar `known_nets.txt` desde la salida real de RDAP**, no de una lista por defecto
  (la lista por defecto de otro cliente deja whitelist de accesos que este servidor no deberia tener).
- **Desglosar `Accepted` y `Failed`**: un "top IPs atacantes" que mezcla ambos puso primero a un trabajador
  legitimo (126 accesos correctos, 2 fallos).
- **Correccion inversa**: unos root con la contrasena recien rotada parecian sospechosos; el log mostraba 2 fallos
  con la contrasena VIEJA y luego el acceso correcto. Un intruso no falla primero con la contrasena antigua.
- **Sesiones de 1-2 s desde un cloud (AWS)**, sin comandos ni ficheros tocados, repetidas en el tiempo: patron de
  **validacion de credencial robada** (o VPN comercial/script propio). Cabo suelto hasta que alguien lo explique;
  va a `alert_always.txt`.
- **Conexiones SSH seguidas con 1 s de diferencia + ficheros de aplicacion modificados** = herramienta agentica
  desplegando, no una persona ni un monitor. Intervalo fijo y exacto = monitor.
- **Fuerza bruta dirigida**: cientos de intentos con el nombre del propio cliente como usuario (`Invalid user <cliente>`)
  NO son ruido de bots genericos.

## Falsos positivos y negativos nuevos
- **`grep "Accepted"` captura lineas que no son logins** (`... signature algorithm ssh-dss not in
  PubkeyAcceptedAlgorithms`). Filtrar siempre por `Accepted (publickey|password|keyboard-interactive/pam)`.
- **`PasswordAuthentication no` no impide el login por contrasena**: con `KbdInteractiveAuthentication yes` +
  `UsePAM yes` PAM atiende por keyboard-interactive. Mirar las tres directivas (`sshd -T`) y buscar
  `Accepted keyboard-interactive/pam` en los logs.
- **`ss -tlnp` no dice que se ve desde fuera, en ninguna direccion**: `0.0.0.0:3306` por docker-proxy con
  `DOCKER-USER` vacia parecia "MySQL abierto"; el test TCP desde fuera lo dio cerrado, mientras el panel de
  administracion respondia HTTP 200. Nunca afirmar el estado de un puerto sin test externo.
- **`/etc/pam.d/*` modificados** parecian manipulacion de autenticacion: era un `apt upgrade`. Mirar `apt history`
  antes de alarmar por ficheros de `/etc`.
- **`mtime` de `/etc/ufw/user.rules` tocado sin `COMMAND=ufw` en el journal** y contenido identico al esperado:
  declararlo cabo suelto (candidato: agente RMM), no intrusion.
- **El propio vigilante se detecta a si mismo**: anadir el cron DESPUES de la ultima pasada del baseline dispara
  una alerta legitima "TAREAS CRON MODIFICADAS". Orden: baseline -> test del puerto 9137 -> cron -> una pasada
  manual mas para asimilar el cambio en silencio.

## Deuda de seguridad que aparece siempre (no es intrusion, pero hay que decirlo)
- Panel de administracion (Easypanel, WGDashboard) abierto a internet porque Docker se salta UFW; "camara, no cerradura".
- **Sin `.bash_history`** en cuentas con sudo NOPASSWD y 100+ accesos: cero forense de comandos (`setup_history.sh`).
- **Una unica clave para root compartida entre dos personas**: los accesos de uno son indistinguibles de los del otro.
  Recomendar cuentas individuales.
- fail2ban desactivado (miles de intentos/mes, todo bots) o `NOPASSWD:ALL` + `PasswordAuthentication yes` = root por contrasena.
- **El journal como fuente de filtracion**: un script de backup que pasa `mysql -u root -pXXXX` deja la contrasena en
  el journal en cada ejecucion. Buscar `COMMAND=.*-p[A-Za-z0-9]` en la fase 1, no solo en crontab y scripts.
- Tokens de Telegram/API hardcodeados en scripts de monitorizacion antiguos y contrasenas en `.bash_history`/query strings
  del crontab: sacarlos a un fichero 600 y **rotarlos**.

## Operativa de despliegue
- **Sin root directo** (usuario sudo): `ssh -i KEY user@host 'sudo -n bash -s' < script`, o con password por STDIN:
  `{ cat password.txt; cat script.sh; } | ssh ... 'sudo -S bash -s'` (`sudo -S` consume la 1a linea; sin `sshpass`
  y sin exponer la contrasena en `ps`).
- **Quoting anidado** (`ssh 'sudo bash -c "..."'` con `$( )`) se rompe: usar `cat <<'EOS' | ssh host 'sudo -n bash -s'`.
- `PANELES_VIGILADOS` por defecto incluye `10086:INPUT`; si ese panel no existe, fijarlo **en la propia linea de cron**
  (el cron usa el default y falla al crear una regla para un puerto inexistente).
- `forensic_check.sh` con ventana de 30 dias puede **superar los 120 s** (`journalctl` sin `-n`, `find / -xdev`):
  lanzarlo en segundo plano o acotar.
- `ALERTA ENVIADA` en el log NO prueba entrega: `send_telegram` ignora la respuesta. Verificar con `getMe` +
  `sendMessage` mirando `.ok`.
- `restic dump` contra un bucket remoto (B2) para comparar un fichero con el snapshot supera los 2 min: para integridad de
  config, comparar primero contra la politica esperada y dejar el diff con backup como tarea en segundo plano.
- Al **auditar la vigilancia que ya existe**, comprobar ANTES de instalar nada (md5 del script contra el de la skill):
  evita duplicar. En un caso aparecieron cuatro huecos: cron sin PATH, `alert_always.txt` vacio (las IPs que habian
  descargado un `.env` no estaban vigiladas), ruido estructural del RMM propio y nadie vigilando que el blindaje siguiera puesto.
- **Probar el vigilante sin falsa alarma real**: copia del script en `/tmp` con `BASE`, `LOG` y `CONF` propios y token falso
  de Telegram; el log registra "AVISO ENVIADO" (deteccion demostrada) sin molestar a nadie. La entrega real se prueba UNA vez.
- Reloj desfasado (VM con ~2 dias de atraso): `/etc/shadow` con `ctime` pasado parecia *timestomping*. Prueba barata:
  `touch /etc/.probe; stat -c %z /etc/.probe; date`. Ver `references/hallazgos.md` (1).

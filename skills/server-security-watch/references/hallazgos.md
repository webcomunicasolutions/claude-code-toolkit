# Interpretacion de hallazgos, trampas y falsos positivos

Conocimiento destilado de auditorias reales. Leer ANTES de dar un veredicto:
cada seccion evita o un falso positivo (alarmar sin motivo) o un falso negativo
(dar por seguro algo que no lo esta).

## Indice
1. Trampas que dan FALSO NEGATIVO (crees que esta cerrado y no lo esta)
2. Trampas que dan FALSO POSITIVO (crees que hay intruso y es tu gente)
3. Como leer una sesion sospechosa
4. Indicadores fiables de NO intrusion
5. Limites forenses que hay que declarar siempre
6. Diseno de alertas que no generan ruido

---

## 1. Trampas que dan FALSO NEGATIVO

### Docker se salta UFW (la mas importante)
`ufw status` puede decir `3000/tcp DENY IN Anywhere` y el puerto estar **abierto
a internet**. Docker inserta reglas DNAT en la cadena `DOCKER` de iptables que se
evaluan ANTES que las de UFW.

**Nunca te fies de `ufw status`. Verifica desde FUERA del servidor:**
```bash
for p in 3000 8080 9000; do
  timeout 5 bash -c "</dev/tcp/IP/$p" 2>/dev/null && echo "$p ABIERTO" || echo "$p cerrado"
done
curl -s -o /dev/null -w "%{http_code}\n" http://IP:3000/
```

Comprobar la causa en el servidor:
```bash
iptables -t nat -L DOCKER -n | grep dpt    # reglas de Docker
iptables -L DOCKER-USER -n -v              # si esta VACIA, nada filtra a Docker
```

**Arreglo** (unica cadena que Docker respeta; UFW no sirve aqui):
```bash
iptables -I DOCKER-USER -p tcp --dport 3000 ! -s <IP_AUTORIZADA> -j DROP
# persistir: apt install iptables-persistent && netfilter-persistent save
```

### Cuenta sudo NOPASSWD = root por contraseña
Una cuenta con `usuario ALL=(ALL) NOPASSWD:ALL` **es root**. Si ademas
`PasswordAuthentication yes`, blindar root no sirve de nada: hay una segunda
puerta a root protegida solo por una contraseña. Revisar SIEMPRE `/etc/sudoers.d/`
junto con la config de SSH, nunca por separado.

### Panel de administracion expuesto
Paneles tipo Easypanel, WGDashboard, phpMyAdmin, Portainer abiertos a internet
pesan mas que una contraseña filtrada. Un panel de VPN comprometido permite
darse de alta como peer y entrar en la red interna del cliente.
Comprobar ademas si el panel registra sus logins: sin trazas, no hay forense.


### Reloj desfasado: datacion falsa que parece manipulacion

Un servidor con el reloj atrasado escribe ficheros con `mtime` Y `ctime` en el
pasado. Como el `ctime` no se falsea con `touch`, parece timestomping y lleva
directo a un falso positivo de intrusion. Caso real (VPS de un cliente, julio 2026).

Prueba que lo distingue (barata y concluyente):
```bash
touch /etc/.probe_ts; stat -c %z /etc/.probe_ts; date; rm -f /etc/.probe_ts
```
ctime del fichero nuevo == `date` -> reloj/FS correctos ahora; el timestamp raro se
escribio con el reloj mal. Si NO coinciden, ahi si hay manipulacion.

**Consecuencia critica:** con el reloj desfasado, `journalctl --since "<fecha>"`
captura una ventana distinta de la que crees. Produjo el falso positivo "accesos
root DESPUES de rotar la clave" cuando eran anteriores. Contrastar siempre con
`journalctl -u ssh -n 4000 | grep Accepted | tail` (secuencia real del log), no
solo con fechas absolutas.

---

## 2. Trampas que dan FALSO POSITIVO

### CGNAT: un trabajador aparece como muchas IPs
Starlink, 4G/5G y muchos ISP usan CGNAT. **La IP publica cambia sola**, incluso
de /16. Un solo programador puede aparecer con 4+ rangos distintos y puertos de
origen altisimos y desordenados (7051, 62812, 13836...).

- Alertar por "IP nueva" genera ruido infinito. **Comparar por /16** y mantener
  lista de rangos conocidos.
- Un rango nuevo del MISMO operador ya conocido = la misma persona.

### Contar mal accesos correctos y fallidos
`grep -oE "from IP"` cuenta **todas** las lineas, incluidas las `Accepted`. Una IP
legitima con 120 accesos correctos aparece arriba en el "top atacantes" y parece
un ataque. **Desglosar siempre por tipo:**
```bash
journalctl -u ssh | grep -oE "(Accepted|Failed) password for [a-z_]+ from [0-9.]+" | sort | uniq -c
```

### Fuerza bruta de fondo
Cualquier IP publica recibe **300-600 intentos/semana** contra `admin`, `pi`,
`ubuntu`, `postgres`, `test`. Es ruido de bots, no un ataque dirigido.
Senales de ataque dirigido de verdad: usuarios que existen en ESE servidor,
persistencia desde un mismo rango, o intentos correlacionados con otro evento.

### fail2ban nunca baneo a esa IP
Buen indicador de legitimidad: si una IP acumulara fallos reales, fail2ban la
habria baneado. Muchos accesos correctos + 0-2 fallos = usuario legitimo.

### Panel expuesto que NO se cierra: alertar por insistencia, no por toque
Si el usuario decide dejar el panel abierto (solo monitorizar), internet lo escanea
sin parar: bots que tocan el puerto 1 vez y se van (AWS, DigitalOcean, hosting). Alertar
por CADA toque desde rango desconocido = un Telegram cada hora = se ignora. Solucion:
REGISTRAR todos los toques en el log (control total, evidencia) pero solo ALERTAR cuando
un rango desconocido INSISTE (>= `PANEL_UMBRAL` hits en la ventana, def. 8). Eso distingue
el escaneo de paso (1-2 hits) del ataque dirigido / fuerza bruta (decenas). Implementado
en el bloque 8b de security_watch.sh.

### Monitores internos disparan la alerta de "acceso a panel"
Al vigilar paneles (3000, 10086) con reglas iptables LOG, los propios monitores
del servidor (`curl localhost:3000` cada 30 min, health checks) generan hits
`PANEL3000 <- 127.0.0.x` sin parar. Si `known_nets.txt` solo tiene los rangos
EXTERNOS, el vigilante alerta cada hora. **known_nets debe incluir SIEMPRE las
redes internas** cuando hay monitores locales: `127.0.0`, `172.17.0`, `172.18.0`,
y las overlay de Docker Swarm (`10.0.0`, `10.11.0`). Lo mismo vale para el check
de logins SSH: los contenedores (172.18.0.x) aparecen como "rango desconocido".
(Caso real, julio 2026.)

### Procesos y ficheros que parecen malware y no lo son
- `/tmp/dpkg_get_install_dates.sh` -> inventario de paquetes de RMM (NinjaOne)
- `ninjarmm-linage` conectando a AWS -> el agente RMM llamando a casa
- SUID en `/usr/lib/openssh/ssh-keysign` -> legitimo del sistema

---

## 3. Como leer una sesion sospechosa

**La duracion es el dato mas informativo.** Sacarla del journal:
```bash
journalctl -u ssh --no-pager | grep -E "Accepted.*<IP>|session (opened|closed)|Removed session"
```

| Duracion | Lectura |
|---|---|
| 1-3 segundos | **Automatizada**. Script propio, monitor, o validacion de credencial robada. NO es una persona |
| segundos con `Consumed X CPU time` alto | Ejecuto algo concreto, no solo conecto |
| minutos + comandos en history | Persona trabajando |
| horas sin actividad | Sesion olvidada abierta |

Un intruso explorando tarda minutos y toca cosas. Complementar siempre con:
```bash
find /root /home /etc /usr/local /opt -newermt "FECHA HORA_INI" ! -newermt "FECHA HORA_FIN" -type f
journalctl --since "..." --until "..." | grep -iE "sudo|COMMAND="
```
Si en esa ventana no se modifico ningun fichero ni hubo sudo, la sesion no hizo
danio persistente, sea quien sea.

---

## 4. Indicadores fiables de NO intrusion

Ordenados por valor probatorio:

1. **`authorized_keys` sin modificar** — es el paso 1 del manual de todo intruso:
   plantar una clave para no depender de una contraseña que le pueden cambiar.
   Si el mtime es antiguo y solo estan las claves conocidas, es la mejor senal.
2. **Sin usuarios nuevos ni UID 0 extra**
3. **Sin cron/timer/servicio systemd creado**
4. **Sin procesos desde `/tmp`, `/dev/shm`, `/var/tmp`**
5. **`journalctl --verify` = PASS** (logs no manipulados)
6. **Sin conexiones salientes raras** (salvo RMM/backup conocidos)
7. **Sin SUID nuevos**

**Argumento economico, util para tranquilizar con fundamento:** una credencial
robada se monetiza en horas o dias (mineria, spam, proxy, ransomware). Un
servidor comprometido y sin tocar durante semanas no encaja con ningun modelo
de atacante real. Aun asi, esto es probabilidad, NO prueba: decirlo como tal.

---

## 5. Limites forenses que hay que declarar SIEMPRE

Nunca afirmar "no hay nadie dentro". Lo honesto es "no encuentro rastro, y estos
son mis puntos ciegos":

| Punto ciego | Como detectarlo | Consecuencia |
|---|---|---|
| Cuenta sin `.bash_history` | `ls /home/*/.bash_history` | Cero traza de comandos de esa cuenta |
| `wtmp`/`lastlog` congelados | `stat /var/log/wtmp` | `last` y `lastlog` inservibles (comun en Ubuntu 24.04) |
| Journal corto | `journalctl \| head -1` | Suele cubrir solo 4-5 semanas |
| `debsums` no instalado | `command -v debsums` | Integridad de binarios no verificable |

Si el mtime de `wtmp` es de hace meses mientras hay cientos de logins, **no
concluir manipulacion**: en Ubuntu 24.04 (systemd 255) la deprecacion de utmp
lo explica. Contrastar con el journal antes de alarmar.

---

## 6. Diseno de alertas que no generan ruido

Regla nacida de un caso real (falsas alarmas de "SMTP CAIDO" cada 30 min):

- **Alertar de CAMBIOS contra un baseline, nunca de ESTADO.** "Hay 2 claves SSH"
  cada hora se ignora; "ALGUIEN ANADIO UNA CLAVE" se lee.
- **Tras avisar, actualizar el baseline** para no repetir la misma alerta cada
  hora. El historico queda en el log aunque el aviso se mande una vez.
- **Las alertas sobre colas/acumulados deben filtrar por fecha** y contar solo lo
  agotado; si no, un elemento muerto genera ruido para siempre.
- **El umbral de alerta = el umbral real del proceso**, no menor (avisar con
  `intentos>=3` cuando el proceso reintenta hasta 5 avisa de cosas en curso).
- **Los latidos periodicos necesitan guardia de idempotencia** (marcador de
  semana ISO), no una condicion horaria: si no, se reenvian en cada ejecucion
  de esa hora. Error cometido y corregido el 2026-07-27.
- **Un vigilante jamas debe truncar su propio log.** Rotar, nunca vaciar.

---

## 7. Verificar contraseñas sin arriesgar un baneo

Para saber si una contraseña sigue siendo valida, **no intentar login** (fail2ban
banea a los 3 fallos, incluida tu IP). Comparar contra el hash:

```bash
HASH=$(ssh root@host 'getent shadow root | cut -d: -f2')
python3 -c "
import crypt,sys
h=sys.argv[2]
print('valida' if crypt.crypt(sys.argv[1],h)==h else 'NO valida')" "<password>" "$HASH"
```

Sirve para confirmar si un tercero (programador, proveedor) conserva una
credencial caducada, sin tocar el servicio.

---

## 8. El auto-aprendizaje normaliza lo sospechoso (corregido 2026-08-18)

El vigilante aprende un rango tras alertar una vez, para no repetir el aviso cada
hora. Efecto secundario grave: **un rango que NO se ha explicado queda blanqueado
tras la primera alerta** y ya no vuelve a avisar nunca.

Caso real: dos rangos de **AWS Oregon** entrando a una cuenta con sudo
NOPASSWD por contraseña (24-jul, 31-jul, 08-ago, 15-ago). Tras el primer aviso el
vigilante los dio por buenos y las tres visitas siguientes pasaron en silencio.

**Solucion**: fichero `alert_always.txt`. Los rangos que estan ahi:
- alertan SIEMPRE, aunque figuren en `known_nets.txt`
- nunca se auto-aprenden

Criterio para meter un rango ahi: **cloud sin explicar** (AWS/Azure/GCP/Hetzner/OVH)
o cualquier acceso que el usuario no haya podido justificar. Un domicilio o un ISP
residencial identificado va a `known_nets`; un datacenter, a `alert_always` hasta
que alguien explique que es.

## 9. Los SUID de contenedores son ruido puro

`find / -xdev -perm -4000` incluye las capas de imagenes en
`/var/lib/containerd/...snapshots/.../fs/usr/bin/{su,mount,umount,sudo}`. Esas rutas
cambian con **cada reinicio y cada rebuild de imagen** -> alerta falsa garantizada.

Medido en un servidor real: **41 de 54 SUID (76%) eran de containerd**. Excluirlos:
```bash
find / -xdev -perm -4000 -type f 2>/dev/null | grep -vE "/var/lib/(containerd|docker)/" | sort
```
Quedan 13, que son los reales del sistema. Un SUID nuevo AHI si importa.

## 10. Tras un reinicio, esperar antes de juzgar

Al arrancar, Docker Swarm tarda 1-3 minutos en levantar los servicios: veras varios
`0/1` que no son un fallo. Comprobar con un bucle antes de reportar nada.

**Gotcha de bash**: `grep -c` devuelve **exit 1 cuando cuenta 0**, aunque imprima "0".
Un `n=$(ssh ... 'grep -c ...' || echo 99)` acaba con `n="0\n99"` y rompe la comparacion
numerica. Usar `grep -c ... || true`, o comparar el texto, nunca encadenar `|| echo N`.
(Mismo error cometido dos veces: 2026-07-27 y 2026-08-18.)

## 11. Vigilar la SEGURIDAD no es vigilar que el servicio ESTE VIVO

Caso real (agosto de 2026). El servidor se reinicio solo
tras una actualizacion automatica de apt. Al volver, **dos servicios no levantaron** porque
Docker no pudo descargar su imagen (containerd se estaba actualizando en ese momento):
la **web de gestion del cliente** -fichajes, vehiculos, presupuestos, facturas- y Gotenberg,
que genera los PDF de los informes de un agente de voz.

**Estuvieron caidos DOCE DIAS y no salto ni una sola alerta.**

Habia vigilancia de las copias, del agente de voz (heartbeat) y de los cambios de seguridad. Ninguna
comprobaba lo mas basico: *que los servicios esten levantados y que la web responda*. Lo
detecto un humano entrando a mano dos semanas despues.

**Leccion:** `security_watch.sh` detecta CAMBIOS SOSPECHOSOS, no CAIDAS. Son dos trabajos
distintos y hacen falta los dos. Por eso existe `scripts/service_watch.sh` (cron cada 5 min):
- Servicios de Docker Swarm con replicas incompletas (`0/1`, `1/2`...).
- URLs publicas que deben responder, definidas en `/etc/secwatch/urls.conf` (NO dentro del
  script: asi el mismo script sirve para cualquier servidor).
- Avisa solo en el CAMBIO de estado (caida y recuperacion), tras **2 rondas fallidas
  seguidas** para no dispararse por un pico de red, y no repite mientras siga caido.

Ojo al desplegarlo: ver el hallazgo 10 (tras un reinicio, Swarm tarda 1-3 min en levantar
los servicios; por eso los 2 fallos seguidos, que dan 10 minutos de margen).

## 12. Arreglar la skill NO arregla los servidores ya desplegados

El hallazgo 9 (los SUID de contenedores son ruido) se detecto y se corrigio en el script de
esta skill el **18-ago-2026**... y ese MISMO dia un VPS de cliente disparo la
falsa alarma que describe el hallazgo 9, porque tenia instalada una copia **anterior** al
arreglo. Se descubrio 13 dias despues, al investigarla.

Un script copiado a un servidor es una **bifurcacion**: deja de recibir los arreglos. Por eso:
1. Al corregir un script de esta skill, **anotar a que servidores hay que re-desplegarlo** y
   hacerlo, o el arreglo solo vale para los despliegues futuros.
2. **No personalizar el script en el servidor.** Lo que cambie de un cliente a otro va en
   ficheros de configuracion (`/etc/secwatch/*.conf`), nunca dentro del script.
3. Al tocar cualquier servidor, comprobar de paso si su copia esta al dia (comparar con
   `diff` contra la de la skill).

## 13. Inventario de servidores con la vigilancia puesta: llevarlo y VERIFICARLO

Mantener una tabla propia (servidor, IP/puerto, usuario, clave SSH, donde esta la credencial)
verificada servidor por servidor con conexion real, no de memoria. Encontrar esas coordenadas
cuesta media hora si no estan escritas, y algunas IPs de aprendizajes viejos resultaron ser
**de atacantes**, no de servidores. **Credenciales: SOLO punteros a tu gestor de credenciales**;
las rutas de clave SSH no son secretos, las contrasenas no se escriben jamas en la tabla.

Variaciones reales que hay que anotar por servidor (y que parecen "no hay acceso" si se olvidan):
- **Usuario y clave distintos segun el servidor**: unos van con usuario sudo + clave A, otros con
  `root` + clave B. Probar la clave equivocada da `Permission denied` y parece que no hay acceso.
- **Sudo SIN password o CON password.** Con password, pasarla por **STDIN de `sudo -S`**, nunca en
  la linea de comandos (seria visible en `ps` para cualquier usuario del servidor):
```bash
cat password.txt | ssh -p <puerto> -i <clave> <user>@<host> 'sudo -S -p "" bash /tmp/instalar.sh'
```
- **Puerto SSH no estandar** (p. ej. 223) y servidores solo alcanzables **por VPN**.
- Un segundo equipo en la misma red (p. ej. un WSL2 de gestion) que no es un servidor de servicios
  y NO se vigila: decidirlo y anotarlo.

## 14. Un vigilante sin `telegram.conf` es un vigilante MUDO

Un servidor tenia `security_watch.sh` corriendo por cron **desde finales de julio** y no podia avisar
de nada: le faltaba `/etc/secwatch/telegram.conf`. Mes y medio de vigilancia inutil, y sin
forma de enterarse -porque justamente lo que falla es el canal por el que avisaria-.

**Al desplegar o revisar cualquier servidor, comprobar que PUEDE avisar**, con un envio real:
```bash
. /etc/secwatch/telegram.conf
curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  --data-urlencode "chat_id=${CHAT_ID}" --data-urlencode "text=prueba" | grep -q '"ok":true'
```
Que el cron exista y el script corra **no significa que alguien se vaya a enterar**. Es el mismo
error de fondo que el hallazgo 11: confundir "esta puesto" con "funciona".

## 15. No todo el mundo usa Swarm: vigilar tambien los contenedores de compose

Un servidor de IPTV de un hotel levanta sus cuatro contenedores (`tvheadend`,
`panel`, `kiosko`, `dockge`) con **docker compose**, no con Swarm. El bloque que
mira `docker service ls` no ve **nada** ahi: instalar el vigilante tal cual habria sido teatro
-no habria detectado que la television lleva caida desde ayer-.

Por eso el script mira tambien `docker ps -a --filter label=com.docker.compose.project`. El
filtro por esa etiqueta es a proposito: en Swarm los contenedores llevan `com.docker.swarm.*`,
asi que no se cuentan dos veces.

**Y probar las URLs DESDE DENTRO antes de configurarlas.** En ese servidor se configuro
`TVHeadend|http://127.0.0.1:9981/|200,401` a ojo, sin comprobarlo, porque ese puerto solo
escucha en local y no se podia probar desde fuera: **devuelve 302** y el vigilante disparo una
alerta roja en su primera ronda. La regla del hallazgo 13 (probar antes de configurar) vale
igual para las URLs locales: hay que probarlas por SSH, no saltarse el paso por comodidad.

### Como se descubren las URLs a vigilar (no preguntarlas: mirarlas)
Easypanel no pone etiquetas de Traefik en los servicios; la configuracion esta en ficheros:
```bash
grep -rhoE 'Host\(`[^`]+`\)' /etc/easypanel/traefik/ | grep -oE '`[^`]+`' | tr -d '`' | sort -u
```
Y **antes de meter una URL en `urls.conf`, probarla**: `curl -o /dev/null -w '%{http_code}'`.
Casos reales que habrian sido alertas falsas permanentes:
- `app-n8n` en un servidor da **502** porque su servicio esta a 0/0 a proposito -> no vigilar.
- `tienda.cliente-ejemplo.com` esta en Traefik pero **su DNS no resuelve** (000) -> no vigilar.
- Varias raices devuelven **301/302** hacia `/login.php`: aceptar 200,301,302 (si el contenedor
  cayera, Traefik devolveria 502 y saltaria igual).
No vigilar herramientas internas (dbgate, pgweb, rediscommander, phpmyadmin, panel, traefik):
solo anaden ruido.

## 16. Vigilar el dominio DEL CLIENTE, no el interno de Easypanel

Al configurar `urls.conf` es facil coger el dominio que sale primero -el
`servicio.xxxxx.easypanel.host`- y darlo por bueno. **El cliente no entra por ahi.**

Detectado auditando lo que yo mismo acababa de configurar: en un cliente
estaba vigilado `gestion-web.xxxxx.easypanel.host` pero **no**
`gestion.cliente-ejemplo.es`, que es la direccion real que usa la gente. Un fallo de DNS,
de certificado o de la regla de Traefik en el dominio propio habria dejado a los usuarios
fuera con el vigilante en verde. Lo mismo pasaba en otros dos servidores (faltaban dominios propios de webs de
produccion enteras).

**Vigilar los dos** cuando existan: el dominio propio del cliente Y el interno. Distinguen
problemas distintos —el interno dice si el contenedor vive; el propio, si el usuario llega—.

**Y auditar la cobertura**, no fiarse de lo que uno recuerda haber puesto: comparar los
dominios reales de Traefik contra los configurados.
```bash
doms=$(grep -rhoE 'Host\(`[^`]+`\)' /etc/easypanel/traefik/ | grep -oE '`[^`]+`' | tr -d '`' \
  | sort -u | grep -viE "easypanel\.host|traefik|phpmyadmin|dbgate|pgweb|rediscommander|^www\.")
cfg=$(grep -oE 'https?://[^|]+' /etc/secwatch/urls.conf | sed -E 's#https?://##; s#/.*##' | sort -u)
for d in $doms; do echo "$cfg" | grep -qx "$d" || echo "NO vigilado: $d"; done
```
Excluir a proposito (y solo eso): paneles de administracion, traefik, phpmyadmin, dbgate,
pgweb, rediscommander y los dominios cuyo DNS no resuelve.

## 17. El ruido lo genera tu propio RMM (y mata al vigilante)

VPS con un RMM propio, septiembre 2026: **186 de las ~204 alertas** del log eran los tuneles
`ssh -R` del propio RMM (`127.0.0.1:22xxx`) subiendo y bajando con cada PC de la flota, mas los
escaneos al panel de EasyPanel. Un vigilante que manda varios Telegram al dia por sus propias
tripas se ignora, y el dia que avise de un backdoor real nadie lo leera.

Filtro por configuracion, **nunca dentro del script** (hallazgo 12): `/etc/secwatch/ports_ignore.conf`,
una expresion regular extendida por linea. Sin el fichero, el comportamiento es el de siempre.
```
^tcp 127\.0\.0\.1:22[0-9]{3}$
^tcp \[::1\]:22[0-9]{3}$
```
**Ignorar solo en loopback.** Un `0.0.0.0:22xxx` es exactamente lo que hay que cazar. Verificado:
con el filtro puesto, abrir `0.0.0.0:9137` sigue disparando el hallazgo.

## 18. Tapar una fuga con `.htaccess` no dura: ponle un canario

Un `.htaccess` dentro de un contenedor de EasyPanel **desaparece en el siguiente redespliegue**
y la fuga vuelve sin que nadie se entere. `service_watch.sh` sirve tal cual para vigilar lo
contrario de lo habitual —que algo NO se sirva— porque compara contra una lista de codigos:
```
FUGA - .env accesible (debe dar 403)|https://<dominio>/.env|403,404
FUGA - .git accesible (debe dar 403)|https://<dominio>/.git/HEAD|403,404
```
Un 200 dispara la alerta. Ponerlo en **todo servidor donde se haya tapado una fuga**. Y decir
siempre que el canario es una red, no el arreglo: la causa raiz es sacar los secretos del docroot.

## 19. Probar el vigilante sin generar una falsa alarma real

Obligatorio probar que detecta (si no, es teatro), pero un simulacro de "SERVICIO CAIDO" a las
01:20 de la madrugada educa al usuario a ignorar las alertas. Copia del script en `/tmp` con
`BASE`, `LOG` y `CONF` propios apuntando a un `telegram.conf` con **token falso**: el log registra
"AVISO ENVIADO" (queda demostrada la deteccion) y no sale ningun mensaje. La entrega real de
Telegram (hallazgo 14) se comprueba aparte, **una sola vez**, con un texto que empiece por
"PRUEBA (no es una alerta)".

## 20. SSH que acepta y corta: /run/sshd desaparecido

Sintoma: el puerto 22 **acepta TCP** pero corta antes del banner. Nadie puede entrar.
El resto del servidor funciona con normalidad.

```
sshd: fatal: Missing privilege separation directory: /run/sshd
```

La unidad de ssh trae `RuntimeDirectory=sshd` con `RuntimeDirectoryPreserve=no`: systemd
**borra /run/sshd al parar el servicio**. Si nadie lo recrea (Ubuntu no trae definicion en
`tmpfiles.d` para sshd), el proceso maestro sigue escuchando pero cada hijo muere al nacer.

**Diagnostico diferencial (hazlo SIEMPRE antes de culpar al firewall):**

| Prueba | Filtrado / ban | sshd roto |
|---|---|---|
| Conexion TCP al 22 | rechazada o timeout **sin aceptar** | **acepta** y luego corta |
| Desde otra IP externa | funciona (si es ban por IP) | falla igual |
| Desde la red interna/VPN | **funciona** | falla igual |

Si falla tambien por la VPN, no es firewall ni whitelist: es el servicio.

**Fix permanente** (probar borrando el directorio y viendo que se recrea):
```bash
printf 'd /run/sshd 0755 root root -\n' > /etc/tmpfiles.d/sshd.conf
systemd-tmpfiles --create /etc/tmpfiles.d/sshd.conf
```

**Nota**: una lista de rangos conocidos del vigilante (`known_nets.txt`) NO es una whitelist
de acceso: solo decide si se manda alerta. No concede ni deniega conexiones. Conviene
aclararlo cuando el usuario sospeche que "el firewall nos ha bloqueado".

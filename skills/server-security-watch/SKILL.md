---
name: server-security-watch
description: 'Auditoria forense de intrusion y despliegue de vigilancia continua en servidores Linux/Ubuntu. Responde a preguntas como "¿ha entrado alguien?" o "¿puede haber alguien dentro que no haya hecho nada todavia?", identifica DE QUIEN son las IPs que acceden (via RDAP), reconstruye que hizo una sesion sospechosa, y deja instalado un vigilante horario que avisa por Telegram SOLO cuando algo cambia (claves SSH, usuarios, sudo, cron, puertos, SUID, rangos nuevos). Usar cuando se pida "revisa si han entrado", "chequeo de seguridad del servidor", "mira los logs por si hay algo extraño", "se ha filtrado una clave", "vigilancia del servidor", "quien esta entrando", "esta IP de quien es", "monta la vigilancia en este servidor". NOT para auditoria de salud o rendimiento (CPU, RAM, disco, backups) — para eso usar la skill linux-server-audit.'
---

# Server Security Watch

Auditoria forense de intrusion + vigilancia continua para servidores Linux.
Complementa `linux-server-audit` (salud y metricas); esta skill cubre **seguridad**.

## Cuando usar cada fase

| Situacion | Fase |
|---|---|
| "¿ha entrado alguien?", clave filtrada, sospecha | 1 (y 2 si hay IPs raras) |
| "¿de quien es esta IP?", accesos desconocidos | 2 |
| "que vigile a diario", tras cerrar un incidente | 3 |
| Servidor nuevo de cliente | 1 -> 2 -> 3 completo |

**Antes de dar cualquier veredicto, leer `references/hallazgos.md`.** Contiene las
trampas que producen falsos positivos (alarmar por tu propio programador) y falsos
negativos (dar por cerrado un puerto que esta abierto). Sin eso, el informe sera
confiado y equivocado.

---

## FASE 1 — Chequeo forense historico

```bash
ssh root@HOST 'bash -s' < scripts/forensic_check.sh 7    # 7 = dias a analizar
```

Solo lectura. Cubre: accesos SSH por cuenta/IP, fuerza bruta, claves autorizadas,
usuarios y sudo, persistencia (cron/timers/servicios), procesos y puertos, SUID,
cambios en /etc y /root, integridad de logs, firewall, parches y secretos en claro.

### Verificacion obligatoria que el script NO puede hacer solo

El script corre DENTRO del servidor, asi que no puede saber que se ve desde fuera.
**Docker se salta UFW**: un puerto puede figurar como `DENY` en `ufw status` y estar
abierto a internet. Comprobar SIEMPRE desde la maquina local:

```bash
for p in 3000 8080 9000 10086; do
  timeout 5 bash -c "</dev/tcp/HOST/$p" 2>/dev/null && echo "$p ABIERTO DESDE INTERNET" || echo "$p cerrado"
done
```

Si aparece abierto algo que deberia estar cerrado, la causa y el arreglo (cadena
`DOCKER-USER`) estan en `references/hallazgos.md` seccion 1.

### Como redactar el veredicto

Estructura que funciona: **hallazgos por gravedad** (critico/alto/medio) con la
evidencia pegada, luego **tabla de lo que esta limpio**, luego **limites del
analisis**, y al final **acciones ordenadas por impacto**.

Reglas de honestidad, no negociables:
- Nunca escribir "no hay nadie dentro". Escribir "no encuentro rastro" + puntos ciegos.
- Cada hallazgo con su evidencia ejecutada (output real), o se descarta.
- Declarar SIEMPRE la ventana real de los logs (suele ser 4-5 semanas, no "siempre").
  Decir "0 usos de esta clave" cuando los logs solo cubren un mes es enganoso.

---

## FASE 2 — Identificar las IPs

```bash
./scripts/identify_ips.sh root@HOST      # se ejecuta EN LOCAL (necesita internet)
```

Consulta RDAP y devuelve operador y pais por IP. Claves de interpretacion:

- **ISP residencial del pais** -> personal propio teletrabajando. Confirmarlo igual.
- **Starlink / moviles** -> CGNAT: **la misma persona aparece con varios /16**.
  No tratarlos como IPs distintas ni alertar por cada una.
- **Cloud (AWS/Azure/GCP/Hetzner)** -> no es un domicilio. VPN comercial, script
  propio, o validacion de credencial robada. Investigar siempre.

Para una IP dudosa, medir la duracion de la sesion: **1-3 segundos = automatizado**,
nunca una persona. El procedimiento completo esta en `references/hallazgos.md` (3).

`whois` no suele estar instalado; el script usa RDAP por HTTPS, que funciona siempre.

---

## FASE 3 — Desplegar la vigilancia

### 3.1 Config de Telegram (fichero 600, nunca hardcodear el token)

```bash
ssh root@HOST 'mkdir -p /etc/secwatch && chmod 700 /etc/secwatch
cat > /etc/secwatch/telegram.conf <<EOF
BOT_TOKEN=<token>
CHAT_ID=<id1> <id2>
EOF
chmod 600 /etc/secwatch/telegram.conf'
```

Si ya hay un monitor con el token incrustado en el script, **avisar al usuario**:
es un secreto en claro y hay que sacarlo al fichero de config y rotarlo.

### 3.2 Instalar el vigilante

```bash
cat scripts/security_watch.sh | ssh root@HOST 'cat > /root/scripts/security_watch.sh
  chmod 700 /root/scripts/security_watch.sh && bash -n /root/scripts/security_watch.sh'
```

**ANTES de la primera ejecucion, precargar los rangos conocidos de ESTE servidor** (salida de la
fase 2; el script arranca con `known_nets.txt` vacio a proposito), o alertara de tu propia gente.
Incluir tambien las redes internas si hay monitores locales (`127.0.0`, `172.17.0`, `172.18.0`...):
```bash
ssh root@HOST 'mkdir -p /var/lib/secwatch && printf "%s\n" 203.0.113 198.51.100 > /var/lib/secwatch/known_nets.txt'
```

```bash
ssh root@HOST '/root/scripts/security_watch.sh'    # 1a vez: crea baseline, NO alerta
ssh root@HOST '/root/scripts/security_watch.sh'    # 2a vez: debe decir "OK - sin cambios"
```

### 3.3 Probar que DETECTA de verdad (obligatorio, si no es teatro)

Abrir un puerto temporal y comprobar que salta. Verificar antes que el puerto este
libre y matar solo el proceso propio:

```bash
ssh root@HOST 'ss -ltn | grep -q ":9137 " && echo OCUPADO || {
  nohup python3 -m http.server 9137 --bind 127.0.0.1 >/dev/null 2>&1 &
  echo $! > /tmp/t.pid; sleep 2
  /root/scripts/security_watch.sh; tail -3 /var/log/security_watch.log
  kill $(cat /tmp/t.pid); rm -f /tmp/t.pid; }'
```
Debe aparecer `HALLAZGO: PUERTOS A LA ESCUCHA MODIFICADOS` y `ALERTA ENVIADA`.

### 3.4 Cron horario

```bash
ssh root@HOST '(crontab -l 2>/dev/null; echo "25 * * * * PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /root/scripts/security_watch.sh >/dev/null 2>&1") | crontab -'
```
Minuto 25 para no chocar con backups y monitores que suelen ir en :00.

**El `PATH` explicito NO es opcional.** Cron corre con `PATH=/usr/bin:/bin` e
`iptables` vive en `/usr/sbin`: sin esto la auto-reparacion de las reglas LOG de
paneles (3.2 / seccion 8b) falla en silencio y la vigilancia del panel no vuelve
tras un reinicio. El resto del script funciona, asi que el fallo no se nota.
Comprobarlo siempre simulando el entorno de cron:
```bash
ssh root@HOST 'env -i PATH=/usr/bin:/bin sh -c "command -v iptables" || echo FALLA'
ssh root@HOST 'env -i PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
   HOME=/root SHELL=/bin/sh /root/scripts/security_watch.sh; tail -3 /var/log/security_watch.log'
```

### 3.5 Trazabilidad de comandos

```bash
cat scripts/setup_history.sh | ssh root@HOST 'bash -s'          # todas las cuentas
cat scripts/setup_history.sh | ssh root@HOST 'bash -s root deploy'   # o concretas
```

Anade `HISTTIMEFORMAT` e history ilimitado. **Comprobar antes si alguna cuenta
carece de `.bash_history`**: es un agujero de trazabilidad total (caso real: cuenta
con sudo NOPASSWD, 100+ accesos y cero registro de comandos).

Para auditoria a prueba de borrado (el usuario puede borrar su history), ofrecer
`auditd` como opcion: mas robusto, pero consume CPU/disco y genera mucho log.

---

## FASE 4 — Vigilar que los servicios SIGAN VIVOS (no es lo mismo que la seguridad)

`security_watch.sh` detecta **cambios sospechosos**. NO detecta **caidas**. Son dos trabajos
distintos y hacen falta los dos: en un cliente real la web estuvo **12 dias
caida** con el vigilante de seguridad funcionando y sin que saltara nada (hallazgo 11).

Desplegar SIEMPRE los dos juntos:

```bash
# 1) el script (mismo para todos los servidores: NO personalizarlo aqui)
cat scripts/service_watch.sh | ssh root@HOST 'cat > /root/scripts/service_watch.sh
  chmod 700 /root/scripts/service_watch.sh && bash -n /root/scripts/service_watch.sh'

# 2) lo que cambia de un cliente a otro va en la CONFIG, no en el script
ssh root@HOST 'cat > /etc/secwatch/urls.conf' <<CONF
# etiqueta|url|codigos aceptables
Web de gestion (cliente)|https://web.ejemplo.com/|200,302
CONF
ssh root@HOST 'chmod 600 /etc/secwatch/urls.conf'

# 3) dos pasadas: la 1a crea la linea base, la 2a debe callar
ssh root@HOST '/root/scripts/service_watch.sh; /root/scripts/service_watch.sh'

# 4) cron cada 5 minutos
ssh root@HOST '(crontab -l 2>/dev/null; echo "*/5 * * * * /root/scripts/service_watch.sh >/dev/null 2>&1") | crontab -'
```

**Comprobar que AVISA de verdad**, no solo que corre callado: duplicar el script en `/tmp`
con `BASE` y `LOG` propios y una URL inexistente, y ejecutarlo 3 veces. Debe callar la 1a,
avisar la 2a y NO repetir la 3a. Luego borrar los restos de la prueba. Un vigilante que
nunca se ha visto avisar no es un vigilante, es un fichero.

| Check | Detecta |
|---|---|
| Replicas de Docker Swarm (`0/1`) | Servicio que no levanto tras un reinicio o un redeploy |
| URLs de `/etc/secwatch/urls.conf` | Web caida, 502 de Traefik, certificado roto |
| Canarios `...|https://dominio/.env|403,404` | Que una fuga tapada con `.htaccess` NO vuelva tras un redespliegue (hallazgo 18) |

Avisa solo en el CAMBIO de estado (caida y recuperacion), tras 2 rondas fallidas seguidas
—10 minutos— para no dispararse ni por un pico de red ni por el arranque de Swarm.

---

## Que vigila el script

| Check | Detecta |
|---|---|
| Hash de `authorized_keys` | Clave SSH plantada — el paso 1 de todo intruso |
| Usuarios, UID 0, `sudoers` | Escalada de privilegios |
| Cron, timers, servicios systemd | Persistencia |
| Puertos a la escucha | Backdoor o servicio expuesto sin querer (filtrables por `/etc/secwatch/ports_ignore.conf`, ver hallazgo 17) |
| SUID | Puerta trasera a root |
| Procesos en `/tmp`, `/dev/shm` | Malware clasico |
| Rangos /16 nuevos con login correcto | Acceso desde sitio desconocido |
| Root por contraseña desde rango desconocido | Uso de credencial filtrada |
| **Accesos a paneles de admin** desde rango desconocido | Quien toca Easypanel/WGDashboard/phpMyAdmin |
| Pico de fuerza bruta (>300/h) | Ataque activo |

### Vigilar paneles de administracion (puertos 3000, 10086, 8080...)

Muchos paneles no registran sus propios logins (WGDashboard no anota ni uno). La
via fiable es registrar a nivel de red con reglas `LOG` que **no bloquean**:

```bash
iptables -I DOCKER-USER -p tcp --dport 3000 -m conntrack --ctstate NEW \
         -m limit --limit 20/min -j LOG --log-prefix "PANEL3000 "
iptables -I INPUT -p tcp --dport 10086 -m conntrack --ctstate NEW \
         -m limit --limit 20/min -j LOG --log-prefix "PANEL10086 "
```

- Puertos publicados por **Docker** -> la regla DEBE ir en `DOCKER-USER` (UFW no filtra Docker).
- Puertos de servicios **nativos** -> cadena `INPUT`.
- El `--limit` evita llenar el disco durante un escaneo masivo.
- El script **recrea estas reglas solas** si faltan (no sobreviven a un reinicio),
  configurables con `PANELES_VIGILADOS="3000:DOCKER-USER 10086:INPUT"`.

**Advertir al usuario:** vigilar un panel abierto es poner una camara, no una
cerradura. Si el panel controla contenedores y BDs, enterarse despues no deshace
el danio. Ofrecer siempre cerrar tambien, y si el equipo tiene IP dinamica (CGNAT),
proponer el acceso **por la propia VPN** en vez de whitelist por IP.

**Principio de diseno:** informa de **cambios contra un baseline**, nunca de estado.
Silencio = todo igual que antes. Tras avisar, actualiza el baseline para no repetir
la alerta cada hora. Latido semanal los lunes (con guardia de semana ISO) para saber
que sigue vivo.

## Errores conocidos

- **Cron sin `PATH`**: `iptables` esta en `/usr/sbin`, fuera del PATH de cron. El
  vigilante parece sano (`OK - sin cambios`) pero no recrea las reglas LOG de
  paneles tras un reinicio. Poner el PATH en la propia linea de cron. Detectado
  en un despliegue real.
- **Latido duplicado**: condicionar solo por dia+hora reenvia el latido en cada
  ejecucion de esa hora. Usa marcador de semana ISO (`date +%G-W%V`). Corregido.
- **Vigilante que trunca su log**: destruye la evidencia que debe conservar. Rotar, nunca vaciar.
- **Alertar por IP exacta**: con CGNAT genera ruido constante. Comparar por /16.
- **Editar scripts remotos con `Edit`** cuando llevan emojis o `\n` en `printf`: el
  matching falla. Descargar -> editar en local -> subir con `cat local | ssh 'cat > destino'`.

## Auto-mejora

Al cerrar cada aplicacion practica de esta skill:
1. Registrar aprendizajes en `aprendizajes/<caso>.md` (o en esta seccion si es breve)
2. Si el patron es generalizable, actualizar el cuerpo de este SKILL.md
3. Si se descubre un error recurrente, anadirlo a "Errores conocidos"

Sin esta fase, la skill se fosiliza y pierde valor con el tiempo.

---

## Barrido de fugas web (`scripts/barrido_fugas_web.sh`)

Busca en TODOS los dominios propios ficheros de configuración, backups y repositorios servidos por
error. **Solo lectura**: hace peticiones GET desde fuera, no toca los servidores.

Nació de un incidente real (septiembre 2026): el `.env` de una aplicación PHP (centralita) vivía dentro del
docroot y lo descargó `l9scan` (leakix.net), un escáner **público** que además indexa y publica lo
que encuentra, **a las horas** de subirse el fichero. El barrido posterior de 73 dominios encontró
4 servicios más igual de expuestos. Aquel barrido se hizo a mano y no quedó nada reutilizable.

```bash
scripts/barrido_fugas_web.sh dominios.txt -o informe.md    # un dominio por línea
scripts/barrido_fugas_web.sh -d ejemplo.com                # uno suelto
#  -j 8  peticiones en paralelo (por defecto 6)   ·   -t 12  timeout (por defecto 10)
```
Sale con **1** si hay alguna fuga, **0** si no: sirve tal cual en un cron o un hook.

### Por qué NO vale un `curl -w %{http_code}`

Los paneles EasyPanel, n8n y cualquier SPA **responden 200 con su HTML a cualquier ruta inventada**.
En el primer barrido, de 16 respuestas 200 **doce eran falsos positivos**; en un segundo barrido, de
62 respuestas 200 **57** lo eran. Por eso el veredicto lo decide el **contenido**: líneas
`CLAVE=VALOR` para un `.env`, `ref: refs/…` para un `.git/HEAD`, `CREATE TABLE` para un dump. Si el
cuerpo empieza por `<!doctype` o `<html>`, es la aplicación respondiendo y se descarta.
Cuando encuentra credenciales, **nombra las claves** que expone (`DB_PASS`, `GOOGLE_CLIENT_SECRET`…),
que es lo que decide si hay que rotar o basta con tapar.

### Cómo conseguir la lista de dominios

No existe un inventario fiable. Se reconstruye desde el Traefik de cada servidor:
```bash
ssh root@HOST 'grep -rhoE "Host\(\`[^\`]+\`\)" /etc/easypanel/traefik/ | sed "s/Host(\`//;s/\`)//" | sort -u'
```

### Lo que el barrido NO ve, y hay que mirar por dentro

Que una ruta dé 403 **no significa que el fichero no esté**. El `.htaccess` es contención y **un
redespliegue puede borrarlo**. La comprobación de verdad es por SSH:
```bash
find /etc/easypanel/projects -maxdepth 4 -name ".env*" -path "*html*"     # ficheros aún en el docroot
find /etc/easypanel/projects -maxdepth 4 -type d -name ".git" -path "*html*"
docker inspect <cont> --format '{{range .Config.Env}}{{println .}}{{end}}' | cut -d= -f1
```
Si las credenciales **no** aparecen en el entorno del contenedor, siguen dependiendo del fichero y
la causa raíz sigue abierta. Caso real: la propia aplicación afectada seguía con TODAS
sus credenciales solo en el `.env` del docroot, siete días después del incidente.

### Canarios permanentes (complemento, no sustituto)

En el `urls.conf` de `service_watch.sh` de cada servidor, para enterarse el mismo día si un
redespliegue deja el fichero al aire otra vez:
```
FUGA - .env accesible (debe dar 403)|https://<dominio>/.env|403,404
FUGA - .git accesible (debe dar 403)|https://<dominio>/.git/HEAD|403,404
```

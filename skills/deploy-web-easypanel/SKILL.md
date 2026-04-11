---
name: deploy-web-easypanel
description: "Desplegar web PHP en Easypanel con MySQL o PostgreSQL. Usar cuando se diga 'desplegar web', 'montar web en servidor', 'deploy web easypanel', 'nueva web en VPS', o 'crear servicio web'."
---

# Deploy Web PHP en Easypanel

Despliegue automatizado de webs PHP con BD (MySQL o PostgreSQL) en servidores con Easypanel.

## Imagenes Docker disponibles

| BD | Imagen PHP | Imagen BD | Puerto BD |
|----|-----------|-----------|-----------|
| MySQL | `webcomunica/php-mysql-custom:8.2-apache` | `mysql:8.4` | 3306 |
| PostgreSQL | `webcomunica/php-pgsql-custom:8.2-apache` | `postgres:16` | 5432 |

Ambas imagenes PHP incluyen: PHP 8.2, Apache, mod_rewrite, headers, expires, deflate, AllowOverride All, php.ini produccion.

## Paso 1: Recopilar datos

Preguntar al usuario (solo lo que no se sepa):

| Dato | Ejemplo | Obligatorio |
|------|---------|-------------|
| **Servidor** | IP, usuario SSH, password | Si |
| **Nombre proyecto** | mi-web, tienda, portal-cliente | Si |
| **Nombre servicio web** | {proyecto}-web | Si (default: {proyecto}-web) |
| **Tipo BD** | mysql / postgres | Si |
| **Nombre BD** | mi_base_datos | Si |
| **Usuario BD** | app_user | Si |
| **Password BD** | (generar si no se da) | Si |
| **Dominio** | web.cliente.es | No (puede ser solo subdominio Easypanel) |
| **Archivos PHP locales** | /ruta/local/archivos/ | No (se pueden subir despues) |

Si el servidor esta en el inventario de `linux-server-audit/servers.yaml`, usar esos datos.

## Paso 2: Verificar acceso al servidor

```bash
sshpass -p 'PASSWORD' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 USER@HOST "echo OK && docker --version && ls /etc/easypanel/ 2>/dev/null && echo 'EASYPANEL_OK'"
```

Verificar:
- SSH funciona
- Docker esta instalado
- Easypanel esta instalado (`/etc/easypanel/` existe)

Si algo falla, informar al usuario y detener.

## Paso 3: Crear carpeta para archivos web

```bash
sshpass -p 'PASSWORD' ssh USER@HOST "
sudo mkdir -p /etc/easypanel/projects/{proyecto}/{servicio}/html
sudo chown -R 33:33 /etc/easypanel/projects/{proyecto}/{servicio}/html
sudo chmod 755 /etc/easypanel/projects/{proyecto}/{servicio}/html
echo 'Carpeta creada OK'
ls -la /etc/easypanel/projects/{proyecto}/{servicio}/
"
```

## Paso 4: Indicar configuracion en Easypanel

Mostrar al usuario instrucciones claras para configurar en el panel web de Easypanel:

### 4.1 Servicio BD

**Si MySQL:**
- Easypanel > Proyecto > + New Service > MySQL
- Version: 8.4
- Root password: (generar)
- Database: {nombre_bd}
- User: {usuario_bd}
- Password: {password_bd}

**Si PostgreSQL:**
- Easypanel > Proyecto > + New Service > Postgres
- Version: 16
- Database: {nombre_bd}
- User: {usuario_bd}
- Password: {password_bd}

### 4.2 Servicio Web (App)

- Easypanel > Proyecto > + New Service > App
- Source: Image
- **Si MySQL:** `webcomunica/php-mysql-custom:8.2-apache`
- **Si PostgreSQL:** `webcomunica/php-pgsql-custom:8.2-apache`
- Puerto: 80

Variables de entorno:

**MySQL:**
```
APACHE_DOCUMENT_ROOT=/var/www/html
TZ=Europe/Madrid
DB_HOST={proyecto}_{servicio-bd}
DB_PORT=3306
DB_NAME={nombre_bd}
DB_USER={usuario_bd}
DB_PASS={password_bd}
```

**PostgreSQL:**
```
APACHE_DOCUMENT_ROOT=/var/www/html
TZ=Europe/Madrid
DB_HOST={proyecto}_{servicio-bd}
DB_PORT=5432
DB_NAME={nombre_bd}
DB_USER={usuario_bd}
DB_PASS={password_bd}
```

Mounts:
- Type: Bind Mount
- Host: `/etc/easypanel/projects/{proyecto}/{servicio}/html`
- Container: `/var/www/html`

Dominio (si aplica):
- Anadir dominio en la seccion Domains
- SSL: Let's Encrypt (automatico)
- Puerto contenedor: 80

### 4.3 Deploy

Indicar al usuario que haga Deploy de ambos servicios.

## Paso 5: Subir archivos PHP (si los tiene)

Si el usuario proporciono ruta local de archivos:

```bash
# Subir al servidor via SCP
sshpass -p 'PASSWORD' scp -o StrictHostKeyChecking=no -r /ruta/local/* USER@HOST:/tmp/web-upload/

# Mover a carpeta correcta y dar permisos
sshpass -p 'PASSWORD' ssh USER@HOST "
sudo cp -r /tmp/web-upload/* /etc/easypanel/projects/{proyecto}/{servicio}/html/
sudo chown -R 33:33 /etc/easypanel/projects/{proyecto}/{servicio}/html/
sudo rm -rf /tmp/web-upload
echo 'Archivos subidos OK'
ls -la /etc/easypanel/projects/{proyecto}/{servicio}/html/ | head -15
"
```

## Paso 6: Verificar despliegue

Esperar a que el usuario confirme que hizo Deploy en Easypanel, luego verificar:

```bash
sshpass -p 'PASSWORD' ssh USER@HOST "
echo '=== CONTENEDORES ==='
sudo docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' | grep -i {proyecto}

echo '=== ARCHIVOS WEB ==='
ls -la /etc/easypanel/projects/{proyecto}/{servicio}/html/ | head -10

echo '=== TEST WEB ==='
PUERTO=\$(sudo docker port \$(sudo docker ps -q -f name={proyecto}_{servicio} | head -1) 80 2>/dev/null | cut -d: -f2)
if [ -n \"\$PUERTO\" ]; then
  curl -s -o /dev/null -w 'HTTP %{http_code}' http://localhost:\$PUERTO/
else
  echo 'No se pudo detectar puerto, verificar manualmente'
fi

echo ''
echo '=== TEST BD ==='
sudo docker exec \$(sudo docker ps -q -f name={proyecto}_{servicio} | head -1) php -m | grep -i -E 'pdo|mysql|pgsql'
"
```

## Paso 7: Resumen final

Mostrar tabla resumen del despliegue:

```
| Campo | Valor |
|-------|-------|
| Servidor | {IP} |
| Proyecto Easypanel | {proyecto} |
| Servicio Web | {servicio} |
| Imagen PHP | webcomunica/php-{bd}-custom:8.2-apache |
| BD | {tipo} {version} |
| Base de datos | {nombre_bd} |
| Carpeta archivos | /etc/easypanel/projects/{proyecto}/{servicio}/html |
| URL | https://{dominio o subdominio easypanel} |
| Estado | OK / Pendiente |
```

## Notas importantes

- **Easypanel SIEMPRE hace docker pull** — las imagenes deben estar en Docker Hub
- **Crear carpeta html ANTES de Deploy** — si no existe, Easypanel falla con "bind source path does not exist"
- **Permisos www-data (UID 33)** — siempre `chown -R 33:33` despues de subir archivos
- **Host de BD** — es el nombre del servicio en Easypanel: `{proyecto}_{servicio-bd}` (NO la IP del servidor)
- **Warning AH00558** de Apache es cosmetico — se puede ignorar
- **MySQL 5.7 legacy** — si se restaura dump de MySQL 5.7 en 8.4 puede haber problemas de collation. Hacer sed si es necesario

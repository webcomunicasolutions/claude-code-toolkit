---
name: docker-hub
description: "Gestionar imágenes Docker Hub de webcomunica. Usar cuando se necesite: construir y subir imágenes custom, desplegar imágenes en Easypanel, listar imágenes disponibles, o resolver problemas de pull/push en Docker Hub."
---

# Docker Hub - webcomunica

Gestión de imágenes Docker custom en Docker Hub para despliegue en servidores con Easypanel.

---

## Cuenta Docker Hub

| Campo | Valor |
|-------|-------|
| **Usuario** | webcomunica |
| **Login** | Google |
| **Repositorio** | https://hub.docker.com/u/webcomunica |
| **Visibilidad** | Público |

---

## Imágenes Disponibles

### webcomunica/php-mysql-custom:8.2-apache

PHP 8.2 con Apache y extensiones MySQL. Para apps web PHP en Easypanel.

**Incluye:**
- PHP 8.2 + Apache (base oficial `php:8.2-apache`)
- Extensiones: `pdo_mysql`, `mysqli`
- Módulos Apache: `rewrite`, `headers`, `expires`, `deflate`
- AllowOverride All (soporte .htaccess)
- php.ini de producción

**Dockerfile:**
```dockerfile
FROM php:8.2-apache
RUN docker-php-ext-install pdo_mysql mysqli
RUN a2enmod rewrite headers expires deflate
RUN sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
EXPOSE 80
```

**En Easypanel:** Usar `webcomunica/php-mysql-custom:8.2-apache` como imagen.

**Servidores donde se usa:**
- gesfac (192.168.4.100) - servicio gesfac_web
- GinerNet VPS (5.134.117.56) - servicio avisos_web

---

## Operaciones

### Construir y subir una imagen nueva

```bash
# 1. Crear Dockerfile
mkdir -p /tmp/mi-imagen && cat > /tmp/mi-imagen/Dockerfile << 'EOF'
FROM base:tag
# ... customizaciones
EOF

# 2. Build
docker build -t webcomunica/nombre-imagen:tag /tmp/mi-imagen/

# 3. Login (necesita Personal Access Token con Read & Write)
echo "TOKEN" | docker login -u webcomunica --password-stdin

# 4. Push
docker push webcomunica/nombre-imagen:tag
```

### Actualizar una imagen existente

```bash
# Rebuild con el Dockerfile actualizado
docker build -t webcomunica/php-mysql-custom:8.2-apache /ruta/al/Dockerfile/
docker push webcomunica/php-mysql-custom:8.2-apache

# En cada servidor con Easypanel: redesplegar desde la UI
```

### Desplegar en Easypanel (servidor remoto)

```bash
# En Easypanel UI: imagen = webcomunica/nombre-imagen:tag
# Easypanel hace docker pull automáticamente

# Si necesitas verificar manualmente:
ssh usuario@servidor 'sudo docker pull webcomunica/nombre-imagen:tag'
```

---

## Lecciones Importantes

1. **Easypanel SIEMPRE hace `docker pull`** - No usa imágenes locales. Toda imagen custom debe estar en un registro (Docker Hub).
2. **Imágenes locales NO funcionan en Docker Swarm** via Easypanel - Aunque existan en el servidor, Easypanel intenta descargarlas.
3. **El nombre de imagen importa** - En Easypanel usar `webcomunica/php-mysql-custom:8.2-apache` (con el prefijo de usuario), no `php-mysql-custom:8.2-apache` (solo local).
4. **Crear directorio html** antes de desplegar - `mkdir -p /etc/easypanel/projects/PROYECTO/SERVICIO/html && chown 33:33 ...`
5. **Warning AH00558** de Apache es normal - Solo indica que no tiene ServerName configurado, no afecta funcionamiento.

---

## Configuración típica en Easypanel para apps PHP

| Parámetro | Valor |
|-----------|-------|
| Imagen | `webcomunica/php-mysql-custom:8.2-apache` |
| Puerto interno | 80 |
| Bind mount | `/etc/easypanel/projects/{proyecto}/{servicio}/html` → `/var/www/html` |
| Variables de entorno | `PORT=80`, `TZ=Europe/Madrid`, `DB_HOST=...`, `DB_PORT=3306`, `DB_NAME=...`, `DB_USER=...`, `DB_PASSWORD=...` |
| Propietario html | `www-data` (UID 33) |

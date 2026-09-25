# Databases & Docker - Persistencia y backups

Cuando se trabaje con bases de datos (PostgreSQL, MySQL, MongoDB, Redis con
persistencia, etc.) o con servicios Docker que contengan datos, seguir este
protocolo SIN excepciones.

## Regla absoluta
Los datos NO viven en volumenes de Docker sin backup. Un volumen puede
perderse por: reset del entorno de contenedores, `docker compose down -v`
accidental, rebuild de imagen, cambio de maquina, corrupcion del daemon,
o una herramienta de sincronizacion de ficheros que NO sincroniza volumenes Docker.

## Al crear o iniciar un servicio de BD en Docker

### 1. Verificar persistencia declarada
- Debe haber un volumen nombrado en `docker-compose.yml`:
  ```yaml
  db:
    volumes:
      - nombre_data:/var/lib/postgresql/data
  volumes:
    nombre_data:
  ```
- NO usar bind mounts anonimos ni volumenes sin nombre.

### 2. Crear script de backup desde el minuto 1
Crear `scripts/backup_<servicio>.sh` ANTES de cargar datos. Requisitos:
- Genera dump comprimido (`.sql.gz` o `.dump`)
- Guarda en `backups/` dentro del proyecto (una carpeta que se sincronice o versione)
- Timestamp en el nombre: `proyecto_mysql_20260413_164805.sql.gz`
- Retencion configurable (por defecto 30 dias)
- Exit code != 0 si el backup sale vacio o falla

### 3. Ejecutar primer backup INMEDIATAMENTE
Despues de cargar datos iniciales, antes de cualquier otra operacion,
ejecutar el backup para validar que funciona Y dejar una copia de seguridad
del estado inicial.

### 4. Avisar al usuario sobre programacion automatica
Proponer anadir a cron (usuario decide si lo activa):
```
0 3 * * * cd /ruta/proyecto && ./scripts/backup_mysql.sh >> backups/.log 2>&1
```

## Antes de cualquier operacion destructiva

Operaciones que requieren backup previo OBLIGATORIO:
- `DROP TABLE`, `DROP DATABASE`, `TRUNCATE`
- `ALTER TABLE` que cambia tipos o borra columnas
- `docker compose down -v`, `docker volume rm`, `docker system prune`
- Migraciones de schema (Alembic, Flyway, migraciones Laravel)
- Scripts de carga masiva que hacen TRUNCATE antes de INSERT
- Cambios en el docker-compose.yml que afecten a servicios con datos

Protocolo:
1. Ejecutar `./scripts/backup_<servicio>.sh`
2. Verificar que el archivo de backup tiene tamano > 0
3. Proceder con la operacion
4. Si algo sale mal: restaurar desde el backup

## Al detectar un servicio con datos SIN backup

Si al leer un proyecto se detecta que hay una BD Docker corriendo pero NO hay
`scripts/backup_*.sh` ni carpeta `backups/`:
1. PARAR cualquier tarea que implique tocar datos
2. AVISAR al usuario: "No veo sistema de backup para la BD, lo creo antes de
   seguir?"
3. NO asumir que los datos son reproducibles
4. NO continuar hasta que haya backup o el usuario confirme que no hace falta

## Al detectar datos perdidos

Si al arrancar una sesion se detecta que una BD Docker deberia tener datos
segun la sesion anterior pero esta vacia:
1. PARAR inmediatamente
2. Comprobar `docker volume ls` y `docker volume inspect` para ver CreatedAt
3. Buscar dumps en disco, en la nube y en carpetas de backups
4. Avisar al usuario con evidencia concreta (timestamps, volumen nuevo, etc.)
5. NO asumir culpa ni reintentar operaciones destructivas
6. Proponer plan A (recuperar) y plan B (rehacer desde fuentes)

## Separacion datos fuente vs datos derivados

Diferenciar siempre:
- **Datos fuente**: CSVs, Excels, fotos, PDFs del cliente. NUNCA en la BD
  Docker. Viven en carpetas sincronizadas o en almacenamiento propio.
- **Datos derivados**: resultado de procesar los fuentes (OCR, merges,
  calculos). Viven en la BD. Si se pierden, se regeneran corriendo los
  scripts sobre los fuentes.

Documentar en el README o CLAUDE.md del proyecto:
- Que es fuente y que es derivado
- Que script regenera cada cosa
- Cuanto tarda / cuesta regenerar

## Cosas que NO se hacen

- NO crear servicios Docker con datos sin definir volumen persistente
- NO ejecutar operaciones destructivas sin backup previo
- NO asumir que `docker compose up` preserva datos (puede no hacerlo si
  cambia el hash del servicio)
- NO confiar en que una herramienta de sincronizacion de ficheros sincroniza
  volumenes Docker (normalmente NO lo hace, solo sincroniza archivos en el
  filesystem del usuario)
- NO borrar volumenes Docker (`docker volume rm`) sin confirmacion explicita
- NO usar `docker compose down -v` jamas, salvo peticion explicita del
  usuario y con backup reciente verificado

---
name: linux-server-audit
description: "Auditoria completa de servidores Linux. Usar cuando se diga 'revisa el servidor', 'auditoria', 'health check', 'chequeo del servidor', 'estado del servidor', 'verifica seguridad', 'server audit', o 'diagnostico del servidor'."
---

# Linux Server Audit

Ejecutar auditoria de servidores Linux en 7 fases, generando reporte priorizado.

## Paso 1: Identificar Servidor

Leer `servers.yaml` de este skill para obtener datos de servidores conocidos.
Si el servidor no esta en el inventario, preguntar al usuario: IP, usuario SSH, password.

Conexion SSH con sshpass:
```bash
sshpass -p 'PASSWORD' ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 USER@HOST "COMANDO"
```

## Paso 2: Ejecutar 7 Fases

Ejecutar cada fase por separado, combinando comandos pequenos en un solo SSH.

1. **Backups** - Crontabs, directorios de backup, edad del ultimo backup
2. **Actualizaciones** - Paquetes pendientes, parches de seguridad, reboot requerido
3. **Logs/Errores** - journalctl errores 24h, OOM killer, auth failures, Docker dies
4. **Hardware** - CPU load, RAM, disco, inodos, swap, top procesos
5. **Seguridad** - Puertos abiertos, config SSH, firewall, fail2ban, usuarios con shell, SUID
6. **Servicios** - Docker containers, health checks, systemd failed, servicios criticos
7. **Vulnerabilidades** - EOL del SO, versiones software, certificados SSL, CVEs

## Paso 3: Reporte

Generar reporte con este formato:

```
# Auditoria: [NOMBRE/IP] - [FECHA]
## Resumen (tabla: Area | Estado | Hallazgos)
## Estado General: SALUDABLE / REQUIERE ATENCION / CRITICO
## Acciones: Urgente (hoy) / Importante (semana) / Recomendado
## Metricas Clave (tabla: CPU, RAM, Disco, Containers)
```

## Criterios de Estado

- CRITICO si: algun area critica, disco >90%, SO EOL, servicios criticos caidos
- ATENCION si: 3+ warnings, disco 80-90%, updates seguridad pendientes
- SALUDABLE si: todo OK

## Notas EasyPanel

Si el servidor usa EasyPanel: verificar `/etc/easypanel/projects/` y `/etc/easypanel/backups/`.
Los contenedores usan naming `<proyecto>_<servicio>`.

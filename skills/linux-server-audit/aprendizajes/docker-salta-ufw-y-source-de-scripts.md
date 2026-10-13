# Docker se salta UFW y no se hace source de scripts de backup

## Gotcha pagado: NUNCA hacer `source` de un script de backup para leer sus variables
Quise leer las env de restic con `. /root/scripts/backup-restic.sh` → **ejecutó el
backup entero** (por suerte terminó OK en 1 min y solo creó un snapshot extra) y cortó
la sesión SSH a mitad de auditoría. Forma correcta:
`eval "$(grep -E '^(export )?[A-Z_]+=' script.sh | grep -E 'RESTIC|B2|AWS')"`.

## Patrón útil: UFW no cuenta con Docker
`ufw status` decía que solo 22/80/443 estaban permitidos, pero el 3000 (panel EasyPanel)
estaba ABIERTO a internet: docker-proxy publica por la cadena DOCKER de iptables y se
salta UFW. **Verificar puertos siempre DESDE FUERA** (`echo > /dev/tcp/IP/puerto`),
nunca fiarse de la salida de ufw en hosts con Docker.

## Patrón útil: en EasyPanel el panel va por HTTP plano en :3000
Si el dueño entra por `http://IP:3000`, el login viaja sin cifrar. Recomendar dominio
HTTPS del panel o bind a 127.0.0.1 + túnel.

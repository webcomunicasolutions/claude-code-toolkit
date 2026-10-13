---
description: Plantillas para conectar a servidores de clientes (SSH, SQL, VPN)
argument-hint: "[cliente] [tipo]"
---

# Conectar a servidor

Expande a comandos listos para conectar a los servidores que tengas registrados.
**Rellena la tabla de abajo con tus propios clientes**; los valores son ejemplos.

## Uso

```
/conectar-servidor                       # Lista servidores disponibles
/conectar-servidor acme                  # Lista tipos para acme
/conectar-servidor acme ssh              # SSH directo
/conectar-servidor acme sql              # sqlcmd contra su SQL Server
```

## Servidores disponibles

### ACME S.L. (ejemplo)

| Tipo | Comando |
|------|---------|
| `ssh` | `ssh -i ~/.ssh/id_ed25519 usuario@<IP_SERVIDOR>` |
| `ssh-vpn` | `ssh -i ~/.ssh/id_ed25519 usuario@<IP_VPN_SERVIDOR>` (con la VPN activa) |
| `sql` | `ssh -i ~/.ssh/id_ed25519 usuario@<IP_SERVIDOR> 'sqlcmd -U sa -P "$SQL_SA_PASSWORD" -S ".\INSTANCIA" -d basedatos -W'` |
| `web` | `http://<IP_SERVIDOR>:8080` (navegador, con la VPN activa) |

**Credenciales**: en tu gestor de credenciales (p.ej. variable de entorno `SQL_SA_PASSWORD`). Nunca el valor en este fichero.

## Comportamiento esperado

Cuando el usuario invoque `/conectar-servidor <cliente> <tipo>`:
1. Busca el comando correspondiente arriba.
2. Si solo da `<cliente>`, muestra los tipos disponibles.
3. Si no da nada, lista los servidores.
4. Si el tipo no existe, sugiere los disponibles.
5. Si la password es `PENDIENTE`, avisa que hay que pedirla al cliente.
6. Antes de ejecutar nada que modifique datos en un servidor de cliente, pedir confirmacion explicita.

## Consultas SQL utiles (SQL Server)

```sql
-- Tablas con datos y numero de filas
SELECT s.name + '.' + t.name AS Tabla, p.rows AS Filas
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
WHERE p.rows > 0 ORDER BY p.rows DESC;

-- Ultimos 10 registros de una tabla
SELECT TOP 10 * FROM Clientes ORDER BY 1 DESC;
```

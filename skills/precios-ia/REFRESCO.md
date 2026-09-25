# Refresco automático de precios

## Cómo está montado

- **Script**: `~/.claude/scripts/refrescar-precios-ia.sh` — lanza `claude -p` en modo
  headless con el procedimiento de refresco de `SKILL.md`.
- **Cron**: `12 9 3 * * ~/.claude/scripts/refrescar-precios-ia.sh`
  → el **día 3 de cada mes a las 9:12**. (Minuto raro a propósito, para no coincidir
  con los picos de :00 y :30.)
- **Log**: `~/.claude/logs/precios-ia.log`
- **Aviso**: solo escribe por Telegram (skill `notify`) **si cambia la combinación
  recomendada** o si un modelo que usamos en producción ha sido retirado. Si no hay
  novedad, actualiza el fichero en silencio.

## Comprobar que sigue vivo

```bash
crontab -l | grep precios-ia          # que la línea siga ahí
tail -20 ~/.claude/logs/precios-ia.log # última ejecución
grep "Última verificación" ~/.claude/skills/precios-ia/SKILL.md
```

## Lanzarlo a mano

```bash
~/.claude/scripts/refrescar-precios-ia.sh
```

## Limitaciones (dichas claras)

- Depende de que **este equipo esté encendido** el día 3 a esa hora. Si está
  apagado, el cron NO se recupera solo: la fecha de "Última verificación" del
  SKILL.md es la que manda. Si tiene más de un mes, refrescar a mano.
- Si Google u OpenAI cambian la maquetación de su página de precios, el `WebFetch`
  puede devolver basura. Por eso el prompt exige **no inventar**: si una fuente no
  carga, se deja el dato anterior marcado como no verificado.
- Un cambio de precios **no cambia solo los workflows**: la tabla es la
  recomendación, migrar los nodos de n8n sigue siendo una decisión del usuario.

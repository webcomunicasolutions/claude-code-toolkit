# Versionado siempre

**Todo lo que acumule trabajo va con git.** Una herramienta de sincronización entre equipos y las
copias `_backup_<fecha>/` no bastan.

**Por qué:** una herramienta de sincronización de ficheros **también sincroniza el borrado** — si
alguien borra o corrompe algo, se propaga a todos los equipos y no hay a qué volver. Y una carpeta
de backups ocupa mucho y **no dice QUÉ cambió**, que suele ser justo lo que hace falta.

## Qué hacer

Al crear o retomar un proyecto (código o no: documentación, playbooks, plantillas, bibliotecas
scrapeadas), comprobar si es repo git. Si no lo es y acumula trabajo, **proponerlo**.

```bash
git status -sb 2>/dev/null || echo "SIN VERSIONAR -> proponer git init"
```

- **Repos locales, sin remoto**, salvo que el usuario pida lo contrario. La sincronización entre
  equipos sigue funcionando igual; git aporta historial y marcha atrás. Sin remoto **no hay que
  pushear**: decirlo para no dejar avisos de "commits sin subir" que no aplican.
- **Commitear al cerrar un bloque de trabajo**, no solo al final del día.

## 🔴 Antes del primer `git init`: escanear secretos

Lo que entra en el primer commit **se queda en el historial para siempre**, y borrarlo después es
reescribir historia.

```bash
grep -rIn --exclude-dir=.git -E \
  'sk_[A-Za-z0-9]{20,}|BEGIN [A-Z ]*PRIVATE KEY|Bearer [A-Za-z0-9_.-]{20,}|password\s*[=:]\s*["'"'"'][^"'"'"']{4,}' .
```

En el `.gitignore`, siempre: credenciales (`.env`, `*.key`, `*.pem`, `.credentials.json`),
carpetas de "pendiente de borrado", `__pycache__/`, resultados de tests y config personal por
máquina (`settings.local.json`). Ver `credentials-handling.md`.

## Contenido descargado o generado

Versionarlo **sí merece la pena** cuando el `diff` responde a una pregunta útil (p. ej. "¿qué cambió
la documentación oficial desde el último refresh?"). Antes de montarlo, comprobar que los cambios
son **de contenido real** y no solo de una marca de tiempo: si solo cambia algo como `scraped_at`,
el versionado no aporta nada. Si aporta, **commitear después de cada actualización**, con la fecha
en el mensaje.

Complementa `git-workflow.md` (cómo se hacen los commits).

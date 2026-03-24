---
name: doc-maintenance
description: Mantenimiento de documentación y estructura de proyectos. Usar cuando se necesite organizar archivos MD, validar estructura, limpiar duplicados, o actualizar índices como CLAUDE.md. Incluye comandos para organizar (/organize), validar (/validate), y actualizar índice (/update-index).
---

# Doc Maintenance - Skill de Mantenimiento de Documentación

Skill para mantener la documentación y estructura de proyectos ordenada.

## Comandos Disponibles

### /organize - Organizar Documentación
Mueve archivos MD a las carpetas correctas según su tipo.

**Uso**: Cuando hay muchos archivos MD en la raíz del proyecto.

**Proceso**:
1. Escanear archivos MD en raíz
2. Clasificar por nombre/contenido
3. Mover a carpeta correcta
4. Reportar cambios

### /validate - Validar Estructura
Verifica que la estructura del proyecto sea correcta.

**Uso**: Para diagnosticar problemas de organización.

**Verifica**:
- [ ] CLAUDE.md, README.md existen
- [ ] Estructura docs/ correcta
- [ ] No hay archivos temporales
- [ ] No hay duplicados

### /update-index - Actualizar CLAUDE.md
Actualiza el índice de documentación en CLAUDE.md.

**Uso**: Después de añadir/mover documentación.

---

## Estructura Estándar

```
proyecto/
├── CLAUDE.md        # Índice para Claude (máx 50 líneas)
├── README.md        # Doc pública
├── CHANGELOG.md     # Historial
│
├── docs/
│   ├── usuario/     # MANUAL*, GUIA*, FAQ*, PRIMEROS*
│   ├── tecnico/     # DOCUMENTACION*, API*, ARQUITECTURA*
│   ├── reportes/    # REPORTE*, RESUMEN*, ESTADO*
│   └── historico/   # *_v0*, *antiguo*, *backup*
│
└── reference/       # Referencias técnicas rápidas
```

## Reglas de Clasificación

| Patrón | Destino |
|--------|---------|
| MANUAL*, GUIA*, FAQ* | docs/usuario/ |
| DOCUMENTACION*, API*, AGENTS* | docs/tecnico/ |
| REPORTE*, RESUMEN* | docs/reportes/ |
| *_v0*, *antiguo* | docs/historico/ |

## Comandos de Diagnóstico

```bash
# Contar MD en raíz
find . -maxdepth 1 -name "*.md" | wc -l

# Ver estructura docs
ls -la docs/*/

# Buscar duplicados
find . -name "*.md" | xargs -I{} basename {} | sort | uniq -d

# Buscar archivos vacíos
find . -name "*.md" -empty
```

## Formato CLAUDE.md Ideal

```markdown
# CLAUDE.md - [Proyecto]

## Resumen
[1-2 líneas]

## Documentación
| Tema | Archivo |
|------|---------|

## Estructura
[Árbol simple]

## Notas
- [puntos clave]

*Actualizado: YYYY-MM-DD*
```

## Reglas Importantes

1. **CLAUDE.md siempre conciso** (máx 50-80 líneas)
2. **Usar tablas** para listar documentación
3. **Links relativos** no contenido inline
4. **Fecha de actualización** siempre presente
5. **Solo info esencial** para Claude

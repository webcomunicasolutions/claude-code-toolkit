# Auto-mejora de Skills

## Regla universal
Toda skill procedimental (que guia un workflow o proceso multi-paso) DEBE
incluir un mecanismo de auto-mejora. Sin el, la skill se fosiliza.

## Que registrar al cerrar cada aplicacion practica
Antes de declarar terminado un caso, registrar:
- **Patrones nuevos**: tecnicas, atajos, secuencias que funcionaron
- **Errores resueltos**: problemas encontrados y sus soluciones
- **Gotchas**: trampas no obvias que costaron tiempo
- **Casos curiosos**: situaciones edge que enriquecen el skill

## Donde registrar
- Si la skill tiene `casos-conocidos/` o `aprendizajes/`: crear archivo por caso
- Si no: anadir seccion al final del SKILL.md o crear la carpeta segun volumen
- Si el patron es generalizable: actualizar tambien el cuerpo del SKILL.md

## Que NO registrar
- Datos especificos del cliente (credenciales, IPs, nombres internos)
- Informacion efimera que no ayuda en casos futuros
- Cosas ya documentadas en el SKILL.md

## Para skills nuevas
Cualquier skill nueva creada con un generador de skills DEBE incluir desde el inicio
una seccion "## Auto-mejora" al final del SKILL.md con el patron:
```markdown
## Auto-mejora

Al cerrar cada aplicacion practica de esta skill:
1. Registrar aprendizajes en `aprendizajes/<caso>.md` (o en esta seccion si es breve)
2. Si el patron es generalizable, actualizar el cuerpo de este SKILL.md
3. Si se descubre un error recurrente, anadirlo a una seccion de "Errores conocidos"

Sin esta fase, la skill se fosiliza y pierde valor con el tiempo.
```

Una skill con una fase de auto-mejora bien implementada (que se aplique de verdad tras
cada uso, no solo declarada) es la referencia a seguir para el resto.

# Coding Style

## Inmutabilidad
- SIEMPRE crear objetos nuevos, NUNCA mutar existentes
- Usar spread operator, map, filter, reduce en vez de push/splice
- En Python: usar tuplas, frozen dataclasses, copy

## Organizacion de archivos
- Archivos enfocados: 200-400 lineas ideal, 800 maximo absoluto
- Organizar por feature/dominio, no por tipo
- Un componente/clase principal por archivo

## Funciones
- Maximo 50 lineas por funcion
- Nombre descriptivo que indique que hace (no como)
- Maximo 4 niveles de nesting
- Early return para reducir nesting

## Error handling
- SIEMPRE manejar errores, NUNCA silenciarlos
- UI: mensajes user-friendly
- Server: logging detallado con contexto
- Usar tipos de error especificos, no genericos

## Validacion de input
- Validar en boundaries del sistema (input de usuario, APIs externas)
- Usar schemas (Zod, Pydantic) cuando sea posible
- Rechazar temprano con mensajes claros
- Asumir que fuentes externas son untrusted

## Checklist pre-entrega
- [ ] Nombres claros y descriptivos
- [ ] Funciones < 50 lineas
- [ ] Archivos < 800 lineas
- [ ] Nesting < 4 niveles
- [ ] Errores manejados
- [ ] Sin valores hardcodeados (usar constantes/config)
- [ ] Patrones inmutables

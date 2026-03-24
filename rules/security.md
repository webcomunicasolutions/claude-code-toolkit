# Security

## Checks obligatorios antes de commit
- [ ] Sin secrets hardcodeados (API keys, passwords, tokens)
- [ ] Input de usuario validado
- [ ] Sin SQL injection
- [ ] Sin XSS
- [ ] Auth verificado en rutas protegidas
- [ ] Mensajes de error sin info sensible

## Gestion de secrets
- NUNCA hardcodear en codigo fuente
- SIEMPRE usar variables de entorno o secret manager
- NUNCA commitear archivos .env
- Rotar secrets comprometidos inmediatamente

## Cuando se detecta un problema de seguridad
1. STOP inmediato
2. Lanzar agente security-reviewer
3. No continuar hasta que el issue este resuelto
4. Documentar el hallazgo

## Principios
- Rate limiting en endpoints publicos
- Sanitizar HTML output (prevenir XSS)
- CSRF protection en formularios
- Mensajes de error genericos al usuario (detallados solo en logs)
- Usar HTTPS siempre
- Validar y sanitizar en boundaries del sistema
- Principio de menor privilegio

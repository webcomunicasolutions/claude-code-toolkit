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

## Formularios de login (obligatorio en todos los proyectos)
- **CSRF token**: campo hidden con token aleatorio en session, verificar en POST
- **bcrypt**: password_hash() para almacenar, password_verify() para comparar
- **No revelar existencia**: mensaje generico "Credenciales incorrectas" (no "usuario no existe")
- **Rate limiting**: max 5 intentos fallidos por IP o cuenta en 5-10 min
- **Bloqueo temporal**: tras 5 intentos fallidos, bloquear cuenta 10 min
- **Prepared statements**: SIEMPRE en queries de auth (anti SQL injection)

## Implementacion CSRF en PHP
```php
// Generar token (en GET o al iniciar sesion)
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

// En el formulario HTML
<input type="hidden" name="csrf_token" value="<?= $_SESSION['csrf_token'] ?>">

// Verificar en POST
if (!hash_equals($_SESSION['csrf_token'], $_POST['csrf_token'] ?? '')) {
    die('Solicitud no valida');
}
// Regenerar tras cada uso
$_SESSION['csrf_token'] = bin2hex(random_bytes(32));
```

## Validacion de contraseña fuerte (recomendado)
- Minimo 8 caracteres
- Al menos 1 mayuscula
- Al menos 1 numero
- Al menos 1 simbolo (!@#$%^&*)

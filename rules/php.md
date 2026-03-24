# PHP

## Estilo
- PSR-12 obligatorio
- declare(strict_types=1) en todos los archivos
- Type hints en parámetros y retornos
- Typed properties
- PHP-CS-Fixer o Pint para formateo

## Patrones
- Controllers thin, lógica en services
- DTOs y value objects para datos
- Dependency injection con interfaces
- FormRequest para validación (Laravel)
- Eloquent scopes para queries reutilizables

## Seguridad
- Prepared statements siempre (PDO/Eloquent)
- Escapar output (XSS)
- CSRF protection en formularios
- password_hash()/verify() para passwords
- composer audit para vulnerabilidades

## Testing
- PHPUnit o Pest
- Cobertura con pcov/Xdebug
- Factory patterns para test data
- PHPStan/Psalm para análisis estático

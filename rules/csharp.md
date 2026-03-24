# C#

## Estilo
- .NET conventions obligatorias
- Nullable reference types habilitados
- record/record struct para value-like types
- class para identity types
- async/await con CancellationToken
- dotnet format para formateo

## Patrones
- Repository con async/await
- Options pattern para configuración
- Dependency injection con interfaces
- Lean constructors (lógica mínima)
- Sealed records para API responses

## Seguridad
- User secrets / variables de entorno (NO hardcode)
- Parameterized queries (Dapper/EF Core)
- Validar DTOs en boundaries
- NO stack traces en respuestas al usuario

## Testing
- xUnit + FluentAssertions
- Moq/NSubstitute para mocking
- Testcontainers para integración
- WebApplicationFactory para API tests
- 80%+ cobertura

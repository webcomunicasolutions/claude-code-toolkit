# Go

## Estilo
- gofmt y goimports obligatorios
- Acepta interfaces en parámetros, retorna tipos concretos
- Error wrapping: fmt.Errorf("context: %w", err)
- Context como primer parámetro siempre

## Patrones
- Functional options para configuración
- Interfaces en punto de uso (no en paquete del implementador)
- Inyección de dependencias con constructores
- Table-driven tests obligatorios
- strings.Builder para concatenación en loops

## Herramientas
- go vet para análisis estático
- staticcheck para linting avanzado
- golangci-lint como meta-linter

## Testing
- go test -race para detectar data races
- go test -cover para cobertura
- Subtests con t.Run()
- t.Helper() en funciones auxiliares

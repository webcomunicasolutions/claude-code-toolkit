# Testing

## Cobertura minima: 80%
- Branches, funciones, lineas, statements

## Tests requeridos
1. **Unit tests**: funciones individuales, utilidades, componentes
2. **Integration tests**: endpoints API, operaciones de BD
3. **E2E tests**: flujos criticos de usuario

## TDD Workflow
1. Escribir test (RED - debe fallar)
2. Ejecutar test (confirmar que falla)
3. Implementar codigo minimo (GREEN - debe pasar)
4. Ejecutar test (confirmar que pasa)
5. Refactorizar manteniendo tests verdes
6. Verificar cobertura >= 80%

## Cuando los tests fallan
- Consultar al agente tdd-guide o tdd-red
- Examinar aislamiento del test
- Validar mocks
- Modificar CODIGO, no tests (a menos que el test tenga error)

## Cobertura 100% obligatoria para:
- Calculos financieros
- Autenticacion y autorizacion
- Codigo de seguridad critico
- Logica de negocio core

## Anti-patrones
- Tests que prueban implementacion, no comportamiento
- Tests interdependientes
- Tests sin assertions significativas
- Over-mocking (mockear todo pierde valor)

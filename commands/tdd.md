---
description: Desarrollo dirigido por tests - RED/GREEN/REFACTOR
---

# TDD

Guia el desarrollo con Test-Driven Development: tests ANTES que implementacion.

## Instrucciones

Sigue el ciclo RED -> GREEN -> REFACTOR:

### 1. RED - Escribe tests que fallan
- Analiza el requisito del usuario
- Escribe tests que describan el comportamiento esperado
- Incluye: happy path, edge cases, errores
- Ejecuta tests - DEBEN fallar (si pasan, el test no vale)

### 2. GREEN - Implementa el minimo
- Escribe SOLO el codigo necesario para que los tests pasen
- Sin over-engineering, sin features extra
- Ejecuta tests - DEBEN pasar todos

### 3. REFACTOR - Mejora manteniendo verde
- Limpia duplicacion, mejora nombres, simplifica
- Ejecuta tests despues de cada cambio - DEBEN seguir pasando
- Verifica cobertura >= 80%

## Cobertura requerida
- **General:** >= 80% (branches, funciones, lineas)
- **100% obligatorio para:** calculos financieros, autenticacion, seguridad, logica de negocio critica

## Tipos de test requeridos
- **Unit:** funciones individuales, utilidades, componentes
- **Integracion:** endpoints API, operaciones de BD
- **E2E:** flujos criticos de usuario (Playwright)

## Anti-patrones a evitar
- Escribir implementacion antes que tests
- Tests que prueban detalles de implementacion (no comportamiento)
- Tests interdependientes
- Assertions que no verifican comportamiento significativo
- Mockear demasiado (o demasiado poco)

$ARGUMENTS

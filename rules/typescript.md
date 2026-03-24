# TypeScript

## Estilo
- Tipos explícitos para APIs públicas, inferidos para variables locales
- async/await con try-catch (no .then/.catch)
- Validación con Zod en boundaries
- NO console.log en producción
- Prefer `unknown` sobre `any`
- Usar `satisfies` para validar tipos sin ampliar

## Patrones
- API response estándar con tipo genérico: `ApiResponse<T>`
- Custom hooks extraídos cuando la lógica se repite
- Repository pattern con genéricos para data access
- Barrel exports (index.ts) para módulos públicos

## Herramientas
- Prettier para formateo
- ESLint para linting
- tsc --noEmit para type checking

## Testing
- Playwright para E2E
- Vitest/Jest para unit tests
- Testing Library para componentes React

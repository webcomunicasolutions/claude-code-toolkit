# Rust

## Estilo
- rustfmt obligatorio
- clippy en modo strict (cargo clippy -- -D warnings)
- Max 100 caracteres por línea
- Prefer borrowing (&T) sobre ownership cuando sea posible

## Error handling
- thiserror para librerías
- anyhow para aplicaciones
- ? operator para propagación
- Nunca unwrap() en producción (usar expect() con mensaje o ?)

## Patrones
- Repository con traits
- Newtype pattern para type safety
- Enum state machines
- Builder pattern para structs complejos
- Cow<'_, str> para strings que pueden ser owned o borrowed

## Seguridad
- unsafe solo en FFI boundaries, siempre justificado
- cargo audit para vulnerabilidades
- cargo deny para license checking

## Testing
- #[cfg(test)] para unit tests
- rstest para parametrización
- proptest para property-based testing
- mockall para mocking
- cargo-llvm-cov para cobertura (80%+)

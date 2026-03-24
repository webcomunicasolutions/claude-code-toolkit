# Swift

## Estilo
- SwiftFormat + SwiftLint obligatorio
- Prefer let sobre var
- Structs por defecto (classes solo para identity/herencia)
- Apple API Design Guidelines
- Swift 6 strict concurrency

## Patrones
- Protocol-oriented design
- Value types (structs/enums) por defecto
- Actor pattern para estado mutable compartido
- Dependency injection con protocols
- Sendable para concurrency safety

## Seguridad
- Keychain Services para secrets
- App Transport Security obligatorio
- Certificate pinning para APIs críticas
- NO force-unwrap (!) en producción

## Testing
- Swift Testing (@Test macro, #expect)
- Parameterized testing
- swift test --enable-code-coverage

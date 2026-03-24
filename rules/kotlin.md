# Kotlin

## Estilo
- ktlint/Detekt obligatorio
- Prefer val sobre var
- Sealed classes para jerarquías
- NO !! (usar ?., ?:, requireNotNull())
- Result<T> en lugar de excepciones para errores esperados

## Patrones
- Constructor injection (Koin/Hilt)
- ViewModel + StateFlow para UI
- Repository con Result<T>
- UseCase layer para lógica de negocio
- Coroutines con viewModelScope
- DSL pattern para APIs fluidas

## Android
- EncryptedSharedPreferences para datos sensibles
- Biometric auth cuando aplique
- ProGuard/R8 para ofuscación

## Testing
- kotlin.test + JUnit
- Turbine para Flow/StateFlow
- runTest para coroutines
- Prefer fakes over mocks
- Room in-memory para tests de BD

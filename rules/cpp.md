# C++

## Estilo
- C++17 mínimo (preferir C++20/23)
- clang-format obligatorio
- RAII siempre (NO manual new/delete)
- std::unique_ptr para ownership único
- std::shared_ptr con make_shared
- constexpr donde sea posible

## Patrones
- Rule of Five o Rule of Zero
- Value semantics por defecto
- std::optional para valores opcionales
- std::expected (C++23) para errores
- RAII wrappers para recursos

## Seguridad
- NO raw new/delete
- Prefer std::string sobre char*
- .at() para bounds checking
- NO strcpy/strcat/sprintf (usar alternativas seguras)
- Enable sanitizers (address, UB) en CI

## Testing
- GoogleTest (gtest/gmock)
- CTest con CMake
- lcov para cobertura
- Sanitizers en CI (address + UB)

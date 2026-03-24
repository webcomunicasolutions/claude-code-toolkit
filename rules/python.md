# Python

## Estilo
- PEP 8 obligatorio
- Type annotations en todas las funciones públicas
- Inmutabilidad: @dataclass(frozen=True), NamedTuple
- NO print() en producción, usar logging
- f-strings para formateo

## Patrones
- Protocol para duck typing
- dataclasses como DTOs
- Context managers para recursos
- Generators para streams de datos
- ABC solo cuando se necesita herencia forzada

## Herramientas
- black/ruff para formateo
- mypy/pyright para type checking
- bandit para análisis de seguridad

## Testing
- pytest obligatorio (no unittest)
- Cobertura con --cov
- @pytest.mark para clasificar tests
- Fixtures para setup/teardown

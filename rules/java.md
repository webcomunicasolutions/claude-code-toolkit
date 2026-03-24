# Java

## Estilo
- google-java-format obligatorio
- Prefer record para DTOs
- Campos final siempre que sea posible
- Optional<T> para retornos nullable (nunca como parámetro)
- Sealed classes para jerarquías cerradas
- Pattern matching con instanceof

## Patrones
- Constructor injection (no field injection con @Autowired)
- Service layer para lógica de negocio
- Repository pattern para data access
- DTO con records, entities separadas
- Builder pattern para objetos complejos

## Spring Boot
- @Transactional en service layer
- @Valid en request bodies
- @ControllerAdvice para exception handling global
- Nunca exponer entities en responses

## Herramientas
- Checkstyle para estilo
- SpotBugs para análisis estático
- JaCoCo para cobertura (80%+)

## Testing
- JUnit 5 + AssertJ + Mockito
- Testcontainers para integración
- mvn verify para validación completa

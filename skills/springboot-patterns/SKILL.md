---
name: springboot-patterns
description: Arquitectura production-grade Spring Boot - REST, JPA, services, validation, caching. Usar cuando se trabaje con Spring Boot.
---

# Spring Boot Patterns

## REST Controller
```java
@RestController
@RequestMapping("/api/v1/users")
public class UserController {
    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PostMapping
    public ResponseEntity<UserDTO> create(@Valid @RequestBody CreateUserRequest req) {
        return ResponseEntity.status(201).body(userService.create(req));
    }
}
```

## Service Layer
```java
@Service
@Transactional(readOnly = true)
public class UserService {
    @Transactional
    public UserDTO create(CreateUserRequest req) {
        User user = userMapper.toEntity(req);
        return userMapper.toDTO(userRepo.save(user));
    }
}
```

## Global Exception Handler
```java
@ControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(NotFoundException ex) {
        return ResponseEntity.status(404).body(new ErrorResponse("NOT_FOUND", ex.getMessage()));
    }
}
```

## Validation
```java
public record CreateUserRequest(
    @NotBlank String name,
    @Email String email,
    @Min(18) int age
) {}
```

## Caching
```java
@Cacheable(value = "users", key = "#id")
public UserDTO findById(Long id) { ... }

@CacheEvict(value = "users", key = "#id")
public void update(Long id, UpdateRequest req) { ... }
```

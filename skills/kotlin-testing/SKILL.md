---
name: kotlin-testing
description: Patrones de testing Kotlin - Kotest, MockK, coroutines, Flow, property-based. Usar cuando se escriban tests en Kotlin.
---

# Kotlin Testing

## Kotest
```kotlin
class UserServiceTest : StringSpec({
    "should create user" {
        val user = service.create("Alice")
        user.name shouldBe "Alice"
    }
    "should throw on duplicate" {
        shouldThrow<DuplicateException> { service.create("existing") }
    }
})
```

## MockK
```kotlin
val repo = mockk<UserRepository>()
every { repo.findById(1) } returns User(1, "Alice")
coEvery { repo.save(any()) } returns Unit

val service = UserService(repo)
service.getUser(1).name shouldBe "Alice"
verify { repo.findById(1) }
```

## Coroutine Testing
```kotlin
@Test
fun `test async`() = runTest {
    val result = service.fetchData()
    result shouldBe expected
}
```

## Flow Testing (Turbine)
```kotlin
@Test
fun `test flow`() = runTest {
    viewModel.state.test {
        awaitItem() shouldBe State.Loading
        awaitItem() shouldBe State.Success(data)
        cancelAndConsumeRemainingEvents()
    }
}
```

## Property-Based
```kotlin
class MathTest : StringSpec({
    "commutative" {
        checkAll<Int, Int> { a, b -> (a + b) shouldBe (b + a) }
    }
})
```

## Coverage: Kover (80%+)
```bash
./gradlew koverHtmlReport
```

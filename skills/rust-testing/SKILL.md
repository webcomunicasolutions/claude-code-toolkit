---
name: rust-testing
description: Patrones de testing Rust - unit, integration, async, property-based, mocking, benchmarks. Usar cuando se escriban tests en Rust.
---

# Rust Testing

## Unit Tests
```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add() { assert_eq!(add(2, 3), 5); }

    #[test]
    fn test_error() {
        let result = parse("invalid");
        assert!(result.is_err());
    }

    #[test]
    #[should_panic(expected = "index out of bounds")]
    fn test_panic() { let v: Vec<i32> = vec![]; let _ = v[0]; }
}
```

## Integration Tests (tests/)
```rust
// tests/api_test.rs
#[tokio::test]
async fn test_health() {
    let server = Server::start().await;
    let resp = reqwest::get(&format!("{}/health", server.url())).await.unwrap();
    assert_eq!(resp.status(), 200);
}
```

## Parametrized (rstest)
```rust
#[rstest]
#[case("hello", 5)]
#[case("", 0)]
fn test_len(#[case] input: &str, #[case] expected: usize) {
    assert_eq!(input.len(), expected);
}
```

## Property-Based (proptest)
```rust
proptest! {
    #[test]
    fn roundtrip(s in "[a-z]{1,10}") {
        let parsed = parse(&s).unwrap();
        assert_eq!(parsed.to_string(), s);
    }
}
```

## Mocking (mockall)
```rust
#[automock]
trait Repository { fn find(&self, id: i64) -> Result<User>; }
```

## Coverage: cargo-llvm-cov (80%+)

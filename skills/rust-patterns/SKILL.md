---
name: rust-patterns
description: Patrones seguros y eficientes de Rust - ownership, error handling, traits, async, enums. Usar cuando se escriba código Rust.
---

# Rust Patterns

## Error Handling
```rust
// Librerías: thiserror
#[derive(Debug, thiserror::Error)]
enum AppError {
    #[error("not found: {0}")]
    NotFound(String),
    #[error("database error")]
    Database(#[from] sqlx::Error),
}

// Aplicaciones: anyhow
fn main() -> anyhow::Result<()> {
    let config = load_config().context("failed to load config")?;
    Ok(())
}
```

## Newtype Pattern
```rust
struct UserId(i64);
struct Email(String);
```

## Builder Pattern
```rust
struct ServerBuilder { port: u16, host: String }
impl ServerBuilder {
    fn port(mut self, port: u16) -> Self { self.port = port; self }
    fn build(self) -> Server { Server { port: self.port, host: self.host } }
}
```

## Enum State Machines
```rust
enum OrderState {
    Pending,
    Confirmed { confirmed_at: DateTime },
    Shipped { tracking: String },
    Delivered,
}
```

## Cow for Flexible Strings
```rust
fn greet(name: &str) -> Cow<'_, str> {
    if name.is_empty() { Cow::Borrowed("World") }
    else { Cow::Owned(format!("Hello, {name}!")) }
}
```

## Async with Tokio
```rust
#[tokio::main]
async fn main() -> Result<()> {
    let (tx, mut rx) = mpsc::channel(32);
    tokio::spawn(async move { /* producer */ });
    while let Some(msg) = rx.recv().await { /* consumer */ }
    Ok(())
}
```

## Organización: por dominio, no por tipo

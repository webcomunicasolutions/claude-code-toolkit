---
name: python-patterns
description: Patrones idiomaticos de Python - type hints, dataclasses, async, generators, context managers. Usar cuando se escriba codigo Python.
---

# Python Patterns

## Type Hints (3.9+)
```python
def process(items: list[str], config: dict[str, Any] | None = None) -> Result:
    ...
```

## Dataclasses
```python
@dataclass(frozen=True)
class User:
    name: str
    email: str
    created_at: datetime = field(default_factory=datetime.now)
```

## Error Handling
```python
class AppError(Exception):
    def __init__(self, message: str, code: str, cause: Exception | None = None):
        super().__init__(message)
        self.code = code
        self.__cause__ = cause

try:
    result = do_something()
except SpecificError as e:
    raise AppError("Failed to process", "PROC_ERR") from e
```

## Context Managers
```python
@contextmanager
def managed_resource(name: str):
    resource = acquire(name)
    try:
        yield resource
    finally:
        resource.release()
```

## Generators
```python
def read_large_file(path: str) -> Iterator[str]:
    with open(path) as f:
        for line in f:
            yield line.strip()
```

## Async
```python
async def fetch_all(urls: list[str]) -> list[Response]:
    async with aiohttp.ClientSession() as session:
        tasks = [session.get(url) for url in urls]
        return await asyncio.gather(*tasks)
```

## Herramientas: black, ruff, mypy, pytest

---
name: python-testing
description: Patrones de testing Python con pytest - fixtures, parametrización, mocking, async, cobertura 80%+. Usar cuando se escriban tests en Python.
---

# Python Testing (pytest)

## Fixtures
```python
@pytest.fixture
def db_session():
    session = create_session()
    yield session
    session.rollback()
```

## Parametrización
```python
@pytest.mark.parametrize("input,expected", [
    ("hello", 5),
    ("", 0),
])
def test_length(input, expected):
    assert len(input) == expected
```

## Mocking
```python
def test_send_email(mocker):
    mock_send = mocker.patch('app.email.send', autospec=True)
    notify_user(user)
    mock_send.assert_called_once_with(user.email, subject=ANY)
```

## Async
```python
@pytest.mark.asyncio
async def test_fetch_data():
    result = await fetch_data("https://api.example.com")
    assert result.status == 200
```

## Markers
```python
@pytest.mark.slow
def test_heavy(): ...

@pytest.mark.integration
def test_db(): ...
```

## Cobertura
```bash
pytest --cov=app --cov-report=term-missing --cov-fail-under=80
```

## Organización
```
tests/
├── unit/
├── integration/
├── e2e/
└── conftest.py
```

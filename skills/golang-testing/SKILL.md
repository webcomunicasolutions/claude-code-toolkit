---
name: golang-testing
description: Patrones de testing Go - table-driven, subtests, benchmarks, fuzzing, mocking con interfaces. Usar cuando se escriban tests en Go.
---

# Go Testing

## Table-Driven Tests
```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name string
        a, b int
        want int
    }{
        {"positive", 1, 2, 3},
        {"zero", 0, 0, 0},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            if got := Add(tt.a, tt.b); got != tt.want {
                t.Errorf("got %d, want %d", got, tt.want)
            }
        })
    }
}
```

## Parallel Tests
```go
t.Run("name", func(t *testing.T) {
    t.Parallel()
})
```

## Test Helpers
```go
func newTestServer(t *testing.T) *httptest.Server {
    t.Helper()
    srv := httptest.NewServer(handler)
    t.Cleanup(srv.Close)
    return srv
}
```

## Interface Mocking
```go
type MockDB struct{ users map[string]User }
func (m *MockDB) FindByID(id string) (User, error) {
    u, ok := m.users[id]
    if !ok { return User{}, ErrNotFound }
    return u, nil
}
```

## Benchmarks
```go
func BenchmarkProcess(b *testing.B) {
    for i := 0; i < b.N; i++ { Process(testData) }
}
// go test -bench=. -benchmem
```

## Fuzzing (1.18+)
```go
func FuzzParse(f *testing.F) {
    f.Add("hello")
    f.Fuzz(func(t *testing.T, input string) {
        _, _ = Parse(input)
    })
}
```

## Coverage
```bash
go test -cover ./...
go test -coverprofile=c.out ./... && go tool cover -html=c.out
```

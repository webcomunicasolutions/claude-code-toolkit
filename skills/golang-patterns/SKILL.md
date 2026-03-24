---
name: golang-patterns
description: Patrones idiomaticos de Go - error handling, concurrency, interfaces, functional options. Usar cuando se escriba codigo Go.
---

# Go Patterns

## Error Handling
```go
func processOrder(id string) (*Order, error) {
    order, err := repo.FindByID(id)
    if err != nil {
        return nil, fmt.Errorf("processOrder(%s): %w", id, err)
    }
    return order, nil
}
```

## Custom Errors
```go
type NotFoundError struct {
    Resource string
    ID       string
}
func (e *NotFoundError) Error() string {
    return fmt.Sprintf("%s %s not found", e.Resource, e.ID)
}
```

## Functional Options
```go
type Option func(*Server)
func WithPort(port int) Option { return func(s *Server) { s.port = port } }
func NewServer(opts ...Option) *Server {
    s := &Server{port: 8080}
    for _, opt := range opts { opt(s) }
    return s
}
```

## Concurrency - Worker Pool
```go
func worker(jobs <-chan Job, results chan<- Result) {
    for job := range jobs {
        results <- process(job)
    }
}
// Launch N workers
for i := 0; i < numWorkers; i++ {
    go worker(jobs, results)
}
```

## Interfaces (pequenas, en punto de uso)
```go
type Reader interface { Read(p []byte) (n int, err error) }
type Writer interface { Write(p []byte) (n int, err error) }
```

## Table-Driven Tests
```go
tests := []struct {
    name  string
    input string
    want  int
}{
    {"empty", "", 0},
    {"single", "a", 1},
}
for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
        got := Len(tt.input)
        if got != tt.want { t.Errorf("got %d, want %d", got, tt.want) }
    })
}
```

---
name: laravel-patterns
description: Arquitectura production-grade Laravel - controllers, services, Eloquent, queues, events. Usar cuando se trabaje con Laravel.
---

# Laravel Patterns

## Layered Architecture
Controllers -> Services/Actions -> Models

## Route Model Binding
```php
Route::get('/users/{user}', function (User $user) {
    $this->authorize('view', $user);
    return new UserResource($user);
});
```

## Service/Action Pattern
```php
class CreateOrderAction {
    public function execute(User $user, array $items): Order {
        return DB::transaction(function () use ($user, $items) {
            $order = $user->orders()->create(['status' => 'pending']);
            $order->items()->createMany($items);
            OrderCreated::dispatch($order);
            return $order;
        });
    }
}
```

## Form Requests
```php
class StoreUserRequest extends FormRequest {
    public function rules(): array {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users'],
        ];
    }
}
```

## Eloquent Scopes
```php
public function scopeActive(Builder $query): void {
    $query->where('status', 'active');
}
// Uso: User::active()->get();
```

## Events & Jobs
```php
OrderCreated::dispatch($order);

class SendOrderConfirmation implements ShouldQueue {
    public function handle(OrderCreated $event): void { ... }
}
```

## API Resources
```php
class UserResource extends JsonResource {
    public function toArray(Request $request): array {
        return ['id' => $this->id, 'name' => $this->name];
    }
}
```

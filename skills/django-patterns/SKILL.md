---
name: django-patterns
description: Arquitectura production-grade Django - models, views, serializers, signals, caching. Usar cuando se trabaje con Django/DRF.
---

# Django Patterns

## Settings Split
```
settings/
├── base.py        # Común
├── development.py # DEBUG=True
├── production.py  # Security, caching
└── test.py        # Fast, SQLite
```

## QuerySet Optimization
```python
# SIEMPRE usar select_related (FK) y prefetch_related (M2M)
User.objects.select_related('profile').prefetch_related('orders__items')

# Bulk operations
User.objects.bulk_create([User(name=n) for n in names])
User.objects.filter(active=False).update(status='inactive')
```

## Service Layer
```python
class OrderService:
    @staticmethod
    def create_order(user: User, items: list[dict]) -> Order:
        with transaction.atomic():
            order = Order.objects.create(user=user)
            OrderItem.objects.bulk_create([...])
            send_confirmation.delay(order.id)
        return order
```

## DRF Serializers
```python
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'name', 'email']
        read_only_fields = ['id']
```

## Signals
```python
@receiver(post_save, sender=Order)
def notify_on_order(sender, instance, created, **kwargs):
    if created:
        send_notification.delay(instance.id)
```

## Caching
```python
@cache_page(60 * 15)
def product_list(request): ...
```

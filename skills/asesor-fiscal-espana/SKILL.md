---
name: asesor-fiscal-espana
description: Conocimiento fiscal español para extracción y validación de facturas. Usar cuando se trabaje con: (1) Facturas españolas o europeas, (2) IVA y sus tipos (21%, 10%, 4%), (3) Operaciones especiales (ISP, intracomunitaria, extracomunitaria), (4) Retenciones IRPF, (5) Recargo de equivalencia, (6) Validación de CIF/NIF/VAT. Contiene reglas fiscales, formatos y ejemplos para España.
---

# Asesor Fiscal España

Conocimiento fiscal español para extracción de datos de facturas.

## Tipos de IVA en España

| Tipo | Porcentaje | Aplicación |
|------|------------|------------|
| General | 21% | Mayoría de productos y servicios |
| Reducido | 10% | Alimentos, transporte, hostelería |
| Superreducido | 4% | Pan, leche, libros, medicamentos |

## Recargo de Equivalencia

Solo para comerciantes minoristas en régimen de estimación directa.

| Tipo IVA | Recargo | Total |
|----------|---------|-------|
| 21% | 5,2% | 26,2% |
| 10% | 1,4% | 11,4% |
| 4% | 0,5% | 4,5% |

## Retenciones IRPF

| Porcentaje | Aplicación |
|------------|------------|
| 15% | Profesionales (general) |
| 7% | Profesionales nuevos (3 primeros años) |
| 19% | Alquileres de inmuebles urbanos |

## Formatos de Identificación Fiscal

### España
- **CIF empresa**: Letra + 8 dígitos (ej: B93445385)
- **NIF persona**: 8 dígitos + letra (ej: B12345678)
- **NIE extranjero**: X/Y/Z + 7 dígitos + letra (ej: X1234567T)

### Regla ES
Si el CIF/NIF tiene prefijo "ES", eliminarlo:
- ESB93445385 → B93445385
- ESB12345678 → B12345678

### Otros países UE (conservar prefijo)
- LU20260743 (Luxemburgo)
- IE8256796U (Irlanda)
- DE123456789 (Alemania)
- FR12345678901 (Francia)

## Operaciones Especiales

### 1. Factura Normal (con IVA)
- Proveedor español aplica IVA
- base_21 + iva_21 (o 10%, 4%)

### 2. ISP - Inversión Sujeto Pasivo
**Requisitos (TODOS):**
- Proveedor ESPAÑOL (CIF sin prefijo país)
- Sin IVA en factura
- Mención EXPLÍCITA: "Inversión del Sujeto Pasivo", "I.S.P.", "Art. 84.1.2°"

**Resultado:**
- isp: "SI"
- Base en "exento"
- base_21/iva_21 vacíos

### 3. Intracomunitaria
**Requisitos:**
- Proveedor de la UE (no España)
- VAT con prefijo país (IE, DE, FR, LU, etc.)
- Sin IVA aplicado

**Resultado:**
- intra: "SI"
- Base en "exento"
- base_21/iva_21 vacíos

**Ejemplos:** Microsoft Ireland (IE), Amazon Luxembourg (LU), SAP Germany (DE)

### 4. Extracomunitaria
**Requisitos:**
- Proveedor fuera de la UE
- Sin IVA aplicado

**Países comunes:**
- USA, UK (post-Brexit), China, Japón, Suiza (no UE)

**Resultado:**
- extra: "SI"
- Base en "exento"
- base_21/iva_21 vacíos

**Ejemplos:** OpenAI (USA), Apple Inc. (USA), Amazon.com (USA)

## Formato Numérico Español

**SIEMPRE usar formato español:**
- Decimales: coma (,)
- Miles: punto (.)

| Entrada | Salida correcta |
|---------|-----------------|
| 20.00 | 20,00 |
| 1,234.56 | 1.234,56 |
| $175.73 | 175,73 |

## Facturas Rectificativas/Abonos

Si aparece "rectificativa", "abono" o "nota de crédito":
- TODOS los importes en NEGATIVO
- Ejemplo: base_21: "-500,00", iva_21: "-105,00"

## Zonas de Búsqueda en Factura

### Datos del PROVEEDOR (extraer)
Buscar en: cabecera, "From", "Seller", "Supplier", "Emisor", "Vendido por"

### Datos del CLIENTE (solo verificar)
Buscar en: "Bill to", "Customer", "Cliente", "Destinatario", "Facturado a"

## Países Zona Euro

AT, BE, CY, DE, EE, ES, FI, FR, GR, HR, IE, IT, LT, LU, LV, MT, NL, PT, SI, SK

## Países UE no Euro

| País | Moneda |
|------|--------|
| DK | DKK (Corona danesa) |
| SE | SEK (Corona sueca) |
| PL | PLN (Zloty) |
| CZ | CZK (Corona checa) |
| HU | HUF (Florín húngaro) |
| RO | RON (Leu rumano) |
| BG | BGN (Lev búlgaro) |

## Campos de Factura para Extracción

### Obligatorios
| Campo | Descripción | Valor si no existe |
|-------|-------------|-------------------|
| nombre_empresa | Proveedor en MAYÚSCULAS | "REVISAR" |
| cif | CIF/NIF/VAT normalizado | "REVISAR" |
| codigo_postal | CP del proveedor | "REVISAR" |
| fecha_expedicion | DD/MM/AAAA | "REVISAR" |
| numero_factura | Nº factura | "REVISAR" |
| total_factura | Importe total | "REVISAR" |
| moneda | EUR/USD/GBP... | "REVISAR" |

### Bases e IVA
| Campo | Descripción | Valor si no existe |
|-------|-------------|-------------------|
| base_21 | Base al 21% | "" |
| iva_21 | IVA al 21% | "" |
| base_10 | Base al 10% | "" |
| iva_10 | IVA al 10% | "" |
| base_4 | Base al 4% | "" |
| iva_4 | IVA al 4% | "" |
| exento | Base exenta | "" |

### Opcionales
| Campo | Descripción | Valor si no existe |
|-------|-------------|-------------------|
| recargo_52 | Recargo 5,2% | "" |
| recargo_14 | Recargo 1,4% | "" |
| recargo_05 | Recargo 0,5% | "" |
| porcentaje_retencion | 15/7/19 | "" |
| cuota_retencion | Importe IRPF | "" |

### Flags Operaciones Especiales
| Campo | Cuándo poner "SI" |
|-------|-------------------|
| intra | Proveedor UE sin IVA |
| isp | Proveedor ES sin IVA + mención explícita |
| extra | Proveedor fuera UE sin IVA |

## Árbol de Decisión: Tipo de Operación

```
¿El proveedor es español (CIF sin prefijo)?
├── SÍ → ¿Tiene IVA la factura?
│       ├── SÍ → FACTURA NORMAL (base_21 + iva_21)
│       └── NO → ¿Menciona "ISP" o "Inversión Sujeto Pasivo"?
│               ├── SÍ → ISP (isp:"SI", base en exento)
│               └── NO → EXENTA (solo exento, sin flags)
└── NO → ¿El proveedor es de la UE?
        ├── SÍ → INTRACOMUNITARIA (intra:"SI", base en exento)
        └── NO → EXTRACOMUNITARIA (extra:"SI", base en exento)
```

## Ejemplo JSON Completo

```json
{
  "nombre_empresa": "DISTRIBUCIONES MYLAR S.A.U.",
  "cif": "B93445385",
  "codigo_postal": "18210",
  "fecha_expedicion": "19/12/2025",
  "numero_factura": "M/8.805",
  "base_21": "7,99",
  "iva_21": "1,68",
  "base_10": "",
  "iva_10": "",
  "base_4": "",
  "iva_4": "",
  "exento": "",
  "total_factura": "9,67",
  "moneda": "EUR",
  "recargo_52": "",
  "recargo_14": "",
  "recargo_05": "",
  "porcentaje_retencion": "",
  "cuota_retencion": "",
  "intra": "",
  "isp": "",
  "extra": "",
  "aviso_cliente": ""
}
```

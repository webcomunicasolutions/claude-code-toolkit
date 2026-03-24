---
name: ninjaone-specialist
description: "Especialista en scripts PowerShell para NinjaOne RMM. Usar cuando se mencione NinjaOne, NinjaRMM, RMM, Custom Fields, Ninja-Property-Get/Set, o se necesiten scripts de monitoreo/mantenimiento/diagnostico para Windows remotos via NinjaOne."
---

# NinjaOne Specialist Skill

Especialista en crear, mantener y optimizar scripts PowerShell para NinjaOne RMM.

---

# Referencia Técnica NinjaOne

## 1. Comandos PowerShell de NinjaOne

### Lectura de Variables (Script Variables)

```powershell
# Variables definidas en NinjaOne se leen con $env:
$miVariable = $env:nombreVariable

# Ejemplo con valor por defecto
$vpnSubnet = if ($env:vpnSubnet) { $env:vpnSubnet } else { "10.20.0.0/24" }
$diasRetener = if ($env:diasRetener) { [int]$env:diasRetener } else { 7 }

# Booleanos vienen como string
$modoSimulacion = $env:WhatIf -eq "true"
```

### Custom Fields - Lectura

```powershell
# Obtener valor de Custom Field del dispositivo
Ninja-Property-Get nombreDelCampo

# Guardar en variable
$diskStatus = Ninja-Property-Get diskHealth

# Verificar si existe
$valor = Ninja-Property-Get miCampo
if ($null -eq $valor -or $valor -eq "") {
    Write-Host "Campo vacío o no existe"
}
```

### Custom Fields - Escritura

```powershell
# Escribir valor a Custom Field
Ninja-Property-Set nombreDelCampo "valor"

# Ejemplos por tipo
Ninja-Property-Set diskHealth "Healthy"              # Dropdown
Ninja-Property-Set diskSpace "C: 45GB free (60%)"   # Text/MultiLine
Ninja-Property-Set failedLogins 5                    # Integer
Ninja-Property-Set lastCheckTime (Get-Date -Format "yyyy-MM-dd HH:mm:ss")  # DateTime

# MultiLine con formato
$report = @"
=== Resumen Diario ===
Fecha: $(Get-Date)
Estado: OK
Alertas: 0
"@
Ninja-Property-Set dailyReport $report
```

### Custom Fields - Limpieza/Reset

```powershell
# Limpiar campo (string vacío)
Ninja-Property-Set miCampo ""

# Para campos numéricos, usar 0
Ninja-Property-Set contador 0
```

### Alertas y Notificaciones

```powershell
# Generar alerta en NinjaOne (aparece en Activities)
# Esto se logra con exit codes específicos + Write-Host

# Exit code 0 = Success (verde)
# Exit code 1 = Warning (amarillo)
# Exit code 2+ = Error/Critical (rojo)

# El texto de Write-Host aparece en el resultado del script
Write-Host "ALERTA: Disco al 95% de capacidad"
exit 1  # Warning

Write-Host "CRITICO: Servicio SQL Server detenido"
exit 2  # Error
```

---

## 2. Tipos de Custom Fields

### Tabla de Tipos y Uso

| Tipo | Uso | Ejemplo PowerShell |
|------|-----|-------------------|
| **Text** | Valores cortos (<255 chars) | `Ninja-Property-Set hostname "PC-001"` |
| **MultiLine** | Informes, listas, logs | `Ninja-Property-Set report $multiLineString` |
| **Integer** | Contadores, números | `Ninja-Property-Set count 42` |
| **Decimal** | Porcentajes, medidas | `Ninja-Property-Set cpuUsage 85.5` |
| **Checkbox** | Booleanos | `Ninja-Property-Set isHealthy $true` |
| **Dropdown** | Estados predefinidos | `Ninja-Property-Set status "Warning"` |
| **Date** | Fechas sin hora | `Ninja-Property-Set lastBackup "2024-01-15"` |
| **DateTime** | Fecha y hora | `Ninja-Property-Set lastCheck "2024-01-15 14:30:00"` |

### Configuración de Permisos

En NinjaOne Admin > Custom Fields, configurar para cada campo:
- **Technician**: Read Only / Read-Write
- **Automation/Scripts**: **Read-Write** (requerido para scripts)
- **API**: Según necesidad

### Campos Recomendados para Monitoreo

```yaml
# Monitoreo de Discos
diskHealth:
  tipo: Dropdown
  valores: [Healthy, Warning, Critical]
  permiso: Read-Write

diskSpace:
  tipo: MultiLine
  permiso: Read-Write

# Monitoreo de Servicios
servicesStatus:
  tipo: Dropdown
  valores: [OK, Warning, Critical]
  permiso: Read-Write

serviceAlerts:
  tipo: MultiLine
  permiso: Read-Write

# Chequeo Diario
dailyCheckStatus:
  tipo: Dropdown
  valores: [OK, Warning, Critical]
  permiso: Read-Write

dailyCheckReport:
  tipo: MultiLine
  permiso: Read-Write

lastCheckTime:
  tipo: DateTime
  permiso: Read-Write

# Inventario
softwareList:
  tipo: MultiLine
  permiso: Read-Write

hardwareInfo:
  tipo: MultiLine
  permiso: Read-Write

# Seguridad
failedLogins:
  tipo: Integer
  permiso: Read-Write

loginAlerts:
  tipo: MultiLine
  permiso: Read-Write
```

---

## 3. Template Base para Scripts NinjaOne

```powershell
<#
.SYNOPSIS
    [Descripción corta del script]

.DESCRIPTION
    [Descripción detallada]

    Compatible con:
    - NinjaOne RMM (variables de entorno)
    - Ejecución manual/SSH (parámetros)

.PARAMETER Parametro1
    [Descripción del parámetro]

.NOTES
    Autor: WebComunica
    Versión: 1.0
    Fecha: $(Get-Date -Format "yyyy-MM-dd")

    Custom Fields requeridos:
    - campoOutput (MultiLine, Read-Write)
    - campoStatus (Dropdown, Read-Write)

.EXAMPLE
    .\script.ps1 -Parametro1 "valor"
#>

#Requires -RunAsAdministrator

param(
    [string]$Parametro1 = ""
)

# ============================================================
# CONFIGURACIÓN
# ============================================================

$ErrorActionPreference = "Stop"
$LogFile = "C:\Windows\Temp\manhattan_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Leer variables de NinjaOne o usar parámetros/defaults
$config = @{
    Parametro1 = if ($env:Parametro1) { $env:Parametro1 } elseif ($Parametro1) { $Parametro1 } else { "default" }
}

# ============================================================
# FUNCIONES AUXILIARES
# ============================================================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logMessage -ErrorAction SilentlyContinue

    switch ($Level) {
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default   { Write-Host $logMessage }
    }
}

function Test-IsElevated {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Set-NinjaProperty {
    param([string]$Name, [string]$Value)
    try {
        if (Get-Command "Ninja-Property-Set" -ErrorAction SilentlyContinue) {
            Ninja-Property-Set $Name $Value
            Write-Log "Custom Field '$Name' actualizado" "SUCCESS"
        } else {
            Write-Log "Ninja-Property-Set no disponible (ejecución manual)" "WARNING"
        }
    } catch {
        Write-Log "Error escribiendo Custom Field '$Name': $_" "ERROR"
    }
}

function Get-NinjaProperty {
    param([string]$Name, [string]$Default = "")
    try {
        if (Get-Command "Ninja-Property-Get" -ErrorAction SilentlyContinue) {
            $value = Ninja-Property-Get $Name
            if ($null -ne $value -and $value -ne "") {
                return $value
            }
        }
    } catch { }
    return $Default
}

# ============================================================
# VALIDACIONES INICIALES
# ============================================================

Write-Log "=== Iniciando Script ===" "INFO"
Write-Log "Log file: $LogFile"

if (-not (Test-IsElevated)) {
    Write-Log "Este script requiere privilegios de administrador" "ERROR"
    exit 1
}

# ============================================================
# LÓGICA PRINCIPAL
# ============================================================

$exitCode = 0
$status = "OK"
$report = @()

try {
    # TODO: Implementar lógica aquí

    Write-Log "Proceso completado correctamente" "SUCCESS"

} catch {
    Write-Log "Error durante ejecución: $_" "ERROR"
    $status = "Critical"
    $exitCode = 2
}

# ============================================================
# OUTPUT Y CUSTOM FIELDS
# ============================================================

# Generar reporte
$reportText = @"
=== Reporte: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") ===
Estado: $status
$($report -join "`n")
"@

# Escribir a Custom Fields
Set-NinjaProperty "campoStatus" $status
Set-NinjaProperty "campoOutput" $reportText
Set-NinjaProperty "lastCheckTime" (Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# Output para NinjaOne Activities
Write-Host $reportText

Write-Log "=== Script Finalizado (Exit: $exitCode) ===" "INFO"
exit $exitCode
```

---

## 4. Patrones de Código Obligatorios

### 4.1 Manejo de Errores

```powershell
# SIEMPRE usar try/catch en operaciones críticas
try {
    $result = Get-WmiObject Win32_LogicalDisk -ErrorAction Stop
} catch {
    Write-Log "Error obteniendo discos: $_" "ERROR"
    $exitCode = 1
}

# Para operaciones que pueden fallar silenciosamente
$services = Get-Service -ErrorAction SilentlyContinue | Where-Object {...}
```

### 4.2 Compatibilidad PowerShell 5.1 y 7+

```powershell
# Detectar versión
$isPSCore = $PSVersionTable.PSVersion.Major -ge 6

# WMI vs CIM (preferir CIM cuando sea posible)
# PowerShell 5.1: Get-WmiObject funciona
# PowerShell 7+: Usar Get-CimInstance

if ($isPSCore) {
    $os = Get-CimInstance Win32_OperatingSystem
} else {
    $os = Get-WmiObject Win32_OperatingSystem
}

# Método universal
$os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
if (-not $os) {
    $os = Get-WmiObject Win32_OperatingSystem
}
```

### 4.3 Detección de Idioma del Sistema

```powershell
# Para grupos locales (Administradores vs Administrators)
function Get-LocalAdminGroupName {
    $adminSID = "S-1-5-32-544"
    try {
        $group = Get-LocalGroup | Where-Object { $_.SID -eq $adminSID }
        return $group.Name
    } catch {
        # Fallback para sistemas antiguos
        $group = [ADSI]"WinNT://./Administrators,group"
        return $group.Name
    }
}

$adminGroup = Get-LocalAdminGroupName  # "Administradores" o "Administrators"
```

### 4.4 Ejecución Segura de Comandos Externos

```powershell
# Verificar si comando existe antes de usar
if (Get-Command "choco" -ErrorAction SilentlyContinue) {
    choco list --local-only
} else {
    Write-Log "Chocolatey no instalado" "WARNING"
}

# Para WMI con filtros (cuidado con comillas)
$filter = "DriveType=3"
$disks = Get-WmiObject Win32_LogicalDisk -Filter $filter
```

### 4.5 Formato de Fechas

```powershell
# ISO 8601 para Custom Fields DateTime
$dateTimeISO = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Formato legible para reportes
$dateReadable = Get-Date -Format "dd/MM/yyyy HH:mm"

# Solo fecha para Custom Fields Date
$dateOnly = Get-Date -Format "yyyy-MM-dd"
```

---

## 5. Exit Codes Estándar

| Código | Significado | Uso en NinjaOne |
|--------|-------------|-----------------|
| 0 | Éxito | Verde, todo OK |
| 1 | Warning | Amarillo, atención requerida |
| 2 | Error/Critical | Rojo, problema grave |
| 3+ | Error específico | Rojo, para debugging |

```powershell
# Ejemplo de uso
$warnings = 0
$errors = 0

# ... lógica del script ...

# Determinar exit code
if ($errors -gt 0) {
    exit 2
} elseif ($warnings -gt 0) {
    exit 1
} else {
    exit 0
}
```

---

## 6. Troubleshooting Común

### Error: "Ninja-Property-Set no reconocido"

**Causa**: Script ejecutándose fuera de NinjaOne (manual/SSH)
**Solución**: Usar función wrapper que verifica disponibilidad

```powershell
function Set-NinjaProperty {
    param([string]$Name, [string]$Value)
    if (Get-Command "Ninja-Property-Set" -ErrorAction SilentlyContinue) {
        Ninja-Property-Set $Name $Value
    } else {
        Write-Host "[NINJA] $Name = $Value"
    }
}
```

### Error: "Custom Field no se actualiza"

**Causas posibles**:
1. Permisos incorrectos (debe ser Read-Write para Automation)
2. Tipo incorrecto (ej: escribir texto en campo Integer)
3. Valor excede límite (Text max 255 chars)

**Verificación**:
```powershell
# Verificar que el comando está disponible
Get-Command Ninja-Property-* | Format-Table Name

# Probar lectura primero
$test = Ninja-Property-Get "nombreCampo"
Write-Host "Valor actual: $test"
```

### Error: "Acceso denegado" en operaciones de disco

**Causa**: Script no ejecutándose como administrador
**Solución**: Agregar validación al inicio

```powershell
#Requires -RunAsAdministrator

# O verificar manualmente
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Requiere privilegios de administrador"
    exit 1
}
```

### SSH: Problemas con comillas en comandos remotos

```bash
# MAL - escapes complejos fallan
ssh user@ip 'Get-WmiObject -Filter "DriveType=3"'

# BIEN - comillas dobles fuera, simples dentro
ssh user@ip "Get-WmiObject -Filter 'DriveType=3'"

# Para expresiones complejas, usar script file
ssh user@ip "powershell -File C:\Scripts\miScript.ps1"
```

### WMI: Filtros con caracteres especiales

```powershell
# MAL - comillas anidadas
Get-WmiObject Win32_Service -Filter "Name="SQL Server""

# BIEN - escape con backtick o comillas simples
Get-WmiObject Win32_Service -Filter 'Name="SQL Server"'
Get-WmiObject Win32_Service -Filter "Name=`"SQL Server`""
```

---

## 7. Scripts de Referencia por Categoría

### Monitoreo
- `monitor_discos.ps1` - SMART, espacio, alertas
- `monitor_servicios.ps1` - Estado de servicios críticos
- `chequeo_diario.ps1` - Resumen ejecutivo

### Mantenimiento
- `limpieza_sistema.ps1` - Limpieza automática segura
- `optimizar_disco.ps1` - Defrag, TRIM

### Seguridad
- `audit_logins.ps1` - Intentos fallidos
- `verificar_usuarios.ps1` - Usuarios locales y admins

### Deploy
- `ninjaone_deploy_ssh.ps1` - Configurar SSH completo
- `crear_usuario_oculto.ps1` - Usuario SSH oculto

### Inventario
- `inventario_software.ps1` - Software instalado
- `inventario_hardware.ps1` - Specs de hardware

---

## 8. Agente de Documentacion

Para consultas que requieran buscar en la documentacion oficial de NinjaOne (API, policies, integraciones, backup, MDM, configuracion), usar el agente `@ninjaone-docs-expert` que tiene acceso a 1600+ paginas de documentacion descargada en `~/proyectos/biblioteca/`.

---

## 9. Referencias Externas

### Documentación Oficial
- [NinjaOne Documentation](https://www.ninjaone.com/docs/)
- [Custom Fields Guide](https://www.ninjaone.com/docs/endpoint-management/custom-fields/)
- [Script Hub](https://www.ninjaone.com/script-hub/)

### Repositorios de Ejemplo
- [fyxtro/NinjaRMM-Scripts](https://github.com/fyxtro/NinjaRMM-Scripts)
- [NinjaOne Community Scripts](https://github.com/NinjaOne)

### Artículos Útiles
- [Homotechsual - NinjaOne Custom Fields](https://homotechsual.dev/2022/12/22/NinjaOne-custom-fields-endless-possibilities/)

---

## 10. Checklist para Nuevos Scripts

Antes de considerar un script completo, verificar:

- [ ] Header con .SYNOPSIS, .DESCRIPTION, .PARAMETER, .NOTES, .EXAMPLE
- [ ] `#Requires -RunAsAdministrator` si necesita privilegios
- [ ] Función `Write-Log` implementada
- [ ] Función `Test-IsElevated` si aplica
- [ ] Funciones wrapper `Set-NinjaProperty` y `Get-NinjaProperty`
- [ ] Variables leídas de `$env:` con fallback a parámetros
- [ ] Try/catch en operaciones críticas
- [ ] Exit codes apropiados (0=OK, 1=Warning, 2=Error)
- [ ] Custom Fields documentados en .NOTES
- [ ] Probado en ejecución manual (sin NinjaOne)
- [ ] Probado en NinjaOne (con Custom Fields)
- [ ] Log file en `C:\Windows\Temp\manhattan_*.log`

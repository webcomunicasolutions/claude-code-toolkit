<#
.SYNOPSIS
    Remates que hay que hacer DESPUES de que el tecnico de el ERP lo instale.

.DESCRIPTION
    el ERP se instala en C:\erp. Este script:

      1. Pone el icono de el ERP en el ESCRITORIO PUBLICO, con lo que aparece de
         golpe en el escritorio de los 5 puestos y de cualquier usuario futuro.
         (Uno por uno no: el escritorio publico lo hereda todo el mundo.)
      2. COMPRUEBA si los usuarios de puesto podran usarlo de verdad:
         - si tienen permiso de escritura donde el ERP guarda sus cosas,
         - si la base de datos esta dentro de C:\ (donde NO deberia estar).
      3. Dice que hay que anadir al backup.

    Por defecto solo MIRA y avisa. Para que ademas conceda los permisos que falten,
    hay que pasarle -DarPermisos a proposito.

.PARAMETER Exe
    Ejecutable de el ERP. Si no se indica, lo busca en C:\erp.

.PARAMETER DarPermisos
    Concede al grupo CLIENTE-Datos permiso de MODIFICAR en las carpetas de datos
    que el ERP necesite escribir. Leer antes el aviso que imprime el script.

.EXAMPLE
    .\postinstalacion-erp.ps1
    # solo diagnostico + icono

.EXAMPLE
    .\postinstalacion-erp.ps1 -DarPermisos
#>
[CmdletBinding()]
param(
    [string]$Exe,
    [switch]$DarPermisos
)

$ErrorActionPreference = 'Stop'

$RAIZ   = 'C:\erp'
$GRUPO  = 'CLIENTE-Datos'      # grupo con los 5 puestos + gerente
$NOMBRE = 'el ERP'

$esAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $esAdmin) { throw 'Hay que ejecutarlo como ADMINISTRADOR.' }
if (-not (Test-Path $RAIZ)) { throw "No existe $RAIZ. Ejecutar DESPUES de que el tecnico instale el ERP." }

Write-Host ''
Write-Host '=== 1) Localizar el ejecutable ===' -ForegroundColor Cyan
if (-not $Exe) {
    # primero por nombre, y si no, el .exe mas grande de la raiz (suele ser el principal)
    $candidatos = @(Get-ChildItem $RAIZ -Filter '*.exe' -ErrorAction SilentlyContinue |
                    Where-Object { $_.BaseName -match 'erp' })
    if (-not $candidatos) {
        $candidatos = @(Get-ChildItem $RAIZ -Filter '*.exe' -ErrorAction SilentlyContinue |
                        Where-Object { $_.BaseName -notmatch 'unins|setup|update|report' } |
                        Sort-Object Length -Descending)
    }
    if (-not $candidatos) { throw "No encuentro ningun .exe en $RAIZ. Pasalo con -Exe." }
    $Exe = $candidatos[0].FullName
    if ($candidatos.Count -gt 1) {
        Write-Host '  Hay varios ejecutables; he elegido el primero:' -ForegroundColor Yellow
        $candidatos | ForEach-Object { Write-Host ('    ' + $_.FullName) -ForegroundColor DarkGray }
        Write-Host '  Si no es el correcto, relanza con -Exe "C:\erp\ElBueno.exe"' -ForegroundColor Yellow
    }
}
if (-not (Test-Path $Exe)) { throw "No existe el ejecutable: $Exe" }
Write-Host "  $Exe" -ForegroundColor Green

Write-Host ''
Write-Host '=== 2) Icono en el escritorio publico ===' -ForegroundColor Cyan
$lnk = Join-Path "$env:PUBLIC\Desktop" "$NOMBRE.lnk"
$w = New-Object -ComObject WScript.Shell
$s = $w.CreateShortcut($lnk)
$s.TargetPath       = $Exe
$s.WorkingDirectory = Split-Path -Parent $Exe
$s.IconLocation     = "$Exe,0"
$s.Description      = 'Programa de gestion de la clinica'
$s.Save()
Write-Host "  creado: $lnk" -ForegroundColor Green
Write-Host '  (lo veran los 5 puestos y cualquier usuario nuevo)' -ForegroundColor DarkGray

Write-Host ''
Write-Host '=== 3) Podran los usuarios USARLO? ===' -ForegroundColor Cyan
# Muchos programas de gestion antiguos escriben en su propia carpeta (ini, logs,
# temporales, la propia base de datos). Bajo C:\ los usuarios normales NO tienen
# escritura, asi que el programa arranca y falla al guardar. Hay que verlo ANTES
# de que lo descubra la clinica con un cliente delante.
$acl = Get-Acl $RAIZ
$reglasGrupo = $acl.Access | Where-Object {
    $_.IdentityReference -match "$GRUPO|Usuarios|Users|Todos|Everyone" -and
    $_.FileSystemRights -match 'Modify|Write|FullControl'
}
if ($reglasGrupo) {
    Write-Host "  OK: hay permiso de escritura en $RAIZ para:" -ForegroundColor Green
    $reglasGrupo | ForEach-Object { Write-Host ('    ' + $_.IdentityReference + ' -> ' + $_.FileSystemRights) -ForegroundColor DarkGray }
}
else {
    Write-Host "  ATENCION: los usuarios de puesto NO tienen escritura en $RAIZ." -ForegroundColor Red
    Write-Host '  Si el ERP guarda datos, configuracion o logs ahi dentro, a los usuarios' -ForegroundColor Yellow
    Write-Host '  les fallara (arranca pero no guarda). Preguntar al tecnico de el ERP' -ForegroundColor Yellow
    Write-Host '  DONDE escribe, y dar permiso solo a esa carpeta.' -ForegroundColor Yellow
    if ($DarPermisos) {
        Write-Host ''
        Write-Host "  -DarPermisos: concediendo MODIFICAR a $GRUPO sobre $RAIZ" -ForegroundColor Yellow
        Write-Host '  (menos fino que darlo solo a la carpeta de datos, pero desbloquea)' -ForegroundColor DarkGray
        $out = icacls $RAIZ /grant "${GRUPO}:(OI)(CI)M" /T /C 2>&1
        if ($LASTEXITCODE -ne 0) { throw "icacls fallo: $($out -join ' | ')" }
        Write-Host '  permisos concedidos' -ForegroundColor Green
    }
}

Write-Host ''
Write-Host '=== 4) Donde estan los datos (para el backup) ===' -ForegroundColor Cyan
$patrones = '*.fdb', '*.gdb', '*.mdb', '*.accdb', '*.dbf', '*.db', '*.sqlite', '*.bak', '*.mdf'
$datos = foreach ($p in $patrones) {
    Get-ChildItem $RAIZ -Filter $p -Recurse -ErrorAction SilentlyContinue
}
if ($datos) {
    Write-Host '  Ficheros de base de datos encontrados:' -ForegroundColor Green
    $datos | Sort-Object Length -Descending | Select-Object -First 10 | ForEach-Object {
        Write-Host ('    ' + $_.FullName + '  (' + [math]::Round($_.Length / 1MB, 1) + ' MB)') -ForegroundColor DarkGray
    }
    Write-Host ''
    Write-Host '  OJO: estan en C:. Lo sano es que los datos vivan en D: (donde apunta' -ForegroundColor Yellow
    Write-Host '  el backup y donde hay sitio). Preguntar al tecnico si se pueden mover,' -ForegroundColor Yellow
    Write-Host '  y si no, ASEGURARSE de que el backup incluye C:\erp.' -ForegroundColor Yellow
}
else {
    Write-Host '  No veo ficheros de BD sueltos. Puede ser un motor de servicio' -ForegroundColor Yellow
    Write-Host '  (SQL Server / Firebird / PostgreSQL): en ese caso el backup NO puede' -ForegroundColor Yellow
    Write-Host '  ser una copia de ficheros, hay que volcar la base de datos.' -ForegroundColor Yellow
    Get-Service | Where-Object { $_.Name -match 'firebird|MSSQL|postgres|mysql|maria|Sybase' } |
        ForEach-Object { Write-Host ('    servicio detectado: ' + $_.Name + ' = ' + $_.Status) -ForegroundColor DarkGray }
}

Write-Host ''
Write-Host '=== RECORDATORIOS ===' -ForegroundColor Cyan
Write-Host '  - El backup restic sigue SIN credenciales de Backblaze: hasta que este' -ForegroundColor Yellow
Write-Host '    funcionando, los datos de la clinica estan en UN SOLO DISCO sin copia.' -ForegroundColor Yellow
Write-Host '  - Probar el ERP con DOS usuarios de puesto a la vez (es un RDS: varios' -ForegroundColor Yellow
Write-Host '    a la vez es el caso normal, y no todos los programas lo soportan).' -ForegroundColor Yellow
Write-Host '  - Comprobar que imprime desde la sesion remota.' -ForegroundColor Yellow
Write-Host ''

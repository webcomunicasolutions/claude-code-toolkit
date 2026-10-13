<#
.SYNOPSIS
    Pone el fondo de escritorio corporativo a TODOS los usuarios del servidor,
    de forma que el tema de Windows no lo pise.

.DESCRIPTION
    Poner la ruta en "Control Panel\Desktop\Wallpaper" NO basta en Server 2025 /
    Windows 11: el tema activo lo sobrescribe al iniciar sesion. Lo que si manda es
    la DIRECTIVA de usuario:

        HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System
            Wallpaper      = ruta del jpg
            WallpaperStyle = 2 (extendido)

    Esa directiva gana al tema y ademas impide que el usuario lo cambie, que en
    puestos de clinica es lo que queremos.

    Se aplica en tres sitios para no dejar a nadie fuera:
      1. El perfil DEFAULT -> lo hereda cualquier usuario que se cree en el futuro.
      2. Los usuarios con sesion abierta ahora -> su hive ya montado en HKEY_USERS.
      3. Los perfiles existentes sin sesion -> montando su NTUSER.DAT.

    Los usuarios que esten dentro ahora mismo lo veran al volver a iniciar sesion.

.PARAMETER Imagen
    Ruta del jpg. Debe ser legible por los usuarios (ojo con los permisos).
#>
[CmdletBinding()]
param(
    [string]$Imagen = 'C:\ProgramData\CLIENTE\wallpaper_cliente.jpg'
)

$ErrorActionPreference = 'Stop'

$esAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $esAdmin) { throw 'Hay que ejecutarlo como ADMINISTRADOR.' }
if (-not (Test-Path $Imagen)) { throw "No existe la imagen: $Imagen" }

# que los usuarios puedan LEERLA, o veran fondo negro
$acl = (Get-Acl $Imagen).Access | Where-Object {
    $_.IdentityReference -match 'Usuarios|Users' -and $_.FileSystemRights -match 'Read'
}
if (-not $acl) {
    icacls $Imagen /grant '*S-1-5-32-545:(RX)' | Out-Null   # S-1-5-32-545 = Usuarios
    if ($LASTEXITCODE -ne 0) { throw 'No pude dar permiso de lectura sobre la imagen' }
    Write-Host '  permiso de lectura concedido a Usuarios sobre la imagen' -ForegroundColor Yellow
}

$RUTA_POL = 'Software\Microsoft\Windows\CurrentVersion\Policies\System'

function Set-Fondo([string]$raizHive, [string]$quien) {
    $k = "Registry::$raizHive\$RUTA_POL"
    if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
    Set-ItemProperty -Path $k -Name 'Wallpaper'      -Value $Imagen -Type String
    Set-ItemProperty -Path $k -Name 'WallpaperStyle' -Value '2'     -Type String
    # y tambien la clave clasica, para el primer pintado antes de aplicar directivas
    $kc = "Registry::$raizHive\Control Panel\Desktop"
    if (Test-Path $kc) {
        Set-ItemProperty -Path $kc -Name 'Wallpaper'      -Value $Imagen -Type String
        Set-ItemProperty -Path $kc -Name 'WallpaperStyle' -Value '10'    -Type String
        Set-ItemProperty -Path $kc -Name 'TileWallpaper'  -Value '0'     -Type String
    }
    $leido = (Get-ItemProperty -Path $k -Name Wallpaper).Wallpaper
    if ($leido -eq $Imagen) { Write-Host "  OK   $quien" -ForegroundColor Green }
    else { Write-Host "  MAL  $quien (quedo '$leido')" -ForegroundColor Red }
}

Write-Host ''
Write-Host '=== 1) perfil DEFAULT (usuarios futuros)' -ForegroundColor Cyan
$hiveDefault = 'C:\Users\Default\NTUSER.DAT'
reg load 'HKU\ClienteDef' $hiveDefault 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "No pude montar $hiveDefault" }
try {
    Set-Fondo 'HKEY_USERS\ClienteDef' 'perfil DEFAULT'
}
finally {
    # SIEMPRE descargar el hive: si queda montado, los perfiles NUEVOS fallan al crearse
    [gc]::Collect(); [gc]::WaitForPendingFinalizers(); Start-Sleep -Seconds 2
    reg unload 'HKU\ClienteDef' 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { Write-Host '  AVISO: no pude descargar HKU\ClienteDef, revisar a mano' -ForegroundColor Red }
    else { Write-Host '  (hive DEFAULT descargado correctamente)' -ForegroundColor DarkGray }
}

Write-Host ''
Write-Host '=== 2) usuarios con sesion abierta ahora' -ForegroundColor Cyan
$sidsMontados = Get-ChildItem Registry::HKEY_USERS | Where-Object {
    $_.PSChildName -match '^S-1-5-21-\d+-\d+-\d+-\d+$'
}
if (-not $sidsMontados) { Write-Host '  (ninguno)' -ForegroundColor DarkGray }
foreach ($s in $sidsMontados) {
    $sid = $s.PSChildName
    $nombre = try {
        (New-Object System.Security.Principal.SecurityIdentifier($sid)).Translate([System.Security.Principal.NTAccount]).Value
    } catch { $sid }
    Set-Fondo "HKEY_USERS\$sid" $nombre
}

Write-Host ''
Write-Host '=== 3) perfiles existentes SIN sesion' -ForegroundColor Cyan
$sidsActivos = $sidsMontados.PSChildName
Get-CimInstance Win32_UserProfile | Where-Object { -not $_.Special } | ForEach-Object {
    $sid = $_.SID
    $ruta = $_.LocalPath
    if ($sidsActivos -contains $sid) { return }          # ese ya se hizo arriba
    $dat = Join-Path $ruta 'NTUSER.DAT'
    if (-not (Test-Path $dat)) { return }
    $tag = "ClienteU$(($sid -split '-')[-1])"
    reg load "HKU\$tag" $dat 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  saltado (hive en uso): $ruta" -ForegroundColor Yellow
        return
    }
    try { Set-Fondo "HKEY_USERS\$tag" (Split-Path $ruta -Leaf) }
    finally {
        [gc]::Collect(); [gc]::WaitForPendingFinalizers(); Start-Sleep -Seconds 2
        reg unload "HKU\$tag" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { Write-Host "  AVISO: hive $tag no descargado" -ForegroundColor Red }
    }
}

Write-Host ''
Write-Host 'Hecho. Quien tenga sesion abierta ahora lo vera al CERRAR SESION y volver a entrar.' -ForegroundColor Cyan
Write-Host 'Los hives montados temporalmente estan descargados (comprobar con: reg query HKU).' -ForegroundColor DarkGray

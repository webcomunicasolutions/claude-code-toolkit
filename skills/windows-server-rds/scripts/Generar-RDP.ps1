<#
.SYNOPSIS
    Fabrica de accesos RDP: genera los .rdp FIRMADOS y el paquete de despliegue
    listo para llevar a los equipos.

.DESCRIPTION
    Vive en el servidor (C:\Tools\rdp-generator) y se abre con el acceso directo
    "Generar accesos RDP" del escritorio del administrador. Se eleva solo.

    Pregunta a que IP van a conectar los equipos, deja elegir para quien se
    generan los accesos, y produce en C:\Tools\rdp-generator\salida\<fecha>\ una
    carpeta con:
        certs\                        los dos certificados publicos
        preparar-pc-cliente.ps1       el que hace el trabajo en el PC destino
        <Prefijo> - <usuario>.rdp     un acceso firmado por usuario
        PREPARAR-<usuario>.cmd        doble clic en el PC destino (se autoeleva)
        LEEME.txt                     instrucciones para el tecnico

    Esa carpeta se copia tal cual a un pendrive. En cada PC del cliente: doble
    clic en el PREPARAR-<usuario>.cmd que corresponda, aceptar el aviso de
    administrador, y queda el icono en el escritorio.

.PARAMETER Ip
    Salta la pregunta de la IP (util para automatizar).

.PARAMETER Usuarios
    Salta la pregunta de usuarios. Ej: -Usuarios entrada,consulta1

.PARAMETER SinInterfaz
    No limpia la pantalla, no abre el explorador y no espera al final. Para poder
    ejecutarlo por SSH/WinRM y para las pruebas. Requiere -Ip y -Usuarios.

.NOTES
    Los .rdp se guardan en UTF-16LE con BOM, que es lo que escribe rdpsign. Si se
    editan con una herramienta que los pase a UTF-8, rdpsign deja de reconocerlos.
    Cualquier cambio en un .rdp invalida su firma: hay que volver a generarlo aqui.
#>
[CmdletBinding()]
param(
    [string]$Ip,
    [string[]]$Usuarios,
    [switch]$SinInterfaz
)

$ErrorActionPreference = 'Stop'

# --- autoelevacion ----------------------------------------------------------
$esAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $esAdmin) {
    Write-Host 'Elevando a administrador...' -ForegroundColor Yellow
    $argumentos = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    if ($Ip)          { $argumentos += @('-Ip', $Ip) }
    if ($Usuarios)    { $argumentos += @('-Usuarios', ($Usuarios -join ',')) }
    if ($SinInterfaz) { $argumentos += '-SinInterfaz' }
    Start-Process powershell.exe -ArgumentList $argumentos -Verb RunAs
    return
}

$RAIZ    = 'C:\Tools\rdp-generator'
$NOMBRE  = 'SRV-CLIENTE'          # nombre del servidor (el del certificado)
$PREFIJO = 'SERVIDOR CLIENTE'     # como empiezan los nombres de los .rdp
$RDPSIGN = "$env:SystemRoot\System32\rdpsign.exe"

function Escribir-Titulo($texto) {
    Write-Host ''
    Write-Host ('  ' + $texto) -ForegroundColor Cyan
    Write-Host ('  ' + ('-' * $texto.Length)) -ForegroundColor DarkGray
}

if (-not $SinInterfaz) { Clear-Host }
Write-Host ''
Write-Host '  ================================================' -ForegroundColor Green
Write-Host '   FABRICA DE ACCESOS RDP' -ForegroundColor Green
Write-Host "   Servidor: $NOMBRE" -ForegroundColor Green
Write-Host '  ================================================' -ForegroundColor Green

# --- 1) certificados --------------------------------------------------------
$certFirma = Get-ChildItem Cert:\LocalMachine\My |
    Where-Object { $_.FriendlyName -eq 'RDP Signing' } |
    Sort-Object NotAfter -Descending | Select-Object -First 1
$certTls = Get-ChildItem Cert:\LocalMachine\My |
    Where-Object { $_.FriendlyName -eq 'CLIENTE RDP TLS' } |
    Sort-Object NotAfter -Descending | Select-Object -First 1

if (-not $certFirma) { throw 'No encuentro el certificado de firma. Ejecuta antes crear-certs-rdp.ps1' }
if (-not $certTls)   { throw 'No encuentro el certificado TLS del servidor. Ejecuta antes crear-certs-rdp.ps1' }

$diasFirma = [int]($certFirma.NotAfter - (Get-Date)).TotalDays
Write-Host ''
Write-Host "  Certificado de firma: $($certFirma.Thumbprint)" -ForegroundColor DarkGray
Write-Host "  Caduca en $diasFirma dias ($($certFirma.NotAfter.ToString('dd/MM/yyyy')))" -ForegroundColor DarkGray
if ($diasFirma -lt 90) {
    Write-Host '  AVISO: el certificado de firma esta a punto de caducar. Renuevalo.' -ForegroundColor Red
}

# --- 2) a que IP van a conectar --------------------------------------------
if (-not $Ip) {
    $ipsLocales = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.InterfaceAlias -notmatch 'Loopback' } |
        Select-Object InterfaceAlias, IPAddress

    Escribir-Titulo 'A que IP de ESTE servidor van a conectar los equipos?'
    Write-Host '  IPs que tiene ahora el servidor:' -ForegroundColor Gray
    $i = 0
    $opciones = @()
    foreach ($ipl in $ipsLocales) {
        $i++
        $etiqueta = if ($ipl.InterfaceAlias -match 'wg|cliente|tunnel') { 'VPN - no cambia si el servidor se muda' }
                    else { 'red local - cambiara al llevarlo a la clinica' }
        Write-Host ("   {0}. {1,-15} {2}  ({3})" -f $i, $ipl.IPAddress, $ipl.InterfaceAlias, $etiqueta)
        $opciones += $ipl.IPAddress
    }
    Write-Host "   $($i + 1). Otra (escribirla a mano: la IP FIJA que tendra en la clinica)"
    Write-Host ''
    $sel = Read-Host '  Opcion'
    if ($sel -eq [string]($i + 1)) {
        $Ip = Read-Host '  IP del servidor en la red de los equipos'
    }
    elseif ([int]::TryParse($sel, [ref]$null) -and [int]$sel -ge 1 -and [int]$sel -le $i) {
        $Ip = $opciones[[int]$sel - 1]
    }
    else { throw 'Opcion no valida.' }
}
if ($Ip -notmatch '^\d{1,3}(\.\d{1,3}){3}$') { throw "IP no valida: $Ip" }

# --- 3) para quien ----------------------------------------------------------
$grupoRdp = 'Usuarios de escritorio remoto'
$miembros = @()
try {
    $miembros = Get-LocalGroupMember -Group $grupoRdp -ErrorAction Stop |
        Where-Object { $_.ObjectClass -eq 'Usuario' -or $_.ObjectClass -eq 'User' } |
        ForEach-Object { ($_.Name -split '\\')[-1] } |
        Sort-Object
}
catch {
    Write-Host "  No pude leer el grupo '$grupoRdp': $($_.Exception.Message)" -ForegroundColor Yellow
}

# Si vienen por parametro: normalizar y VALIDAR. Con `powershell -File`, un
# "-Usuarios a,b,c" llega como UN solo string (con -File no hay parseo de arrays),
# asi que hay que partirlo aqui o se genera un acceso llamado "a,b,c".
if ($Usuarios) {
    $Usuarios = $Usuarios |
        ForEach-Object { $_ -split ',' } |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ } |
        Select-Object -Unique

    # Formato estricto SIEMPRE (aunque no se pueda leer el grupo, p. ej. Windows en otro idioma):
    # el nombre acaba dentro de un .cmd que se ejecuta elevado.
    $malos = $Usuarios | Where-Object { $_ -notmatch '^[A-Za-z0-9._-]{1,64}$' }
    if ($malos) { throw ("Nombre de usuario no valido: " + ($malos -join ', ')) }

    if ($miembros.Count -gt 0) {
        $inexistentes = $Usuarios | Where-Object { $miembros -notcontains $_ }
        if ($inexistentes) {
            throw ("Estos usuarios no estan en '$grupoRdp': " + ($inexistentes -join ', ') +
                   ". Usuarios validos: " + ($miembros -join ', '))
        }
    }
}

if (-not $Usuarios) {
    Escribir-Titulo 'Para quien genero los accesos?'
    if ($miembros.Count -eq 0) { throw "El grupo '$grupoRdp' esta vacio: no hay para quien generar." }
    $j = 0
    foreach ($m in $miembros) { $j++; Write-Host ("   {0}. {1}" -f $j, $m) }
    Write-Host '   T. TODOS'
    Write-Host ''
    Write-Host '  (varios: separados por comas, p.ej. 1,3,4)' -ForegroundColor DarkGray
    $sel = (Read-Host '  Opcion').Trim()

    if ($sel.ToUpper() -eq 'T') { $Usuarios = $miembros }
    else {
        $Usuarios = @()
        foreach ($t in ($sel -split ',')) {
            $n = 0
            if ([int]::TryParse($t.Trim(), [ref]$n) -and $n -ge 1 -and $n -le $miembros.Count) {
                $Usuarios += $miembros[$n - 1]
            }
        }
        if ($Usuarios.Count -eq 0) { throw 'No se selecciono ningun usuario valido.' }
    }
}

# --- 4) carpeta de salida ---------------------------------------------------
$sello   = Get-Date -Format 'yyyy-MM-dd_HHmm'
$salida  = Join-Path $RAIZ "salida\$sello`_$($Ip -replace '\.', '-')"
$dirCert = Join-Path $salida 'certs'
New-Item -ItemType Directory -Force -Path $dirCert | Out-Null

Export-Certificate -Cert $certFirma -FilePath (Join-Path $dirCert 'RDP_Signing.cer') -Force | Out-Null
Export-Certificate -Cert $certTls   -FilePath (Join-Path $dirCert "$NOMBRE`_RDP_TLS.cer") -Force | Out-Null

$plantillaPrep = Join-Path $RAIZ 'plantillas\preparar-pc-cliente.ps1'
if (-not (Test-Path $plantillaPrep)) { throw "Falta la plantilla: $plantillaPrep" }
Copy-Item $plantillaPrep (Join-Path $salida 'preparar-pc-cliente.ps1') -Force

# --- 5) un .rdp firmado + su .cmd por usuario ------------------------------
Escribir-Titulo 'Generando accesos'

# Ajustes del .rdp. La direccion va por NOMBRE a proposito: la firma cubre
# "full address", asi que si fuera por IP habria que rehacer y refirmar todos
# los accesos cada vez que el servidor cambiara de red.
function Nuevo-ContenidoRdp([string]$usuario) {
    @(
        "full address:s:$NOMBRE"
        "username:s:$NOMBRE\$usuario"
        'screen mode id:i:2'          # pantalla completa
        'use multimon:i:1'            # varios monitores
        'desktopwidth:i:1920'
        'desktopheight:i:1080'
        'session bpp:i:32'
        'compression:i:1'
        'audiomode:i:0'
        'redirectprinters:i:1'        # impresoras del puesto
        'redirectclipboard:i:1'       # copiar y pegar
        'redirectsmartcards:i:0'
        'redirectcomports:i:0'
        'drivestoredirect:s:'         # discos locales NO, a proposito
        'autoreconnection enabled:i:1'
        'authentication level:i:2'
        'prompt for credentials:i:0'
        'negotiate security layer:i:1'
        'enableworkspacereconnect:i:0'
        'disable wallpaper:i:0'
        'allow font smoothing:i:1'
        'allow desktop composition:i:1'
        'disable full window drag:i:0'
        'disable menu anims:i:1'
        'disable themes:i:0'
        'bitmapcachepersistenable:i:1'
    )
}

$generados = @()
foreach ($u in $Usuarios) {
    $nombreRdp = "$PREFIJO - $u.rdp"
    $rutaRdp   = Join-Path $salida $nombreRdp

    # UTF-16LE con BOM y CRLF: es el formato que espera/escribe rdpsign
    $utf16 = New-Object System.Text.UnicodeEncoding($false, $true)
    [System.IO.File]::WriteAllText($rutaRdp, ((Nuevo-ContenidoRdp $u) -join "`r`n") + "`r`n", $utf16)

    $out = & $RDPSIGN /sha256 $certFirma.Thumbprint $rutaRdp 2>&1
    if ($LASTEXITCODE -ne 0) { throw "rdpsign fallo con '$u': $($out -join ' ')" }

    # comprobar de verdad que quedo firmado, no fiarse del exit code
    $contenido = Get-Content -LiteralPath $rutaRdp
    if (-not ($contenido | Where-Object { $_ -like 'signature:s:*' })) {
        throw "El .rdp de '$u' quedo SIN firma."
    }

    # .cmd de doble clic para el PC destino. Se eleva relanzandose a si mismo: asi
    # el -File del PowerShell va entre comillas dobles de verdad y aguanta rutas
    # con espacios (Escritorio, Descargas...). Pasar la ruta dentro de un
    # -ArgumentList de PowerShell 5.1 NO aguanta espacios: los une sin entrecomillar.
    $cmd = @"
@echo off
title Preparar este PC - $u ($NOMBRE)
cd /d "%~dp0"

REM Preparar este PC para entrar como '$u' en $NOMBRE ($Ip)
REM Generado el $(Get-Date -Format 'dd/MM/yyyy HH:mm')

REM El .cmd necesita a su lado el .ps1, la carpeta certs\ y su .rdp. Si alguien
REM copia solo los .cmd al escritorio, PowerShell suelta un error crudo de
REM "-File no existe"; mejor decir claramente que falta.
if not exist "%~dp0preparar-pc-cliente.ps1" goto :incompleto
if not exist "%~dp0certs" goto :incompleto
if not exist "%~dp0*- $u.rdp" goto :incompleto
goto :ok

:incompleto
echo.
echo  ============================================================
echo   FALTAN FICHEROS: hay que ejecutarlo desde la CARPETA COMPLETA
echo  ============================================================
echo.
echo  Esto no funciona copiando solo este fichero al escritorio.
echo  Junto a el tienen que estar:
echo      - preparar-pc-cliente.ps1
echo      - la carpeta certs\
echo      - SERVIDOR CLIENTE - $u.rdp
echo.
echo  Abre la carpeta del pendrive y haz doble clic AHI DENTRO,
echo  o copia la carpeta entera al equipo.
echo.
echo  Carpeta actual: %~dp0
echo.
pause
exit /b 1

:ok
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Pidiendo permisos de administrador...
    powershell.exe -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0preparar-pc-cliente.ps1" -IpServidor $Ip -Puesto $u -NombreServidor $NOMBRE
echo.
pause
"@
    Set-Content -LiteralPath (Join-Path $salida "PREPARAR-$u.cmd") -Value $cmd -Encoding ASCII

    Write-Host "   OK  $u" -ForegroundColor Green
    $generados += $u
}

# --- 6) LEEME ---------------------------------------------------------------
$leeme = @"
PAQUETE DE ACCESOS RDP - $NOMBRE
Generado: $(Get-Date -Format 'dd/MM/yyyy HH:mm')
IP del servidor para estos equipos: $Ip
Accesos incluidos: $($generados -join ', ')

EN CADA EQUIPO DEL CLIENTE
1. Copiar esta carpeta completa al equipo (o abrirla desde el pendrive).
2. Doble clic en PREPARAR-<puesto>.cmd  (el del puesto que sea).
3. Aceptar el aviso de administrador de Windows.
4. Queda un icono en el escritorio. Ese es el que hay que usar SIEMPRE.
5. La primera vez pedira la contrasena del usuario: marcar
   "Recordar mis credenciales".

IMPORTANTE
- Entrar SIEMPRE por el icono. Si se escribe la IP a mano en mstsc, esa
  conexion no va firmada y volvera a salir el aviso de "Editor desconocido".
- Los accesos apuntan al NOMBRE $NOMBRE, no a la IP. Si el servidor cambia de
  red, NO hay que regenerar nada: basta volver a ejecutar el PREPARAR del
  equipo... generado con la IP nueva (vuelve a pasar por la fabrica del
  servidor y saca un paquete nuevo con esa IP).
- Para un equipo que entre por la VPN, se genera el paquete con la IP del
  tunel: esa no cambia aunque el servidor se mude de sede.

Contrasenas: tu gestor de credenciales
Documentacion: la documentacion de tu proyecto.
"@
Set-Content -LiteralPath (Join-Path $salida 'LEEME.txt') -Value $leeme -Encoding UTF8

Escribir-Titulo 'Listo'
Write-Host "  Paquete: $salida" -ForegroundColor Green
Write-Host "  Accesos: $($generados.Count) ($($generados -join ', '))" -ForegroundColor Green
Write-Host "  IP configurada: $Ip" -ForegroundColor Green
Write-Host ''
Write-Host '  Copia esa carpeta a un pendrive y en cada equipo haz doble clic en' -ForegroundColor Yellow
Write-Host '  el PREPARAR-<puesto>.cmd que corresponda.' -ForegroundColor Yellow
Write-Host ''
if (-not $SinInterfaz) {
    Start-Process explorer.exe $salida
    Write-Host '  (pulsa Enter para cerrar)' -ForegroundColor DarkGray
    Read-Host | Out-Null
}

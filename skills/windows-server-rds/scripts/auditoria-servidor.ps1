<#
.SYNOPSIS
    Inventario completo de un servidor Windows: que hay instalado, que corre, quien
    puede entrar, donde estan los datos y como sacarlos.

.DESCRIPTION
    Pensado para documentar un servidor despues de que lo toque un tercero (el
    tecnico del programa de gestion, por ejemplo) y para tener una foto a la que
    volver si algun dia algo deja de funcionar.

    Solo LEE. No cambia nada.

    Escribe el informe por pantalla y, si se le da -Salida, tambien a un fichero.

.PARAMETER CarpetaApp
    Carpeta de la aplicacion de gestion a analizar a fondo (estructura, bases de
    datos, permisos, ficheros de configuracion).

.PARAMETER Salida
    Ruta del fichero de informe.

.EXAMPLE
    .\auditoria-servidor.ps1 -CarpetaApp C:\ERP -Salida C:\Temp\auditoria.txt
#>
[CmdletBinding()]
param(
    [string]$CarpetaApp,
    [string]$Salida
)

$ErrorActionPreference = 'Continue'
$lineas = New-Object System.Collections.Generic.List[string]

function Seccion($t) {
    $lineas.Add('')
    $lineas.Add('=' * 78)
    $lineas.Add("  $t")
    $lineas.Add('=' * 78)
}
function L($t) { $lineas.Add($t) }

L "INVENTARIO DEL SERVIDOR $env:COMPUTERNAME"
L "Generado: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"

# --------------------------------------------------------------- sistema
Seccion 'SISTEMA'
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
L "  SO            : $($os.Caption) build $($os.Version).$((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').UBR)"
L "  Equipo        : $($cs.Name)  (dominio/grupo: $($cs.Domain))"
L "  Arranque      : $($os.LastBootUpTime)"
L "  Zona horaria  : $((Get-TimeZone).Id)"
$lic = Get-CimInstance SoftwareLicensingProduct | Where-Object { $_.PartialProductKey -and $_.Name -like '*Windows*' } | Select-Object -First 1
L "  Licencia      : $($lic.Name) -> LicenseStatus=$($lic.LicenseStatus) (1=activada)"
L "  CPU           : $((Get-CimInstance Win32_Processor).Name)"
L "  RAM           : $([math]::Round($cs.TotalPhysicalMemory/1GB,1)) GB"
L '  Graficas      :'
Get-CimInstance Win32_VideoController | ForEach-Object {
    L "    - $($_.Name)  (driver $($_.DriverVersion), $([math]::Round($_.AdapterRAM/1GB,1)) GB)"
}
L '  Discos fisicos:'
Get-PhysicalDisk -ErrorAction SilentlyContinue | ForEach-Object {
    L "    - $($_.FriendlyName)  $([math]::Round($_.Size/1GB,1)) GB  salud=$($_.HealthStatus)  tipo=$($_.MediaType)"
}
L '  Volumenes     :'
Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null } | ForEach-Object {
    L "    - $($_.Name): usado $([math]::Round($_.Used/1GB,1)) GB / libre $([math]::Round($_.Free/1GB,1)) GB"
}

# --------------------------------------------------------------- red
Seccion 'RED'
Get-NetIPConfiguration | Where-Object { $_.IPv4Address } | ForEach-Object {
    L "  $($_.InterfaceAlias): $($_.IPv4Address.IPAddress)/$($_.IPv4Address.PrefixLength)"
    L "    gateway: $($_.IPv4DefaultGateway.NextHop)   DHCP: $((Get-NetIPInterface -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4).Dhcp)"
    L "    DNS    : $(($_.DNSServer | Where-Object { $_.AddressFamily -eq 2 }).ServerAddresses -join ', ')"
}
L '  Puertos a la escucha (con su proceso):'
Get-NetTCPConnection -State Listen | Sort-Object LocalPort -Unique | ForEach-Object {
    $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
    L ("    {0,-6} {1,-16} {2}" -f $_.LocalPort, $_.LocalAddress, $p.ProcessName)
}

# --------------------------------------------------------------- software
Seccion 'SOFTWARE INSTALADO (ordenado por fecha de instalacion)'
Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*,
                 HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName } |
    Sort-Object InstallDate, DisplayName |
    ForEach-Object {
        L ("  {0,-10} {1,-52} {2,-16} {3}" -f $_.InstallDate, $_.DisplayName, $_.DisplayVersion, $_.Publisher)
    }

# --------------------------------------------------------------- servicios
Seccion 'SERVICIOS NO-MICROSOFT (los que no vienen de serie)'
Get-CimInstance Win32_Service |
    Where-Object { $_.PathName -and $_.PathName -notmatch 'system32|SysWOW64|Windows\\Microsoft' } |
    Sort-Object Name | ForEach-Object {
        L "  $($_.Name)  [$($_.State) / $($_.StartMode)]  cuenta: $($_.StartName)"
        L "      $($_.PathName)"
    }

# --------------------------------------------------------------- arranque
Seccion 'PROGRAMAS QUE ARRANCAN SOLOS'
foreach ($k in 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
               'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run') {
    if (Test-Path $k) {
        (Get-Item $k).Property | ForEach-Object {
            L "  [$k] $_ = $((Get-ItemProperty $k -Name $_).$_)"
        }
    }
}
L '  Tareas programadas no-Microsoft:'
Get-ScheduledTask | Where-Object { $_.TaskPath -notmatch '\\Microsoft\\' -and $_.State -ne 'Disabled' } |
    ForEach-Object { L "    $($_.TaskPath)$($_.TaskName)  [$($_.State)]" }

# --------------------------------------------------------------- usuarios
Seccion 'USUARIOS Y GRUPOS LOCALES'
Get-LocalUser | Sort-Object Name | ForEach-Object {
    L ("  {0,-20} activo={1,-6} caduca_pass={2,-22} ultimo_acceso={3}" -f `
        $_.Name, $_.Enabled, $_.PasswordExpires, $_.LastLogon)
}
L ''
foreach ($g in 'Administradores', 'Usuarios de escritorio remoto', 'CLIENTE-Datos') {
    $m = Get-LocalGroupMember -Group $g -ErrorAction SilentlyContinue
    if ($m) { L "  $g : $(($m | ForEach-Object { ($_.Name -split '\\')[-1] }) -join ', ')" }
}

# --------------------------------------------------------------- compartidos
Seccion 'RECURSOS COMPARTIDOS'
Get-SmbShare | ForEach-Object {
    L "  $($_.Name) -> $($_.Path)"
    (Get-SmbShareAccess -Name $_.Name -ErrorAction SilentlyContinue) | ForEach-Object {
        L "      $($_.AccountName) : $($_.AccessRight) ($($_.AccessControlType))"
    }
}

# --------------------------------------------------------------- firewall
Seccion 'FIREWALL - REGLAS DE ENTRADA ACTIVAS (permitir)'
Get-NetFirewallRule -Enabled True -Direction Inbound -Action Allow |
    Where-Object { $_.DisplayName -notmatch '^@' } | ForEach-Object {
        $pf = $_ | Get-NetFirewallPortFilter
        $af = $_ | Get-NetFirewallAddressFilter
        if ($pf.LocalPort -and $pf.LocalPort -ne 'Any') {
            L "  $($_.DisplayName)  puerto=$($pf.LocalPort)/$($pf.Protocol)  desde=$($af.RemoteAddress)  perfil=$($_.Profile)"
        }
    }

# --------------------------------------------------------------- la aplicacion
if ($CarpetaApp -and (Test-Path $CarpetaApp)) {
    Seccion "APLICACION DE GESTION: $CarpetaApp"
    $tam = (Get-ChildItem $CarpetaApp -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
    L "  Tamano total: $([math]::Round($tam/1MB,1)) MB"

    L ''
    L '  PERMISOS de la carpeta:'
    (Get-Acl $CarpetaApp).Access | ForEach-Object {
        L ("    {0,-44} {1,-38} heredado={2}" -f $_.IdentityReference, $_.FileSystemRights, $_.IsInherited)
    }

    L ''
    L '  BASES DE DATOS y copias (fichero, tamano, ultima modificacion):'
    Get-ChildItem $CarpetaApp -Include *.mdb,*.accdb,*.fdb,*.gdb,*.dbf,*.mdf,*.sqlite,*.db -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | ForEach-Object {
            L ("    {0,-58} {1,10} MB  {2}" -f $_.FullName.Replace($CarpetaApp,'.'), [math]::Round($_.Length/1MB,2), $_.LastWriteTime.ToString('dd/MM/yyyy HH:mm'))
        }

    L ''
    L '  EJECUTABLES principales (raiz de la carpeta):'
    Get-ChildItem $CarpetaApp -Filter *.exe -File -ErrorAction SilentlyContinue |
        Sort-Object Length -Descending | Select-Object -First 15 | ForEach-Object {
            $v = $_.VersionInfo
            L ("    {0,-34} {1,-12} {2}" -f $_.Name, $v.FileVersion, $v.CompanyName)
        }

    L ''
    L '  FICHEROS DE CONFIGURACION (se marca si contienen algo con pinta de secreto,'
    L '  SIN mostrar el valor):'
    Get-ChildItem $CarpetaApp -Include *.ini,*.config,*.xml,*.json,*.udl,*.dsn -Recurse -File -ErrorAction SilentlyContinue |
        Select-Object -First 40 | ForEach-Object {
            $texto = ''
            try { $texto = Get-Content $_.FullName -Raw -ErrorAction Stop } catch { }
            $marcas = @()
            if ($texto -match '(?i)password\s*=\s*\S' -or $texto -match '(?i)pwd\s*=\s*\S') { $marcas += 'PASSWORD' }
            if ($texto -match '(?i)(user|uid)\s*=\s*\S')                                    { $marcas += 'usuario' }
            if ($texto -match '(?i)(server|data source|dbq)\s*=\s*\S')                       { $marcas += 'conexion' }
            if ($texto -match '(?i)api[_-]?key|token\s*=')                                   { $marcas += 'TOKEN' }
            L ("    {0,-62} {1}" -f $_.FullName.Replace($CarpetaApp,'.'), ($marcas -join ' '))
        }
}

# --------------------------------------------------------------- salida
$texto = $lineas -join "`r`n"
Write-Output $texto
if ($Salida) {
    $dir = Split-Path -Parent $Salida
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Set-Content -LiteralPath $Salida -Value $texto -Encoding UTF8
    Write-Output ''
    Write-Output "[informe guardado en $Salida]"
}

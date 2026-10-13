<#
.SYNOPSIS
    Prepara un PC para entrar por Escritorio Remoto al servidor SIN avisos de seguridad.

.DESCRIPTION
    Se ejecuta UNA VEZ por PC, COMO ADMINISTRADOR, desde la carpeta del paquete
    (la que contiene los .rdp, la subcarpeta certs\ y los PREPARAR-*.cmd).
    Normalmente no se llama a mano: se hace doble clic en el PREPARAR-<puesto>.cmd
    correspondiente, que ya trae la IP y el puesto puestos.

    Lo que hace y que aviso quita cada cosa:
      1. hosts -> resuelve el NOMBRE del servidor a su IP.
         (los .rdp apuntan al nombre, no a la IP: asi la firma sigue valida el dia
          que el servidor cambie de red; solo hay que volver a ejecutar esto)
      2. Importa el certificado de firma en "Editores de confianza" y en "Raiz de
         confianza" -> quita "el EDITOR de esta conexion remota no se puede
         identificar".
      3. Registra su huella en TrustedCertThumbprints -> refuerza lo anterior
         (es la politica de "editores RDP de confianza"; aqui por registro porque
          no hay dominio ni GPO).
      4. Importa el certificado TLS del servidor en "Raiz de confianza" -> quita
         "no se puede comprobar la IDENTIDAD del equipo remoto".
      5. Copia el .rdp del puesto al escritorio publico y le quita la marca de
         "archivo descargado" (Unblock-File).

    Es idempotente: se puede volver a ejecutar (por ejemplo si cambia la IP del
    servidor) sin dejar entradas duplicadas.

.PARAMETER IpServidor
    IP del servidor en la red desde la que conecta ESTE PC. En la red local de la
    clinica sera una 192.168.x.x; para un equipo que entra por la VPN, la IP del
    tunel (que no cambia si el servidor se muda de sede).

.PARAMETER Puesto
    Nombre del puesto/usuario. Debe existir el fichero "<Prefijo> - <Puesto>.rdp"
    en esta misma carpeta.

.PARAMETER NombreServidor
    Nombre del servidor tal y como figura en el certificado y en los .rdp.

.EXAMPLE
    .\preparar-pc-cliente.ps1 -IpServidor 192.168.1.10 -Puesto entrada

.EXAMPLE
    .\preparar-pc-cliente.ps1 -IpServidor 10.10.0.2 -Puesto gerente
    # equipo de fuera que entra por la VPN
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d{1,3}(\.\d{1,3}){3}$')]
    [string]$IpServidor,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Puesto,

    [string]$NombreServidor = 'SRV-CLIENTE'
)

$ErrorActionPreference = 'Stop'

# --- 0) comprobaciones previas ---------------------------------------------
$esAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $esAdmin) { throw 'Hay que ejecutarlo como ADMINISTRADOR.' }

$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$dirCerts = Join-Path $base 'certs'

# el .rdp del puesto: se busca por patron para no depender del prefijo del nombre
$rdp = Get-ChildItem -LiteralPath $base -Filter "*- $Puesto.rdp" -File |
       Select-Object -First 1
if (-not $rdp) {
    $disponibles = (Get-ChildItem -LiteralPath $base -Filter '*.rdp' -File |
        ForEach-Object { ($_.BaseName -split ' - ')[-1] }) -join ', '
    throw "No hay ningun .rdp para el puesto '$Puesto' en $base. Disponibles: $disponibles"
}

# los certificados se localizan por su uso, no por nombre de fichero
$certFirma = Get-ChildItem -LiteralPath $dirCerts -Filter '*Signing*.cer' -File |
             Select-Object -First 1
$certTls = Get-ChildItem -LiteralPath $dirCerts -Filter '*TLS*.cer' -File |
           Select-Object -First 1
if (-not $certFirma) { throw "Falta el certificado de firma (*Signing*.cer) en $dirCerts" }
if (-not $certTls)   { throw "Falta el certificado del servidor (*TLS*.cer) en $dirCerts" }

# la huella se LEE del propio certificado: nada de pegarla a mano en el codigo
$huellaFirma = ([System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
    $certFirma.FullName)).Thumbprint

Write-Host "== Preparando este PC como '$Puesto' -> $NombreServidor ($IpServidor)" -ForegroundColor Cyan

# --- 1) hosts ---------------------------------------------------------------
# El hosts es un REFUERZO, no un requisito: en una red plana Windows resuelve
# "SRV-CLIENTE" solo. Asi que si esto falla se avisa y se SIGUE: lo que de verdad
# quita los avisos son los certificados de los pasos 2 a 4.
$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
try {
    if (Test-Path -LiteralPath $hosts) {
        Copy-Item -LiteralPath $hosts -Destination "$hosts.bak-cliente" -Force

        # algunos antivirus y utilidades de "limpieza" dejan el hosts como solo lectura
        $item = Get-Item -LiteralPath $hosts -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReadOnly) {
            $item.Attributes = $item.Attributes -bxor [IO.FileAttributes]::ReadOnly
            Write-Host '        (el hosts estaba en solo lectura, quitado)' -ForegroundColor DarkGray
        }
    }

    $lineas = @()
    if (Test-Path -LiteralPath $hosts) {
        $lineas = @([IO.File]::ReadAllLines($hosts))
    }
    # fuera CUALQUIER entrada previa de este nombre (con o sin comentario detras, sea
    # la IP que sea): si no, al cambiar de IP quedarian dos y ganaria la vieja.
    $limpias = @($lineas | Where-Object {
        $_ -notmatch "^\s*\d{1,3}(\.\d{1,3}){3}\s+$NombreServidor(\s|$)"
    })
    $nuevas = $limpias + "$IpServidor`t$NombreServidor`t# CLIENTE - servidor de la clinica"

    # .NET directo en vez de Set-Content: el proveedor de PowerShell falla en algunos
    # equipos con "No se puede leer la secuencia / GetContentWriterArgumentError"
    [IO.File]::WriteAllLines($hosts, [string[]]$nuevas, [Text.Encoding]::ASCII)
    Write-Host "  [1/5] hosts: $NombreServidor -> $IpServidor" -ForegroundColor Green
}
catch {
    Write-Host "  [1/5] AVISO: no pude escribir el hosts ($($_.Exception.Message))" -ForegroundColor Yellow
    Write-Host '        Sigo con los certificados. Se comprueba al final si el nombre resuelve.' -ForegroundColor Yellow
}

# --- 2) certificado de firma en Editores de confianza + Raiz ---------------
foreach ($store in 'TrustedPublisher', 'Root') {
    Import-Certificate -FilePath $certFirma.FullName -CertStoreLocation "Cert:\LocalMachine\$store" | Out-Null
}
Write-Host '  [2/5] certificado de firma importado (TrustedPublisher + Root)' -ForegroundColor Green

# --- 3) huella en la lista de editores RDP de confianza --------------------
$kTs = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
if (-not (Test-Path $kTs)) { New-Item -Path $kTs -Force | Out-Null }
$actual = (Get-ItemProperty -Path $kTs -Name TrustedCertThumbprints -ErrorAction SilentlyContinue).TrustedCertThumbprints
$lista = @()
if ($actual) { $lista = $actual -split ',' | Where-Object { $_ } }
if ($lista -notcontains $huellaFirma) { $lista += $huellaFirma }
Set-ItemProperty -Path $kTs -Name TrustedCertThumbprints -Value ($lista -join ',') -Type String
Write-Host "  [3/5] huella registrada: $huellaFirma" -ForegroundColor Green

# --- 4) certificado TLS del servidor como raiz de confianza ----------------
Import-Certificate -FilePath $certTls.FullName -CertStoreLocation 'Cert:\LocalMachine\Root' | Out-Null
Write-Host '  [4/5] certificado del servidor importado (Root)' -ForegroundColor Green

# --- 5) acceso directo en el escritorio publico ----------------------------
$destino = Join-Path $env:PUBLIC "Desktop\$($rdp.Name)"
Copy-Item -LiteralPath $rdp.FullName -Destination $destino -Force
Unblock-File -LiteralPath $destino
Write-Host "  [5/5] copiado al escritorio: $($rdp.Name)" -ForegroundColor Green

Write-Host ''
Write-Host '=== comprobacion final: este PC llega al servidor por su NOMBRE?' -ForegroundColor Cyan
$resuelve = $null
try { $resuelve = ([Net.Dns]::GetHostAddresses($NombreServidor) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1).IPAddressToString } catch { }
if ($resuelve -eq $IpServidor) {
    Write-Host "  OK: $NombreServidor -> $resuelve" -ForegroundColor Green
}
elseif ($resuelve) {
    Write-Host "  ATENCION: $NombreServidor resuelve a $resuelve y esperabamos $IpServidor" -ForegroundColor Red
    Write-Host '  Revisar el hosts de este PC antes de usarlo.' -ForegroundColor Red
}
else {
    Write-Host "  ATENCION: este PC NO resuelve el nombre $NombreServidor." -ForegroundColor Red
    Write-Host '  El acceso del escritorio no conectara. Avisar para arreglar el hosts.' -ForegroundColor Red
}

Write-Host ''
Write-Host 'LISTO. Entra SIEMPRE por el icono del escritorio.' -ForegroundColor Cyan
Write-Host 'Si se escribe la IP a mano en mstsc, esa conexion NO va firmada y el' -ForegroundColor Yellow
Write-Host 'aviso del editor volvera a salir.' -ForegroundColor Yellow
Write-Host ''
Write-Host 'La primera vez pedira la contrasena del usuario: marcar "Recordar mis' -ForegroundColor Yellow
Write-Host 'credenciales" y ya no la volvera a pedir.' -ForegroundColor Yellow

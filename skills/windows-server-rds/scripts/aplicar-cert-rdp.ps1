# aplicar-cert-rdp.ps1 — fija el cert TLS propio en RDP-Tcp DANDO ANTES acceso a la
# clave privada a NETWORK SERVICE (sin esto, TermService no puede usarlo y RDP corta
# la conexion en el handshake — pasó el 11/08/2026).
$ErrorActionPreference = 'Stop'
$hash = '05C1705B1E8A41E275AA829867139BF5D422014F'
$cert = Get-Item "Cert:\LocalMachine\My\$hash"

# --- 1) localizar el fichero de la clave privada (CNG o CAPI) y dar lectura ---
$unique = $null
try   { $unique = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert).Key.UniqueName }
catch { }
if (-not $unique) {
    try { $unique = $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName } catch { }
}
if (-not $unique) { throw 'No se pudo determinar el contenedor de la clave privada' }

$paths = @(
    "$env:ProgramData\Microsoft\Crypto\Keys\$unique",
    "$env:ProgramData\Microsoft\Crypto\RSA\MachineKeys\$unique"
) | Where-Object { Test-Path $_ }
if (-not $paths) { throw "No se encontro el fichero de clave: $unique" }

# OJO: por SID (*S-1-5-20), NO por nombre. En un Windows en español la cuenta se
# llama "SERVICIO DE RED" y `icacls /grant "NETWORK SERVICE:(R)"` falla con
# "No se efectuó ninguna asignación entre los nombres de cuenta y los SID" —
# y icacls NO lanza excepción, así que hay que mirar el exit code o se da por
# bueno algo que no se aplicó (pasó el 11/08/2026 y dejó el RDP cortando).
foreach ($p in $paths) {
    $out = icacls $p /grant '*S-1-5-20:(R)' 2>&1
    if ($LASTEXITCODE -ne 0) { throw "icacls FALLO en $p :: $($out -join ' | ')" }
    "ACL aplicada (SID *S-1-5-20): $p"
}

# --- 2) fijar el hash en RDP-Tcp ---
$k = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
$bytes = [byte[]]::new(20)
for ($i = 0; $i -lt 20; $i++) { $bytes[$i] = [Convert]::ToByte($hash.Substring($i*2,2),16) }
Set-ItemProperty -Path $k -Name SSLCertificateSHA1Hash -Value $bytes -Type Binary

Restart-Service TermService -Force
Start-Sleep 5
'TermService: ' + (Get-Service TermService).Status
$fijado = ((Get-ItemProperty $k -Name SSLCertificateSHA1Hash).SSLCertificateSHA1Hash |
           ForEach-Object { $_.ToString('X2') }) -join ''
"Hash fijado:  $fijado"
if ($fijado -ne $hash) { throw "El hash del registro NO coincide con el esperado" }

# La comprobacion QUE IMPORTA no se puede hacer aqui: hay que verificar desde fuera
# que el servidor SIRVE ese certificado (handshake X.224+TLS). Ver
# docs/RDP-SIN-AVISOS.md. Si da "Connection reset", revertir con:
#   Remove-ItemProperty -Path $k -Name SSLCertificateSHA1Hash; Restart-Service TermService -Force
'Ahora verifica el handshake desde fuera (docs/RDP-SIN-AVISOS.md) antes de darlo por bueno.'

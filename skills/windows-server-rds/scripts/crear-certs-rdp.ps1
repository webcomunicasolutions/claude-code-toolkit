# crear-certs-rdp.ps1 — CLIENTE / SRV-CLIENTE
# Crea (idempotente) dos certificados propios de larga duracion:
#   1) TLS de Escritorio Remoto  -> quita "no se puede comprobar la identidad del equipo remoto"
#   2) Firma de codigo (.rdp)    -> quita "el editor de esta conexion remota no se puede identificar"
# Exporta los .cer publicos y el .pfx de firma a C:\Tools\rdp-signing
# NO fija todavia el cert TLS en RDP-Tcp: eso va en un paso aparte y verificado.

$ErrorActionPreference = 'Stop'
$dir = 'C:\Tools\rdp-signing'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# ACL: solo administradores
icacls $dir /inheritance:r /grant:r "*S-1-5-32-544:(OI)(CI)F" /grant:r "*S-1-5-18:(OI)(CI)F" | Out-Null

$result = @{}

# --- 1) Certificado TLS para RDP -------------------------------------------
$tls = Get-ChildItem Cert:\LocalMachine\My |
       Where-Object { $_.Subject -eq 'CN=SRV-CLIENTE' -and $_.FriendlyName -eq 'CLIENTE RDP TLS' } |
       Sort-Object NotAfter -Descending | Select-Object -First 1

if (-not $tls) {
    $tls = New-SelfSignedCertificate `
        -Subject 'CN=SRV-CLIENTE' `
        -DnsName 'SRV-CLIENTE','srv-cliente','SRV-CLIENTE.local' `
        -CertStoreLocation 'Cert:\LocalMachine\My' `
        -KeyExportPolicy NonExportable `
        -KeyLength 2048 `
        -KeyAlgorithm RSA `
        -HashAlgorithm SHA256 `
        -KeyUsage DigitalSignature,KeyEncipherment `
        -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.1') `
        -NotAfter (Get-Date).AddYears(10) `
        -FriendlyName 'CLIENTE RDP TLS'
    $result.tls_creado = $true
} else {
    $result.tls_creado = $false
}
$result.tls_thumbprint = $tls.Thumbprint
$result.tls_notafter   = $tls.NotAfter.ToString('yyyy-MM-dd')
Export-Certificate -Cert $tls -FilePath "$dir\SRV-CLIENTE_RDP_TLS.cer" -Force | Out-Null

# --- 2) Certificado de firma de codigo para los .rdp -----------------------
$sign = Get-ChildItem Cert:\LocalMachine\My |
        Where-Object { $_.FriendlyName -eq 'RDP Signing' } |
        Sort-Object NotAfter -Descending | Select-Object -First 1

if (-not $sign) {
    $sign = New-SelfSignedCertificate `
        -Subject 'CN=Tu Empresa TI, O=Tu Empresa, L=Tu Ciudad, C=ES' `
        -Type CodeSigningCert `
        -CertStoreLocation 'Cert:\LocalMachine\My' `
        -KeyExportPolicy Exportable `
        -KeyLength 2048 `
        -HashAlgorithm SHA256 `
        -NotAfter (Get-Date).AddYears(10) `
        -FriendlyName 'RDP Signing'
    $result.sign_creado = $true
} else {
    $result.sign_creado = $false
}
$result.sign_thumbprint = $sign.Thumbprint
$result.sign_notafter   = $sign.NotAfter.ToString('yyyy-MM-dd')
Export-Certificate -Cert $sign -FilePath "$dir\RDP_Signing.cer" -Force | Out-Null

# .pfx con clave privada (para poder re-firmar los .rdp en el futuro / desde otra maquina)
$pfxPass = $env:CLIENTE_PFX_PASS
if ($pfxPass) {
    $sec = ConvertTo-SecureString -String $pfxPass -Force -AsPlainText
    Export-PfxCertificate -Cert $sign -FilePath "$dir\RDP_Signing.pfx" -Password $sec -Force | Out-Null
    $result.pfx_exportado = $true
} else {
    $result.pfx_exportado = $false
}

$result | ConvertTo-Json -Compress

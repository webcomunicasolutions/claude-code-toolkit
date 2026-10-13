# RDS alojado por un proveedor (RDS de OTRO) (2026-09-05)

Primer caso de la skill sobre un RDS **que no es nuestro**: un programa de gestión alojado por su fabricante,
RemoteApp por RD Gateway. Objetivo: doble clic sin teclear credenciales. Conseguido.

## El hallazgo que vale para cualquier cliente

**Un `.rdp` firmado con un certificado CADUCADO llega como `Editor: Editor desconocido`, y con un
`.rdp` sin editor identificable Windows SE NIEGA a usar credenciales guardadas.**

No es "no confío en este editor": la firma es inválida y el fichero se trata como no firmado.
Consecuencia práctica: puedes tener la credencial perfectamente guardada, la directiva de
delegación perfecta y el `.rdp` perfecto — y seguirá pidiendo la contraseña. Un diagnóstico dio
**15 de 15 correctos** y aun así preguntaba.

Y ojo: **declarar su huella en `TrustedCertThumbprints` NO lo arregla.** No se puede confiar en un
editor que no llega a identificarse.

El proveedor firmaba con `CN=*.proveedor.es` (GoDaddy), caducado el 17/08/2026 y con
`Extended Key Usage: TLS Web Server Authentication` — su certificado **web**, que además nunca fue
el adecuado para firmar. Lo sufren todos sus clientes de hosted.

### Cómo mirar el certificado de un `.rdp` ajeno, sin Windows

La firma es un PKCS#7 en base64 con **12 bytes de cabecera propia de Windows** por delante:

```bash
python3 -c "import base64;raw=open('x.rdp','rb').read();
enc='utf-16' if raw[:2] in (b'\xff\xfe',b'\xfe\xff') else 'utf-8';
l=[x for x in raw.decode(enc).splitlines() if x.startswith('signature:s:')][0]
open('sig.bin','wb').write(base64.b64decode(l[12:]))"
tail -c +13 sig.bin > sig7.der
openssl pkcs7 -inform DER -in sig7.der -print_certs -noout   # subject, issuer
openssl x509 -in cert.pem -noout -dates -fingerprint -sha1   # caducidad y huella
```

En PowerShell: `Add-Type -AssemblyName System.Security` (5.1 **no** lo carga solo, si no
`[Security.Cryptography.Pkcs.SignedCms]` no existe) y `$cms.SignerInfos[0].Certificate.Thumbprint`.

### La solución: firmar nosotros el acceso de un proveedor

1. `New-SelfSignedCertificate -Type CodeSigningCert` (10 años) en el equipo del técnico.
2. Quitar `signature:`/`signscope:` del original, poner los ajustes **y el `username`**, y firmar
   con `rdpsign /sha256 <huella>`.
   **El usuario va ANTES de firmar**: editar el fichero después rompe nuestra propia firma. Por eso
   se generan N ficheros (uno por persona), no uno que se personaliza al instalar.
3. En cada PC: el `.cer` en `TrustedPublisher` + `Root`, y su huella en `TrustedCertThumbprints`.

## Credenciales guardadas para RDP: dos trampas

- **`cmdkey /generic:` NO sirve.** Guarda `LegacyGeneric:target=TERMSRV/...` y mstsc la ignora.
  Tiene que ser `Domain:target=...` → `cmdkey /add:` o, mejor, `CredWrite` con
  `CRED_TYPE_DOMAIN_PASSWORD` + `CRED_PERSIST_LOCAL_MACHINE` por P/Invoke (así la contraseña no
  pasa por la línea de órdenes, que `cmdkey /pass:` sí la expone en el argv).
  *Cómo se detectó*: en el mismo equipo convivían las dos formas; las conexiones que funcionaban de
  siempre eran `Domain:target`. **Mirar lo que YA funciona en la máquina antes de teorizar.**
- **`cmdkey /add:` no acepta la petición interactiva de contraseña** como sí hace `/generic:`.

## Granja con balanceo: autorizar el dominio, no el servidor

Con `use redirection server name:i:1` + `loadbalanceinfo`, el intermediario redirige a **otro**
servidor y Windows pide delegar hacia ESE nombre, que no está en la lista. Hay que guardar la
credencial y autorizar la delegación también con comodín:

```
TERMSRV/<host del rdp>        TERMSRV/<gateway>
TERMSRV/*.<dominio de la granja>    TERMSRV/*.<dominio del gateway>
```

## Herramienta que resolvió el caso: el espía de ventanas

Tras varias vueltas suponiendo, un script que solo apunta **proceso / clase / título** de cada
ventana que pasa a primer plano reveló que **antes** del cuadro de credenciales salía
`mstsc / #32770 / "Advertencia de seguridad de conexión a Escritorio remoto"`. Ese aviso era la
causa, no un adorno. Guardar el patrón: cuando algo "no detecta la ventana" o "sale un aviso raro",
que lo diga el equipo, no yo.

## Errores propios que costaron la mañana (no repetir)

- **Dar un script que se cierra en silencio al fallar.** Cada iteración se convirtió en adivinar.
  `try/catch` con mensaje, línea y `Read-Host` **desde el primer minuto**, antes que nada.
- **No llamar `R` a una función de PowerShell**: `R` es alias de `Invoke-History` y los alias tienen
  **prioridad sobre las funciones**. El diagnóstico no comprobó nada y el resumen decía "0 correctos,
  0 fallos → todo correcto". Un resumen debe distinguir "cero fallos" de "cero comprobaciones".
- **`HKCU\Software\Policies` solo lo escribe un administrador.** La parte de usuario va también en el
  bloque elevado, apuntando a `Registry::HKEY_USERS\<SID>` del usuario real (el admin del UAC puede
  ser otro).
- **Elevar escribiendo un `.ps1` en `%TEMP%` y lanzarlo con `-File` es escalada de privilegios**
  (otro proceso puede sustituirlo entre medias). Usar `-EncodedCommand`.
- Confirmado de nuevo: **`.rdp` en UTF-16LE que `sed` "edita" sin cambiar nada.** Aquí convivían los
  dos formatos en la misma entrega: unos ASCII y otro UTF-16. Detectar el BOM y respetarlo.

## Contexto que conviene recordar

Solo 3 usuarios contratados para ~10 personas. Y se probó que **no hace falta el doble salto** por
el servidor del cliente: la RemoteApp funciona directa desde el PC de cada usuario.

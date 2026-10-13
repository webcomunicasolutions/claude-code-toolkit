# Antivirus que bloquea una web nuestra recién publicada (falso positivo)

Caso real: un panel interno de un cliente (28-29/09/2026). El subdominio nuevo se publicó el 28/09 y al día
siguiente **Kaspersky lo bloqueaba en cualquier equipo**, en la oficina del cliente y en la del proveedor de TI:
«Dangerous – Phishing», **método de detección: bases de datos**. Se pidió la reclasificación por opentip a las ~15:50
del 29/09 y **a las 19:31 contestaron que la habían quitado de la lista negra: en unas 4 horas.** Úsalo en cualquier cliente.

## 1. Diagnóstico: ¿es la lista negra o la página?
- **«Método de detección: bases de datos»** → la URL está en la **lista negra** del antivirus. No ha visto nada malo
  en la página: la tiene marcada. Una excepción local puede no bastar y le pasa a CUALQUIER equipo con ese antivirus.
- Si el aviso habla de heurística o de un fichero concreto, es otra cosa: mirar qué sirve la página.
- **Descartar antes el DNS**: si parte de los equipos aún resuelven la IP vieja del dominio (p. ej. el hosting de la web
  principal), ese servidor presenta un certificado que no es del subdominio y el antivirus lo ve como ataque.
  `dig +short <sub>.<dominio> @8.8.8.8` y `@1.1.1.1` varias veces; todas deben dar la IP nueva.

## Por qué nos pasa (y qué lo dispara)
Dominio o subdominio **recién creado** + **formulario de login** + (en el caso real) unas horas con parte del DNS
apuntando al servidor viejo con otro certificado. Es el perfil exacto de una web de phishing, así que los
antivirus lo meten en su lista negra aunque la web sea legítima.

## 2. Lo que funciona YA (mientras tanto)
- **Desde la red del cliente, entrar por la IP local** (p. ej. `http://192.168.1.30:8090`): no pasa por el
  dominio y el antivirus no lo bloquea.
- **Excepción en el equipo (Kaspersky de casa: Standard/Plus/Premium)**:
  1. ⚙️ Ajustes → **Ajustes de seguridad** → **Protección contra amenazas web** («Antivirus para Internet» en
     algunas versiones) → **Configuración avanzada** → **Direcciones web de confianza**.
  2. Marcar **«No analizar el tráfico web de las direcciones web de confianza»**. Sin esa casilla la lista no sirve.
  3. Añadir el dominio **sin** `https://` y sin `/*`. Guardar.
  4. Si sigue igual, añadirlo también en la lista de confianza de **Navegación segura** / **Antiphishing**.
  5. Cerrar el navegador DEL TODO (también desde el icono junto al reloj) y volver a abrirlo.
- **Kaspersky de empresa** (Security Center / Endpoint Security Cloud): la excepción local se revierte. La pone
  quien administre la consola, en las **exclusiones de la directiva**.

## 3. El arreglo de fondo: pedir que lo saquen de la lista negra
1. Entrar en **https://opentip.kaspersky.com**, buscar el dominio. Si sale como peligroso, usar el formulario de
   reclasificación / falso positivo (en inglés). Captcha y **Submit**.
2. Contestan desde **newvirus@kaspersky.com** al correo que se ponga (un buzón del proveedor de TI). En
   el caso real: ~4 h. Suelen decir 1-3 días. Luego llega a los equipos **con la siguiente actualización de firmas**.
3. Si en una semana sigue marcado, insistir respondiendo al mismo ticket.

Texto que funcionó (adaptar nombres, fechas e IPs; no inventar nada que no sea cierto):
```
False positive. <sub.dominio> is the private internal web portal of <Empresa S.L.> (owner of <dominio>,
registered at <registrador>), used only by its own staff to <para qué>. It does not imitate any other brand
or service: it shows <Empresa>'s own logo and data.

The subdomain was created on <fecha> and points to <IP>, a reverse proxy operated by the company's IT provider,
<Proveedor de TI>. It has a valid Let's Encrypt certificate. Access requires username,
password and two-factor authentication (TOTP), with brute-force protection.

[Solo si pasó] For a few hours after it was created, part of the DNS resolvers still returned the old address
(<IP vieja>), which has no certificate for this subdomain. This is now fixed: all resolvers return <IP>.

Please reclassify it as safe. Contact: <correo del proveedor de TI>
```

## 4. Para que no pase (al publicar un dominio nuevo con login)
- **Crear el registro DNS con antelación** y no enseñar el login hasta que TODOS los resolvers den la IP nueva
  (bajar el TTL antes si el nombre ya existía apuntando a otro sitio).
- Certificado válido desde el primer minuto (Traefik/Let's Encrypt) y web con la **marca propia del cliente**.
- Nada más publicarlo, **buscarlo en opentip.kaspersky.com** (y en Google Safe Browsing:
  https://transparencyreport.google.com/safe-browsing/search). Si ya sale marcado, pedir la reclasificación ese día,
  antes de que el cliente lo encuentre bloqueado.
- Otros antivirus tienen su propio formulario de falsos positivos (ESET, Bitdefender, Microsoft Defender
  SmartScreen). ⬜ Sin caso real todavía: cuando pase, apuntar aquí cuál se usó y cuánto tardaron.

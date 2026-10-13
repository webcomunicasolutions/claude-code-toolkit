# Panel interno de gestion (primer caso, origen de la skill)

Web: PHP 8.2 + MySQL 8.4 en Docker sobre un NAS del cliente (LAN + VPN, sin HTTPS). 221 pruebas
funcionales en verde ANTES de la auditoria.

- Reparto: 2 agentes Sonnet en paralelo (seguridad adversarial ~5 min, pautas de estilo ~3 min) + yo en vivo.
  El de seguridad leyo 23 de 38 ficheros enteros; el resto por grep dirigido (lo declaro, bien).
- Encontrado y confirmado: formulas en CSV (8 razones sociales y 127 conceptos REALES empiezan por
  + / -), sin cabeceras anti-iframe. **Lo que el agente NO vio y yo si, en vivo**: CSRF con token vacio
  (POST sin token con sesion nueva → 200). Leccion: la fase 2 en vivo no es opcional; encuentra lo que la
  lectura de codigo pasa por alto.
- Falso positivo evitado: "display_errors no verificable" → comprobado en el contenedor (apagado).
- Pautas de estilo: 14/21. Incumplimientos de estilo (cabecera de autoria, iconos, franja lateral, 1 JS inline).
  Excepciones del responsable escritas en el CLAUDE.md del proyecto: CSV y no TSV, cabecera de autoria neutra.
- En el servidor: `nohup` no existe en TrueNAS (usar systemd-run); el .htaccess NO se toco (decision del responsable): las cabeceras van en PHP.
- Resultado: arnes 221 → 229 (8 comprobaciones nuevas), 2/2 en verde, desplegado con etiqueta de version,
  cabeceras y CSRF comprobados en produccion.

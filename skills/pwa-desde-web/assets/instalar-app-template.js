/**
 * PLANTILLA del aviso de instalacion de una PWA ("instalar como app").
 * Skill `pwa-desde-web`. Sustituir: {{NOMBRE_APP}}, {{ICONO}}, {{CLAVE}}, {{GUARDA_EXTRA}}.
 *
 * Version rodada en produccion en webs PHP clasicas con login por sesion.
 * Sustituye a la version anterior de esta plantilla (guardada como
 * `instalar-app-template.ANTERIOR.js`), que ESPERABA al evento del navegador en Android:
 * con aquella, el aviso casi nunca llegaba a salir.
 *
 * Se carga en las DOS paginas de entrada (login.php y paginas/index.php).
 *
 * DONDE NO SE OFRECE NUNCA (guardas, por orden de importancia):
 *   1. Mural de la tele (?tv=1)  -> una barra fija sobre el mural del local seria un desastre.
 *   2. Dentro de la APK Android  -> ya ES la app; ofrecer instalarla no tiene sentido.
 *   3. Ya instalada (standalone) -> idem.
 *   4. Pospuesta hace poco       -> no dar la lata en cada visita.
 *
 * POR QUE EN MOVIL SE PINTA SIEMPRE Y NO SE ESPERA AL EVENTO DEL NAVEGADOR:
 * Chrome dispara 'beforeinstallprompt' cuando LE PARECE (guarda el evento hasta que
 * considera que el usuario ha usado bastante la web), asi que esperarlo significaba que
 * el aviso no aparecia casi nunca. Ahora la barra se pinta sola en movil y, si al pulsar
 * todavia no ha llegado el evento, se enseñan los pasos a mano —que funcionan igual—.
 * En ESCRITORIO se mantiene el comportamiento anterior (solo si el navegador lo ofrece):
 * ahi no hay "pantalla de inicio" y el aviso seria ruido.
 *
 * Cada navegador se instala de una forma distinta, y dos de ellos NO PUEDEN:
 *   - iOS: Apple no implementa 'beforeinstallprompt'. Solo Safari añade a la pantalla de
 *     inicio; Chrome/Firefox/Edge de iPhone NO pueden -> se pide abrirla en Safari.
 *   - Firefox de Android: su "Añadir a la pantalla de inicio" crea un acceso directo que
 *     vuelve a abrirse DENTRO de Firefox; no es una app instalada -> se pide usar Chrome.
 */
(function () {
    'use strict';

    var CLAVE_POSPUESTO = '{{CLAVE}}_instalar_pospuesto';
    var DIAS_REPETIR = 30;              // si dice "ahora no", no volver a preguntar en 30 dias
    var RETRASO_MS = 2000;              // dejar que la pagina cargue antes de asomar el aviso

    // ---------- Guardas ----------

    // {{GUARDA_EXTRA}} — modos de pantalla fija del proyecto (mural, kiosco, TV).
    // Ejemplo: ?tv=1. Si el proyecto no tiene ninguno, devolver false.
    function modoSinAvisos() {
        return new URLSearchParams(window.location.search).get('tv') === '1';
    }

    function yaInstalada() {
        return window.matchMedia('(display-mode: standalone)').matches ||
               window.navigator.standalone === true ||             // iOS
               document.referrer.indexOf('android-app://') === 0;  // abierta desde la app instalada
    }

    // La APK de la tele es un WebView de Android: su user agent lleva "; wv)".
    function dentroDeWebView() {
        return /;\s*wv\)/i.test(navigator.userAgent);
    }

    // localStorage puede lanzar excepcion (modo privado, cookies bloqueadas): nunca romper por esto.
    function leerPospuesto() {
        try {
            return parseInt(window.localStorage.getItem(CLAVE_POSPUESTO) || '0', 10) || 0;
        } catch (e) {
            return 0;
        }
    }

    function recordarPospuesto() {
        try {
            window.localStorage.setItem(CLAVE_POSPUESTO, String(Date.now()));
        } catch (e) {
            /* sin persistencia: como mucho volvera a preguntar en la siguiente visita */
        }
    }

    function pospuestaHacePoco() {
        var cuando = leerPospuesto();
        return cuando > 0 && (Date.now() - cuando) < DIAS_REPETIR * 86400000;
    }

    // ---------- Que aparato y que navegador ----------

    function esMovil() {
        return /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent) ||
               window.matchMedia('(max-width: 820px)').matches;
    }

    // El iPad moderno se hace pasar por Mac: se le pilla porque tiene tactil.
    function esIos() {
        return /iPad|iPhone|iPod/.test(navigator.userAgent) ||
               (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
    }

    function esSafari() {
        var ua = navigator.userAgent;
        return /Safari/.test(ua) && !/CriOS|FxiOS|EdgiOS|OPiOS|Chrome/.test(ua);
    }

    function esFirefox() {
        return /Firefox|FxiOS/i.test(navigator.userAgent);
    }

    /** Que instrucciones tocan: 'ios' | 'ios-otro' | 'firefox' | 'android'. */
    function tipoDeGuia() {
        if (esIos()) return esSafari() ? 'ios' : 'ios-otro';
        if (esFirefox()) return 'firefox';
        return 'android';
    }

    // ---------- Barra ----------

    var eventoInstalacion = null;   // el 'beforeinstallprompt' guardado para usarlo al pulsar
    var caja = null;

    function construir() {
        var el = document.createElement('div');
        el.className = 'pwa-inst';
        el.setAttribute('role', 'dialog');
        el.setAttribute('aria-label', 'Instalar la aplicacion');

        el.innerHTML =
            // Icono SIMPLIFICADO (sin las lineas de texto pequeño del icono de la app): a los
            // 46px de esta barra, los subtitulos y lemas no se leen y ensucian.
            // El icono completo (con ambas marcas) sigue siendo el de la app instalada.
            '<img class="pwa-inst__ico" src="/img/icon-banner.png" alt="">' +
            '<div class="pwa-inst__txt">' +
                '<div class="pwa-inst__t">Instalar {{NOMBRE_APP}}</div>' +
                '<div class="pwa-inst__d">Acceso directo en tu pantalla de inicio, sin barra del navegador.</div>' +
            '</div>' +
            '<div class="pwa-inst__acc">' +
                '<button type="button" class="pwa-inst__ok">Instalar</button>' +
                '<button type="button" class="pwa-inst__no">Ahora no</button>' +
            '</div>';

        el.querySelector('.pwa-inst__ok').addEventListener('click', instalar);
        el.querySelector('.pwa-inst__no').addEventListener('click', function () {
            recordarPospuesto();
            ocultar();
        });
        return el;
    }

    function mostrar() {
        if (caja) return;
        caja = construir();
        document.body.appendChild(caja);
        // Un tick para que la transicion de entrada se vea (si se añade la clase en el mismo frame, no anima).
        window.requestAnimationFrame(function () {
            window.requestAnimationFrame(function () {
                if (caja) caja.classList.add('pwa-inst--visible');
            });
        });
    }

    function ocultar() {
        if (!caja) return;
        var salir = caja;
        caja = null;
        salir.classList.remove('pwa-inst--visible');
        window.setTimeout(function () {
            if (salir.parentNode) salir.parentNode.removeChild(salir);
        }, 300);
    }

    function instalar() {
        if (!eventoInstalacion) {
            // Aun no ha llegado el evento (o este navegador no lo tiene): pasos a mano.
            mostrarPasos();
            return;
        }
        var evento = eventoInstalacion;
        eventoInstalacion = null;       // el evento se consume: solo se puede usar UNA vez
        evento.prompt();
        evento.userChoice.then(function (eleccion) {
            if (eleccion.outcome !== 'accepted') recordarPospuesto();
            ocultar();
        }).catch(function () {
            ocultar();
        });
    }

    // ---------- Pasos a mano (cuando el navegador no instala por codigo) ----------

    var ICONO_COMPARTIR =
        '<svg class="pwa-pasos__ic" width="17" height="17" viewBox="0 0 24 24" fill="none" ' +
        'stroke="currentColor" stroke-width="2" aria-hidden="true">' +
        '<path d="M12 16V4M12 4L8 8M12 4l4 4"/>' +
        '<path d="M5 14v5a1 1 0 001 1h12a1 1 0 001-1v-5"/></svg>';

    /** Texto de cada caso. Devuelve {titulo, sub, pasos:[], url:bool}. */
    function guion(tipo) {
        if (tipo === 'ios') {
            return {
                titulo: 'Instalar en el iPhone',
                sub: 'Apple no deja instalarla de un toque. Son tres pasos:',
                pasos: [
                    'Pulsa <b>Compartir</b> ' + ICONO_COMPARTIR + ' en la barra de abajo de Safari',
                    'Baja y pulsa <b>Añadir a pantalla de inicio</b>',
                    'Pulsa <b>Añadir</b> arriba a la derecha'
                ],
                url: false
            };
        }
        if (tipo === 'ios-otro') {
            return {
                titulo: 'Ábrela en Safari',
                sub: 'En el iPhone solo Safari puede añadir la app a la pantalla de inicio. Chrome, Firefox y Edge no pueden.',
                pasos: [
                    'Copia la direccion con el boton de abajo',
                    'Abre <b>Safari</b>',
                    'Pegala y pulsa <b>Compartir</b> ' + ICONO_COMPARTIR + ' &rarr; <b>Añadir a pantalla de inicio</b>'
                ],
                url: true
            };
        }
        if (tipo === 'firefox') {
            return {
                titulo: 'Ábrela en Chrome',
                sub: 'Firefox no instala la aplicacion: su acceso directo vuelve a abrirse dentro de Firefox.',
                pasos: [
                    'Copia la direccion con el boton de abajo',
                    'Abre <b>Chrome</b>',
                    'Pegala y pulsa <b>Instalar</b> en el aviso de abajo'
                ],
                url: true
            };
        }
        return {
            titulo: 'Instalar {{NOMBRE_APP}}',
            sub: 'Si no ha salido el aviso del navegador, son tres pasos:',
            pasos: [
                'Abre el menu del navegador <b>(⋮)</b> arriba a la derecha',
                'Pulsa <b>Instalar aplicacion</b> o <b>Añadir a pantalla de inicio</b>',
                'Confirma pulsando <b>Instalar</b>'
            ],
            url: false
        };
    }

    function mostrarPasos() {
        if (document.getElementById('pwa-pasos')) return;
        var g = guion(tipoDeGuia());

        var capa = document.createElement('div');
        capa.id = 'pwa-pasos';
        capa.className = 'pwa-pasos';
        capa.setAttribute('role', 'dialog');
        capa.setAttribute('aria-label', g.titulo);

        var lista = '';
        for (var i = 0; i < g.pasos.length; i++) lista += '<li>' + g.pasos[i] + '</li>';

        capa.innerHTML =
            '<div class="pwa-pasos__caja">' +
                '<h3 class="pwa-pasos__t">' + g.titulo + '</h3>' +
                '<p class="pwa-pasos__sub">' + g.sub + '</p>' +
                '<ol class="pwa-pasos__ol">' + lista + '</ol>' +
                (g.url
                    ? '<div class="pwa-pasos__url" id="pwa-pasos-url">' + window.location.origin + '</div>' +
                      '<button type="button" class="pwa-pasos__copiar">Copiar la direccion</button>'
                    : '') +
                '<button type="button" class="pwa-pasos__cerrar">Entendido</button>' +
            '</div>';
        document.body.appendChild(capa);

        var copiar = capa.querySelector('.pwa-pasos__copiar');
        if (copiar) copiar.addEventListener('click', function () {
            var texto = window.location.origin;
            var hecho = function () { copiar.textContent = 'Direccion copiada'; };
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(texto).then(hecho, seleccionarUrl);
            } else {
                seleccionarUrl();
            }
        });

        // Sin portapapeles (http, permisos denegados): al menos dejar el texto seleccionado.
        function seleccionarUrl() {
            var el = document.getElementById('pwa-pasos-url');
            if (!el) return;
            var rango = document.createRange();
            rango.selectNodeContents(el);
            var sel = window.getSelection();
            sel.removeAllRanges();
            sel.addRange(rango);
        }

        capa.addEventListener('click', function (e) {
            if (e.target === capa || e.target.classList.contains('pwa-pasos__cerrar')) {
                capa.parentNode.removeChild(capa);
            }
        });
    }

    // ---------- Arranque ----------

    if (modoSinAvisos() || yaInstalada() || dentroDeWebView() || pospuestaHacePoco()) return;

    // Chromium (Android, Chrome/Edge de escritorio). El preventDefault quita el aviso
    // diminuto del navegador y nos deja a nosotros el control de cuando enseñarlo.
    window.addEventListener('beforeinstallprompt', function (e) {
        e.preventDefault();
        eventoInstalacion = e;
        mostrar();                      // en escritorio, esta es la UNICA via
    });

    window.addEventListener('appinstalled', function () {
        recordarPospuesto();            // instalada: no volver a ofrecerlo en el navegador
        ocultar();
    });

    // En movil no se espera al navegador: se ofrece siempre (ver cabecera).
    if (esMovil()) {
        window.setTimeout(mostrar, RETRASO_MS);
    }
})();

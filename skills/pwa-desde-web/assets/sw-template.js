/* Service worker — PWA de cascaron sobre web existente.
 * Regla de oro: cachear SOLO el "cascaron" estatico (CSS/JS/imagenes/fuentes) para que la app
 * abra rapido e instalable; NUNCA cachear los datos (ajustar prefijos abajo), que siempre
 * van a la red — si no, la app mostraria datos viejos.
 * Las paginas (login/panel) van network-first para no romper la sesion. */
const CACHE = 'PROYECTO-pwa-v1'; // subir version para invalidar todo lo cacheado

// AJUSTAR: prefijos de endpoints de datos del proyecto (nunca se cachean)
const DATOS = ['/api/', '/interno/'];

self.addEventListener('install', (e) => {
  // Activa la nueva version sin esperar a que se cierren las pestañas viejas.
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (e) => {
  const req = e.request;
  if (req.method !== 'GET') return;                       // POST (guardados) siempre a la red
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;        // CDN: no tocar
  if (DATOS.some((p) => url.pathname.startsWith(p))) return; // datos: solo red

  // Estaticos: stale-while-revalidate (rapido y se refresca en segundo plano)
  if (/\.(css|js|png|jpg|jpeg|svg|webp|ico|woff2?)$/.test(url.pathname)) {
    e.respondWith(staleWhileRevalidate(req));
    return;
  }
  // Navegacion: network-first, con la cache como red de seguridad si no hay conexion
  if (req.mode === 'navigate') {
    e.respondWith(networkFirst(req));
    return;
  }
});

async function staleWhileRevalidate(req) {
  const cache = await caches.open(CACHE);
  const cached = await cache.match(req);
  const fetching = fetch(req).then((res) => {
    if (res && res.ok) cache.put(req, res.clone());
    return res;
  }).catch(() => cached);
  return cached || fetching;
}

async function networkFirst(req) {
  const cache = await caches.open(CACHE);
  try {
    const res = await fetch(req);
    if (res && res.ok) cache.put(req, res.clone());
    return res;
  } catch (err) {
    const cached = await cache.match(req);
    if (cached) return cached;
    throw err;
  }
}

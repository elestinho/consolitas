/* Consolitas: modo sin conexión.
   Guarda la app, JSZip y lo que descarga EmulatorJS (cargador, núcleos, descompresor…) en una caché propia.
   Siempre se pide primero a la red, así las versiones nuevas de la app y del emulador llegan igual que antes;
   solo si no hay conexión (o tarda demasiado) se sirve lo guardado. Las ROMs y partidas siguen en IndexedDB. */
var CACHE = 'consolitas-offline';
var EJS = 'https://cdn.emulatorjs.org/stable/data/';
var JSZIP = 'https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js';
var SCOPE = self.registration.scope;                                  // …/consolitas/
var PRECACHE = [SCOPE, JSZIP, EJS + 'loader.js', EJS + 'emulator.min.js', EJS + 'emulator.min.css', EJS + 'compression/extract7z.js'];
var SLOW = 5000;                                                      // con caché, no se espera más a una red lenta

self.addEventListener('install', function (e) {
  e.waitUntil(caches.open(CACHE).then(function (c) {
    return Promise.all(PRECACHE.map(function (u) { return save(c, u, fresh(u)).catch(function () {}); }));
  }).then(function () { return self.skipWaiting(); }));
});
self.addEventListener('activate', function (e) { e.waitUntil(self.clients.claim()); });

function isApp(url) { return url.indexOf(SCOPE) === 0 && /^(index\.html)?$/.test(url.slice(SCOPE.length).split(/[?#]/)[0]); }
function keyOf(url) { return isApp(url) ? SCOPE : url.split('#')[0]; }
function fresh(url, mode) { return fetch(url, { mode: 'cors', credentials: 'omit', cache: mode || 'no-cache' }); }
function save(c, url, p) {
  return p.then(function (r) {
    if (r && r.ok && r.status === 200) c.put(keyOf(url), r.clone()).catch(function () {});
    return r;
  });
}

function offline(r) {                                                 // la app servida desde la caché lo dice (para «Buscar actualización»)
  var h = new Headers(r.headers); h.set('X-Consolitas-Offline', '1');
  return new Response(r.body, { status: r.status, statusText: r.statusText, headers: h });
}

self.addEventListener('fetch', function (e) {
  var req = e.request, url = req.url;
  if (req.method !== 'GET') return;
  var app = isApp(url) || (req.mode === 'navigate' && url.indexOf(SCOPE) === 0);
  if (!app && url.indexOf(EJS) !== 0 && url !== JSZIP) return;       // portadas, skins, juegos gratis…: como siempre
  e.respondWith(caches.open(CACHE).then(function (c) {
    var key = app ? SCOPE : keyOf(url);
    return c.match(key, { ignoreSearch: app, ignoreVary: true }).then(function (hit) {
      // La app se pide tal cual (respeta el modo de caché de «Buscar actualización»); lo de fuera, con CORS para poder guardarlo
      var net = save(c, key, app ? fetch(req) : fresh(url, req.cache === 'default' ? 'default' : req.cache).catch(function () { return fetch(req); }));
      if (!hit) return net;
      if (app) hit = offline(hit);
      net.catch(function () {});
      return new Promise(function (ok) {
        var t = setTimeout(function () { ok(hit); }, SLOW);
        net.then(function (r) { clearTimeout(t); ok(r.ok ? r : hit); }, function () { clearTimeout(t); ok(hit); });
      });
    });
  }));
});

const CACHE_NAME = 'nibex-v1';
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/app.js',
  '/styles.css',
  '/manifest.json'
];

// Install — cache static assets
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(STATIC_ASSETS))
  );
  self.skipWaiting();
});

// Activate — clean old caches
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// Fetch — offline-first for static assets, network-first for API calls
self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);

  // API calls — network first, no cache
  if (url.hostname.includes('supabase.co') || url.hostname.includes('anthropic.com')) {
    event.respondWith(fetch(event.request).catch(() => new Response(
      JSON.stringify({ error: 'offline' }),
      { headers: { 'Content-Type': 'application/json' } }
    )));
    return;
  }

  // Static assets — cache first, network fallback
  event.respondWith(
    caches.match(event.request).then(cached => {
      if (cached) return cached;
      return fetch(event.request).then(response => {
        if (response.ok) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(event.request, clone));
        }
        return response;
      });
    })
  );
});

// Background sync — queue failed writes and retry when online
self.addEventListener('sync', event => {
  if (event.tag === 'nibex-sync') {
    event.waitUntil(syncPendingWrites());
  }
});

async function syncPendingWrites() {
  // Implemented in app.js — service worker signals readiness
  const clients = await self.clients.matchAll();
  clients.forEach(client => client.postMessage({ type: 'SYNC_READY' }));
}

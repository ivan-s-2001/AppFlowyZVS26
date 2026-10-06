const CACHE = "zvs26-full-web-v1";
const SHELL = ["/", "/app", "/manifest.webmanifest", "/zvs26-icon.svg"];

self.addEventListener("install", (event) => {
  event.waitUntil(caches.open(CACHE).then((cache) => cache.addAll(SHELL)));
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key))),
    ),
  );
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  const request = event.request;
  if (request.method !== "GET") return;

  const url = new URL(request.url);

  // Never cache API/auth/websocket traffic.
  if (
    url.pathname.startsWith("/api/") ||
    url.pathname.startsWith("/gotrue/") ||
    url.pathname.startsWith("/ws/")
  ) {
    return;
  }

  event.respondWith(
    fetch(request)
      .then((response) => {
        if (response.ok && url.origin === self.location.origin) {
          const copy = response.clone();
          caches.open(CACHE).then((cache) => cache.put(request, copy));
        }
        return response;
      })
      .catch(async () => {
        return (
          (await caches.match(request)) ||
          (await caches.match("/app")) ||
          (await caches.match("/"))
        );
      }),
  );
});

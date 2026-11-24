/* TiradA anon — service worker.
   Two jobs: (1) a minimal shell cache so the app still opens offline;
   (2) Web Push — show the notification and open the app on tap.
   EVERY same-origin GET is network-first (v19): the cache is only an
   offline fallback, never a source of truth. The old
   stale-while-revalidate branch served the previous release's files
   on the first load after every deploy — and for the four UNVERSIONED
   scripts (maplibre-gl.js, map-style.js, vendor-supabase.js,
   supabase.js) "previous release" could mean arbitrarily old code
   stitched into a new page. All first-party assets are ?v=-versioned
   since v19 as well; network-first makes the mix impossible, the
   version query makes it detectable, and the build guard in app.js
   heals a pair that still slips through. Cross-origin traffic
   (Supabase, map tiles, emoji CDN) is never touched. */
var CACHE = "tirada-shell-v34";

self.addEventListener("install", function (e) {
  self.skipWaiting();
});

self.addEventListener("activate", function (e) {
  e.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(keys.map(function (k) {
        if (k !== CACHE) return caches.delete(k);
      }));
    }).then(function () { return self.clients.claim(); })
  );
});

self.addEventListener("fetch", function (e) {
  var req = e.request;
  if (req.method !== "GET") return;
  var url = new URL(req.url);
  if (url.origin !== self.location.origin) return;
  /* Network-first for navigations AND assets alike: a fresh response
     always wins and refreshes the offline copy; the cache answers
     only when the network is gone. */
  e.respondWith(
    fetch(req).then(function (res) {
      if (res && res.ok) {
        var copy = res.clone();
        caches.open(CACHE).then(function (c) { c.put(req, copy); });
      }
      return res;
    }).catch(function () { return caches.match(req); })
  );
});

self.addEventListener("push", function (e) {
  var data = { title: "TiradA anon 👻", body: "Что-то новенькое в городе", url: "./index.html#profile" };
  if (e.data) {
    try {
      var j = e.data.json();
      if (j.title) data.title = j.title;
      if (j.body) data.body = j.body;
      if (j.url) data.url = j.url;
    } catch (err) {
      try { data.body = e.data.text(); } catch (e2) { /* keep default */ }
    }
  }
  e.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: "icon-192.png",
      badge: "icon-192.png",
      data: { url: data.url }
    })
  );
});

self.addEventListener("notificationclick", function (e) {
  e.notification.close();
  var target = (e.notification.data && e.notification.data.url) || "./index.html#profile";
  e.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then(function (list) {
      for (var i = 0; i < list.length; i++) {
        if ("focus" in list[i]) {
          if (list[i].navigate) {
            try {
              var p = list[i].navigate(target);
              if (p && p.catch) p.catch(function () {});
            } catch (err) { /* older engines: focus is enough */ }
          }
          return list[i].focus();
        }
      }
      if (self.clients.openWindow) return self.clients.openWindow(target);
    })
  );
});

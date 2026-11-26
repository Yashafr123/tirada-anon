// TiradA anon — send-fcm: real FCM pushes via HTTP v1 API.
// =====================================================================
// v2.0.26: TWO auth paths.
//
// Path 1 — server/webhook (unchanged): header x-webhook-secret must
//   equal env WEBHOOK_SECRET (same as send-push). Body:
//   { user_ids?: string[], tokens?: string[], title: string,
//     body: string, type?: string, data?: Record<string,string> }
//   The caller composes the text and names the recipients.
//
// Path 2 — client event calls (NEW): Authorization: Bearer <the
//   signed-in user's Supabase JWT>. The app NEVER sees the webhook
//   secret; it only reports an event, and this function validates
//   it against the database before composing anything itself:
//     { event: 'ping', ping_id } — a pings row must exist with
//       from_id == caller and created_at within 15 min. Recipient
//       is the row's to_id; title is the sender's display name
//       («Призрак» when the sender's mode is 'ghost'); body is
//       «Прислал тебе привет» / «Прислал тебе стикер» by kind.
//     { event: 'checkin_photo', photo_id, place_name } — a
//       place_photos row must exist with user_id == caller,
//       created_at within 15 min, visibility 'public' or 'friends'
//       («Не показывать» creates no row, so it can never push).
//     { event: 'checkin', place_id, place_name } — the plain
//       «Я здесь» check-in has no row of its own: the JWT is the
//       signature. The sender's name/mode come from the caller's
//       own profile, a fresh profile_locations row (<= 20 min) is
//       required as proof of a live presence session, and mode
//       'offline' («Невидимка») is refused outright.
//   Check-in text: title = place name (place names are never
//   translated), body = «<name> зашёл в «<place>»» with «Призрак»
//   for a ghost sender. Check-in recipients: every registered
//   user except the sender (the app's one-system model: everyone
//   is in everyone's list). Client-supplied title/body/user_ids
//   are IGNORED on this path — a client can never push in someone
//   else's name or to an audience the event doesn't justify.
//
// DEPLOY (parent, manual): replace the send-fcm function source
//   with this file and deploy, e.g.
//     supabase functions deploy send-fcm
//   or paste into the Supabase Dashboard editor (project
//   qrlyuvnfkrufnnladclf → Edge Functions → send-fcm). No new
//   secrets: WEBHOOK_SECRET and FCM_SERVICE_ACCOUNT_JSON stay as
//   they are; SUPABASE_URL / SUPABASE_ANON_KEY /
//   SUPABASE_SERVICE_ROLE_KEY are auto-injected. The v2.0.26 app
//   degrades gracefully until this is deployed (its event calls
//   are fire-and-forget; the old function answers them 401).
//
// Secrets used: FCM_SERVICE_ACCOUNT_JSON, WEBHOOK_SECRET.
// Dedupe: same (user, title, body) within 6h is skipped (push_log),
// like send-push.
// =====================================================================

const WEBHOOK_SECRET = Deno.env.get("WEBHOOK_SECRET") ?? "";
const SA_RAW = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? SERVICE_KEY;

const EVENT_WINDOW_MS = 15 * 60 * 1000; // ping / check-in row freshness
const PRESENCE_WINDOW_MS = 20 * 60 * 1000; // live-presence proof

let tokenCache: { token: string; exp: number } | null = null;

function b64url(data: ArrayBuffer | Uint8Array | string): string {
  let bytes: Uint8Array;
  if (typeof data === "string") bytes = new TextEncoder().encode(data);
  else if (data instanceof Uint8Array) bytes = data;
  else bytes = new Uint8Array(data);
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

async function getAccessToken(sa: { client_email: string; private_key: string }): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (tokenCache && tokenCache.exp > now + 60) return tokenCache.token;
  const pem = sa.private_key.replace(/-----BEGIN PRIVATE KEY-----/, "").replace(/-----END PRIVATE KEY-----/, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey("pkcs8", der, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now, exp: now + 3600,
  }));
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(`${header}.${claims}`));
  const jwt = `${header}.${claims}.${b64url(sig)}`;
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  const json = await res.json();
  if (!res.ok || !json.access_token) throw new Error("oauth failed: " + JSON.stringify(json).slice(0, 200));
  tokenCache = { token: json.access_token, exp: now + (json.expires_in ?? 3600) };
  return tokenCache.token;
}

async function rest(path: string, init: RequestInit = {}): Promise<any> {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...init,
    headers: {
      apikey: SERVICE_KEY,
      Authorization: `Bearer ${SERVICE_KEY}`,
      "Content-Type": "application/json",
      ...(init.headers ?? {}),
    },
  });
  const text = await res.text();
  try { return JSON.parse(text); } catch { return text; }
}

/* Validate a user JWT (Path 2) and return the caller's user id. */
async function callerFromJwt(req: Request): Promise<string | null> {
  const auth = req.headers.get("Authorization") ?? "";
  if (!auth.startsWith("Bearer ")) return null;
  try {
    const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: { apikey: ANON_KEY, Authorization: auth },
    });
    if (!res.ok) return null;
    const user = await res.json();
    return typeof user?.id === "string" ? user.id : null;
  } catch {
    return null;
  }
}

type Target = { userId: string | null; token: string };

async function deliver(
  sa: { project_id: string; client_email: string; private_key: string },
  targets: Target[],
  title: string,
  body: string,
  type: string,
  data: Record<string, string>,
): Promise<Response> {
  if (!targets.length) return Response.json({ sent: 0, skipped: 0, failed: 0, note: "no tokens", diag: lastTokenReadDiag });
  const access = await getAccessToken(sa);
  let sent = 0, skipped = 0, failed = 0;
  const errors: string[] = [];

  for (const tg of targets) {
    if (tg.userId) {
      const since = new Date(Date.now() - 6 * 3600 * 1000).toISOString();
      const dup = await rest(
        `push_log?select=id&user_id=eq.${tg.userId}&title=eq.${encodeURIComponent(title)}&body=eq.${encodeURIComponent(body)}&created_at=gte.${since}&limit=1`,
      );
      if (Array.isArray(dup) && dup.length) { skipped++; continue; }
    }
    const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
      method: "POST",
      headers: { Authorization: `Bearer ${access}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        message: {
          token: tg.token,
          notification: { title, body },
          data: { type, ...data },
          android: { priority: "high" },
        },
      }),
    });
    const json = await res.json().catch(() => ({}));
    if (res.ok) {
      sent++;
      if (tg.userId) {
        await rest("push_log", {
          method: "POST",
          headers: { Prefer: "return=minimal" },
          body: JSON.stringify({ user_id: tg.userId, title, body }),
        }).catch(() => {});
      }
    } else {
      failed++;
      const code = json?.error?.details?.[0]?.errorCode ?? json?.error?.status ?? "unknown";
      errors.push(String(code));
      if (code === "UNREGISTERED" || code === "INVALID_ARGUMENT") {
        await rest(`device_tokens?token=eq.${encodeURIComponent(tg.token)}`, { method: "DELETE" }).catch(() => {});
      }
    }
  }
  return Response.json({ sent, skipped, failed, errors: errors.slice(0, 5) });
}

/* v3 diagnostic: WHY the last device_tokens read returned what it
   did — surfaced in deliver()'s empty-targets response so a broken
   service-role read names itself instead of posing as "no tokens"
   (2026-11-26: rows provably existed while the function saw none). */
let lastTokenReadDiag: string | null = null;

async function targetsForUsers(userIds: string[]): Promise<Target[]> {
  if (!userIds.length) return [];
  const rows = await rest(`device_tokens?select=user_id,token&user_id=in.(${userIds.join(",")})`);
  const targets: Target[] = [];
  if (Array.isArray(rows)) {
    for (const r of rows) targets.push({ userId: r.user_id, token: r.token });
    lastTokenReadDiag = `ok rows=${rows.length}`;
  } else {
    lastTokenReadDiag = `read_failed: ${JSON.stringify(rows).slice(0, 240)}`;
    console.error("TiradA send-fcm device_tokens read failed:", lastTokenReadDiag);
  }
  return targets;
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function freshEnough(iso: unknown, windowMs: number): boolean {
  const t = typeof iso === "string" ? Date.parse(iso) : NaN;
  return Number.isFinite(t) && Date.now() - t <= windowMs && t <= Date.now() + 60 * 1000;
}

async function senderProfile(userId: string): Promise<{ name: string; mode: string } | null> {
  const rows = await rest(`profiles?select=name,mode&id=eq.${userId}&limit=1`);
  if (!Array.isArray(rows) || !rows.length) return null;
  return { name: String(rows[0].name ?? ""), mode: String(rows[0].mode ?? "visible") };
}

/* Display name that never leaks a hidden identity: a ghost is
   «Призрак», exactly as every in-app surface masks him. */
function displayName(p: { name: string; mode: string }): string {
  return p.mode === "ghost" || !p.name ? "Призрак" : p.name;
}

async function allOtherUserIds(callerId: string): Promise<string[]> {
  const rows = await rest(`profiles?select=id&id=neq.${callerId}&limit=500`);
  if (!Array.isArray(rows)) return [];
  return rows.map((r: any) => String(r.id)).filter((id) => UUID_RE.test(id));
}

function cleanPlaceName(v: unknown): string {
  return typeof v === "string" ? v.trim().slice(0, 80) : "";
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("method not allowed", { status: 405 });
  if (!SA_RAW) return Response.json({ error: "FCM_SERVICE_ACCOUNT_JSON not set" }, { status: 500 });
  const sa = JSON.parse(SA_RAW);
  const payload = await req.json().catch(() => ({} as any));

  // ---- Path 1: webhook secret (server callers, unchanged) ----
  if (WEBHOOK_SECRET && req.headers.get("x-webhook-secret") === WEBHOOK_SECRET) {
    const { user_ids = [], tokens = [], title, body, type = "general", data = {} } = payload;
    if (!title || !body) return Response.json({ error: "title and body required" }, { status: 400 });
    const targets: Target[] = (tokens as string[]).map((t) => ({ userId: null, token: t }));
    targets.push(...await targetsForUsers(user_ids as string[]));
    return deliver(sa, targets, title, body, type, data);
  }

  // ---- Path 2: signed-in user's JWT (client event calls) ----
  const caller = await callerFromJwt(req);
  if (!caller) return new Response("unauthorized", { status: 401 });
  const event = String(payload?.event ?? "");

  if (event === "ping") {
    const pingId = String(payload?.ping_id ?? "");
    if (!UUID_RE.test(pingId)) return Response.json({ error: "bad ping_id" }, { status: 400 });
    const rows = await rest(`pings?select=id,from_id,to_id,kind,place_name,created_at&id=eq.${pingId}&limit=1`);
    const ping = Array.isArray(rows) ? rows[0] : null;
    if (!ping) return Response.json({ sent: 0, note: "ping not found" });
    if (ping.from_id !== caller) return new Response("forbidden", { status: 403 });
    if (!freshEnough(ping.created_at, EVENT_WINDOW_MS)) {
      return Response.json({ sent: 0, note: "ping too old" });
    }
    const sender = await senderProfile(caller);
    if (!sender) return Response.json({ sent: 0, note: "no sender profile" });
    const title = displayName(sender);
    // v4 (2.0.28): kind 'invite' carries a place — «Приглашает тебя в …».
    const body = ping.kind === "sticker"
      ? "Прислал тебе стикер"
      : ping.kind === "invite"
        ? `Приглашает тебя в «${String(ping.place_name ?? "").slice(0, 80)}»`
        : "Прислал тебе привет";
    const targets = await targetsForUsers([String(ping.to_id)]);
    return deliver(sa, targets, title, body, "ping",
      { ping_id: pingId, from_id: caller });
  }

  if (event === "checkin_photo" || event === "checkin") {
    const placeName = cleanPlaceName(payload?.place_name);
    if (!placeName) return Response.json({ error: "place_name required" }, { status: 400 });
    const sender = await senderProfile(caller);
    if (!sender) return Response.json({ sent: 0, note: "no sender profile" });
    if (sender.mode === "offline") {
      // «Невидимка» never announces himself — refused server-side
      // even if a client asks.
      return Response.json({ sent: 0, note: "sender hidden" });
    }
    let placeId = "";
    if (event === "checkin_photo") {
      const photoId = String(payload?.photo_id ?? "");
      if (!UUID_RE.test(photoId)) return Response.json({ error: "bad photo_id" }, { status: 400 });
      const rows = await rest(
        `place_photos?select=id,user_id,place_id,visibility,created_at&id=eq.${photoId}&limit=1`);
      const photo = Array.isArray(rows) ? rows[0] : null;
      if (!photo) return Response.json({ sent: 0, note: "photo not found" });
      if (photo.user_id !== caller) return new Response("forbidden", { status: 403 });
      if (!freshEnough(photo.created_at, EVENT_WINDOW_MS)) {
        return Response.json({ sent: 0, note: "check-in too old" });
      }
      if (photo.visibility !== "public" && photo.visibility !== "friends") {
        return Response.json({ sent: 0, note: "check-in not shared" });
      }
      placeId = String(photo.place_id ?? "");
    } else {
      // Plain «Я здесь»: no row exists — the JWT is the signature,
      // and a live presence row proves the caller's app is actually
      // out there right now.
      placeId = String(payload?.place_id ?? "").slice(0, 64);
      const rows = await rest(
        `profile_locations?select=updated_at&user_id=eq.${caller}&limit=1`);
      const loc = Array.isArray(rows) ? rows[0] : null;
      if (!loc || !freshEnough(loc.updated_at, PRESENCE_WINDOW_MS)) {
        return Response.json({ sent: 0, note: "no live presence" });
      }
    }
    const name = displayName(sender);
    // v5 (2.0.28): the PERSON is the headline, the place is the text —
    // owner: a check-in push titled just «Макдональдс» didn't tell the
    // friend that HE is there. Body wording is his: «находится в …».
    const body = `Находится в «${placeName}»`;
    const recipients = await allOtherUserIds(caller);
    const targets = await targetsForUsers(recipients);
    return deliver(sa, targets, name, body, "checkin",
      { place_id: placeId, from_id: caller });
  }

  return Response.json({ error: "unknown event" }, { status: 400 });
});

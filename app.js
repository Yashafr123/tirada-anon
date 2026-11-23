/* ===== TiradA anon — preview v2 (demo data, all Israel) ===== */
(function(){
"use strict";

/* ================= i18n (v16) =================
   The app follows the phone language: he/iw -> Hebrew (RTL), en -> English,
   everything else -> Russian (the source language). A manual choice in
   Profile -> Settings (gear), or the language picked at sign-up, beats the
   auto detection; "auto" follows navigator.language. UI strings are keyed
   by their Russian source text in window.I18N_UI; content arrays (types,
   tasks, quests, levels, generated place names) live in I18N_CONTENT;
   plural forms in PLURALS_I18N (see js/i18n.js). */
function navLang(){
  var nav = "";
  try { nav = (navigator.languages && navigator.languages[0]) || navigator.language || ""; } catch(e){}
  nav = String(nav).toLowerCase();
  if (nav.indexOf("he") === 0 || nav.indexOf("iw") === 0) return "he";
  if (nav.indexOf("en") === 0) return "en";
  return "ru";
}
function langChoiceGet(){
  try { var v = localStorage.getItem("tirada_lang_choice"); if (v === "auto" || v === "ru" || v === "he" || v === "en") return v; } catch(e){}
  return "auto";
}
var LANG_CHOICE = langChoiceGet();
var LANG = LANG_CHOICE === "auto" ? navLang() : LANG_CHOICE;
function t(s){
  if (LANG === "ru" || typeof s !== "string") return s;
  var d = (typeof I18N_UI !== "undefined") && I18N_UI[LANG];
  return (d && d[s]) || s;
}
function tf(s, vals){
  var out = t(s);
  if (vals) for (var k in vals) out = out.split("{" + k + "}").join(String(vals[k]));
  return out;
}
function pl(n, key){
  var P = (typeof PLURALS_I18N !== "undefined") && PLURALS_I18N[key];
  if (!P) return "";
  if (LANG === "ru") return pluralRu(n, P.ru);
  var f = P[LANG] || P.en;
  return n === 1 ? f[0] : f[1];
}
function cityName(c){
  if (!c) return "";
  if (LANG !== "ru" && typeof CITY_NAMES_I18N !== "undefined" && CITY_NAMES_I18N[LANG] && CITY_NAMES_I18N[LANG][c.id]) return CITY_NAMES_I18N[LANG][c.id];
  return c.name;
}
function contentI18n(){ return (LANG !== "ru" && typeof I18N_CONTENT !== "undefined" && I18N_CONTENT[LANG]) || null; }
function typeLabel(k){ var C = contentI18n(); return (C && C.TYPES && C.TYPES[k] && C.TYPES[k].label) || TYPES[k].label; }
function typeTags(k){ var C = contentI18n(); return (C && C.TYPES && C.TYPES[k] && C.TYPES[k].tags) || TYPES[k].tags; }
function typeTasks(k){ var C = contentI18n(); return (C && C.TYPES && C.TYPES[k] && C.TYPES[k].tasks) || TYPES[k].tasks; }
function applyLang(){
  document.documentElement.lang = LANG;
  document.documentElement.dir = LANG === "he" ? "rtl" : "ltr";
}
function setLangChoice(choice, skipCloud){
  LANG_CHOICE = choice;
  try { localStorage.setItem("tirada_lang_choice", choice); } catch(e){}
  LANG = choice === "auto" ? navLang() : choice;
  applyLang();
  if (!skipCloud && typeof cloudSaveLang === "function") cloudSaveLang();
  if (typeof refreshI18n === "function") refreshI18n();
}
applyLang();

/* ================= Boot diagnostics & build guard (v19) =================
   Why this exists: on the v18 prod, a returning user's first load could
   come up with every boot surface dead (counter stuck on "…", empty
   ticker, empty city list, blank avatar, empty map) while the SAME
   functions worked fine when triggered by taps — and a clean-room
   jsdom boot with the same files and every legacy storage state stayed
   alive. The one layer no lab here can reproduce is the phone's own
   cache stack (service worker + HTTP cache) stitching files from
   different releases into one page. So v19 (1) stamps the build into
   the HTML itself and self-heals a mismatched pair, and (2) records
   the whole boot — step by step — into localStorage
   "tirada_boot_errors", rendered readably by the «Диагностика
   запуска» block in the About sheet, so the next failure is readable
   from a screenshot instead of a DevTools session nobody can open. */
var APP_BUILD = "29";
function tracePush(kind, msg){
  try { if (typeof window.__tiradaTrace === "function"){ window.__tiradaTrace(kind, msg); return; } } catch(e){}
  try {
    var a = lsGet("tirada_boot_errors", []);
    if (!Array.isArray(a)) a = [];
    a.push({ t: Date.now(), b: window.__tiradaBootId || 0, kind: String(kind), msg: String(msg == null ? "" : msg).slice(0, 300) });
    if (a.length > 40) a = a.slice(a.length - 40);
    lsSet("tirada_boot_errors", a);
  } catch(e){}
}
/* bootStep and its result arrays live HERE, at the top (v22), not next
   to the boot calls at the bottom of the file. repaintCoreSurfaces()
   revives dead surfaces by calling bootStep(), and repaint is invoked
   from promise handlers (auth-settled, profile-applied) — in v21 the
   `var bootStepOk = []` initialiser sat at line ~4887, BELOW the
   strict-mode ReferenceError that aborted the script at 4736, so the
   arrays stayed undefined and every bootStep() call ran its step and
   then threw "Cannot read properties of undefined (reading 'push')" —
   aborting the repaint mid-pass (first revived surface won, the rest
   stayed dead) and surfacing as an unhandled rejection right after
   each repaint trace line. Initialised here, before anything can call
   bootStep, and bootStep also self-heals a missing array. */
var bootStepOk = [], bootStepFail = [];
function bootStep(name, fn){
  if (!bootStepOk) bootStepOk = [];
  if (!bootStepFail) bootStepFail = [];
  try { fn(); bootStepOk.push(name); }
  catch (e) {
    bootStepFail.push(name);
    tracePush("step-fail", name + ": " + ((e && e.message) || e));
    console.warn("TiradA boot: step '" + name + "' failed:", e);
  }
}
(function bootBuildGuard(){
  var htmlBuild = null;
  try { htmlBuild = window.TIRADA_BUILD || null; } catch(e){}
  tracePush("trace", "app.js executing, js build " + APP_BUILD + ", html build " + htmlBuild);
  if (htmlBuild === APP_BUILD) return;
  var healed = false;
  try { healed = !!sessionStorage.getItem("tirada_healed_" + APP_BUILD); } catch(e){}
  tracePush("guard", "build mismatch: html=" + htmlBuild + " js=" + APP_BUILD + (healed ? " (already healed once — continuing)" : " — healing: unregister SW, clear caches, reload"));
  if (healed) return;
  try { sessionStorage.setItem("tirada_healed_" + APP_BUILD, "1"); } catch(e){}
  var reloaded = false;
  function reloadOnce(){ if (reloaded) return; reloaded = true; try { location.reload(); } catch(e){} }
  try {
    var jobs = [];
    if (navigator.serviceWorker && navigator.serviceWorker.getRegistrations)
      jobs.push(navigator.serviceWorker.getRegistrations().then(function(rs){ return Promise.all(rs.map(function(r){ return r.unregister(); })); }));
    if (window.caches && caches.keys)
      jobs.push(caches.keys().then(function(ks){ return Promise.all(ks.map(function(k){ return caches.delete(k); })); }));
    if (jobs.length){ Promise.all(jobs).then(reloadOnce, reloadOnce); setTimeout(reloadOnce, 1800); return; }
  } catch(e){}
  reloadOnce();
})();
/* Health of the four surfaces whose death defined the v17/v18 bug, and
   an idempotent revival used after window load, after auth settles and
   by watchdogs: whatever the environment did to the first paint, the
   same load repairs itself — and leaves a trace of what was dead.
   v20: the v19 criteria were too weak and let the watchdog certify
   corpses — the live check found all four "alive" while visibly dead:
   a .tick-half shell with no text in it counted as a live ticker, any
   child of #cityList (the empty-state div, a static footer) counted as
   a live city list, and ANY innerHTML in #ghostBig counted as a live
   avatar — including a broken <img> whose pixels never arrive, which
   is exactly the empty red circle the user sees. Now a surface is
   alive only when it holds the real thing: text items in the ticker,
   actual city rows, and a face that can paint (a glyph with text, or
   an image that is not broken). */
function tickerHasText(tt){
  if (!tt) return false;
  var items = tt.querySelectorAll(".tick-item"), len = 0;
  for (var i = 0; i < items.length; i++) len += (items[i].textContent || "").replace(/\s+/g, "").length;
  return len > 0;
}
function imgBroken(img){ return !!(img && img.complete && img.naturalWidth === 0); }
function avatarFaceState(gb){
  if (!gb) return "dead";
  var font = gb.querySelector(".avfont");
  if (font && (font.textContent || "").trim().length > 0) return "ok";
  var img = gb.querySelector("img");
  if (img){
    if (imgBroken(img)) return "dead";
    if (img.complete && img.naturalWidth > 0) return "ok";
    return "pending"; /* still loading: not a corpse, not yet a face */
  }
  return "dead"; /* empty circle / faceless span */
}
function coreSurfacesHealth(){
  var ct = $("#counterText"), tt = $("#tickerTrack"), cl = $("#cityList"), gb = $("#ghostBig");
  return {
    counter: !!(ct && ct.textContent && ct.textContent.indexOf("…") < 0 && ct.textContent.length > 3),
    ticker: tickerHasText(tt),
    cityList: !!(cl && cl.querySelectorAll(".city-item").length > 0),
    avatar: avatarFaceState(gb) !== "dead",
    /* v21: the map is the fifth surface. Its health is a STATE, not a
       boolean — "loading" is healthy (a slow style must never be
       "revived" to death), "fallback"/"dead" are what repaint retries. */
    map: mapSurfaceState()
  };
}
/* Repair pass for the profile avatar: a face image that can never paint
   (dead photo URL, emoji CDN unreachable) is swapped for something that
   always renders — the current emoji face for a broken photo, the font
   glyph for a broken CDN face — so the profile never shows the empty
   red circle the v19 live check found. DOM-only: state is untouched,
   and a later successful render still wins. */
function glyphSpanFor(img, gb){
  var w = img.offsetWidth || (gb && gb.offsetWidth) || 88;
  var s = document.createElement("span");
  s.className = img.className + " avfont";
  s.textContent = img.getAttribute("data-emoji") || "👻";
  s.style.fontSize = Math.max(11, Math.round(w * 0.84)) + "px";
  return s;
}
function repairAvatarFace(force){
  var gb = $("#ghostBig");
  if (!gb || avatarFaceState(gb) === "ok") return;
  var photo = gb.querySelector("img.avphoto");
  if (photo && (imgBroken(photo) || force)){
    gb.innerHTML = avatarFace(state.myAvatar);
    /* A forced repair (the 8 s pass) terminates in the glyph right
       away: in an environment where the photo never painted, a fresh
       CDN <img> is not a credible next step. */
    if (force){
      var ni = gb.querySelector("img[data-emoji]");
      if (ni) ni.replaceWith(glyphSpanFor(ni, gb));
    }
    return;
  }
  var img = gb.querySelector("img[data-emoji]");
  if (img && (imgBroken(img) || force)){ img.replaceWith(glyphSpanFor(img, gb)); return; }
  if (avatarFaceState(gb) === "dead") gb.innerHTML = currentAvatarHtml();
}
function repaintCoreSurfaces(why){
  var h = coreSurfacesHealth(), dead = [];
  if (!h.counter) dead.push("counter");
  if (!h.ticker) dead.push("ticker");
  if (!h.cityList) dead.push("cityList");
  if (!h.avatar) dead.push("avatar");
  if (dead.length) {
    tracePush("repaint", why + ": reviving " + dead.join(", "));
    if (!h.counter) bootStep("updateCounter", updateCounter);
    if (!h.ticker) bootStep("buildTicker", buildTicker);
    if (!h.cityList) bootStep("renderCityList", renderCityList);
    if (!h.avatar){ bootStep("renderMyAvatar", renderMyAvatar); repairAvatarFace(); }
  } else repairAvatarFace();
  /* v28: nothing ticker-specific remains here — the fade ticker
     has no parked animation to restart, its single cycle is
     resumed by onAppResume (startTickerFade is idempotent), and
     buildTicker no-ops when the phrases did not change. */
  /* The map is revived by the same pass (v21): dead/fallback maps are
     retried, a still-loading map is left strictly alone. Guarded
     (v22): a map-revival error must never abort the surface pass —
     repaint runs inside promise handlers, where a throw becomes an
     unhandled rejection and kills the remaining revival triggers. */
  try { ensureMapAlive(why, false); } catch (e) {}
}
/* The «Диагностика запуска» block (About sheet): build stamps, the
   CURRENT health of the four critical surfaces, and the tail of the
   boot trace — everything needed to read a failure off a screenshot. */
function bootDiagHtml(){
  function esc(s){ return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"); }
  var h = coreSurfacesHealth();
  function mark(ok){ return ok ? "✅" : "❌"; }
  var mel = $("#map");
  function yn(b){ return b ? t("да") : t("нет"); }
  var mapStateWord = h.map === "ready" ? t("готова ✅") : h.map === "loading" ? t("грузится…") : h.map === "fallback" ? t("показан fallback-текст") : h.map === "absent" ? t("нет элемента") : t("мертва ❌");
  var mapRow = tf("Карта: {state} · mapReady {a} · карта создана {b} · маркер создан {c} · канвас {d} · data-fallback {e}",
      { state: mapStateWord, a: yn(mapReady), b: yn(mapConstructed), c: yn(meMarkerCreated),
        d: (mel && mel.querySelector("canvas")) ? t("есть") : t("нет"),
        e: mel ? (mel.getAttribute("data-fallback") || "—") : "—" })
    + (mapLastError ? " · " + tf("посл. ошибка [{k}] {m}", { k: mapLastError.kind, m: mapLastError.msg }) : " · " + t("ошибок карты не было"));
  var rows = [
    tf("Сборка: html {a} · js {b}", { a: window.TIRADA_BUILD || "?", b: APP_BUILD }),
    tf("Поверхности сейчас: счётчик {c} · тикер {t} · города {g} · аватар {a}", { c: mark(h.counter), t: mark(h.ticker), g: mark(h.cityList), a: mark(h.avatar) }),
    mapRow,
    tf("Браузер: {ua}", { ua: String(navigator.userAgent || "").slice(0, 110) })
  ];
  var a = lsGet("tirada_boot_errors", []);
  if (Array.isArray(a) && a.length){
    rows.push(t("— журнал запуска —"));
    a.slice(-16).forEach(function(en){
      var d = new Date(en.t || 0);
      var hh = ("0" + d.getHours()).slice(-2) + ":" + ("0" + d.getMinutes()).slice(-2) + ":" + ("0" + d.getSeconds()).slice(-2);
      rows.push(hh + " [" + en.kind + "] " + en.msg);
    });
  } else rows.push(t("Журнал запуска пуст."));
  return "<b>" + esc(t("Диагностика запуска")) + "</b><br>" + rows.map(esc).join("<br>");
}

/* ================= Ghost avatars: emoji characters in glowing circles ================= */
var AVATARS = [
  { e:"👻", bg:"radial-gradient(circle at 32% 28%, #ffd9d4, #e50914)" },
  { e:"😎", bg:"radial-gradient(circle at 32% 28%, #ffc4bc, #b3001b)" },
  { e:"🥷", bg:"radial-gradient(circle at 32% 28%, #e5e7eb, #4b5563)" },
  { e:"🦊", bg:"radial-gradient(circle at 32% 28%, #ffd9a0, #ea580c)" },
  { e:"🐺", bg:"radial-gradient(circle at 32% 28%, #fecaca, #991b1b)" },
  { e:"👽", bg:"radial-gradient(circle at 32% 28%, #fca5a5, #7f1d1d)" },
  { e:"🤖", bg:"radial-gradient(circle at 32% 28%, #d1d5db, #374151)" },
  { e:"🎭", bg:"radial-gradient(circle at 32% 28%, #fda4af, #881337)" },
  { e:"🐱", bg:"radial-gradient(circle at 32% 28%, #ffedd5, #c2410c)" },
  { e:"🦄", bg:"radial-gradient(circle at 32% 28%, #ffe4e6, #be123c)" },
  { e:"🐼", bg:"radial-gradient(circle at 32% 28%, #e7e5e4, #57534e)" },
  { e:"😈", bg:"radial-gradient(circle at 32% 28%, #fecdd3, #9f1239)" }
];
function emojiUrl(e){
  return "https://emojicdn.elk.sh/" + encodeURIComponent(e) + "?style=apple";
}
function emojiImg(e, cls){
  return '<img class="' + cls + '" data-emoji="' + e + '" src="' + emojiUrl(e) + '" alt="' + e + '" loading="lazy">';
}
/* Warm the CDN cache for all ghost faces at startup, so the avatar
   picker and the map marker show pictures instantly — not empty
   circles while the CDN wakes up. Place-type art gets the same warm-up:
   cards, sheets and route steps reuse the same dozen glyphs. */
AVATARS.forEach(function(av){ var im = new Image(); im.src = emojiUrl(av.e); });
function avatarFace(idx){
  /* Any legacy/damaged index (negative, NaN from a non-numeric stored
     value) must still yield a face — never an undefined.bg throw. */
  var n = AVATARS.length;
  var av = AVATARS[((idx % n) + n) % n] || AVATARS[0];
  return '<span class="avface" style="background:' + av.bg + '">' + emojiImg(av.e, "avimg") + '</span>';
}
/* CDN fallback: if an emoji image fails, swap it for the font glyph —
   sized from the box the image was supposed to fill, so the glyph sits
   centered at the right scale instead of shrinking into a corner. */
document.addEventListener("error", function(ev){
  var t = ev.target;
  if (t && t.tagName === "IMG" && t.getAttribute("data-emoji")){
    var w = t.offsetWidth || t.getBoundingClientRect().width || 24;
    var s = document.createElement("span");
    s.className = t.className + " avfont";
    s.textContent = t.getAttribute("data-emoji");
    s.style.fontSize = Math.max(11, Math.round(w * 0.84)) + "px";
    t.replaceWith(s);
  }
}, true);

/* ================= Place types ================= */
var TYPES = {
  bar:    { label:"Бары",       art:"🍸", grad:"linear-gradient(135deg,#8f0f16,#ff1e1e)",
            tags:["громко","коктейли","до утра"],
            songs:["Espresso — Sabrina Carpenter","Unholy — Sam Smith","Levitating — Dua Lipa"],
            tasks:["Задание: закажите один коктейль наугад на всех — что принесёт бармен, то и ваше.","Бармен — ваш судья: пусть выберет песню, под которую вы танцуете всей компанией."] },
  club:   { label:"Клубы",      art:"🪩", grad:"linear-gradient(135deg,#e50914,#4c0510)",
            tags:["громко","танцы","до утра"],
            songs:["Titanium — David Guetta ft. Sia","One More Time — Daft Punk","Levels — Avicii"],
            tasks:["Танцпол-челлендж: 60 секунд все танцуют, не останавливаясь. Кто встал — платит за вход в следующее место.","Снимите 10-секундное видео, где вся компания синхронно прыгает на дропе."] },
  park:   { label:"Парки",      art:"🌳", grad:"linear-gradient(135deg,#3d0a0e,#a3121c)",
            tags:["тихо","природа","компании"],
            songs:["As It Was — Harry Styles","Put Your Records On — Corinne Bailey Rae","Here Comes The Sun — The Beatles"],
            tasks:["Фото, где все прыгают одновременно. С первого дубля — слабо?","Найдите самое старое дерево в парке и сфотографируйтесь у него, как у знаменитости."] },
  view:   { label:"Смотровые",  art:"🌇", grad:"linear-gradient(135deg,#ff7a1a,#e50914 60%,#5c0a10)",
            tags:["закат","тихо","романтика"],
            songs:["Levitating — Dua Lipa","golden hour — JVKE","Perfect — Ed Sheeran"],
            tasks:["Встретить закат и снять панораму без единого фильтра.","Каждый показывает пальцем, где его дом. Кто дальше всех — тот ведёт в следующую точку."] },
  beach:  { label:"Пляжи",      art:"🏖️", grad:"linear-gradient(135deg,#450a0a,#dc2626)",
            tags:["море","закат","компании"],
            songs:["Watermelon Sugar — Harry Styles","Despacito — Luis Fonsi","Cake By The Ocean — DNCE"],
            tasks:["Постройте из песка логотип TiradA — призрака. Фото в студию.","Закатное селфи всей компании спиной к морю — силуэтами."] },
  cafe:   { label:"Кафе",       art:"☕", grad:"linear-gradient(135deg,#431407,#b91c1c)",
            tags:["тихо","вкусно","дёшево"],
            songs:["Volare — Gipsy Kings","Banana Pancakes — Jack Johnson","Sunday Morning — Maroon 5"],
            tasks:["Написать на салфетке предсказание на ночь и оставить её следующему гостю.","Каждый заказывает не себе, а соседу слева. Без подсказок."] },
  roof:   { label:"Руфтопы",    art:"🌆", grad:"linear-gradient(135deg,#ff4d00,#e50914)",
            tags:["крыша","вид","романтика"],
            songs:["Paint The Town Red — Doja Cat","Starboy — The Weeknd","Midnight City — M83"],
            tasks:["Селфи на фоне всего города. Бонус — найти на фото свой дом.","Тост за город с самой высокой точки. Видео — в архив ночи."] },
  hookah: { label:"Кальянные",  art:"💨", grad:"linear-gradient(135deg,#1f2937,#991b1b)",
            tags:["тихо","лаунж","компании"],
            songs:["Heat Waves — Glass Animals","Lovely — Billie Eilish","Sweater Weather — The Neighbourhood"],
            tasks:["Каждый загадывает желание на первую затяжку — вслух говорит только последний.","Кольцо дыма на видео с трёх попыток. У кого получилось — тот выбирает следующую точку."] },
  prom:   { label:"Набережные", art:"🌉", grad:"linear-gradient(135deg,#111827,#7f1d1d)",
            tags:["прогулка","вид","романтика"],
            songs:["Counting Stars — OneRepublic","Shivers — Ed Sheeran","A Sky Full of Stars — Coldplay"],
            tasks:["Прогулка от одного конца набережной до другого — и ни разу не посмотреть в телефон.","Фото отражения огней в воде. Лучший кадр выбирает вся компания."] },
  stage:  { label:"Сцены",      art:"🎭", grad:"linear-gradient(135deg,#991b1b,#ff1e1e)",
            tags:["громко","под открытым небом","танцы"],
            songs:["Blinding Lights — The Weeknd","We Will Rock You — Queen","Uptown Funk — Mark Ronson ft. Bruno Mars"],
            tasks:["Фото-челлендж: вся компания на сцене — как рок-группа за секунду до концерта.","Аплодисменты незнакомцам: похлопайте чужому выступлению так, будто это ваши кумиры."] },
  market: { label:"Рынки",      art:"🧺", grad:"linear-gradient(135deg,#7c2d12,#ea580c)",
            tags:["шумно","вкусно","дёшево"],
            songs:["Volare — Gipsy Kings","Despacito — Luis Fonsi","Hava Nagila — DJ Remix"],
            tasks:["Найдите самый странный товар на рынке и сфотографируйте его, не покупая.","Торгуйтесь до последнего: скиньте цену на фрукт хотя бы на шекель."] }
};
Object.keys(TYPES).forEach(function(k){ var im = new Image(); im.src = emojiUrl(TYPES[k].art); });

/* ================= Cities ================= */
var CITIES = [
  { id:"telaviv",     name:"Тель-Авив",     lat:32.0853, lng:34.7818, big:true  },
  { id:"jerusalem",   name:"Иерусалим",     lat:31.7683, lng:35.2137, big:true  },
  { id:"haifa",       name:"Хайфа",         lat:32.7940, lng:34.9896, big:true  },
  { id:"karmiel",     name:"Кармиэль",      lat:32.9155, lng:35.2960, big:false },
  { id:"beersheva",   name:"Беэр-Шева",     lat:31.2518, lng:34.7913, big:true  },
  { id:"eilat",       name:"Эйлат",         lat:29.5577, lng:34.9519, big:true  },
  { id:"netanya",     name:"Нетания",       lat:32.3215, lng:34.8532, big:false },
  { id:"ashdod",      name:"Ашдод",         lat:31.8014, lng:34.6435, big:false },
  { id:"ashkelon",    name:"Ашкелон",       lat:31.6688, lng:34.5743, big:false },
  { id:"rishon",      name:"Ришон-ле-Цион", lat:31.9730, lng:34.7925, big:false },
  { id:"petahtikva",  name:"Петах-Тиква",   lat:32.0841, lng:34.8878, big:false },
  { id:"holon",       name:"Холон",         lat:32.0158, lng:34.7874, big:false },
  { id:"ramatgan",    name:"Рамат-Ган",     lat:32.0684, lng:34.8244, big:false },
  { id:"batyam",      name:"Бат-Ям",        lat:32.0171, lng:34.7454, big:false },
  { id:"herzliya",    name:"Герцлия",       lat:32.1624, lng:34.8447, big:false },
  { id:"kfarsaba",    name:"Кфар-Саба",     lat:32.1750, lng:34.9069, big:false },
  { id:"hadera",      name:"Хадера",        lat:32.4340, lng:34.9196, big:false },
  { id:"nazareth",    name:"Нацерет",       lat:32.6996, lng:35.3035, big:false },
  { id:"acre",        name:"Акко",          lat:32.9275, lng:35.0817, big:false },
  { id:"tiberias",    name:"Тверия",        lat:32.7959, lng:35.5310, big:false },
  { id:"safed",       name:"Цфат",          lat:32.9646, lng:35.4960, big:false },
  { id:"amiad",       name:"Амиад",         lat:32.9270, lng:35.5420, big:false },
  { id:"afula",       name:"Афула",         lat:32.6091, lng:35.2892, big:false },
  { id:"kiryatshmona",name:"Кирьят-Шмона",  lat:33.2073, lng:35.5698, big:false },
  { id:"modiin",      name:"Модиин",        lat:31.8903, lng:35.0104, big:false },
  { id:"dimona",      name:"Димона",        lat:31.0696, lng:35.0334, big:false },
  { id:"bneibrak",    name:"Бней-Брак",     lat:32.0807, lng:34.8338, big:true  },
  { id:"rehovot",     name:"Реховот",       lat:31.8947, lng:34.8093, big:true  },
  { id:"beitshemesh", name:"Бейт-Шемеш",    lat:31.7514, lng:34.9885, big:true  },
  { id:"lod",         name:"Лод",           lat:31.9514, lng:34.8886, big:false },
  { id:"ramla",       name:"Рамле",         lat:31.9292, lng:34.8656, big:false },
  { id:"raanana",     name:"Раанана",       lat:32.1848, lng:34.8713, big:false },
  { id:"roshhaayin",  name:"Рош-ха-Аин",    lat:32.0956, lng:34.9564, big:false },
  { id:"givatayim",   name:"Гиватаим",      lat:32.0722, lng:34.8106, big:false },
  { id:"hodhasharon", name:"Ход-ха-Шарон",  lat:32.1594, lng:34.8932, big:false },
  { id:"kiryatata",   name:"Кирьят-Ата",    lat:32.8097, lng:35.1050, big:false },
  { id:"nahariya",    name:"Нагария",       lat:33.0114, lng:35.0947, big:false },
  { id:"kiryatgat",   name:"Кирьят-Гат",    lat:31.6100, lng:34.7642, big:false },
  { id:"kiryatmotzkin",name:"Кирьят-Моцкин",lat:32.8376, lng:35.0795, big:false },
  { id:"kiryatbialik",name:"Кирьят-Бялик",  lat:32.8325, lng:35.0875, big:false },
  { id:"kiryatyam",   name:"Кирьят-Ям",     lat:32.8497, lng:35.0678, big:false },
  { id:"maaleadumim", name:"Маале-Адумим",  lat:31.7774, lng:35.2981, big:false },
  { id:"netivot",     name:"Нетивот",       lat:31.4164, lng:34.5881, big:false },
  { id:"arad",        name:"Арад",          lat:31.2588, lng:35.2149, big:false },
  { id:"ofakim",      name:"Офаким",        lat:31.3136, lng:34.6192, big:false },
  { id:"yehud",       name:"Йехуд",         lat:32.0350, lng:34.8919, big:false },
  { id:"oryehuda",    name:"Ор-Йехуда",     lat:32.0300, lng:34.8558, big:false },
  { id:"nesciona",    name:"Нес-Циона",     lat:31.9322, lng:34.8011, big:false },
  { id:"elad",        name:"Эльад",         lat:32.0522, lng:34.9511, big:false },
  { id:"ramathasharon",name:"Рамат-ха-Шарон",lat:32.1461, lng:34.8394, big:false },
  { id:"tira",        name:"Тире",          lat:32.2322, lng:34.9486, big:false },
  { id:"arraba",      name:"Аррабе",        lat:32.8511, lng:35.3383, big:false },
  { id:"sderot",      name:"Сдерот",        lat:31.5250, lng:34.5969, big:false },
  { id:"tayibe",      name:"Тайбе",         lat:32.2658, lng:35.0094, big:false },
  { id:"shfaram",     name:"Шфарам",        lat:32.8056, lng:35.1694, big:false },
  { id:"kiryatono",   name:"Кирьят-Оно",    lat:32.0636, lng:34.8553, big:false },
  { id:"sakhnin",     name:"Сахнин",        lat:32.8647, lng:35.2944, big:false },
  { id:"yavne",       name:"Явне",         lat:31.8778, lng:34.7394, big:false },
  { id:"ummelfahm",   name:"Умм-эль-Фахм",  lat:32.5192, lng:35.1525, big:false },
  { id:"tamra",       name:"Тамра",         lat:32.8514, lng:35.2069, big:false },
  { id:"beeryaakov",  name:"Беэр-Яаков",    lat:31.9450, lng:34.8394, big:false },
  { id:"kiryatmalakhi",name:"Кирьят-Малахи",lat:31.7300, lng:34.7361, big:false },
  { id:"yokneam",     name:"Йокнеам",       lat:32.6594, lng:35.1100, big:false },
  { id:"kafrqasim",   name:"Кафр-Касем",    lat:32.1150, lng:34.9772, big:false },
  { id:"qalansawa",   name:"Калансуа",      lat:32.2847, lng:34.9808, big:false },
  { id:"ariel",       name:"Ариэль",        lat:32.1061, lng:35.1844, big:false },
  { id:"maalot",      name:"Маалот-Таршиха",lat:33.0158, lng:35.2725, big:false },
  { id:"mitzperamon", name:"Мицпе-Рамон",   lat:30.6122, lng:34.8019, big:false },
  { id:"migdalhaemek",name:"Мигдаль-ха-Эмек",lat:32.6778, lng:35.2439, big:false },
  { id:"nofhagalil",  name:"Ноф-ха-Галиль", lat:32.7089, lng:35.3244, big:false },
  { id:"rahat",       name:"Рахат",         lat:31.3925, lng:34.7544, big:false },
  { id:"baqa",        name:"Бака-эль-Гарбия",lat:32.4200, lng:35.0400, big:false },
  { id:"daliyat",     name:"Далият-эль-Кармель",lat:32.6931, lng:35.0458, big:false },
  { id:"maghar",      name:"Магар",         lat:32.8897, lng:35.4069, big:false },
  { id:"roshpina",    name:"Рош-Пина",      lat:32.9694, lng:35.5422, big:false },
  { id:"zikhron",     name:"Зихрон-Яаков",  lat:32.5706, lng:34.9519, big:false },
  { id:"metula",      name:"Метула",        lat:33.2769, lng:35.5781, big:false },
  { id:"katzrin",     name:"Кацрин",        lat:32.9925, lng:35.6906, big:false },
  { id:"orakiva",     name:"Ор-Акива",      lat:32.5028, lng:34.9200, big:false },
  { id:"nesher",      name:"Нешер",         lat:32.7669, lng:35.0419, big:false },
  { id:"kfaryona",    name:"Кфар-Йона",     lat:32.3150, lng:34.9358, big:false },
  { id:"harish",      name:"Хариш",         lat:32.4597, lng:35.0447, big:false },
  { id:"modiinillit", name:"Модиин-Илит",   lat:31.9325, lng:35.0433, big:false },
  { id:"beitarillit", name:"Бейтар-Илит",   lat:31.6969, lng:35.1169, big:false },
  { id:"givatshmuel", name:"Гиват-Шмуэль",  lat:32.0781, lng:34.8489, big:false },
  { id:"ganeitikva",  name:"Ганей-Тиква",   lat:32.0611, lng:34.8733, big:false },
  { id:"tiratcarmel", name:"Тират-Кармель", lat:32.7589, lng:34.9719, big:false }
];
function cityById(id){ for (var i=0;i<CITIES.length;i++) if (CITIES[i].id===id) return CITIES[i]; return CITIES[3]; }

/* deterministic pseudo-random */
function hashStr(s){ var h=2166136261; for (var i=0;i<s.length;i++){ h^=s.charCodeAt(i); h=Math.imul(h,16777619); } return h>>>0; }
function rng(seed){ var t=seed>>>0; return function(){ t+=0x6D2B79F5; var r=Math.imul(t^t>>>15,1|t); r^=r+Math.imul(r^r>>>7,61|r); return ((r^r>>>14)>>>0)/4294967296; }; }

/* ================= Karmiel — full hand-written data (from v1) ================= */
var KARMIEL_PLACES = [
  { name:"Амфитеатр Кармиэля", type:"stage", typeLabel:"Открытая сцена · концерты", lat:32.9105, lng:35.3047,
    heat:88, rating:4.8, tags:["громко","под открытым небом","танцы"], song:"Blinding Lights — The Weeknd",
    task:"Фото-челлендж: вся компания на сцене — как рок-группа за секунду до концерта." },
  { name:"Бар «Неон»", type:"bar", typeLabel:"Бар · коктейли", lat:32.9189, lng:35.2931,
    heat:76, rating:4.6, tags:["громко","коктейли","до утра"], song:"Espresso — Sabrina Carpenter",
    task:"Задание: закажите один коктейль наугад на всех — что принесёт бармен, то и ваше." },
  { name:"«Крыша 360»", type:"roof", typeLabel:"Руфтоп · вид на город", lat:32.9172, lng:35.2989,
    heat:64, rating:4.5, tags:["крыша","вид","романтика"], song:"Paint The Town Red — Doja Cat",
    task:"Селфи на фоне всего города. Бонус — найти на фото свой дом." },
  { name:"Кальянная «Дым и мята»", type:"hookah", typeLabel:"Кальянная · лаунж", lat:32.9128, lng:35.2908,
    heat:57, rating:4.4, tags:["тихо","лаунж","компании"], song:"Heat Waves — Glass Animals",
    task:"Каждый загадывает желание на первую затяжку — вслух говорит только последний." },
  { name:"Пиццерия «Форно»", type:"cafe", typeLabel:"Еда · компании", lat:32.9161, lng:35.2962, art:"🍕",
    heat:51, rating:4.7, tags:["вкусно","дёшево","компании"], song:"Volare — Gipsy Kings",
    task:"Одна пицца — три начинки: каждый выбирает свою треть, спорить нельзя." },
  { name:"Водопад в парке а-Галиль", type:"park", typeLabel:"Парк · природа", lat:32.9099, lng:35.2913, art:"💦",
    heat:42, rating:4.9, tags:["тихо","природа","романтика"], song:"As It Was — Harry Styles",
    task:"Фото у водопада, где все прыгают одновременно. С первого дубля — слабо?" },
  { name:"Смотровая «Мицпор Шай»", type:"view", typeLabel:"Смотровая площадка", lat:32.9092, lng:35.2877, art:"🌅",
    heat:35, rating:4.7, tags:["закат","тихо","романтика"], song:"Levitating — Dua Lipa",
    task:"Встретить закат и снять панораму города без единого фильтра." },
  { name:"Кафе «У фонтана»", type:"cafe", typeLabel:"Кафе · десерты", lat:32.9198, lng:35.3005, art:"🧁",
    heat:27, rating:4.4, tags:["тихо","дёшево","десерты"], song:"golden hour — JVKE",
    task:"Написать на салфетке предсказание на ночь и оставить её следующему гостю." }
];

/* ================= Compact catalog for other cities: [name, type, heat] ================= */
var RAW = {
  telaviv: [
    ["Клуб «Пасаж»","club",93,32.0673,34.7715],["Бар «Спутник»","bar",88,32.0668,34.7722],
    ["Бар «Империал»","bar",79,32.0847,34.7697],["Пляж «Гордон»","beach",74,32.0825,34.7668],
    ["Пляж «Фришман»","beach",70,32.0803,34.7656],["Пляж «Банана»","beach",66,32.0717,34.7636],
    ["Рынок «Кармель»","market",84,32.0685,34.7700],["Набережная «Таелет»","prom",72,32.0770,34.7640],
    ["Парк «Яркон»","park",52,32.0980,34.7880],["Кафе «Ротшильд»","cafe",63,32.0630,34.7740],
    ["Руфтоп «Принц»","roof",77,32.0617,34.7700],["Смотровая «Азриэли»","view",58,32.0744,34.7919]
  ],
  jerusalem: [
    ["Рынок «Махане Иегуда»","market",89,31.7850,35.2125],["Бар «Гэтсби»","bar",76,31.7800,35.2170],
    ["Клуб «Сира»","club",71,31.7817,35.2217],["Смотровая «Масличная гора»","view",60,31.7777,35.2430],
    ["Променад «Армон а-Нацив»","prom",55,31.7550,35.2306],["Парк «Ган Сакер»","park",47,31.7800,35.2070],
    ["Кафе «Немецкая колония»","cafe",57,31.7630,35.2190],["Руфтоп «Мамилла»","roof",68,31.7778,35.2230],
    ["Руфтоп «Нотр-Дам»","roof",62,31.7794,35.2256],["Сцена «Брехат а-Султан»","stage",66,31.7717,35.2256]
  ],
  haifa: [
    ["Смотровая «Бахайские сады»","view",78,32.8122,34.9869],["Пляж «Дадо»","beach",75,32.7633,34.9589],
    ["Пляж «Бат-Галим»","beach",64,32.8333,34.9850],["Променад «Луи»","prom",69,32.8078,34.9850],
    ["Бар «Даунтаун»","bar",82,32.8197,34.9997],["Клуб «Бит»","club",80,32.8194,34.9989],
    ["Кафе «Кармель»","cafe",55,32.8030,34.9880],["Парк «Ган а-Эм»","park",46,32.8053,34.9883],
    ["Кафе «Немецкая колония»","cafe",59,32.8219,34.9906],["Смотровая «Стелла Марис»","view",61,32.8267,34.9700]
  ],
  beersheva: [
    ["Клуб «Пульс»","club",84,31.2520,34.7910],["Бар «Старый город»","bar",73,31.2380,34.7880],
    ["Парк «Нахаль Беэр-Шева»","park",45,31.2350,34.7750],["Кафе «Рингельблюм»","cafe",58,31.2630,34.8020],
    ["Смотровая «Монумент Негев»","view",41,31.2670,34.8210],["Кальянная «Дым пустыни»","hookah",56,31.2400,34.7850],
    ["Руфтоп «Гранд Скай»","roof",63,31.2500,34.7950],["Амфитеатр парка Нахаль","stage",48,31.2330,34.7720]
  ],
  eilat: [
    ["Клуб «Крейзи Элефант»","club",90,29.5700,34.9650],["Паб «Три обезьяны»","bar",85,29.5510,34.9530],
    ["Пляж «Коралловый»","beach",81,29.5078,34.9219],["Пляж «Дельфиний риф»","beach",77,29.5250,34.9350],
    ["Набережная Эйлата","prom",74,29.5530,34.9540],["Руфтоп «Лагуна»","roof",67,29.5550,34.9520],
    ["Кафе «Марина»","cafe",55,29.5490,34.9550],["Смотровая «Гора Цфахот»","view",38,29.5400,34.9200]
  ],
  netanya: [
    ["Пляж «Сиронит»","beach",74,32.3060,34.8470],["Пляж «Полег»","beach",71,32.2680,34.8360],
    ["Набережная Нетании","prom",63],["Кафе «Кикар а-Ацмаут»","cafe",52,32.3290,34.8550],["Бар «Площадь»","bar",64]
  ],
  ashdod: [
    ["Пляж «Лидо»","beach",69],["Пляж «Кшатот»","beach",66,31.8160,34.6370],
    ["Смотровая «Гиват Йона»","view",45,31.8080,34.6450],["Парк «Ашдод-Ям»","park",44],["Кафе «Сити»","cafe",47]
  ],
  ashkelon: [
    ["Пляж «Бар-Кохва»","beach",71],["Пляж «Длила»","beach",68],
    ["Нацпарк Ашкелон","park",48,31.6650,34.5460],["Набережная «Марина»","prom",56],["Бар «Дельфин»","bar",61]
  ],
  rishon: [
    ["Пляж «Ришон»","beach",73,31.9810,34.7370],["Сцена «Суперленд»","stage",62,31.9790,34.7450],
    ["Парк «Ган а-Мошава»","park",46],["Бар «Ротшильд»","bar",68],["Руфтоп «Сити Скай»","roof",59]
  ],
  petahtikva: [
    ["Рынок Петах-Тиквы","market",64,32.0880,34.8850],["Бар «ПТ Найт»","bar",62],
    ["Кафе «Хаим Озер»","cafe",48],["Парк «Ган а-Меясдим»","park",37],["Кальянная «ПТ Лаунж»","hookah",53]
  ],
  holon: [
    ["Парк «Переса»","park",50,32.0050,34.7750],["Смотровая «Музей дизайна»","view",44,32.0120,34.7780],
    ["Парк «Ямит»","park",42],["Кафе «Савьон»","cafe",44],["Паб «Дублин»","bar",57]
  ],
  ramatgan: [
    ["Парк «Сафари»","park",58,32.0450,34.8220],["Парк «Леуми»","park",48],
    ["Руфтоп «Бурса»","roof",69,32.0830,34.8020],["Бар «Даймонд»","bar",62],["Кафе «Бялик»","cafe",50]
  ],
  batyam: [
    ["Пляж «Бат-Ям»","beach",76,32.0210,34.7380],["Набережная Бат-Яма","prom",60],
    ["Кафе «Мацева»","cafe",43],["Бар «Си Пойнт»","bar",58]
  ],
  herzliya: [
    ["Пляж «Акадия»","beach",79,32.1640,34.7950],["Пляж «Герцлия»","beach",76],
    ["Набережная «Марина»","prom",67,32.1860,34.7950],["Смотровая «Аполлония»","view",47,32.1910,34.8070],
    ["Руфтоп «Питуах Скай»","roof",70],["Кафе «Марина Вью»","cafe",52]
  ],
  kfarsaba: [
    ["Парк «Кфар-Саба»","park",41],["Кафе «Вайцман»","cafe",46],["Бар «У Ави»","bar",55]
  ],
  hadera: [
    ["Пляж «Гиват Ольга»","beach",67,32.4430,34.8850],["Парк «Нахаль Хадера»","park",42,32.4230,34.9330],
    ["Кафе «Герберт Самуэль»","cafe",44],["Паб «Факел»","bar",54]
  ],
  nazareth: [
    ["Рынок Нацерета","market",58,32.7030,35.3000],["Смотровая «Старый город»","view",52,32.7040,35.2980],
    ["Кафе «Старый Нацерет»","cafe",49],["Смотровая «Гора Свержения»","view",38,32.6830,35.3090]
  ],
  acre: [
    ["Набережная «Порт Акко»","prom",66,32.9210,35.0690],["Рынок Акко","market",61,32.9220,35.0700],
    ["Смотровая «Маяк Акко»","view",45,32.9190,35.0660],["Кафе «Старый город»","cafe",47],["Бар «Маяк»","bar",57]
  ],
  tiberias: [
    ["Набережная Тверии","prom",68,32.7880,35.5420],["Пляж «Гай»","beach",72],
    ["Пляж «Бора-Бора»","beach",70,32.7660,35.5450],["Кафе «Ям Кинерет»","cafe",51],["Бар «Галиль»","bar",60]
  ],
  safed: [
    ["Кафе «Квартал художников»","cafe",48,32.9690,35.4940],["Смотровая «Цитадель»","view",42,32.9680,35.4950],
    ["Парк «Ган а-Мецуда»","park",34],["Кальянная «Каббала»","hookah",44]
  ],
  afula: [
    ["Рынок Афулы","market",47,32.6080,35.2900],["Кафе «Афула Центр»","cafe",42],
    ["Парк «Ган а-Эмек»","park",36],["Бар «Долина»","bar",52]
  ],
  kiryatshmona: [
    ["Парк «Ган а-Захав»","park",44,33.2050,35.5680],["Смотровая «Манара»","view",40,33.1960,35.5450],
    ["Кафе «Шмона»","cafe",41],["Паб «Северный»","bar",50]
  ],
  modiin: [
    ["Парк «Анава»","park",47,31.8980,35.0060],["Кафе «Модиин Центр»","cafe",48],
    ["Бар «Модиин Найт»","bar",56],["Смотровая «Гиват а-Тура»","view",36]
  ],
  dimona: [
    ["Парк «Димона»","park",35],["Кафе «Негев»","cafe",39],["Смотровая «Гора Димона»","view",30]
  ],
  bneibrak: [
    ["Променад «Раби Акива»","prom",44],["Кондитерская «Визниц»","cafe",46,32.0830,34.8340],
    ["Кафе «Арома»","cafe",40],["Парк «Ган а-Шлоша»","park",33]
  ],
  rehovot: [
    ["Рынок Реховота","market",55,31.8930,34.8110],["Кафе «Герцль»","cafe",52,31.8940,34.8180],
    ["Смотровая «Институт Вейцмана»","view",45,31.9070,34.8090],["Парк «А-Ораним»","park",38],["Бар «Градус»","bar",58]
  ],
  beitshemesh: [
    ["Маркет «Биг»","market",52,31.7470,34.9860],["Кафе «Роладин»","cafe",45],
    ["Парк «Нахаль Сорек»","park",36],["Смотровая «Тель Бейт-Шемеш»","view",33,31.7520,34.9750]
  ],
  lod: [
    ["Рынок Лода","market",57,31.9530,34.8930],["Смотровая «Мозаика Лода»","view",40,31.9560,34.9000],
    ["Променад «Старый город»","prom",42],["Кафе «Лод»","cafe",44]
  ],
  ramla: [
    ["Рынок Рамле","market",66,31.9310,34.8720],["Смотровая «Белая башня»","view",48,31.9340,34.8700],
    ["Кафе «Рамле»","cafe",45],["Парк «Ган а-Наси»","park",35]
  ],
  raanana: [
    ["Парк Раананы","park",55,32.1760,34.8530],["Сцена «Амфитеатр»","stage",47,32.1770,34.8540],
    ["Кафе «Ахуза»","cafe",53,32.1830,34.8720],["Бар «Раанана Найт»","bar",57]
  ],
  roshhaayin: [
    ["Парк «Мигдаль Цедек»","park",46,32.1010,34.9530],["Парк «Яркон»","park",44,32.1060,34.9210],
    ["Кафе «Рош»","cafe",43],["Паб «Якорь»","bar",52]
  ],
  givatayim: [
    ["Кафе «Вайцман»","cafe",49],["Смотровая «Планетарий»","view",43,32.0700,34.8050],
    ["Парк Гиватаима","park",41],["Бар «Гиватаим Найт»","bar",55]
  ],
  hodhasharon: [
    ["Парк «Ход-ха-Шарон»","park",47,32.1550,34.8850],["Кафе «Матаим»","cafe",45],["Бар «Ход Найт»","bar",53]
  ],
  kiryatata: [
    ["Маркет «Шаарей а-Кирья»","market",46],["Кафе «Ата»","cafe",42],["Парк «Ган а-Ир»","park",36],["Бар «Свои»","bar",51]
  ],
  nahariya: [
    ["Пляж «Галей Галиль»","beach",70,33.0090,35.0910],["Променад «Гаатон»","prom",62,33.0080,35.0980],
    ["Кафе «Соколь»","cafe",47],["Паб «Галей»","bar",56]
  ],
  kiryatgat: [
    ["Маркет «Биг Гат»","market",48],["Кафе «Гат»","cafe",44],["Парк «Ган а-Шалом»","park",37],["Бар «Гат Найт»","bar",54]
  ],
  kiryatmotzkin: [
    ["Парк «Хай-Парк»","park",52,32.8440,35.0860],["Кафе «Моцкин»","cafe",44],["Паб «Бочка»","bar",53]
  ],
  kiryatbialik: [
    ["Парк «Эйн Афек»","park",45,32.8460,35.1120],["Кафе «Бялик»","cafe",43],["Бар «Стихи»","bar",50]
  ],
  kiryatyam: [
    ["Пляж «Звулун»","beach",68,32.8510,35.0590],["Променад Кирьят-Ям","prom",55],["Кафе «Ям»","cafe",42]
  ],
  maaleadumim: [
    ["Кафе «Адумим»","cafe",44],["Смотровая «Музей Кастеля»","view",40,31.7720,35.2940],
    ["Парк «Ган а-Цви»","park",35],["Паб «Красные холмы»","bar",51]
  ],
  netivot: [
    ["Маркет «Биг Нетивот»","market",47],["Кафе «Нетивот»","cafe",43],["Парк «Южный»","park",34],["Пиццерия «Нетивот»","cafe",52]
  ],
  arad: [
    ["Кафе «Муза»","cafe",52,31.2610,35.2130],["Смотровая «Мицпе Моав»","view",44,31.2550,35.2350],
    ["Парк «Пустынный»","park",33],["Бар «Мираж»","bar",49]
  ],
  ofakim: [
    ["Парк Офаким","park",38,31.3140,34.6220],["Кафе «Офаким»","cafe",41],["Паб «Горизонт»","bar",50]
  ],
  yehud: [
    ["Кафе «Йехуд»","cafe",44],["Парк «А-Тиква»","park",35],["Бар «Центр»","bar",51]
  ],
  oryehuda: [
    ["Кафе «Ор»","cafe",43],["Парк «Ган а-Тайасим»","park",36],["Паб «Светлячок»","bar",50]
  ],
  nesciona: [
    ["Маркет «Биг Нес-Циона»","market",49],["Кафе «Нес»","cafe",47],["Парк «Ган а-Мошава»","park",38],["Бар «Нес Найт»","bar",55]
  ],
  elad: [
    ["Кафе «Эльад»","cafe",40],["Парк Эльада","park",36],["Пиццерия «Эльад»","cafe",47]
  ],
  ramathasharon: [
    ["Кафе «Соколь»","cafe",51,32.1460,34.8410],["Парк «Ган а-Неве»","park",39],["Бар «Шарон Найт»","bar",56]
  ],
  tira: [
    ["Кафе «Тира»","cafe",46],["Кальянная «Тира»","hookah",50],["Парк «Оливковый»","park",35]
  ],
  arraba: [
    ["Кафе «Аррабе»","cafe",43],["Кальянная «Аррабе»","hookah",48],["Парк «Оливковая роща»","park",34]
  ],
  sderot: [
    ["Кафе «Сдерот»","cafe",44],["Парк «Ган а-Музика»","park",36],["Бар «Сдерот Найт»","bar",51]
  ],
  tayibe: [
    ["Кафе «Тайбе»","cafe",45],["Кальянная «Тайбе»","hookah",49],["Парк «Акация»","park",34]
  ],
  shfaram: [
    ["Променад «Старый город»","prom",45],["Смотровая «Крепость Шфарам»","view",42,32.8060,35.1700],["Кафе «Шфарам»","cafe",44]
  ],
  kiryatono: [
    ["Кафе «Оно»","cafe",46],["Парк «Ган а-Ришоним»","park",37],["Бар «Оно Найт»","bar",52]
  ],
  sakhnin: [
    ["Сцена «Стадион Доха»","stage",50,32.8660,35.2880],["Кафе «Сахнин»","cafe",45],["Кальянная «Сахнин»","hookah",49]
  ],
  yavne: [
    ["Пляж «Пальмахим»","beach",64,31.9330,34.6980],["Кафе «Явне»","cafe",44],
    ["Парк «Ган а-Савьоним»","park",36],["Бар «Явне Найт»","bar",53]
  ],
  ummelfahm: [
    ["Кафе «Умм»","cafe",45],["Смотровая «Джебель Искандар»","view",43,32.5230,35.1560],["Парк «У холма»","park",33]
  ],
  tamra: [
    ["Кафе «Тамра»","cafe",43],["Кальянная «Тамра»","hookah",47],["Парк «Гранатовый»","park",33]
  ],
  beeryaakov: [
    ["Кафе «Беэр»","cafe",42],["Парк «Старый колодец»","park",35],["Бар «У колодца»","bar",49]
  ],
  kiryatmalakhi: [
    ["Кафе «Малахи»","cafe",42],["Парк «Солнечный»","park",34],["Паб «Ангел»","bar",50]
  ],
  yokneam: [
    ["Кафе «Йокнеам»","cafe",44],["Смотровая «Тель Йокнеам»","view",39,32.6650,35.1080],["Парк «У ручья»","park",35]
  ],
  kafrqasim: [
    ["Кафе «Касем»","cafe",43],["Кальянная «Касем»","hookah",47],["Парк «А-Шаар»","park",33]
  ],
  qalansawa: [
    ["Кафе «Калансуа»","cafe",42],["Кальянная «Калансуа»","hookah",46],["Парк «Тихий»","park",32]
  ],
  ariel: [
    ["Кафе «Ариэль»","cafe",43],["Смотровая «Ариэль»","view",40,32.1060,35.1840],["Парк «Верхний»","park",34]
  ],
  maalot: [
    ["Парк «Озеро Монфорт»","park",46,33.0070,35.2860],["Кафе «Маалот»","cafe",42],["Смотровая «Монфорт»","view",41,33.0430,35.2250]
  ],
  mitzperamon: [
    ["Смотровая «Махтеш Рамон»","view",58,30.6110,34.8020],["Променад «Альберт»","prom",50,30.6100,34.8000],["Кафе «Ха-Махтеш»","cafe",45]
  ],
  migdalhaemek: [
    ["Кафе «Мигдаль»","cafe",41],["Парк «Кедровый»","park",34],["Бар «Башня»","bar",49]
  ],
  nofhagalil: [
    ["Кафе «Ноф»","cafe",43],["Смотровая «Гора Двора»","view",40,32.7000,35.3550],["Парк «Ган а-Цви»","park",34]
  ],
  rahat: [
    ["Рынок Рахата","market",48,31.3930,34.7550],["Кафе «Рахат»","cafe",42],["Парк «Ган а-Шалом»","park",32]
  ],
  baqa: [
    ["Кафе «Бака»","cafe",43],["Кальянная «Бака»","hookah",46],["Парк «Абрикосовый»","park",33]
  ],
  daliyat: [
    ["Променад «Главная улица»","prom",55,32.6930,35.0460],["Кафе «Далия»","cafe",47],["Смотровая «Мухрака»","view",46,32.6730,35.0880]
  ],
  maghar: [
    ["Кафе «Магар»","cafe",42],["Кальянная «Магар»","hookah",45],["Смотровая «Гора Маар»","view",37]
  ],
  roshpina: [
    ["Кафе «Пина ба-Рош»","cafe",50,32.9700,35.5430],["Променад «Старая Рош-Пина»","prom",46],["Смотровая «Долина Хула»","view",42]
  ],
  zikhron: [
    ["Променад «Мидрахов»","prom",56,32.5710,34.9520],["Кафе «Тушия»","cafe",49],["Парк «Рамат а-Надив»","park",48,32.5480,34.9450]
  ],
  metula: [
    ["Кафе «Канада Центр»","cafe",42,33.2760,35.5770],["Смотровая «Хермон»","view",44,33.2770,35.5780],["Променад «Главная улица»","prom",40]
  ],
  katzrin: [
    ["Парк «Кацрин а-Атика»","park",44,32.9900,35.6880],["Бар «Вина Голан»","bar",48,32.9930,35.6910],["Кафе «Кацрин»","cafe",41]
  ],
  orakiva: [
    ["Пляж «Акведукт»","beach",63,32.5150,34.8980],["Кафе «Ор»","cafe",42],["Парк «Ган а-Ям»","park",35]
  ],
  nesher: [
    ["Парк «Висячие мосты»","park",47,32.7630,35.0500],["Кафе «Нешер»","cafe",42],["Бар «Орёл»","bar",50]
  ],
  kfaryona: [
    ["Кафе «Йона»","cafe",42],["Парк «Ган а-Йона»","park",35],["Паб «Голубь»","bar",49]
  ],
  harish: [
    ["Кафе «Хариш»","cafe",41],["Парк «Новый»","park",34],["Паб «Борозда»","bar",48]
  ],
  modiinillit: [
    ["Кафе «Модиин-Илит»","cafe",37],["Парк «Семейный»","park",31]
  ],
  beitarillit: [
    ["Кафе «Бейтар»","cafe",38],["Парк «А-Неве»","park",32],["Смотровая «Гиват а-Бейтар»","view",30]
  ],
  givatshmuel: [
    ["Кафе «Гиват»","cafe",46],["Парк «Ган а-Шмуэль»","park",37],["Бар «У Шмуэля»","bar",52]
  ],
  ganeitikva: [
    ["Кафе «Ганей»","cafe",44],["Парк «Зелёный»","park",36],["Паб «Надежда»","bar",50]
  ],
  tiratcarmel: [
    ["Пляж «Тират-Кармель»","beach",64,32.7570,34.9550],["Кафе «Тират»","cafe",42],["Парк «Ган а-Ир»","park",34]
  ]
};

/* v28 — secret places, hidden behind the ghost levels. Until the
   unlock every surface masks them: no name, photo, song or price in
   cards, map badges, popups, the place sheet, search, routes, the
   deal or the ticker. THE unlock condition (one, documented): level
   >= 3 («Тусовщик» / Party Animal) — chosen over the AI-tasks
   alternative because the level is always on screen, so the goal
   explains itself in the UI. */
var SECRET_PLACES = { "karmiel|Ирисим": 1, "telaviv|Yarkon Park": 1, "haifa|Bat Galim Beach": 1 };
function secretUnlocked(){ return levelOf(myXp()).num >= 3; }
function isSecretLocked(p){ return !!(p && p.secret && !secretUnlocked()); }

function buildPlaces(city){
  /* Real venues from Google (places-data.js) win over the generated
     catalogue: real names, coordinates, ratings, review counts and price
     levels. Heat stays the honest time-of-day model; song/task/tags are
     still assigned per type, as before. */
  var CI = contentI18n();
  var real = [];
  if (typeof REAL_PLACES !== "undefined" && REAL_PLACES[city.id]) real = real.concat(REAL_PLACES[city.id]);
  /* Hand-added local spots (CUSTOM_PLACES, source:"local") merge into the
     same list: no Google rating/reviews/prices, marked «🏠 Местное место». */
  if (typeof CUSTOM_PLACES !== "undefined" && CUSTOM_PLACES[city.id]) real = real.concat(CUSTOM_PLACES[city.id]);
  if (real.length){
    return real.map(function(rp, i){
      var t = TYPES[rp.type] || TYPES.cafe;
      var rand = rng(hashStr(city.id + "|" + rp.name));
      var song = t.songs[Math.floor(rand() * t.songs.length)];
      var tTasks = typeTasks(rp.type);
      var task = tTasks[Math.floor(rand() * tTasks.length)];
      return { id: city.id + "-" + i, name: rp.name, type: rp.type, typeLabel: typeLabel(rp.type),
        lat: rp.lat, lng: rp.lng, heat: 35 + Math.floor(rand() * 55),
        rating: (typeof rp.rating === "number" ? rp.rating : null),
        reviews: rp.reviews || null,
        priceLevel: (rp.priceLevel === undefined ? null : rp.priceLevel),
        address: rp.address || null, addressHe: rp.addressHe || null, addressEn: rp.addressEn || null, real: rp.source !== "local", local: rp.source === "local",
        secret: !!SECRET_PLACES[city.id + "|" + rp.name],
        tags: typeTags(rp.type).slice(), tagsRu: t.tags.slice(), song: song, task: task,
        art: t.art, grad: t.grad };
    });
  }
  if (city.id === "karmiel"){
    return KARMIEL_PLACES.map(function(p,i){
      var t = TYPES[p.type];
      return { id:"karmiel-"+i, name:(CI && CI.KARMIEL && CI.KARMIEL[i]) || p.name, type:p.type, typeLabel:typeLabel(p.type),
        lat:p.lat, lng:p.lng, heat:p.heat, rating:p.rating, tags:p.tags, tagsRu:p.tags, song:p.song, task:p.task,
        art:p.art || t.art, grad:t.grad };
    });
  }
  var raw = RAW[city.id] || [];
  return raw.map(function(r,i){
    var t = TYPES[r[1]];
    var rand = rng(hashStr(city.id + "|" + r[0]));
    var lat, lng;
    if (typeof r[3] === "number"){ lat = r[3]; lng = r[4]; }
    else {
      /* No real coords: deterministic polar placement (seeded by the place
         id, stable across reloads) within ~600 m of the city centre —
         not a ±2 km random scatter. */
      var ang = rand() * Math.PI * 2, radM = Math.sqrt(rand()) * 600;
      lat = city.lat + (radM * Math.cos(ang)) / 111320;
      lng = city.lng + (radM * Math.sin(ang)) / (111320 * Math.cos(city.lat * Math.PI / 180));
    }
    var rating = Math.round((3.8 + rand() * 1.2) * 10) / 10;
    var song = t.songs[Math.floor(rand() * t.songs.length)];
    var gTasks = typeTasks(r[1]);
    var task = gTasks[Math.floor(rand() * gTasks.length)];
    return { id:city.id + "-" + i, name:(CI && CI.RAW && CI.RAW[city.id] && CI.RAW[city.id][i]) || r[0], type:r[1], typeLabel:typeLabel(r[1]),
      lat:lat, lng:lng, heat:r[2], rating:rating, tags:typeTags(r[1]).slice(), tagsRu:t.tags.slice(), song:song, task:task,
      art:t.art, grad:t.grad };
  });
}
var PLACES_BY_CITY = {};
CITIES.forEach(function(c){ PLACES_BY_CITY[c.id] = buildPlaces(c); });

/* ================= State & helpers ================= */
function lsGet(k, d){ try { var v = localStorage.getItem(k); return v ? JSON.parse(v) : d; } catch(e){ return d; } }
function lsSet(k, v){ try { localStorage.setItem(k, JSON.stringify(v)); } catch(e){} }
/* lsGet returns whatever JSON.parse produced. For a legacy or damaged
   key that can be null, a string, a number or an array where the code
   expects a plain object — and reading a property of null (or writing
   one onto a primitive, in strict mode) throws and used to abort the
   whole boot (v18 post-mortem). objOr() is the single coercion point:
   anything that is not a plain object becomes the fallback. */
function objOr(v, d){ return (v && typeof v === "object" && !Array.isArray(v)) ? v : d; }
var state = {
  city: cityById("karmiel"),
  filter: "all",
  mode: "visible",
  myAvatar: lsGet("tirada_avatar_idx", 0),
  avatarPhoto: lsGet("tirada_avatar_photo", null),
  avatarUrl: lsGet("tirada_avatar_url", null),
  nick: lsGet("tirada_nick", ""),
  dealAlt: 0,
  routeRound: 0,
  routeSteps: null,
  transport: "car",
  search: "",
  sort: "heat",
  favs: lsGet("tirada_favs", {}),
  stats: lsGet("tirada_stats", { nights: 0, places: [], routes: 0, lastDealDay: "", photos: 0, tasks: 0, questSteps: 0, quests: 0, votes: 0, streak: 0, bestStreak: 0 }),
  vote: lsGet("tirada_vote", null),
  voteLink: null,
  routeDone: lsGet("tirada_route_done", {}),
  geo: null
};
/* Sanitise legacy/damaged local state BEFORE anything renders from it.
   A returning user's storage may hold values written by any older build
   (or damaged ones): stats always pass through normalizeStats — the same
   shape the cloud merge produces — favs/routeDone are always plain
   objects, and the avatar index is always a valid AVATARS slot. No
   single stored key may be able to abort the boot ever again (v18). */
state.stats = normalizeStats(state.stats);
state.favs = objOr(state.favs, {});
state.routeDone = objOr(state.routeDone, {});
state.myAvatar = (function(){
  var i = parseInt(state.myAvatar, 10);
  if (!isFinite(i)) return 0;
  return ((i % AVATARS.length) + AVATARS.length) % AVATARS.length;
})();
/* v26 — the avatar priority applies from the FIRST frame, not from the
   moment the cloud profile lands. The state literal above seeds
   avatarUrl from localStorage (the cloud bake — for Yasha a rotated
   pre-v15 copy), so the first profile render showed the cloud photo
   and applyRemoteProfile swapped it to the local pick seconds later:
   a visible swap on exactly the screen the push-entry path lands on.
   When this device holds a local photo the cloud has not confirmed
   (localPhotoWins), the stored URL is NOT seeded — state starts
   URL-less and every render shows the local photo until the heal
   re-upload makes the two copies identical. The stored key itself is
   left in place: cloudSyncNow echoes it back while the local photo
   wins, so a sync can never wipe the cloud copy's URL from the
   profile row before the heal lands. */
if (localPhotoWins()) state.avatarUrl = null;
function places(){ return PLACES_BY_CITY[state.city.id]; }
function $(s){ return document.querySelector(s); }
function $$(s){ return Array.prototype.slice.call(document.querySelectorAll(s)); }
function heatClass(h){ return h>=70 ? "hot" : (h>=40 ? "mid" : "low"); }
function heatLabel(h){ return h>=70 ? t("🔥 жарко") : (h>=40 ? t("средне") : t("пусто")); }
function distKm(a,b){
  var R=6371, dLat=(b.lat-a.lat)*Math.PI/180, dLng=(b.lng-a.lng)*Math.PI/180;
  var x=Math.sin(dLat/2)*Math.sin(dLat/2)+Math.cos(a.lat*Math.PI/180)*Math.cos(b.lat*Math.PI/180)*Math.sin(dLng/2)*Math.sin(dLng/2);
  return R*2*Math.atan2(Math.sqrt(x),Math.sqrt(1-x));
}
function fmtDist(km){ return km<1 ? tf("{v} м", { v: Math.round(km*1000) }) : tf("{v} км", { v: (LANG === "ru" ? km.toFixed(1).replace(".",",") : km.toFixed(1)) }); }
function fmtRating(r){ return LANG === "ru" ? String(r).replace(".",",") : String(r); }
function mePos(){
  if (state.geo) return state.geo; /* real position when geolocation is granted */
  return { lat: state.city.lat + 0.0022, lng: state.city.lng + 0.0022 };
}

/* ================= Stable heat =================
   Heat is a deterministic function of the place id, the current
   15-minute window and the local time of day: it does NOT jump on
   re-renders or reloads inside the window, and every counter, card
   and popup reads the number from this one source. */
function heatWindow(){ return Math.floor(Date.now() / 900000); }
/* Honest daily curve (wave 2): the city sleeps at night and peaks in the
   evening. Anchors are [hour, factor]; between them we interpolate, so
   02–06 is nearly empty, mornings rise, evenings peak at 20–24. The
   per-place hash stays as a small ±2 variation inside the curve. */
var DAY_CURVE = [[0,0.45],[2,0.12],[5,0.08],[7,0.30],[10,0.35],[11,0.50],[16,0.65],[17,0.80],[19,0.85],[20,1.00],[24,1.00]];
function dayCurveFactor(d){
  var h = d.getHours() + d.getMinutes() / 60;
  for (var i = 1; i < DAY_CURVE.length; i++){
    if (h <= DAY_CURVE[i][0]){
      var a = DAY_CURVE[i - 1], b = DAY_CURVE[i];
      return a[1] + (b[1] - a[1]) * ((h - a[0]) / (b[0] - a[0]));
    }
  }
  return 1;
}
function heatOf(p){
  if (!openStatus(p).open) return 0; /* closed by its own hours — no fake buzz */
  var drift = (hashStr(p.id + "@" + heatWindow()) % 5) - 2;
  var v = Math.round(p.heat * dayCurveFactor(new Date())) + drift;
  return Math.max(0, Math.min(97, v));
}
/* The one honest heat label used by cards, sheets and popups: a closed
   place says «закрыто» instead of a percentage. */
function heatBadge(p){
  if (!openStatus(p).open) return t("закрыто");
  var h = heatOf(p);
  return heatLabel(h) + " · " + h + "%";
}

/* ================= Russian plurals ================= */
function pluralRu(n, forms){
  var m10 = n % 10, m100 = n % 100;
  if (m10 === 1 && m100 !== 11) return forms[0];
  if (m10 >= 2 && m10 <= 4 && (m100 < 10 || m100 >= 20)) return forms[1];
  return forms[2];
}
function hotWord(n){ return pl(n, "hotPlace"); }
function placeWord(n){ return pl(n, "place"); }

/* ================= Your ghost's own number =================
   Every ghost gets a STABLE personal number: for a signed-in user it is
   hashed from the cloud profile id (same number on every device), for a
   guest — from a local seed generated once and kept in localStorage. */
function ghostSeed(){
  var s = lsGet("tirada_ghost_seed", null);
  if (!s){
    s = "guest-" + Date.now().toString(36) + "-" + Math.floor(Math.random() * 1e9).toString(36);
    lsSet("tirada_ghost_seed", s);
  }
  return s;
}
function ghostNumberFor(id){ return 100 + (hashStr("ghost#" + id) % 9900); /* 100..9999 */ }
function ghostNumber(){
  var src = (typeof cloudUser !== "undefined" && cloudUser && cloudUser.id) ? cloudUser.id : ghostSeed();
  return ghostNumberFor(src);
}

/* Honest distance label: straight-line, and says from whom */
function distFromText(p){
  return tf("{from} · по прямой: {d}", { from: state.geo ? t("от тебя") : t("от центра города"), d: fmtDist(distKm(mePos(), p)) });
}

/* ================= Place details (demo data, deterministic) ================= */
var STREET_POOL = ["ул. Герцль","ул. Вайцман","ул. Бен-Гурион","ул. Жаботински","ул. Бялик","ул. Соколов","ул. Ротшильд","ул. Дизенгоф","ул. Аленби","ул. Левински"];
function placeAddress(p){
  if (p.real || p.local){
    /* Hand-added local spots carry hand-written addresses: show the
       he/en variant when the entry provides one (CUSTOM_PLACES). Real
       Google addresses are source data, like place names. */
    if (LANG === "he" && p.addressHe) return p.addressHe;
    if (LANG === "en" && p.addressEn) return p.addressEn;
    return p.address || "";
  }
  var r = rng(hashStr("addr|" + p.id));
  var pool = (LANG !== "ru" && typeof STREET_POOL_I18N !== "undefined" && STREET_POOL_I18N[LANG]) || STREET_POOL;
  return pool[Math.floor(r() * pool.length)] + ", " + (1 + Math.floor(r() * 120));
}
var HOURS = { bar:[18,3], club:[21,4], cafe:[8,23], beach:[0,24], park:[6,23], view:[0,24], prom:[0,24], roof:[17,2], hookah:[16,2], stage:[10,22], market:[7,19] };
function fmtHour(h){ h = ((h % 24) + 24) % 24; return (h < 10 ? "0" : "") + h + ":00"; }
function hoursText(p){
  var hh = HOURS[p.type] || [9,22];
  if (hh[0] === 0 && hh[1] === 24) return t("Круглосуточно");
  return fmtHour(hh[0]) + "–" + fmtHour(hh[1]);
}
function openStatus(p){
  var hh = HOURS[p.type] || [9,22], o = hh[0], c = hh[1];
  if (o === 0 && c === 24) return { open: true, text: t("Открыто сейчас · круглосуточно") };
  var d = new Date(), now = d.getHours() + d.getMinutes() / 60, open;
  if (c > o) open = (now >= o && now < c); else open = (now >= o || now < c);
  if (open) return { open: true, text: tf("Открыто сейчас · до {h}", { h: fmtHour(c) }) };
  return { open: false, text: tf("Откроется в {h}", { h: fmtHour(o) }) };
}
/* Google price levels for real venues: 0 free … 4 very expensive.
   One display format everywhere (card, sheet, map popup): the level's
   symbols + word from PRICE_LEVELS, always through t() so he/en match.
   Commercial places with a null level show NO price line — nothing is
   invented. Open public spaces (park / beach / viewpoint / promenade)
   are the one exception: they are free by nature, Google itself rates
   every park it lists at level 0, and the generated catalogue has
   always shown them as free — so a null level there reads «Бесплатно»
   for real and local spots too, instead of a mysteriously empty line
   next to an identical free park across the street. */
var PRICE_LEVELS = { 0:"Бесплатно", 1:"₪ · недорого", 2:"₪₪ · умеренно", 3:"₪₪₪ · дорого", 4:"₪₪₪₪ · очень дорого" };
var FREE_TYPES = { park:1, beach:1, view:1, prom:1 };
/* Generated (fallback) places have no Google level; map each type to
   the equivalent PRICE_LEVELS entry so they render in the exact same
   symbols + word format as real venues instead of bare symbols. */
var GEN_PRICE_LEVEL = { bar:2, club:3, cafe:1, market:1, hookah:2, stage:2, roof:3 };
function priceOf(p){
  if (p.real){
    if (p.priceLevel === null || p.priceLevel === undefined)
      return FREE_TYPES[p.type] ? t("Бесплатно") : "";
    return t(PRICE_LEVELS[p.priceLevel] || "");
  }
  if (p.local){
    /* Hand-added local spots carry no Google price level: open public
       spaces are free, anything else shows no price line rather than
       an invented one. */
    if (p.priceLevel !== null && p.priceLevel !== undefined) return t(PRICE_LEVELS[p.priceLevel] || "");
    return FREE_TYPES[p.type] ? t("Бесплатно") : "";
  }
  if (FREE_TYPES[p.type]) return t("Бесплатно");
  var gl = GEN_PRICE_LEVEL[p.type];
  return gl !== undefined ? t(PRICE_LEVELS[gl]) : "";
}
function ratingText(p){ return (typeof p.rating === "number" && p.rating > 0) ? fmtRating(p.rating) : "—"; }
function reviewsText(p){
  if (!p.real || !p.reviews) return "";
  return String(p.reviews).replace(/\B(?=(\d{3})+(?!\d))/g, " ") + " " + pl(p.reviews, "review");
}
function isFree(p){ return priceOf(p) === t("Бесплатно"); }
function ageOf(p){ return (p.type === "bar" || p.type === "club" || p.type === "roof") ? "18+" : t("Можно всем"); }

/* ================= Favorites & personal stats (local, from real actions) ================= */
function saveStats(){ lsSet("tirada_stats", state.stats); scheduleCloudSync(); }
function toggleFav(id){
  if (state.favs[id]) delete state.favs[id]; else state.favs[id] = 1;
  lsSet("tirada_favs", state.favs);
  favsDirty = true;
  scheduleCloudSync();
  renderPlaces();
  toast(state.favs[id] ? t("Добавлено в избранное ❤️") : t("Убрано из избранного"));
}
function markPlaceOpened(id){
  if (state.stats.places.indexOf(id) < 0){
    state.stats.places.push(id); saveStats(); renderStats();
  }
}
function countRouteBuilt(){ state.stats.routes++; saveStats(); renderStats(); }
function countDealNight(){
  var today = new Date().toDateString();
  if (state.stats.lastDealDay !== today){
    state.stats.lastDealDay = today; state.stats.nights++; saveStats(); renderStats();
  }
}

/* ================= Ghost XP & levels (wave 3) =================
   XP is DERIVED from the lifetime counters in stats (the same object that
   syncs to profiles.stats), so it is identical on every device and can be
   computed for friends from their cloud stats for the leaderboard:
     задание дня +20 · шаг квеста +15 · квест целиком +100 · маршрут +40 ·
     ночь в деле +30 · фото места +25 · голос +5 · серия: бонус ниже.
   Streak bonus is additive and quadratic — min(bestStreak,30)^2 * 2 —
   because a per-task multiplier cannot be applied retroactively to
   counters; the best streak is used so XP (and levels) never drop when
   a streak breaks. */
var LEVELS = [
  { xp: 0,    name: "Новичок" },
  { xp: 100,  name: "Бродяга" },
  { xp: 250,  name: "Тусовщик" },
  { xp: 500,  name: "Призрак района" },
  { xp: 900,  name: "Призрак города" },
  { xp: 1500, name: "Легенда ночей" },
  { xp: 2500, name: "Хранитель движа" },
  { xp: 4000, name: "Миф" }
];
function streakBonusXp(best){
  var s = Math.min(Math.max(0, Math.floor(+best || 0)), 30);
  return s * s * 2;
}
function xpOfStats(raw){
  var s = normalizeStats(raw);
  return s.tasks * 20 + s.questSteps * 15 + s.quests * 100 + s.routes * 40 +
         s.nights * 30 + s.photos * 25 + s.votes * 5 + s.aiXp +
         streakBonusXp(Math.max(s.bestStreak, s.streak));
}
function levelName(idx){ var C = contentI18n(); return (C && C.LEVELS && C.LEVELS[idx]) || LEVELS[idx].name; }
function levelOf(xp){
  var i = 0;
  while (i + 1 < LEVELS.length && xp >= LEVELS[i + 1].xp) i++;
  var cur = LEVELS[i], next = LEVELS[i + 1] || null;
  return { num: i + 1, name: levelName(i), xp: xp, next: next ? { xp: next.xp, name: levelName(i + 1) } : null,
           left: next ? next.xp - xp : 0,
           pct: next ? Math.min(100, Math.round((xp - cur.xp) / (next.xp - cur.xp) * 100)) : 100 };
}
function myXp(){ return xpOfStats(state.stats); }
function renderLevel(){
  var card = $("#levelCard"); if (!card) return;
  var xp = myXp(), lv = levelOf(xp), s = state.stats;
  /* Milestone: a real level-up (vs the level this device last saw)
     becomes a cloud event — friends and the user get a push. The
     first sighting only seeds the marker, never fires. */
  var prevLv = lsGet("tirada_ev_level", 0);
  if (prevLv && lv.num > prevLv){
    writeEvent("level_up", tf("⭐ {name} поднялся до уровня {num} · {lname}", { name: myDisplayName(), num: lv.num, lname: lv.name }));
    fireConfetti();
    /* v28: crossing into level 3 opens the secret places — repaint
       the surfaces that mask them and say so out loud. */
    if (prevLv < 3 && lv.num >= 3){
      toast(t("🔓 Секретные места открыты!"));
      try { renderPlaces(); } catch (e) {}
      try { if (map && mapReady) renderMapMarkers(); } catch (e) {}
    }
  }
  if (lv.num !== prevLv) lsSet("tirada_ev_level", lv.num);
  var bEl = $("#levelBadge"); if (bEl) bEl.textContent = lv.num;
  var nEl2 = $("#levelName"); if (nEl2) nEl2.textContent = lv.name;
  var xEl = $("#levelXpText"); if (xEl) xEl.textContent = xp + " XP";
  var fEl = $("#levelFill"); if (fEl) fEl.style.width = lv.pct + "%";
  var nxEl = $("#levelNext");
  if (nxEl) nxEl.textContent = lv.next
    ? tf("До уровня {n} «{name}» осталось {left} XP", { n: lv.num + 1, name: lv.next.name, left: lv.left })
    : t("Максимальный уровень — ты и есть движ 👑");
  var bd = $("#levelBreakdown");
  if (bd) bd.textContent = tf("задания {a} · квест {b} · маршруты {c} · ночи {d} · фото {e} · голоса {f} · серия {g}",
    { a: s.tasks * 20, b: s.questSteps * 15 + s.quests * 100, c: s.routes * 40, d: s.nights * 30,
      e: s.photos * 25, f: s.votes * 5, g: streakBonusXp(Math.max(s.bestStreak, s.streak)) });
}
/* One-time seed for the wave-3 counters: older builds never counted total
   tasks / quest steps / votes, so derive what is honestly derivable from
   the local records that DO exist — completed quests from the badge count,
   quest steps as 5 per finished quest plus this week's progress, tasks at
   least the current streak, streak mirrored from tirada_streak. From now
   on every counter is incremented at the real action. */
function seedStatsWave3(){
  if (lsGet("tirada_stats_w3", 0)) return;
  var st = objOr(lsGet("tirada_streak", null), { last: "", streak: 0 });
  var qb = lsGet("tirada_quest_badges", 0);
  if (typeof qb !== "number" || !isFinite(qb)) qb = 0;
  var q = objOr(lsGet("tirada_quest", null), { week: -1, done: 0 });
  var s = state.stats;
  s.quests = Math.max(s.quests || 0, qb);
  s.questSteps = Math.max(s.questSteps || 0, s.quests * 5 + (q.week === weekIndex() ? (q.done || 0) : 0));
  s.tasks = Math.max(s.tasks || 0, st.streak || 0);
  s.streak = Math.max(s.streak || 0, st.streak || 0);
  s.bestStreak = Math.max(s.bestStreak || 0, st.streak || 0);
  lsSet("tirada_stats", s);
  lsSet("tirada_stats_w3", 1);
}
function renderStats(){
  var nEl = $("#statNights"), pEl = $("#statPlaces"), rEl = $("#statRoutes"), box = $("#achievements");
  if (!nEl) return;
  var np = state.stats.places.length;
  nEl.textContent = state.stats.nights;
  pEl.textContent = np;
  rEl.textContent = state.stats.routes;
  var phEl = $("#statPhotos"); if (phEl) phEl.textContent = state.stats.photos || 0;
  var nl = $("#statNightsLabel"), plEl = $("#statPlacesLabel"), rl = $("#statRoutesLabel");
  if (nl) nl.textContent = pl(state.stats.nights, "nightIn");
  if (plEl) plEl.textContent = pl(np, "placeOpened");
  if (rl) rl.textContent = pl(state.stats.routes, "routeBuilt");
  renderLevel();
  if (typeof renderLeaderboard === "function") renderLeaderboard();
  if (!box) return;
  var s = state.stats;
  var friendCount = 0;
  if (typeof friendsRows !== "undefined" && typeof cloudUser !== "undefined" && cloudUser){
    friendsRows.forEach(function(r){ if (r.status === "accepted") friendCount++; });
  }
  var lvNow = levelOf(myXp());
  var ach = [
    { icon:"🏆", name:"Первый движ", have: np >= 1, need: t("открой первое место") },
    { icon:"🗺️", name:"Исследователь", have: np >= 5, need: tf("ещё {n} {w}", { n: Math.max(0, 5 - np), w: placeWord(Math.max(0, 5 - np)) }) },
    { icon:"🎯", name:"Задачник", have: s.tasks >= 25, need: tf("ещё {n} {w}", { n: Math.max(0, 25 - s.tasks), w: pl(Math.max(0, 25 - s.tasks), "dailyTaskW") }) },
    { icon:"🏅", name:"Квест недели", have: s.quests >= 1, need: t("пройди квест недели на экране «Маршрут»") },
    { icon:"🔥", name:"7 ночей в деле", have: s.nights >= 7, need: tf("ещё {n} {w}", { n: Math.max(0, 7 - s.nights), w: pl(Math.max(0, 7 - s.nights), "night") }) },
    { icon:"🧭", name:"Маршрутник", have: s.routes >= 10, need: tf("ещё {n} {w}", { n: Math.max(0, 10 - s.routes), w: pl(Math.max(0, 10 - s.routes), "route") }) },
    { icon:"📸", name:"Глаз города", have: s.photos >= 5, need: tf("ещё {n} фото на страницах мест", { n: Math.max(0, 5 - s.photos) }) },
    { icon:"📷", name:"Фотограф города", have: s.photos >= 50, need: tf("ещё {n} фото на страницах мест", { n: Math.max(0, 50 - s.photos) }) },
    { icon:"🌟", name:"Неделя серии", have: s.bestStreak >= 7, need: tf("серия заданий 7 дней подряд, сейчас лучшая — {n}", { n: s.bestStreak }) },
    { icon:"🌙", name:"Месяц серии", have: s.bestStreak >= 30, need: tf("серия заданий 30 дней подряд, сейчас лучшая — {n}", { n: s.bestStreak }) },
    { icon:"⭐", name:"Призрак города", have: lvNow.num >= 5, need: tf("нужен уровень 5, сейчас {n}", { n: lvNow.num }) },
    { icon:"👻", name:"Первый друг", have: friendCount >= 1, need: t("добавь первого друга в блоке «Друзья»") },
    { icon:"🥂", name:"Своя компания", have: friendCount >= 5, need: tf("ещё {n} {w} в друзья", { n: Math.max(0, 5 - friendCount), w: pl(Math.max(0, 5 - friendCount), "friend") }) }
  ];
  /* Milestone: a badge that flips to earned for the first time on
     this device becomes a cloud event (friends + the user pushed).
     The first render only seeds the known set, never fires. */
  var knownBadges = lsGet("tirada_ev_badges", null);
  if (!Array.isArray(knownBadges)) knownBadges = null; /* legacy/damaged value -> treat as first sighting, never .indexOf a non-array */
  var haveNow = ach.filter(function(a){ return a.have; }).map(function(a){ return a.name; });
  if (knownBadges){
    var freshBadges = 0;
    haveNow.forEach(function(nm){
      if (knownBadges.indexOf(nm) < 0){
        freshBadges++;
        writeEvent("badge", tf("🏅 {name} получил бейдж «{b}»", { name: myDisplayName(), b: t(nm) }));
      }
    });
    if (freshBadges) fireConfetti();
  }
  lsSet("tirada_ev_badges", haveNow);
  box.innerHTML = ach.map(function(a){
    return '<span class="achip' + (a.have ? "" : " locked") + '">' + a.icon + " " + t(a.name) +
      (a.have ? "" : '<small>' + t("не хватает: ") + a.need + "</small>") + "</span>";
  }).join("");
}

/* ================= Place detail sheet ================= */
var currentSheetPlaceId = null;
function openPlaceSheet(p){
  if (!p) return;
  /* v28 hardening: unhide the sheet FIRST and never let a build
     error look like a dead tap — on failure the sheet still opens
     with a minimal fallback and the boot trace names the place. */
  var sheetEl = $("#placeSheet");
  if (sheetEl) sheetEl.hidden = false;
  try { openPlaceSheetInner(p); }
  catch (e) {
    tracePush("sheet", "open failed " + (p && p.id) + ": " + (e && e.message));
    var b = $("#placeSheetBody");
    if (b) b.innerHTML = '<div class="ps-body"><div class="ps-name">' + (isSecretLocked(p) ? t("🔒 Секретное место") : escHtml(p.name || "")) + '</div>' +
      '<button class="btn-alt" id="psCloseFallback">' + t("Закрыть") + "</button></div>";
    var fb2 = $("#psCloseFallback");
    if (fb2) fb2.addEventListener("click", closePlaceSheet);
  }
  try { updateAmbientForPlace(p); } catch (e) {}
}
function openPlaceSheetInner(p){
  currentSheetPlaceId = p.id;
  /* v28: a locked secret place opens as a lock — no name, photo,
     song, price or task leaks, and it does not count as opened. */
  if (isSecretLocked(p)){
    $("#placeSheetBody").innerHTML =
      '<div class="ps-art ps-art-lock"><div class="ps-lock-emoji">🔒</div>' +
      '<button class="sheet-close ps-close" id="psClose" aria-label="' + t("Закрыть") + '">✕</button></div>' +
      '<div class="ps-body"><div class="ps-name">' + t("🔒 Секретное место") + '</div>' +
      '<div class="ps-sub">' + cityName(state.city) + '</div>' +
      '<div class="ps-task">🔒 ' + tf("Откроется на уровне 3 — «{name}». Качай XP заданиями дня, квестами и маршрутами — и возвращайся.", { name: levelName(2) }) + '</div></div>';
    $("#psClose").addEventListener("click", closePlaceSheet);
    return;
  }
  markPlaceOpened(p.id);
  var h = heatOf(p), st = openStatus(p), fav = !!state.favs[p.id];
  $("#placeSheetBody").innerHTML =
    '<div class="ps-art" style="background:' + p.grad + '">' + emojiImg(p.art, "ps-art-img") +
      '<button class="sheet-close ps-close" id="psClose" aria-label="' + t("Закрыть") + '">✕</button>' +
      '<span class="art-heat ' + heatClass(h) + '">' + heatBadge(p) + "</span></div>" +
    '<div class="ps-body">' +
      '<div class="ps-name">' + p.name + "</div>" +
      '<div class="ps-sub">' + (p.local ? p.typeLabel + " · 🏠 " + t("Местное место") : p.typeLabel + " · ★ " + ratingText(p) + (reviewsText(p) ? " · " + reviewsText(p) : "")) + "</div>" +
      '<div class="ps-open ' + (st.open ? "is-open" : "is-closed") + '">' + st.text + "</div>" +
      (priceOf(p) ? '<div class="ps-price-big">' + t("💰 Цены:") + " " + priceOf(p) + "</div>" : "") +
      (friendsAtPlaceNames(p.id).length ? '<div class="ps-friends">' + t("Здесь сейчас:") + " 👻 " + friendsAtPlaceNames(p.id).map(escHtml).join(", ") + "</div>" : "") +
      '<div class="ps-rows">' +
        '<div class="ps-row"><span>📍 ' + t("Адрес") + '</span><b>' + (placeAddress(p) ? placeAddress(p) + ", " : "") + cityName(state.city) + "</b></div>" +
        '<div class="ps-row"><span>🕐 ' + t("Часы") + '</span><b>' + hoursText(p) + "</b></div>" +
        '<div class="ps-row"><span>🔞 ' + t("Возраст") + '</span><b>' + ageOf(p) + "</b></div>" +
        '<div class="ps-row"><span>📏 ' + t("Расстояние") + '</span><b>' + distFromText(p) + "</b></div>" +
        '<div class="ps-row"><span>🎵 ' + t("Вайб места") + '</span><b>' + p.song + "</b></div>" +
      "</div>" +
      (p.real ? '<div class="ps-google">' + t("★ Рейтинг, отзывы и цены — по данным Google") + '</div>' : "") +
      (p.local ? '<div class="ps-google">' + t("🏠 Местное место — добавлено по словам местных, без рейтинга Google") + '</div>' : "") +
      '<div class="ps-task">🎯 ' + p.task + "</div>" +
      '<div class="ps-actions">' +
        '<button class="btn-yes" id="psRoute">🚗 ' + t("Маршрут") + '</button>' +
        '<button class="btn-alt" id="psCheckin">📍 ' + t("Я здесь") + '</button>' +
        '<button class="btn-alt ps-fav' + (fav ? " active" : "") + '" id="psFav">' + (fav ? t("❤️ В избранном") : t("🤍 В избранное")) + "</button>" +
      "</div>" +
      '<div class="ps-photos">' +
        '<div class="ps-photos-title">' + t("📸 Фото призраков здесь") + '</div>' +
        '<div class="ps-photos-grid" id="psPhotosGrid"><div class="friend-empty">' + t("Загружаю фото…") + '</div></div>' +
      "</div>" +
    "</div>";
  $("#placeSheet").hidden = false;
  $("#psClose").addEventListener("click", closePlaceSheet);
  $("#psRoute").addEventListener("click", function(){ closePlaceSheet(); routeTo(p); });
  $("#psFav").addEventListener("click", function(){ toggleFav(p.id); openPlaceSheet(p); });
  $("#psCheckin").addEventListener("click", function(){
    if (eventCooldownOk("tirada_ev_checkin", p.id, 30 * 60000))
      writeEvent("checkin", tf("📍 {name} чекинится: {place}", { name: myDisplayName(), place: p.name }));
    startPhotoFlow(p, function(){ toast(t("Ты здесь! 📍 Чек-ин засчитан")); });
  });
  loadPlaceGallery(p.id);
}
function closePlaceSheet(){ $("#placeSheet").hidden = true; try { updateAmbientForPlace(null); } catch (e) {} }
function openPlaceSheetById(id){
  var f = findPlace(id);
  if (!f) return;
  if (f.cityId !== state.city.id) setCity(f.cityId);
  openPlaceSheet(f.place);
}
$("#placeSheet").addEventListener("click", function(e){ if (e.target === this) closePlaceSheet(); });

/* ================= My avatar: emoji face or own photo ================= */
function currentAvatarHtml(){
  /* v26: the source comes from avatarDisplaySrc() — the single
     priority (local photo while unconfirmed, cloud URL once synced
     or when there is no local photo). The old url-first order here
     was the visible half of the push-entry swap: the boot-seeded
     cloud URL rendered first, the local pick replaced it seconds
     later when the profile landed. */
  var src = avatarDisplaySrc();
  if (src) return '<img class="avphoto" src="' + src + '" alt="' + t("Аватарка призрака") + '">';
  return avatarFace(state.myAvatar);
}

/* ================= Real geolocation =================
   With permission, your ghost stands on your REAL coordinates: the nearest
   city is auto-selected and routes start from where you actually are.
   Denied/unavailable → quiet fallback to the demo position, one small toast. */
var geoWatchId = null, geoToastShown = false;
function startGeoWatch(){
  if (geoWatchId !== null || !navigator.geolocation) return;
  geoWatchId = navigator.geolocation.watchPosition(function(pos){
    state.geo = { lat: pos.coords.latitude, lng: pos.coords.longitude };
    if (meMarker) meMarker.setLngLat([state.geo.lng, state.geo.lat]);
    trackMySpeed(state.geo.lat, state.geo.lng);
    cloudGeoSync();
    checkSelfAtPlace();
  }, function(){}, { enableHighAccuracy: false, maximumAge: 60000, timeout: 20000 });
}
function applyGeo(lat, lng){
  state.geo = { lat: lat, lng: lng };
  trackMySpeed(lat, lng);
  var gb = $("#geoBtn"); if (gb) gb.hidden = true;
  var near = nearestCity(state.geo);
  if (near && near.id !== state.city.id && distKm(state.geo, near) <= 30) setCity(near.id);
  if (meMarker) meMarker.setLngLat([lng, lat]);
  if (map) map.flyTo({ center: [lng, lat], zoom: Math.max(map.getZoom(), 15), duration: 800 });
  cloudGeoSync();
  try { loadWeather(); } catch (e) {}
  checkSelfAtPlace();
  startGeoWatch();
}
function requestGeo(manual){
  if (!navigator.geolocation){
    if (manual) toast(t("Геолокация недоступна — демо-режим 👻"));
    return;
  }
  navigator.geolocation.getCurrentPosition(function(pos){
    applyGeo(pos.coords.latitude, pos.coords.longitude);
  }, function(){
    if (manual || !geoToastShown){ toast(t("Геолокация выключена — демо-режим 👻")); geoToastShown = true; }
  }, { enableHighAccuracy: true, timeout: 8000, maximumAge: 30000 });
}
/* Toasts: a QUEUE, one at a time, pinned to the TOP of the screen so they
   never overlay sheets or the tab bar */
var toastQueue = [], toastBusy = false;
function toast(msg){ toastQueue.push(msg); pumpToasts(); }
function pumpToasts(){
  if (toastBusy || !toastQueue.length) return;
  toastBusy = true;
  var t = $("#toast");
  t.textContent = toastQueue.shift();
  t.hidden = false;
  setTimeout(function(){
    t.hidden = true; toastBusy = false;
    setTimeout(pumpToasts, 150);
  }, 2300);
}

/* ================= Map (MapLibre GL — vector, WebGL) =================
   v4: the raster Leaflet map is gone. Bump/Zenly smoothness comes from a
   vector map rendered by the GPU: pinch zoom is CONTINUOUS (fractional
   zooms are real rendered frames, not rescaled raster tiles), and pan/zoom
   never repaints a filtered layer. Style: CARTO dark-matter GL, recolored
   to Yasha's palette (dark-green land, dark-turquoise water) — map-style.js. */
var map = null, mapReady = false, meMarker = null, placeMarkers = {}, badgeMarkers = [], friendMarkers = {};
/* v21 map lifecycle state: the last classified map error (for the
   diagnostics block), whether this environment can EVER host a map
   (no WebGL / no library — retries are pointless then), the double-init
   guard, and the repaint retry throttle. */
var mapLastError = null, mapUnsupported = false, mapInitInFlight = false,
    mapLastRetryAt = 0, mapErrTraceKind = "", mapErrTraceAt = 0;
var MAP_STYLE_DEADLINE_MS = 20000;
/* Milestones of the CURRENT map instance, for the diagnostics block:
   the 2026-11-23 phone screenshot showed a map tab with no tiles, no
   fallback text and — the telling part — no ghost marker, although
   meMarker is created synchronously inside initMap, before 'load'.
   These flags (plus the trace lines written at each milestone) show
   exactly how far the chain got: constructed? marker created? */
var mapConstructed = false, meMarkerCreated = false;

/* Map markers v3.6 (Snap Map style): places = small round badges by heat with a white
   SVG icon of the place type; ghosts on the map are you — a round avatar
   (Emoji CDN face on a gradient) — plus your accepted friends (see the
   friends-on-map module below). No demo people. */
var TYPE_ICONS = {
  bar:   '<path d="M3 4h18l-8.2 8.6V19h3.2v2H8v-2h3v-6.4L3 4z"/>',
  club:  '<path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/>',
  park:  '<path d="M12 2L6.5 9h2.7L5 14.5h5.5V22h3v-7.5H19L14.8 9h2.7L12 2z"/>',
  view:  '<path d="M12 4.5C7 4.5 2.73 7.61 1 12c1.73 4.39 6 7.5 11 7.5s9.27-3.11 11-7.5c-1.73-4.39-6-7.5-11-7.5zm0 12.5a5 5 0 1 1 0-10 5 5 0 0 1 0 10zm0-8a3 3 0 1 0 0 6 3 3 0 0 0 0-6z"/>',
  beach: '<path d="M6.76 4.84l-1.8-1.79-1.41 1.41 1.79 1.79 1.42-1.41zM4 10.5H1v2h3v-2zm9-9.95h-2V3.5h2V.55zm7.45 3.91l-1.41-1.41-1.79 1.79 1.41 1.41 1.79-1.79zm-3.21 13.7l1.79 1.8 1.41-1.41-1.8-1.79-1.4 1.4zM20 10.5v2h3v-2h-3zm-8-5c-2.76 0-5 2.24-5 5s2.24 5 5 5 5-2.24 5-5-2.24-5-5-5zm-1 13.95h2V16.5h-2v2.95zm-7.45-3.91l1.41 1.41 1.79-1.79-1.41-1.41-1.79 1.79z"/>',
  cafe:  '<path d="M20 3H4v10c0 2.21 1.79 4 4 4h6c2.21 0 4-1.79 4-4v-3h2c1.11 0 2-.9 2-2V5c0-1.11-.89-2-2-2zm0 5h-2V5h2v3zM2 21h18v-2H2v2z"/>',
  roof:  '<path d="M3 21h18v-2.4H3V21zM5.5 17.5V4.8L13 3v14.5h-2.6v-4H8.1v4H5.5zm10.1 0V9.2h3.4v8.3h-3.4z"/>',
  hookah:'<path d="M19.35 10.04A7.49 7.49 0 0 0 12 4C9.11 4 6.6 5.64 5.35 8.04A5.99 5.99 0 0 0 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96z"/>',
  prom:  '<path d="M12 2s6.5 7.05 6.5 11.5a6.5 6.5 0 1 1-13 0C5.5 9.05 12 2 12 2z"/>',
  stage: '<path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21 12 17.27z"/>',
  market:'<path d="M17 18c-1.1 0-1.99.9-1.99 2S15.9 22 17 22s2-.9 2-2-.9-2-2-2zM1 2v2h2l3.6 7.59-1.35 2.45C5.09 14.32 5 14.65 5 15c0 1.1.9 2 2 2h12v-2H7.42c-.14 0-.25-.11-.25-.25l.03-.12.9-1.63h7.45c.75 0 1.41-.41 1.75-1.03l3.58-6.49c.08-.13.12-.27.12-.42 0-.55-.45-1-1-1H5.21l-.94-2H1zm16 16c-1.1 0-1.99.9-1.99 2s.89 2 1.99 2 2-.9 2-2-.9-2-2-2z"/>'
};
function badgeHtml(p){
  var delay = (p.name.length % 7) * 0.33;
  return '<div class="place-badge ' + heatClass(heatOf(p)) + '"><span class="badge-ring" style="animation-delay:' + delay.toFixed(2) + 's"></span><svg viewBox="0 0 24 24" aria-hidden="true">' + (TYPE_ICONS[p.type] || TYPE_ICONS.stage) + '</svg></div>';
}
function badgeEl(p){
  var el = document.createElement("div");
  el.className = "badge-marker";
  el.innerHTML = badgeHtml(p);
  return el;
}
function ghostHtml(){
  return '<div class="ghost-round me mode-' + state.mode + '">' + currentAvatarHtml() + '</div>';
}
function ghostEl(){
  var el = document.createElement("div");
  el.className = "ghost-marker";
  el.style.zIndex = "3"; /* your ghost renders (and takes taps) above place badges and friend markers */
  el.innerHTML = ghostHtml();
  return el;
}
function updateMeMarker(){
  if (meMarker) meMarker.getElement().innerHTML = ghostHtml();
}
function myPopupHtml(){
  var xp = myXp(), lv = levelOf(xp);
  return '<div class="pop-card">' +
    '<div class="pop-head me"><div class="pop-name">' + tf("Это ты — призрак #{n}", { n: ghostNumber() }) + '</div><span class="pop-tag">' + t("ты") + '</span></div>' +
    '<div class="pop-status">' + t(MODES[state.mode].mapStatus) + '</div>' +
    '<div class="pop-level">⭐ ' + t("Уровень") + " " + lv.num + ' · ' + lv.name + ' · ' + xp + ' XP</div>' +
    speedLineHtml(mySpeedState) +
    '<div class="pop-note">' + t("Сменить вид и режим — на экране «Профиль».") + '</div></div>';
}
function popupHtml(p){
  /* v28: locked secret — the map popup shows the lock, never the name. */
  if (isSecretLocked(p)){
    return '<div class="pop-card"><div class="pop-head"><div class="pop-name">' + t("🔒 Секретное место") + '</div></div>' +
      '<div class="pop-meta">' + tf("Откроется на уровне 3 — «{name}»", { name: levelName(2) }) + '</div>' +
      '<button class="pop-btn" data-place-open="' + p.id + '">' + t("Смотреть место →") + '</button></div>';
  }
  var h = heatOf(p), hc = heatClass(h);
  return '<div class="pop-card">' +
    '<div class="pop-head ' + hc + '"><div class="pop-name">' + p.name + '</div>' +
    '<span class="pop-heat-badge ' + hc + '">' + heatBadge(p) + '</span></div>' +
    '<div class="pop-meta">' + (p.local ? '🏠 ' + t("Местное место") : '★ ' + ratingText(p) + (reviewsText(p) ? ' · ' + reviewsText(p) : '')) + ' · ' + distFromText(p) + '</div>' +
    (priceOf(p) ? '<div class="pop-price">' + t("💰 Цены:") + " " + priceOf(p) + '</div>' : '') +
    '<div class="pop-song">🎵 ' + t("Вайб места:") + " " + p.song + '</div>' +
    '<button class="pop-btn route-btn" data-route-place="' + p.id + '">🚗 ' + t("Маршрут сюда") + '</button>' +
    '<button class="pop-btn" data-place-open="' + p.id + '">' + t("Смотреть место →") + '</button></div>';
}
function findPlace(id){
  for (var cid in PLACES_BY_CITY){
    var arr = PLACES_BY_CITY[cid];
    for (var i=0;i<arr.length;i++) if (arr[i].id === id) return { place: arr[i], cityId: cid };
  }
  return null;
}
function nearestCity(ll){
  var best = null, bd = 1e9;
  CITIES.forEach(function(c){ var d = distKm(ll, c); if (d < bd){ bd = d; best = c; } });
  return best;
}
var mapBadgesCityId = null;
var popupOpenNow = false;
var mapMoving = false; /* true between movestart/moveend: CSS anims pause, fake-live touches no DOM */
var dotPopup = null;
function makePopup(html, offset){
  var popup = new maplibregl.Popup({ offset: offset || 20, closeOnClick: false, maxWidth: "280px" }).setHTML(html);
  popup.on("open", function(){
    popupOpenNow = true;
    closeOtherPopups(popup);
  });
  popup.on("close", function(){
    popupOpenNow = false;
    refreshMapMode();
  });
  return popup;
}
function allPopups(){
  var list = [];
  badgeMarkers.forEach(function(m){ var p = m.getPopup(); if (p) list.push(p); });
  if (meMarker){ var mp = meMarker.getPopup(); if (mp) list.push(mp); }
  Object.keys(friendMarkers).forEach(function(id){ var fp = friendMarkers[id].getPopup(); if (fp) list.push(fp); });
  if (dotPopup) list.push(dotPopup);
  return list;
}
function closeOtherPopups(except){
  allPopups().forEach(function(p){ if (p !== except && p.isOpen()) p.remove(); });
}
function closeAllPopups(){
  allPopups().forEach(function(p){ if (p.isOpen()) p.remove(); });
}
function renderBadges(city){
  if (!map) return;
  clearBadges();
  (PLACES_BY_CITY[city.id] || []).forEach(function(p){
    /* Per-marker isolation: one bad place (broken popup data, bad coords)
       is skipped — the rest of the city's badges still render. */
    try {
      p._band = heatClass(heatOf(p)); /* badge restyles only when the band flips */
      var html;
      try { html = popupHtml(p); }
      catch(e2){ html = '<div class="pop-card"><div class="pop-name">' + escHtml(p.name || "") + '</div></div>'; }
      var m = new maplibregl.Marker({ element: badgeEl(p) })
        .setLngLat([p.lng, p.lat])
        .setPopup(makePopup(html, 20))
        .addTo(map);
      badgeMarkers.push(m);
      if (city.id === state.city.id) placeMarkers[p.id] = m;
    } catch(e){ /* skip this place only */ }
  });
  mapBadgesCityId = city.id;
}
function clearBadges(){
  badgeMarkers.forEach(function(m){ m.remove(); });
  badgeMarkers = [];
  placeMarkers = {};
  mapBadgesCityId = null;
}
function setDotsVisible(v){
  if (map && mapReady && map.getLayer("places-dots"))
    map.setLayoutProperty("places-dots", "visibility", v ? "visible" : "none");
}
/* Two map modes: zoomed out — EVERY place in Israel as a compact GL circle;
   zoomed in (z>=11) near a city — that city's full DOM badges. Your own
   ghost marker sits on the map in both modes. Switching is deferred while
   a popup is open. */
function refreshMapMode(){
  if (!map || !mapReady || popupOpenNow) return;
  var near = null;
  if (map.getZoom() >= 11){
    near = nearestCity(map.getCenter());
    if (near && distKm(map.getCenter(), near) > 30) near = null;
  }
  if (!near){
    setDotsVisible(true);
    if (badgeMarkers.length) clearBadges();
    return;
  }
  setDotsVisible(false);
  if (mapBadgesCityId !== near.id) renderBadges(near);
}
function renderMapMarkers(){
  if (!map) return;
  var me = mePos();
  if (meMarker) meMarker.setLngLat([me.lng, me.lat]);
  refreshMapMode();
}
/* ================= MapLibre layers & init ================= */
var EMPTY_FC = { type: "FeatureCollection", features: [] };
function initMapLayers(){
  if (mapReady || !map) return;
  mapReady = true;
  /* Country dots: every place of every city as one GeoJSON circle layer.
     Per-place isolation: one malformed place (a missing field in the
     catalogue data) must not kill the whole layer — or the whole map. */
  var feats = [];
  CITIES.forEach(function(c){
    (PLACES_BY_CITY[c.id] || []).forEach(function(p){
      try {
        feats.push({
          type: "Feature",
          geometry: { type: "Point", coordinates: [p.lng, p.lat] },
          properties: { id: p.id, name: p.name, city: c.name, heat: heatOf(p), band: heatClass(heatOf(p)), closed: openStatus(p).open ? 0 : 1 }
        });
      } catch(e){ /* skip the bad place, keep the other ~1400 */ }
    });
  });
  var dotsOk = false;
  try {
    map.addSource("places-all", { type: "geojson", data: { type: "FeatureCollection", features: feats } });
    map.addLayer({
      id: "places-dots", type: "circle", source: "places-all",
      paint: {
        "circle-color": ["match", ["get", "band"], "hot", "#ff2213", "mid", "#ff9a3c", "#8a8f98"],
        "circle-radius": ["match", ["get", "band"], "hot", 5, "mid", 4, 3],
        "circle-stroke-color": "rgba(255,255,255,0.8)",
        "circle-stroke-width": 1,
        "circle-opacity": 0.95
      }
    });
    dotsOk = true;
  } catch(e){ /* no country dots — DOM badges near cities still work */ }
  if (dotsOk) map.on("click", "places-dots", function(e){
    /* Marker priority: a tap that lands on ANY DOM marker (your ghost, a
       friend, a place badge) belongs to that marker — its own popup is
       already toggling — so a place dot underneath must not hijack it. */
    var tgt = e.originalEvent && e.originalEvent.target;
    if (tgt && tgt.closest && tgt.closest(".maplibregl-marker")) return;
    /* Near-miss taps just beside your ghost (within its screen radius)
       also belong to the ghost: open the GHOST popup, not the place's. */
    if (meMarker){
      var gp = map.project(meMarker.getLngLat());
      var gdx = gp.x - e.point.x, gdy = gp.y - e.point.y;
      if (gdx * gdx + gdy * gdy <= 32 * 32){
        var mp = meMarker.getPopup();
        if (mp && !mp.isOpen()) meMarker.togglePopup();
        return;
      }
    }
    var f = e.features && e.features[0];
    if (!f) return;
    var pr = f.properties;
    if (dotPopup) dotPopup.remove();
    dotPopup = makePopup('<div class="pop-card">' +
      '<div class="pop-head ' + pr.band + '"><div class="pop-name">' + pr.name + '</div>' +
      '<span class="pop-heat-badge ' + pr.band + '">' + (pr.closed ? t("закрыто") : tf("движ {h}%", { h: pr.heat })) + '</span></div>' +
      '<div class="pop-meta">' + pr.city + '</div>' +
      '<button class="pop-btn" data-place-open="' + pr.id + '">' + t("Смотреть место →") + '</button></div>', 12);
    dotPopup.setLngLat(f.geometry.coordinates).addTo(map);
  });
  if (dotsOk) map.on("mouseenter", "places-dots", function(){ map.getCanvas().style.cursor = "pointer"; });
  if (dotsOk) map.on("mouseleave", "places-dots", function(){ map.getCanvas().style.cursor = ""; });
  /* Route layers (OSRM): white casing, neon red line, flowing dot pulse.
     Isolated: a route-layer failure must not take the dots/badges down. */
  try {
    map.addSource("route", { type: "geojson", data: EMPTY_FC });
    map.addLayer({ id: "route-casing", type: "line", source: "route",
      layout: { "line-cap": "round", "line-join": "round" },
      paint: { "line-color": "#ffffff", "line-width": 9, "line-opacity": 0.85 } });
    map.addLayer({ id: "route-line", type: "line", source: "route",
      layout: { "line-cap": "round", "line-join": "round" },
      paint: { "line-color": "#ff2a1e", "line-width": 5, "line-opacity": 1 } });
    map.addLayer({ id: "route-flow", type: "line", source: "route",
      layout: { "line-cap": "round", "line-join": "round" },
      paint: { "line-color": "#ffffff", "line-width": 2.5, "line-opacity": 0.95, "line-dasharray": [0, 4, 3] } });
  } catch(e){ /* routes just won't draw on the map */ }
  try { refreshMapMode(); } catch(e){}
}
/* Edge zoom is invisible by design — teach it exactly once, on the
   first map visit, with a small floating hint that fades away. */
function showZoomHintOnce(){
  if (lsGet("tirada_zoom_hint", false)) return;
  var h = $("#zoomHint");
  if (!h) return;
  /* the welcome sheet covers the map on a first visit — wait until it
     is gone, otherwise the hint burns unseen behind the sheet */
  var ws = $("#welcomeSheet");
  if (ws && !ws.hidden){ setTimeout(showZoomHintOnce, 900); return; }
  h.hidden = false;
  setTimeout(function(){
    h.classList.add("bye");
    setTimeout(function(){ h.hidden = true; }, 450);
    lsSet("tirada_zoom_hint", true);
  }, 4600);
}
function mapFallback(){
  var el = $("#map");
  if (!el) return;
  /* data-fallback marks the state for the health checks/lab: an empty
     dark #map with neither canvas nor this text is a dead surface.
     Presentation lives in the .map-fallback rule in style.css (v21) —
     no inline styles, so the text is styled even if this string is
     reused somewhere the style attribute would be stripped. */
  el.setAttribute("data-fallback", "1");
  el.innerHTML = '<div class="map-fallback">' + t("Карта не загрузилась (нет сети или недоступен WebGL) — но места на экране «Места» на месте.") + '</div>';
}
/* The map as a surface state (v21): "ready" (style loaded, layers in),
   "loading" (constructed, style still on its way — HEALTHY, hands
   off), "fallback" (map === null, honest text on screen), "dead"
   (map === null and not even the fallback), "absent" (no element). */
function mapSurfaceState(){
  var el = $("#map");
  if (!el) return "absent";
  if (map && mapReady) return "ready";
  if (el.getAttribute("data-fallback") === "1") return "fallback";
  if (map) return "loading";
  return "dead";
}
/* Drop to the supported map === null state, with the reason traced. */
function teardownMap(why){
  tracePush("map", "teardown: " + why);
  try { if (map) map.remove(); } catch (e){}
  map = null; meMarker = null; mapReady = false;
  mapConstructed = false; meMarkerCreated = false;
  if (typeof window !== "undefined") window.__tiradaMap = null;
}
/* MapLibre error events, classified. Tile errors are routine — one bad
   tile must never kill the map — so they are only RECORDED (the
   diagnostics block shows the last one). A sprite/glyph failure is
   different: those resources gate the style itself, so the 'load'
   event may NEVER fire (the v19 symptom on Yasha's phone: one CARTO
   host serves tiles, glyphs AND sprite from a single snapshot — a hung
   sprite meant no load, no layers, no fallback, just the dark field).
   For those, don't wait for the deadline: after a short grace period,
   finish the layers manually if the style did arrive, else tear down
   to the fallback early. */
function onMapError(m, e){
  var em = (e && e.error && e.error.message) || (e && e.message) || "unknown map error";
  var kind = "other";
  if (e && e.tile) kind = "tile";
  else if (/sprite/i.test(em)) kind = "sprite";
  else if (/glyph|font|\.pbf/i.test(em)) kind = "glyph";
  else if (/tile|\.mvt|source/i.test(em)) kind = "tile";
  mapLastError = { kind: kind, msg: String(em).slice(0, 160), t: Date.now() };
  /* The trace is capped at 40 entries — a flapping tile host must not
     flush the boot record out of it. Trace the first error of each
     kind, then at most one line per 10 s. */
  var now = Date.now();
  if (kind !== mapErrTraceKind || now - mapErrTraceAt > 10000){
    mapErrTraceKind = kind; mapErrTraceAt = now;
    tracePush("map-error", kind + ": " + mapLastError.msg);
  }
  if (kind !== "sprite" && kind !== "glyph") return;
  setTimeout(function(){
    if (map !== m || !map || mapReady) return;
    try { if (map.isStyleLoaded()){ initMapLayers(); return; } } catch (e2){}
    if (map !== m || mapReady) return;
    teardownMap("style resource failed (" + kind + "): " + mapLastError.msg);
    mapFallback();
  }, 4000);
}
/* The map was constructed (a WebGL context existed) but its style is
   taking forever — tile/style hosts unreachable, a GPU process that
   died after the probe. v20 tore the map down after a flat 5 s, which
   also killed healthy-but-slow maps on real phones (style JSON +
   glyphs + sprite over a mobile network legitimately take longer).
   v21: the deadline is ~20 s, the watchdog is bound to THIS map
   instance, and before tearing anything down it gives the layers one
   more chance — if the style did arrive and only the 'load' event was
   missed, initMapLayers() finishes the job and the map lives. */
function mapStyleWatchdog(){
  var m = map;
  setTimeout(function(){
    if (map !== m || !map || mapReady) return;
    try { if (map.isStyleLoaded()){ initMapLayers(); return; } } catch (e){}
    if (map !== m || mapReady) return;
    teardownMap("style never loaded in 20s" + (mapLastError ? "; last error [" + mapLastError.kind + "] " + mapLastError.msg : "; no error recorded"));
    mapFallback();
  }, MAP_STYLE_DEADLINE_MS);
}
/* Revive a dead/fallback map exactly like the other surfaces (v21):
   called by repaintCoreSurfaces and when the user opens the Map tab.
   A map that exists — ready OR still loading — is never touched, an
   environment that cannot host a map at all (mapUnsupported) is not
   retried, and repaint-driven retries are throttled so a dead network
   doesn't spin construction attempts (tab-open passes force=true: the
   user is literally looking at the map screen asking for it). */
function ensureMapAlive(why, force){
  if (map || mapUnsupported) return;
  var st = mapSurfaceState();
  if (st !== "fallback" && st !== "dead") return;
  var now = Date.now();
  if (!force && now - mapLastRetryAt < 10000) return;
  mapLastRetryAt = now;
  tracePush("map", why + ": map surface '" + st + "' — retrying initMap");
  bootStep("initMap-retry", initMap);
}
/* MapLibre's Map constructor THROWS synchronously ("Failed to initialize
   WebGL") whenever the browser/WebView cannot create a WebGL context —
   headless browsers, in-app WebViews, GPU blocklists. Unguarded, that
   throw aborted the whole boot sequence: the LIVE counter stayed on its
   static "…" placeholder, the ticker never built, the places list never
   rendered — and #map stayed an empty dark div. So: probe WebGL first,
   guard the constructor always. The map is an enhancement; the rest of
   the app (map === null is a fully supported state) must boot regardless. */
function webglAvailable(){
  try {
    if (!window.WebGLRenderingContext) return false;
    var cv = document.createElement("canvas");
    return !!(cv.getContext("webgl2") || cv.getContext("webgl") || cv.getContext("experimental-webgl"));
  } catch(e){ return false; }
}
function initMap(){
  /* Double-initialisation guard (v21): repaint retries and tab-open
     retries call initMap again — a second Map on the same container
     would fight the first one's canvas and markers. */
  if (map || mapInitInFlight) return;
  if (typeof maplibregl === "undefined" || !window.TIRADA_MAP_STYLE || !webglAvailable()){
    /* Nothing a retry can change inside this page load — remember it
       so ensureMapAlive doesn't spin on an impossible map. */
    mapUnsupported = true;
    mapFallback();
    return;
  }
  mapInitInFlight = true;
  try {
  /* A retry after a fallback starts from a clean container: MapLibre
     appends its canvas next to whatever is inside #map, it does not
     clear it — the fallback text would stay on screen under the map. */
  var mel = $("#map");
  if (mel && mel.getAttribute("data-fallback") === "1"){ mel.removeAttribute("data-fallback"); mel.innerHTML = ""; }
  map = new maplibregl.Map({
    container: "map",
    style: window.TIRADA_MAP_STYLE,
    /* Start on the USER'S city (state.city, city zoom) — never the whole
       country. state.city is always set (karmiel by default), and mePos()
       is that city's ghost spot; once real geolocation is granted and a
       position arrives, applyGeo() re-centers on the user himself. */
    center: [mePos().lng, mePos().lat],
    zoom: 13,
    minZoom: 6, maxZoom: 18,
    attributionControl: false, /* no attribution bar (Yasha's call) */
    dragRotate: false, pitchWithRotate: false, touchPitch: false,
    fadeDuration: 0
  });
  window.__tiradaMap = map; /* audit/debug hook */
  mapConstructed = true;
  tracePush("map", "constructed — awaiting style load");
  var thisMap = map;
  map.on("error", function(e){ onMapError(thisMap, e); });
  mapStyleWatchdog();
  map.touchZoomRotate.disableRotation();
  map.scrollZoom.disable();
  map.getContainer().addEventListener("focusin", function(){ map.scrollZoom.enable(); });
  map.getContainer().addEventListener("focusout", function(){ map.scrollZoom.disable(); });
  map.on("load", initMapLayers);
  setTimeout(function(){ if (map === thisMap && !mapReady && map.isStyleLoaded()) initMapLayers(); }, 3000);
  setTimeout(showZoomHintOnce, 1600);
  var me = mePos();
  /* The ghost marker gets its OWN guard (v21): it is assembled from
     app-side pieces (ghost element, popup HTML) — if any of them ever
     throws on some device, the map itself must survive (tiles and
     place dots are worth more than one marker), and the trace must
     name the MARKER as the failure, not the map. The 2026-11-23 phone
     screenshot (living app, empty map, no ghost, no fallback) is
     exactly the case this separation exists to diagnose. */
  try {
    meMarker = new maplibregl.Marker({ element: ghostEl() })
      .setLngLat([me.lng, me.lat])
      .setPopup(makePopup(myPopupHtml(), 30))
      .addTo(map);
    meMarkerCreated = true;
    tracePush("map", "meMarker created");
    /* tap on your own avatar = center on yourself + refresh REAL geolocation */
    meMarker.getElement().addEventListener("click", function(){
      var p = mePos();
      map.flyTo({ center: [p.lng, p.lat], zoom: Math.max(map.getZoom(), 15), duration: 700 });
      requestGeo(true);
    });
  } catch (eMarker){
    meMarker = null;
    tracePush("map", "meMarker failed: " + ((eMarker && eMarker.message) || eMarker));
    console.warn("TiradA map: ghost marker failed:", eMarker);
  }
  refreshFriendMarkers();
  map.on("click", function(e){
    var t = $("#legendTip"); if (t) t.hidden = true;
    /* a tap on empty map closes popups; taps on markers/popups/dots are not "empty" */
    var el = e.originalEvent && e.originalEvent.target;
    if (el && el.closest && (el.closest(".maplibregl-marker") || el.closest(".maplibregl-popup"))) return;
    if (mapReady && map.getLayer("places-dots") &&
        map.queryRenderedFeatures(e.point, { layers: ["places-dots"] }).length) return;
    closeAllPopups();
  });
  map.on("zoomend", refreshMapMode);
  map.on("moveend", function(){
    mapMoving = false;
    map.getContainer().classList.remove("map-is-moving");
    refreshMapMode();
  });
  /* While the map is being dragged/zoomed, every repaint shekel goes to the
     GL render: pause CSS animations inside the map (badge pulse rings) via
     .map-is-moving, and let fake-live skip its DOM writes. */
  map.on("movestart", function(){
    mapMoving = true;
    map.getContainer().classList.add("map-is-moving");
  });
  /* popup buttons (delegated — popups live inside the map container):
     "Маршрут" → build route; "Смотреть место" → places screen, scroll to the card */
  $("#map").addEventListener("click", function(e){
    if (!e.target.closest) return;
    var rBtn = e.target.closest("[data-route-place]");
    if (rBtn){
      var f = findPlace(rBtn.getAttribute("data-route-place"));
      if (f) routeTo(f.place);
      return;
    }
    var btn = e.target.closest("[data-place-open]");
    if (!btn) return;
    openPlaceSheetById(btn.getAttribute("data-place-open"));
  });
  mapInitInFlight = false;
  } catch(e){
    /* A half-wired map is worse than none: drop to the supported
       map === null state and let the app run without it. v21: the
       failure is no longer silent — it goes to the boot trace (and
       the console), so the diagnostics block can name it. */
    mapInitInFlight = false;
    tracePush("map", "initMap threw: " + ((e && e.message) || e));
    console.warn("TiradA map: initMap failed:", e);
    try { if (map) map.remove(); } catch (e2){}
    map = null; meMarker = null; mapReady = false;
    mapConstructed = false; meMarkerCreated = false;
    if (typeof window !== "undefined") window.__tiradaMap = null;
    mapFallback();
  }
}

/* ================= Legend: small round "i" button, tip on tap ================= */
var legendTipTimer = null;
$("#legendInfo").addEventListener("click", function(){
  var tip = $("#legendTip");
  var willShow = tip.hidden;
  tip.hidden = !willShow;
  clearTimeout(legendTipTimer);
  if (willShow) legendTipTimer = setTimeout(function(){ tip.hidden = true; }, 4500);
});

/* ================= Edge zoom: drag along EITHER edge =================
   Fully invisible touch strips on BOTH map edges (right + left, for
   left-handers): drag up = zoom in, drag down = zoom out. On the vector
   map the zoom is CONTINUOUS, exactly like the native pinch: the drag
   sets a target zoom and a rAF loop eases the camera to it (easeTo
   retargets mid-flight), so the strip feels like Bump, not like steps. */
(function(){
  var strips = [$("#edgeZoom"), $("#edgeZoomL")].filter(Boolean);
  if (!strips.length) return;
  var PX_PER_LEVEL = 90; /* ~90px of drag = 1 zoom level */
  var drag = null, rafId = null;
  function targetZoom(){
    return Math.max(map.getMinZoom(), Math.min(map.getMaxZoom(), drag.startZoom + (drag.startY - drag.y) / PX_PER_LEVEL));
  }
  function applyZoom(dur){
    if (!drag || !map) return;
    var tz = targetZoom();
    if (Math.abs(tz - map.getZoom()) > 0.005)
      map.easeTo({ zoom: tz, duration: dur, easing: function(t){ return t; } });
  }
  function queue(){
    if (rafId === null) rafId = requestAnimationFrame(function(){ rafId = null; applyZoom(140); });
  }
  function start(y){
    if (!map) return;
    drag = { startY: y, y: y, startZoom: map.getZoom() };
  }
  function move(y){
    if (!drag) return;
    drag.y = y;
    queue();
  }
  function end(){
    if (rafId !== null){ cancelAnimationFrame(rafId); rafId = null; }
    applyZoom(200);
    drag = null;
  }
  strips.forEach(function(strip){
    strip.addEventListener("touchstart", function(e){ start(e.touches[0].clientY); }, { passive:true });
    strip.addEventListener("touchmove", function(e){ if (drag){ e.preventDefault(); move(e.touches[0].clientY); } }, { passive:false });
    strip.addEventListener("touchend", end);
    strip.addEventListener("touchcancel", end);
    strip.addEventListener("mousedown", function(e){
      start(e.clientY);
      var mv = function(ev){ move(ev.clientY); };
      var up = function(){ end(); window.removeEventListener("mousemove", mv); window.removeEventListener("mouseup", up); };
      window.addEventListener("mousemove", mv);
      window.addEventListener("mouseup", up);
    });
  });
})();

/* ================= Route to a place (Waze style, OSRM) =================
   From your ghost position to a place: real driving route via the free OSRM
   demo server, drawn as a red-neon line with a white underlay and flowing
   pulse dots. If OSRM is unreachable — honest fallback: a smooth direct arc
   and a chip that says "по прямой" (no invented road time). */
var routeReq = 0, routeDashTimer = null, routeDashStep = 0;
/* flowing pulse: cycle the dash pattern of route-flow (MapLibre has no
   dash-offset animation; stepping line-dasharray is the standard trick) */
var ROUTE_DASH_SEQ = [[0,4,3],[0.5,4,2.5],[1,4,2],[1.5,4,1.5],[2,4,1],[2.5,4,0.5],[3,4,0],[0,0.5,3,3.5],[0,1,3,3],[0,1.5,3,2.5],[0,2,3,2],[0,2.5,3,1.5],[0,3,3,1],[0,3.5,3,0.5]];
function fmtDur(min){
  if (min < 60) return tf("{v} мин", { v: Math.max(1, Math.round(min)) });
  return tf("{h} ч {m} мин", { h: Math.floor(min / 60), m: Math.round(min % 60) });
}
function showRouteChip(main, sub){
  $("#routeChipMain").textContent = main;
  $("#routeChipSub").textContent = sub || "";
  $("#routeChip").hidden = false;
}
function stopRouteDash(){
  if (routeDashTimer){ clearInterval(routeDashTimer); routeDashTimer = null; }
}
function startRouteDash(){
  stopRouteDash();
  routeDashTimer = setInterval(function(){
    if (!map || !mapReady || mapMoving || !map.getLayer("route-flow")) return;
    routeDashStep = (routeDashStep + 1) % ROUTE_DASH_SEQ.length;
    map.setPaintProperty("route-flow", "line-dasharray", ROUTE_DASH_SEQ[routeDashStep]);
  }, 70);
}
function clearRoute(){
  routeReq++; /* invalidate any in-flight OSRM request */
  stopRouteDash();
  if (map && mapReady && map.getSource("route")) map.getSource("route").setData(EMPTY_FC);
  var chip = $("#routeChip");
  if (chip) chip.hidden = true;
}
function drawRouteLine(latlngs){
  if (!map || !mapReady) return;
  var coords = latlngs.map(function(ll){ return [ll[1], ll[0]]; });
  map.getSource("route").setData({ type: "Feature", geometry: { type: "LineString", coordinates: coords } });
  var b = coords.reduce(function(bb, c){ return bb.extend(c); }, new maplibregl.LngLatBounds(coords[0], coords[0]));
  map.fitBounds(b, { padding: 42, duration: 800 });
  startRouteDash();
}
function buildArc(a, b){
  var pts = [], N = 42;
  var mx = (a.lng + b.lng) / 2, my = (a.lat + b.lat) / 2;
  var dx = b.lng - a.lng, dy = b.lat - a.lat;
  var cx = mx - dy * 0.18, cy = my + dx * 0.18; /* control point, bowed to the side */
  for (var i = 0; i <= N; i++){
    var t = i / N, u = 1 - t;
    pts.push([u*u*a.lat + 2*u*t*cy + t*t*b.lat, u*u*a.lng + 2*u*t*cx + t*t*b.lng]);
  }
  return pts;
}
var TRANSPORTS = {
  car:  { icon:"🚗", osrm:"driving", label:"на машине" },
  bus:  { icon:"🚌", osrm:"driving", label:"на автобусе · примерно" },
  walk: { icon:"🚶", osrm:"foot",    label:"пешком" }
};
function routeTo(place){
  if (!map || !place) return;
  countRouteBuilt();
  var tm = TRANSPORTS[state.transport] || TRANSPORTS.car;
  $("#routeChipIco").textContent = tm.icon;
  closeDeal();
  showScreen("map");
  closeAllPopups();
  clearRoute();
  var req = routeReq;
  var me = mePos();
  showRouteChip(t("Строю маршрут…"), tf("до «{place}»", { place: place.name }));
  var ctrl = ("AbortController" in window) ? new AbortController() : null;
  var timer = ctrl ? setTimeout(function(){ ctrl.abort(); }, 9000) : null;
  var url = "https://router.project-osrm.org/route/v1/" + tm.osrm + "/" +
    me.lng + "," + me.lat + ";" + place.lng + "," + place.lat +
    "?overview=full&geometries=geojson";
  fetch(url, ctrl ? { signal: ctrl.signal } : undefined)
    .then(function(r){ if (!r.ok) throw new Error("osrm " + r.status); return r.json(); })
    .then(function(j){
      if (timer) clearTimeout(timer);
      if (req !== routeReq) return; /* route was cleared/replaced meanwhile */
      if (!j || j.code !== "Ok" || !j.routes || !j.routes[0]) throw new Error("no route");
      var rt = j.routes[0];
      var latlngs = rt.geometry.coordinates.map(function(c){ return [c[1], c[0]]; });
      latlngs.unshift([me.lat, me.lng]); /* line starts exactly on your ghost marker… */
      latlngs.push([place.lat, place.lng]); /* …and ends exactly on the place badge */
      drawRouteLine(latlngs);
      var durMin = rt.duration / 60;
      if (state.transport === "bus") durMin *= 1.35; /* bus = road geometry, honest ~x1.35 time */
      showRouteChip(fmtDist(rt.distance / 1000) + " · " + fmtDur(durMin),
        t(tm.label) + " " + tf("до «{place}»", { place: place.name }));
    })
    .catch(function(){
      if (timer) clearTimeout(timer);
      if (req !== routeReq) return;
      drawRouteLine(buildArc(me, place));
      showRouteChip(tf("По прямой: {d}", { d: fmtDist(distKm(me, place)) }),
        tf("до «{place}» · дороги сейчас недоступны", { place: place.name }));
    });
}
$("#routeChipX").addEventListener("click", function(){ clearRoute(); });

/* ================= Places feed ================= */
function renderFilter(){
  var present = {};
  places().forEach(function(p){ present[p.type] = true; });
  var chips = ['<button class="filter-chip' + (state.filter === "all" ? " active" : "") + '" data-type="all">' + t("Все") + '</button>'];
  chips.push('<button class="filter-chip' + (state.filter === "fav" ? " active" : "") + '" data-type="fav">❤️ ' + t("Избранное") + '</button>');
  chips.push('<button class="filter-chip' + (state.filter === "free" ? " active" : "") + '" data-type="free">🆓 ' + t("Бесплатно") + '</button>');
  Object.keys(TYPES).forEach(function(k){
    if (present[k]) chips.push('<button class="filter-chip' + (state.filter === k ? " active" : "") + '" data-type="' + k + '">' + typeLabel(k) + '</button>');
  });
  $("#typeFilter").innerHTML = chips.join("");
  $$("#typeFilter .filter-chip").forEach(function(ch){
    ch.addEventListener("click", function(){
      state.filter = ch.getAttribute("data-type");
      renderFilter(); renderPlaces();
    });
  });
}
$("#placeSearch").addEventListener("input", function(){
  state.search = this.value.trim().toLowerCase();
  renderPlaces();
});
$("#placeSort").addEventListener("change", function(){
  state.sort = this.value;
  renderPlaces();
});
var TOP_ID = null;
function placeCard(p, i){
  /* v28: a locked secret place renders as a lock — no name, photo,
     heat, song or price leaks into the list. Tap still opens the
     (locked) sheet, which explains the unlock condition. */
  if (isSecretLocked(p)){
    return '<article class="place-card card-locked" data-id="' + p.id + '">' +
      '<div class="place-art" style="background:' + p.grad + '"><span class="art-emoji">🔒</span></div>' +
      '<div class="place-body"><div class="place-top"><div><div class="place-name">' + t("🔒 Секретное место") + '</div>' +
      '<div class="place-type">' + tf("Откроется на уровне 3 — «{name}»", { name: levelName(2) }) + '</div></div></div>' +
      '<div class="song">🔒 ' + t("Название, фото и вайб — после открытия") + '</div></div></article>';
  }
  var h = heatOf(p), hc = heatClass(h);
  var badge = (p.id === TOP_ID) ? '<span class="art-badge">👑 ' + t("ТОП движа") + '</span>'
    : (h >= 85 ? '<span class="art-badge heat-badge">⚡ ' + t("Сейчас жарко") + '</span>' : '');
  var fav = !!state.favs[p.id];
  var fHere = friendsAtPlaceNames(p.id);
  var fBadge = fHere.length ? '<div class="friend-here-badge">👻 ' + t("Здесь:") + " " + fHere.map(escHtml).join(", ") + '</div>' : '';
  /* One meta line for every place class, same bits in the same order:
     reviews (real venues) · local mark (hand-added) · price (any class
     that has one). Before v23 local cards hid their price behind the
     «Местное место» mark and generated cards showed no price at all,
     while the sheet and the map popup showed it — the card now agrees
     with them. */
  var realMeta = "";
  var bits = [];
  if (p.real && p.reviews) bits.push("👥 " + reviewsText(p));
  if (p.local) bits.push("🏠 " + t("Местное место"));
  if (priceOf(p)) bits.push(t("💰 Цены:") + " " + priceOf(p));
  if (bits.length) realMeta = '<div class="place-real-meta">' + bits.join(" · ") + '</div>';
  return '<article class="place-card' + (p.id === TOP_ID ? ' top-card' : '') + '" data-id="' + p.id + '" style="animation-delay:' + (Math.min(i, 10) * 0.06).toFixed(2) + 's">' +
    '<div class="place-art" style="background:' + p.grad + '">' + emojiImg(p.art, "art-img") + badge +
    '<button class="fav-btn' + (fav ? " active" : "") + '" data-fav="' + p.id + '" aria-label="' + t("В избранное") + '">' + (fav ? "❤️" : "🤍") + '</button>' +
    '<span class="art-heat ' + hc + '">' + heatBadge(p) + '</span></div>' +
    '<div class="place-body">' + fBadge +
      '<div class="place-top"><div><div class="place-name">' + p.name + '</div>' +
      '<div class="place-type">' + p.typeLabel + ' · ' + distFromText(p) + '</div></div>' +
      '<div class="place-rating">' + (p.local ? "🏠" : "★ " + ratingText(p)) + '</div></div>' +
      '<div class="heat-row"><div class="heat-bar"><div class="heat-fill ' + hc + '" style="width:' + h + '%"></div></div>' +
      '<div class="heat-label ' + hc + '">' + heatBadge(p) + '</div></div>' + realMeta +
      '<div class="tags">' + p.tags.map(function(t){ return '<span class="tag">' + t + '</span>'; }).join("") + '</div>' +
      '<div class="song">🎵 <b>' + p.song + '</b> ' + t("— трек под настроение места") + '</div>' +
      '<button class="btn-route-to" data-route-card="' + p.id + '">🚗 ' + t("Маршрут") + '</button>' +
    '</div></article>';
}
function renderPlaces(){
  TOP_ID = hottest()[0] ? hottest()[0].id : null;
  var all = places();
  var list = all.slice();
  if (state.filter === "fav") list = list.filter(function(p){ return !!state.favs[p.id]; });
  else if (state.filter === "free") list = list.filter(isFree);
  else if (state.filter !== "all") list = list.filter(function(p){ return p.type === state.filter; });
  if (state.search) list = list.filter(function(p){ return !isSecretLocked(p) && p.name.toLowerCase().indexOf(state.search) >= 0; });
  if (state.sort === "near") list.sort(function(a,b){ return distKm(mePos(), a) - distKm(mePos(), b); });
  else if (state.sort === "rating") list.sort(function(a,b){ return (b.rating || 0) - (a.rating || 0); });
  else list.sort(function(a,b){ return heatOf(b) - heatOf(a); });
  /* Places where an accepted friend is hanging out right now float to
     the very top, keeping the chosen sort inside each group. */
  if (Object.keys(friendsAtPlace).length){
    var withF = list.filter(function(p){ return !!friendsAtPlace[p.id]; });
    if (withF.length) list = withF.concat(list.filter(function(p){ return !friendsAtPlace[p.id]; }));
  }
  $("#placesCount").textContent = tf("Показано {a} из {b} · {city}", { a: list.length, b: all.length, city: cityName(state.city) });
  if (!list.length){
    $("#placesList").innerHTML = '<div class="places-empty">' +
      (state.filter === "fav"
        ? '<div class="empty-art">🤍</div><div class="empty-title">' + t("Избранное пока пусто") + '</div>' +
          '<div class="empty-text">' + t("Тапни 🤍 на карточке места — и оно будет жить здесь, под рукой.") + '</div>' +
          '<button class="btn-yes empty-btn" data-empty-all>' + t("Смотреть все места") + '</button>'
        : '<div class="empty-art">👻</div><div class="empty-title">' + t("Тут пока тихо") + '</div>' +
          '<div class="empty-text">' + tf("В этой подборке в городе {city} пусто. Но движ точно где-то есть.", { city: cityName(state.city) }) + '</div>' +
          '<button class="btn-yes empty-btn" data-empty-all>' + t("Заглянуть в «Все»") + '</button>') + "</div>";
    var eb = $("#placesList [data-empty-all]");
    if (eb) eb.addEventListener("click", function(){
      state.filter = "all"; renderFilter(); renderPlaces();
    });
    return;
  }
  $("#placesList").innerHTML = list.map(placeCard).join("");
  $$(".place-card").forEach(function(card){
    var id = card.getAttribute("data-id");
    var p = null;
    for (var i = 0; i < all.length; i++) if (all[i].id === id) p = all[i];
    var rb = card.querySelector("[data-route-card]");
    if (rb) rb.addEventListener("click", function(e){
      e.stopPropagation();
      if (p) routeTo(p);
    });
    var fb = card.querySelector("[data-fav]");
    if (fb) fb.addEventListener("click", function(e){
      e.stopPropagation();
      toggleFav(id);
    });
    /* A tap on the card opens THE SAME place's detail sheet — no map
       round-trip, so the old "card X opened popup Y" bug is gone. */
    card.addEventListener("click", function(){ if (p) openPlaceSheet(p); });
  });
}
function updatePlaceCard(p){
  var card = document.querySelector('.place-card[data-id="' + p.id + '"]');
  if (!card) return;
  var h = heatOf(p), hc = heatClass(h);
  var fill = card.querySelector(".heat-fill"), lbl = card.querySelector(".heat-label"), art = card.querySelector(".art-heat");
  if (fill){ fill.style.width = h + "%"; fill.className = "heat-fill " + hc; }
  if (lbl){ lbl.textContent = heatBadge(p); lbl.className = "heat-label " + hc; }
  if (art){ art.textContent = heatBadge(p); art.className = "art-heat " + hc; }
}

/* ================= Counter & ticker ================= */
function hotCount(){ return places().filter(function(p){ return heatOf(p) >= 70; }).length; }
/* Real published-photo count for the current city, read from the
   place_photos table (wave 2 honesty: the counter and the ticker only
   ever show numbers the app actually has — no invented crowds). */
var cityPhotoCount = null; /* null = not loaded / unavailable */
function refreshCityPhotoCount(){
  cityPhotoCount = null;
  if (typeof db === "undefined" || !db) return;
  var cityId = state.city.id;
  var ids = places().map(function(p){ return p.id; });
  db.from("place_photos").select("id", { count: "exact", head: true })
    .in("place_id", ids).eq("hidden", false).lt("reports", 3)
    .then(function(res){
      if (res.error || state.city.id !== cityId) return;
      cityPhotoCount = res.count || 0;
      updateCounter();
      buildTicker();
    }, function(){});
}
function updateCounter(){
  var hot = hotCount(), total = places().length;
  var txt = tf("в городе: <b>{hot} {hw}</b> сейчас • всего {total} {pw} на радаре", { hot: hot, hw: hotWord(hot), total: total, pw: placeWord(total) });
  if (cityPhotoCount) txt += tf(" • 📸 фото призраков: <b>{n}</b>", { n: cityPhotoCount });
  $("#counterText").innerHTML = txt;
}
function buildTicker(){
  var open = hottest().filter(function(p){ return openStatus(p).open; });
  var items = [];
  if (open[0]) items.push(tf("🔥 <i>{name}</i> — самый живой движ по радару сейчас: {h}%", { name: open[0].name, h: heatOf(open[0]) }));
  items.push(tf("📍 <i>{city}</i>: {n} {pw} на радаре, {h} {hw} прямо сейчас", { city: cityName(state.city), n: places().length, pw: placeWord(places().length), h: hotCount(), hw: hotWord(hotCount()) }));
  if (cityPhotoCount) items.push(tf("📸 Призраки опубликовали в городе уже {n} фото — загляни в карточки мест", { n: cityPhotoCount }));
  if (open[1]) items.push(tf("🎵 Вайб места <i>{name}</i>: {song} — трек под настроение", { name: open[1].name, song: open[1].song }));
  items.push(tf("🗺️ Маршрутов ты построил: {n} — вечер собирается на экране «Маршрут»", { n: state.stats.routes }));
  /* The strip must never be able to end up textless: if data hiccups
     emptied the items, one honest line about the current city remains. */
  if (!items.length) items.push(tf("📍 <i>{city}</i>: загляни на экран «Места» — там весь движ города", { city: cityName(state.city) }));
  /* v28 — FADE ticker. The marquee is gone for good: no transform
     animation, no duplicated halves, exactly ONE .tick-item in the
     track at any moment, phrases rotate by fading (an opacity
     transition on the item itself). One phrase physically cannot
     overlap or mirror another — there is never a second copy.
     The rotation runs on ONE interval whose starter is idempotent
     (v28 loop discipline: every periodic loop in the app is a
     single instance; a starter called while its loop is alive is
     a no-op). buildTicker touches the DOM only when the phrase
     list actually changed — repaint/resume cycles with the same
     phrases leave the running cycle completely alone. */
  var sig = items.join("\u0001");
  if (sig === tickerSig){ startTickerFade(); return; }
  tickerSig = sig;
  tickerItems = items;
  tickerIdx = 0;
  var track = $("#tickerTrack");
  if (track) track.innerHTML = '<span class="tick-item">' + items[0] + "</span>";
  startTickerFade();
}
var tickerItems = [], tickerIdx = 0, tickerSig = "";
var tickerTimer = null, tickerSwapTo = null;
function startTickerFade(){
  if (tickerTimer || document.hidden || tickerItems.length < 2) return;
  tickerTimer = setInterval(tickerAdvance, 5200);
}
function stopTickerFade(){
  if (tickerTimer){ clearInterval(tickerTimer); tickerTimer = null; }
  if (tickerSwapTo){ clearTimeout(tickerSwapTo); tickerSwapTo = null; }
}
function tickerAdvance(){
  if (document.hidden || tickerItems.length < 2) return;
  var track = $("#tickerTrack"); if (!track) return;
  var item = track.querySelector(".tick-item");
  if (!item){ track.innerHTML = '<span class="tick-item">' + tickerItems[tickerIdx % tickerItems.length] + "</span>"; return; }
  item.classList.add("tick-fade");
  if (tickerSwapTo) clearTimeout(tickerSwapTo);
  tickerSwapTo = setTimeout(function(){
    tickerSwapTo = null;
    tickerIdx = (tickerIdx + 1) % tickerItems.length;
    var it = track.querySelector(".tick-item");
    if (it){ it.innerHTML = tickerItems[tickerIdx]; it.classList.remove("tick-fade"); }
  }, 480);
}

/* ================= Fake-live heat =================
   Heat no longer mutates randomly: heatOf() derives it from the place id
   and the 15-minute window, so every surface shows the SAME number and it
   only changes when the window flips. This tick just re-syncs the DOM
   when a new window starts (and stays silent while the map is moving). */
var lastHeatWindow = heatWindow(), tickN = 0;
setInterval(function(){
  if (document.hidden) return; /* v28: visual loops pause in the background */
  try { applySkyPhase(); } catch (e) {}
  if (mapMoving) return;
  var w = heatWindow();
  if (w !== lastHeatWindow){
    lastHeatWindow = w;
    places().forEach(function(p){
      var m = placeMarkers[p.id];
      if (m){
        var band = heatClass(heatOf(p));
        if (p._band !== band){
          p._band = band;
          var bEl = m.getElement().firstChild;
          if (bEl) bEl.className = "place-badge " + band;
        }
        var mp2 = m.getPopup();
        if (mp2 && mp2.isOpen()) mp2.setHTML(popupHtml(p));
      }
      updatePlaceCard(p);
    });
    updateCounter();
    buildTicker();
  }
  tickN++;
}, 9000);

/* ================= Modes (synced switches) ================= */
var MODES = {
  visible:{ status:"Тебя видят друзья на карте — с аватаркой, без имени.", mapStatus:"Тебя видят друзья — без имени и фото." },
  ghost:  { status:"Ты видишь всех, тебя — никто. Полная невидимка с открытыми глазами.", mapStatus:"Невидимка: ты видишь всех, тебя — никто." },
  dnd:    { status:"Ты на карте, но звать тебя нельзя. Сам смотри по радару, куда идти.", mapStatus:"Не беспокоить: ты на карте, но звать тебя нельзя." },
  offline:{ status:"Тебя никто не видит на карте. Полная невидимость — даже для друзей.", mapStatus:"Оффлайн: тебя никто не видит на карте." }
};
function setMode(mode){
  state.mode = mode;
  scheduleCloudSync();
  $$("[data-modeswitch] .mode-btn").forEach(function(b){
    b.classList.toggle("active", b.getAttribute("data-mode") === mode);
  });
  $("#modeStatusProfile").textContent = t(MODES[mode].status);
  if (meMarker){
    updateMeMarker();
    var mp = meMarker.getPopup();
    if (mp && mp.isOpen()) mp.setHTML(myPopupHtml());
  }
}
$$("[data-modeswitch] .mode-btn").forEach(function(btn){
  btn.addEventListener("click", function(){
    setMode(btn.getAttribute("data-mode"));
    if (state.mode === "offline") toast(t("Ты исчез с карты 👻"));
    if (state.mode === "ghost") toast(t("Режим невидимки: ты — просто силуэт"));
  });
});

/* ================= My avatar & nick =================
   Avatar = one of the 12 ready ghosts (Emoji CDN faces) or your own photo
   (cropped to a circle, kept as a dataURL in localStorage). It shows in
   the Profile, and — the main stage — on the map on your ghost. When the
   the cloud account lands, avatars will sync across devices. */
function renderMyAvatar(){
  $("#ghostBig").innerHTML = currentAvatarHtml();
  var nickEl = $("#ghostNick");
  if (nickEl) nickEl.textContent = state.nick || t("Призрак");
  var numEl = $("#ghostNum");
  if (numEl) numEl.textContent = ghostNumber();
  updateMeMarker();
}
function renderAvatarGrid(){
  var grid = $("#avatarGrid");
  if (!grid) return;
  var hasPhoto = !!(state.avatarUrl || state.avatarPhoto);
  var rotateBtn = $("#avatarRotate");
  if (rotateBtn) rotateBtn.hidden = !hasPhoto;
  var html = AVATARS.map(function(av, i){
    var sel = (!hasPhoto && state.myAvatar === i) ? " selected" : "";
    return '<button class="avatar-cell' + sel + '" data-avatar="' + i + '">' + avatarFace(i) + "</button>";
  }).join("");
  if (hasPhoto)
    html += '<button class="avatar-cell selected" data-avatar="photo"><img class="avphoto" src="' + avatarDisplaySrc() + '" alt="' + t("Моё фото") + '"></button>';
  grid.innerHTML = html;
  $$("#avatarGrid [data-avatar]").forEach(function(btn){
    btn.addEventListener("click", function(){
      var v = btn.getAttribute("data-avatar");
      if (v !== "photo"){
        state.myAvatar = parseInt(v, 10);
        state.avatarPhoto = null;
        state.avatarUrl = null;
        lsSet("tirada_avatar_idx", state.myAvatar);
        lsSet("tirada_avatar_photo", null);
        lsSet("tirada_avatar_url", null);
        scheduleCloudSync();
      }
      renderMyAvatar(); renderAvatarGrid();
      toast("Аватарка обновлена 👻");
    });
  });
}
$("#ghostBig").addEventListener("click", function(){
  renderAvatarGrid();
  $("#avatarSheet").hidden = false;
});
$("#avatarClose").addEventListener("click", function(){ $("#avatarSheet").hidden = true; });
$("#avatarSheet").addEventListener("click", function(e){ if (e.target === this) this.hidden = true; });
/* ================= EXIF orientation =================
   Phone photos usually store unrotated pixels plus an EXIF orientation
   flag. A plain <img> + drawImage() pipeline ignores that flag in several
   browsers/WebViews, so avatars got baked upside down (v15 bug, seen on
   the user's own screen recording). Decode with
   createImageBitmap(imageOrientation:"from-image") where available;
   otherwise parse the EXIF flag ourselves and rotate/flip on a canvas. */
function exifOrientation(buf){
  try {
    var v = new DataView(buf);
    if (v.byteLength < 4 || v.getUint16(0) !== 0xFFD8) return 1;
    var off = 2;
    while (off + 4 <= v.byteLength){
      var marker = v.getUint16(off), len = v.getUint16(off + 2);
      if (marker === 0xFFE1 && len >= 16 && v.getUint32(off + 4) === 0x45786966 && v.getUint16(off + 8) === 0){
        var tiff = off + 10, le = v.getUint16(tiff) === 0x4949;
        var ifd = tiff + v.getUint32(tiff + 4, le), n = v.getUint16(ifd, le);
        for (var i = 0; i < n; i++){
          var e = ifd + 2 + i * 12;
          if (v.getUint16(e, le) === 0x0112) return v.getUint16(e + 8, le) || 1;
        }
        return 1;
      }
      if ((marker & 0xFF00) !== 0xFF00 || len < 2) break;
      off += 2 + len;
    }
  } catch(e){}
  return 1;
}
function loadOrientedSource(file){
  if (window.createImageBitmap){
    return createImageBitmap(file, { imageOrientation: "from-image" })
      .catch(function(){ return createImageBitmap(file); })
      .then(function(bmp){
        return { src: bmp, w: bmp.width, h: bmp.height,
                 close: function(){ if (bmp.close) bmp.close(); } };
      });
  }
  return file.arrayBuffer().then(function(buf){
    var orient = exifOrientation(buf);
    return new Promise(function(resolve, reject){
      var url = URL.createObjectURL(file);
      var img = new Image();
      img.onload = function(){
        var w = img.naturalWidth || 1, h = img.naturalHeight || 1;
        if (orient === 1){
          resolve({ src: img, w: w, h: h, close: function(){ URL.revokeObjectURL(url); } });
          return;
        }
        var swap = orient >= 5 && orient <= 8;
        var c = document.createElement("canvas");
        c.width = swap ? h : w; c.height = swap ? w : h;
        var x = c.getContext("2d");
        switch (orient){
          case 2: x.transform(-1, 0, 0, 1, w, 0); break;
          case 3: x.transform(-1, 0, 0, -1, w, h); break;
          case 4: x.transform(1, 0, 0, -1, 0, h); break;
          case 5: x.transform(0, 1, 1, 0, 0, 0); break;
          case 6: x.transform(0, 1, -1, 0, h, 0); break;
          case 7: x.transform(0, -1, -1, 0, h, w); break;
          case 8: x.transform(0, -1, 1, 0, 0, w); break;
        }
        x.drawImage(img, 0, 0);
        URL.revokeObjectURL(url);
        resolve({ src: c, w: c.width, h: c.height, close: function(){} });
      };
      img.onerror = function(){ URL.revokeObjectURL(url); reject(new Error("load")); };
      img.src = url;
    });
  });
}
$("#avatarFile").addEventListener("change", function(){
  var file = this.files && this.files[0];
  this.value = "";
  if (!file) return;
  loadOrientedSource(file).then(function(o){
    var S = 256, cv = document.createElement("canvas");
    cv.width = S; cv.height = S;
    var side = Math.min(o.w, o.h);
    cv.getContext("2d").drawImage(o.src, (o.w - side) / 2, (o.h - side) / 2, side, side, 0, 0, S, S);
    o.close();
    state.avatarPhoto = cv.toDataURL("image/jpeg", 0.85);
    lsSet("tirada_avatar_photo", state.avatarPhoto);
    renderMyAvatar(); renderAvatarGrid();
    toast(t("Фото-аватарка готова 👻 Она уже на карте"));
    if (window.TiradaDB && typeof cloudUploadAvatar === "function"){
      cv.toBlob(function(blob){ if (blob) cloudUploadAvatar(blob); }, "image/jpeg", 0.85);
    }
  }).catch(function(){ toast(t("Не вышло прочитать фото")); });
});
/* ================= Rotate the avatar photo (v25) =================
   Yasha's cloud photo is a sharp selfie whose PIXELS are baked rotated
   (~180°) by the pre-v15 pipeline; the EXIF flag is long gone, so no
   automatic orientation is possible. The manual fix lives here: each
   tap turns the CURRENT photo 90° clockwise on a canvas. The result
   becomes the local photo (the v24 single truth) and is uploaded
   through the same cloudUploadAvatar path as a fresh upload, which
   stamps tirada_avatar_synced for the NEW photo — so the heal logic
   can never roll the rotation back. Works for a cloud-only photo too:
   it is downloaded first, then rotated like a local one. */
$("#avatarRotate").addEventListener("click", function(){
  /* Rotate the photo the user actually SEES (v26 priority). */
  var src = avatarDisplaySrc();
  if (!src) return;
  var img = new Image();
  if (src.indexOf("data:") !== 0 && src.indexOf("blob:") !== 0) img.crossOrigin = "anonymous";
  img.onload = function(){
    try {
      var w = img.naturalWidth || 1, h = img.naturalHeight || 1;
      var rc = document.createElement("canvas");
      rc.width = h; rc.height = w;
      var rx = rc.getContext("2d");
      rx.translate(h / 2, w / 2);
      rx.rotate(Math.PI / 2);
      rx.drawImage(img, -w / 2, -h / 2);
      var S = 256, cv = document.createElement("canvas");
      cv.width = S; cv.height = S;
      var side = Math.min(rc.width, rc.height);
      cv.getContext("2d").drawImage(rc, (rc.width - side) / 2, (rc.height - side) / 2, side, side, 0, 0, S, S);
      state.avatarPhoto = cv.toDataURL("image/jpeg", 0.85);
      lsSet("tirada_avatar_photo", state.avatarPhoto);
      /* Show the rotated local copy at once; the cloud URL still
         points at the old bake until the upload below lands and
         replaces it (cloudUploadAvatar sets the fresh URL itself). */
      state.avatarUrl = null;
      lsSet("tirada_avatar_url", null);
      renderMyAvatar(); renderAvatarGrid();
      toast(t("Фото повёрнуто ⟳"));
      /* This upload supersedes any heal that has not started yet:
         a late heal would re-upload the pre-rotation photo. */
      avatarHealStarted = true;
      if (window.TiradaDB && typeof cloudUploadAvatar === "function"){
        cv.toBlob(function(blob){ if (blob) cloudUploadAvatar(blob, true); }, "image/jpeg", 0.85);
      }
    } catch (e){ toast(t("Не вышло повернуть фото")); }
  };
  img.onerror = function(){ toast(t("Не вышло повернуть фото")); };
  img.src = src;
});
/* ================= Nick validation =================
   A ghost name may be written in Russian, Hebrew or Latin letters —
   plus digits, a space, a hyphen, an underscore and an apostrophe
   (' or ’ — Hebrew names are often typed with one). Length 2–24.
   Anything else is rejected with a plain-language reason; characters
   are never silently stripped or cut. */
var NICK_RE = /^[A-Za-zА-Яа-яЁё\u0590-\u05FF0-9 _'\u2019-]+$/;
function validateNick(raw){
  var v = (raw == null ? "" : String(raw)).trim();
  if (!v) return { ok: false, error: t("Ник не может быть пустым") };
  if (v.length < 2) return { ok: false, error: t("Ник слишком короткий — нужно минимум 2 символа") };
  if (v.length > 24) return { ok: false, error: t("Ник слишком длинный — максимум 24 символа") };
  if (!NICK_RE.test(v)) return { ok: false, error: t("В нике можно только буквы (русские, иврит или латиница), цифры, пробел, дефис, подчёркивание и апостроф") };
  return { ok: true, value: v };
}
window.__validateNick = validateNick;
/* A rejected nick must not look like a silent "doesn't work": besides the
   toast, the reason stays visible as a red line under the field and the
   field keeps a red outline until the next input. */
function showNickError(msg){
  var err = $("#nickError"), inp = $("#nickInput");
  if (err){ err.textContent = msg; err.hidden = false; }
  if (inp) inp.classList.add("nick-invalid");
}
function clearNickError(){
  var err = $("#nickError"), inp = $("#nickInput");
  if (err){ err.textContent = ""; err.hidden = true; }
  if (inp) inp.classList.remove("nick-invalid");
}
function applyNick(){
  var inp = $("#nickInput");
  if (!inp) return;
  if (inp.value.trim() === (state.nick || "")){ clearNickError(); return; }
  if (!inp.value.trim()){
    state.nick = "";
    inp.value = "";
    lsSet("tirada_nick", state.nick);
    renderMyAvatar();
    scheduleCloudSync();
    renderAccount();
    clearNickError();
    toast(t("Ник сброшен"));
    return;
  }
  var chk = validateNick(inp.value);
  if (!chk.ok){
    toast(chk.error);
    showNickError(chk.error);
    inp.value = state.nick || "";
    return;
  }
  var commitNick = function(){
    state.nick = chk.value;
    inp.value = state.nick;
    lsSet("tirada_nick", state.nick);
    renderMyAvatar();
    scheduleCloudSync();
    renderAccount();
    clearNickError();
    toast(tf("Ник сохранён: {nick}", { nick: state.nick }));
  };
  /* Signed in: nicks are unique in the cloud — check before promising
     "saved" (the upsert would bounce off the unique index anyway, and
     cloudSyncNow turns that 23505 into the same visible error). */
  if (db && cloudUser){
    var pat = chk.value.replace(/[%_\\]/g, "\\$&");
    db.from("profiles").select("id").ilike("name", pat).limit(5)
      .then(function(res){
        var taken = !res.error && res.data && res.data.some(function(r){ return r.id !== cloudUser.id; });
        if (taken){
          toast(t(NICK_TAKEN_MSG));
          showNickError(t(NICK_TAKEN_MSG));
          inp.value = state.nick || "";
          return;
        }
        commitNick();
      }, function(){ commitNick(); });
    return;
  }
  commitNick();
}
$("#nickInput").addEventListener("change", applyNick);
$("#nickInput").addEventListener("keydown", function(e){
  if (e.key === "Enter"){ e.preventDefault(); applyNick(); this.blur(); }
});
$("#nickInput").addEventListener("input", clearNickError);
$("#shareGeoBtn").addEventListener("click", function(){
  if (!state.geo){ toast(t("Сначала включи геолокацию")); return; }
  var link = "https://maps.google.com/?q=" + state.geo.lat + "," + state.geo.lng;
  if (navigator.share){
    navigator.share({ title: t("Я здесь 👻"), text: t("Моя геопозиция в TiradA anon"), url: link }).catch(function(){});
  } else if (navigator.clipboard) {
    navigator.clipboard.writeText(link).then(function(){ toast(t("Ссылка на геопозицию скопирована 📍")); }, function(){ toast(link); });
  } else toast(link);
});

/* ================= Tabs / screens ================= */
function showScreen(name){
  $$(".tab").forEach(function(t){ t.classList.toggle("active", t.getAttribute("data-screen") === name); });
  $$(".screen").forEach(function(s){ s.classList.toggle("active", s.id === "screen-" + name); });
  if (name === "map" && map) setTimeout(function(){
    if (!map) return;
    map.resize();
    /* Resize alone does not reposition DOM markers in MapLibre (they
       update on move/terrain events): re-pin the ghost explicitly, so
       a marker created against a stale size can never sit off-screen
       after the tab becomes visible. */
    renderMapMarkers();
  }, 60);
  /* Opening the Map tab is the user asking for the map (v21): if it
     died to the fallback earlier, retry construction right now —
     the network may be back, and the watchdog will not fire again
     on its own. */
  if (name === "map" && !map) ensureMapAlive("tab-open", true);
  if (name === "map") refreshFriendMarkers();
  if (name === "places") renderPlaces();
  if (name === "profile" && typeof cloudUser !== "undefined" && cloudUser) friendsLoad();
}
$$(".tab").forEach(function(t){
  t.addEventListener("click", function(){
    /* If the nick field was edited but never confirmed (no blur/Enter on a
       phone), apply it before leaving the profile — when it is valid. */
    var ni = $("#nickInput");
    if (ni && ni.value.trim() !== (state.nick || "")) applyNick();
    showScreen(t.getAttribute("data-screen"));
  });
});

/* ================= City picker ================= */
function renderCityList(){
  var q = (($("#citySearch") && $("#citySearch").value) || "").trim().toLowerCase();
  var list = CITIES.filter(function(c){ return !q || c.name.toLowerCase().indexOf(q) >= 0 || cityName(c).toLowerCase().indexOf(q) >= 0; });
  $("#cityList").innerHTML = list.length ? list.map(function(c){
    var n = PLACES_BY_CITY[c.id].length;
    return '<button class="city-item' + (c.id === state.city.id ? " current" : "") + '" data-city="' + c.id + '">' +
      '<span>' + cityName(c) + '</span><span class="city-item-meta">' + n + ' ' + placeWord(n) + (c.id === state.city.id ? t(" · ты здесь") : "") + '</span></button>';
  }).join("") : '<div class="places-empty">' + t("Город не нашёлся 👻") + '</div>';
  $$(".city-item").forEach(function(it){
    it.addEventListener("click", function(){ setCity(it.getAttribute("data-city")); });
  });
}
function setCity(id){
  state.city = cityById(id);
  state.filter = "all";
  state.dealAlt = 0;
  state.routeRound = 0;
  state.routeSteps = null;
  state.search = "";
  var ps = $("#placeSearch"); if (ps) ps.value = "";
  $("#cityName").textContent = cityName(state.city);
  $("#routeCity").textContent = cityName(state.city);
  $("#citySheet").hidden = true;
  var cs = $("#citySearch"); if (cs) cs.value = "";
  renderFilter(); renderPlaces(); updateCounter(); buildTicker(); buildRoute();
  refreshCityPhotoCount();
  if (map){
    clearRoute();
    renderMapMarkers();
    map.flyTo({ center: [state.city.lng, state.city.lat], zoom: 13, duration: 1100 });
  }
  renderCityList();
  scheduleCloudSync();
  toast(tf("Ты теперь призрак в городе {city} 👻", { city: cityName(state.city) }));
}
$("#citySearch").addEventListener("input", function(){ renderCityList(); });
$("#cityBtn").addEventListener("click", function(){
  /* Open first, then render (v22): the sheet must never present a
     stale or never-rendered list. Before v22 this handler only
     unhid the sheet, so whenever the boot render of #cityList had
     not happened (the v21 cascade) the user opened an empty sheet
     that only filled after typing in the search box. */
  $("#citySheet").hidden = false;
  try { renderCityList(); } catch (e) { try { tracePush("error", "citySheet render: " + ((e && e.message) || e)); } catch (e2){} }
});
$("#cityClose").addEventListener("click", function(){ $("#citySheet").hidden = true; });
$("#citySheet").addEventListener("click", function(e){ if (e.target === this) this.hidden = true; });

/* ================= Deal overlay ================= */
function hottest(){ return places().filter(function(p){ return !isSecretLocked(p); }).sort(function(a,b){ return heatOf(b) - heatOf(a); }); }
/* Voting for the meetup place: the 3 hottest places of the city (or the 3
   from a shared #vote= link). Votes live in the votes table and count for
   signed-in ghosts only; a guest is offered sign-in and nothing is
   recorded — no invented percentages, no fake friends' votes. */
function dealCandidates(){
  if (state.voteLink && state.voteLink.length){
    var out = [];
    state.voteLink.forEach(function(id){
      var f = findPlace(id);
      if (f) out.push(f.place);
    });
    if (out.length) return out;
  }
  return hottest().slice(0, 3);
}
function voteHtml(){
  var cands = dealCandidates();
  /* A guest has no vote: only a signed-in ghost's vote exists (wave 2 —
     no more local fake votes that never reach the votes table). */
  var mine = (cloudUser && state.vote && state.vote.cityId === state.city.id) ? state.vote.placeId : null;
  var mineName = null;
  cands.forEach(function(p){ if (p.id === mine) mineName = p.name; });
  return '<div class="vote-box"><h4>🗳️ ' + t("Куда идём?") + '</h4>' +
    '<div class="vote-list">' + cands.map(function(p){
      var cnt = (typeof cloudUser !== "undefined" && cloudUser)
        ? '<span class="vote-count" data-vcount="' + p.id + '">' + ((typeof cloudVoteCounts !== "undefined" && cloudVoteCounts && cloudVoteCounts[p.id]) || 0) + "</span>"
        : "";
      return '<button class="vote-btn' + (p.id === mine ? " chosen" : "") + '" data-vote="' + p.id + '">' +
        '<span>' + p.name + '</span>' + cnt + '<span class="vote-heat">' + (openStatus(p).open ? heatOf(p) + "%" : t("закрыто")) + "</span></button>";
    }).join("") + "</div>" +
    (mineName
      ? '<div class="vote-mine">' + t("Твой голос:") + " <b>" + mineName + "</b></div>"
      : '<div class="vote-mine dim">' + (cloudUser ? t("Тапни место — это будет твой голос") : t("Войди, чтобы твой голос засчитался")) + "</div>") +
    '<button class="btn-alt vote-share" id="voteShare">' + t("Позвать голосовать") + ' 👻</button></div>';
}
function renderDeal(place){
  $("#dealBody").innerHTML =
    '<div class="indeal-card">' +
    '<div class="deal-online" id="dealOnline"></div>' +
    '<div id="dealFriends"></div>' +
    '<div class="deal-empty" id="dealEmpty">' +
      '<div class="deal-empty-emoji">🤫</div>' +
      '<h4>' + t("Пока никто из твоих друзей не в деле") + '</h4>' +
      '<p class="deal-empty-text">' + t("Здесь будут друзья-призраки, когда сами нажмут «Я в деле». Позови их — и вечер соберётся сам.") + '</p>' +
      '<button class="btn-yes" id="dealInvite">' + t("Позвать друзей") + ' 👻</button>' +
    '</div>' +
    '<div class="deal-meet"><div style="text-align:center"><span class="deal-top-badge">🏆 ' + t("Топ выбор радара") + '</span></div>' +
    '<div class="meet-place">' + tf("📍 А движ уже есть: {place}", { place: place.name }) + '</div>' +
    '<div class="meet-meta">' + tf("Город {city} · {status}, {dist}. Можно стартовать отсюда — друзья подтянутся по ссылке.", { city: cityName(state.city), status: (openStatus(place).open ? tf("сейчас там {hl} (движ {h}%)", { hl: heatLabel(heatOf(place)).replace("🔥 ", ""), h: heatOf(place) }) : t("сейчас это место закрыто — движ по радару нулевой")), dist: distFromText(place) }) + '</div>' +
    '<div class="indeal-actions">' +
    '<button class="btn-route-deal" id="dealRoute">🚗 ' + t("Маршрут") + '</button>' +
    '<button class="btn-alt" id="dealAlt">' + t("Другое место") + '</button></div></div>' +
    voteHtml() + '</div>';
  $("#dealInvite").addEventListener("click", shareFriendInvite);
  $("#dealRoute").addEventListener("click", function(){ routeTo(place); });
  $("#dealAlt").addEventListener("click", function(){
    state.dealAlt++;
    renderDeal(hottest()[state.dealAlt % 3]);
  });
  $$("#dealBody [data-vote]").forEach(function(btn){
    btn.addEventListener("click", function(){
      if (!cloudUser){
        /* Guest: no vote is recorded anywhere — offer sign-in instead. */
        toast(t("Войди, чтобы твой голос засчитался 🗳️"));
        $("#loginModal").hidden = false;
        return;
      }
      var newVoteId = btn.getAttribute("data-vote");
      var voteChanged = !state.vote || state.vote.cityId !== state.city.id || state.vote.placeId !== newVoteId;
      state.vote = { cityId: state.city.id, placeId: newVoteId };
      lsSet("tirada_vote", state.vote);
      cloudCastVote(state.vote.placeId);
      if (voteChanged){ state.stats.votes++; saveStats(); renderStats(); }
      renderDeal(place);
      toast(t("Голос принят 🗳️"));
    });
  });
  refreshOnlineLine();
  refreshVoteCounts();
  renderDealFriends();
  friendsLoad();
  var vs = $("#voteShare");
  if (vs) vs.addEventListener("click", function(){
    var ids = dealCandidates().map(function(p){ return p.id; }).join(",");
    var url = location.origin + location.pathname + "#deal&vote=" + ids;
    if (navigator.share){
      navigator.share({ title: t("TiradA anon — голосуем"), text: t("Куда идём сегодня? Голосуй в TiradA anon 👻"), url: url }).catch(function(){});
    } else if (navigator.clipboard) {
      navigator.clipboard.writeText(url).then(function(){ toast(t("Ссылка голосования скопирована 🗳️")); }, function(){ toast(tf("Ссылка: {url}", { url: url })); });
    } else toast(tf("Ссылка: {url}", { url: url }));
  });
}
function openDeal(){
  countDealNight();
  var fab = $("#fabDeal");
  if (fab){
    fab.classList.add("in-deal");
    var lb = fab.querySelector(".fab-label");
    if (lb) lb.textContent = t("Ты в деле");
  }
  state.dealAlt = 0;
  $("#dealOverlay").hidden = false;
  $("#dealBody").innerHTML = '<div class="searching">' + tf("Смотрю, где в городе {city} сейчас жарче всего", { city: cityName(state.city) }) + '<span class="dots"></span></div>';
  setTimeout(function(){ renderDeal(hottest()[0]); }, 800);
}
function closeDeal(){ $("#dealOverlay").hidden = true; }
$("#fabDeal").addEventListener("click", openDeal);
$("#dealClose").addEventListener("click", closeDeal);
$("#dealOverlay").addEventListener("click", function(e){ if (e.target === this) closeDeal(); });

/* ================= Evening route =================
   Steps are picked once per "round" (transport switches re-render the
   same steps with new times). Leg times are honest estimates per
   transport: walk 5 km/h, car ~28 km/h in the city, bus = car x1.35.
   Task checkboxes persist per route signature in localStorage. */
function legMinutes(km, mode){
  if (mode === "walk") return km / 5 * 60;
  if (mode === "bus") return km / 28 * 60 * 1.35;
  return km / 28 * 60;
}
function pickRouteSteps(){
  var all = places().filter(function(p){ return !isSecretLocked(p); });
  var chill = all.filter(function(p){ var tg = p.tagsRu || p.tags; return tg.indexOf("тихо") >= 0 || tg.indexOf("вкусно") >= 0; });
  var calm  = all.filter(function(p){ var tg = p.tagsRu || p.tags; return tg.indexOf("романтика") >= 0; });
  var hot = hottest();
  if (!chill.length) chill = all;
  if (!calm.length) calm = all.slice().sort(function(a,b){ return heatOf(a) - heatOf(b); });
  var pick = function(arr, seed){ return arr[Math.abs(seed) % arr.length]; };
  var used = {};
  var take = function(arr, seed){
    var p = pick(arr, seed), guard = 0;
    while (used[p.id] && guard < arr.length){ seed++; p = pick(arr, seed); guard++; }
    used[p.id] = 1;
    return p;
  };
  state.routeSteps = [
    { time:"19:30", place:take(chill, state.routeRound),     note:t("Старт — спокойно зайти в вечер.") },
    { time:"21:00", place:take(hot, state.routeRound),       note:t("Пик ночи — туда, где жарче всего.") },
    { time:"22:40", place:take(calm, state.routeRound + 1),  note:t("Финал — красиво и без суеты.") }
  ];
  /* Route tasks: bank = all type tasks (22) + ROUTE_TASKS (16) = 38 unique;
     inside one route a task never repeats. */
  var pool = [];
  Object.keys(TYPES).forEach(function(k){ typeTasks(k).forEach(function(x){ pool.push(x); }); });
  ((contentI18n() && contentI18n().ROUTE_TASKS) || ROUTE_TASKS).forEach(function(x){ pool.push(x); });
  var usedT = {};
  state.routeSteps.forEach(function(s, i){
    var t = s.place.task;
    if (usedT[t]){
      var cand = pool[(state.routeRound * 3 + i * 5) % pool.length], g = 0;
      while (usedT[cand] && g < pool.length){ cand = pool[(state.routeRound * 3 + i * 5 + g) % pool.length]; g++; }
      t = cand;
    }
    usedT[t] = 1;
    s.taskText = t;
  });
  state.routeRound++;
}
var ROUTE_TASKS = [
  "Сфотографируйте вывеску места так, чтобы она выглядела как обложка альбома.",
  "Найдите в этом месте что-то круглое и красное — фото в студию.",
  "Вся компания показывает пальцем в одну точку неба. Фото снизу вверх.",
  "Сделайте фото, где все отражены в витрине или зеркале, а не смотрят в камеру.",
  "Запишите 5-секундное видео: каждый говорит одно слово о сегодняшнем вечере.",
  "Найдите самое яркое окно рядом и сфотографируйтесь на его фоне силуэтами.",
  "Челлендж «статуи»: замрите в смешных позах на 10 секунд посреди места.",
  "Сфотографируйте свои тени на асфальте — чтобы было понятно, сколько вас.",
  "Каждый находит рядом предмет своего любимого цвета. Общее фото находок.",
  "Сделайте панораму места, где в кадр попадут все участники хотя бы частично.",
  "Фото «до и после»: одно и то же место с двух противоположных точек.",
  "Придумайте название для вашей компании на эту ночь и напишите его мелом… шутка — просто вслух и на видео.",
  "Найдите уличного кота рядом с местом. Фото кота — обязательный трофей.",
  "Снимите, как вся компания синхронно делает три шага назад и вперёд. С первого дубля.",
  "Каждый фотографирует одну деталь места крупным планом — остальные угадывают, что это.",
  "Финальное фото точки: все спиной к камере смотрят на место, как герои фильма."
];
function routeKey(){
  if (!state.routeSteps) return "";
  return state.city.id + "|" + state.routeSteps.map(function(s){ return s.place.id; }).join(",");
}
function routeDoneCount(){
  var d = state.routeDone[routeKey()] || {};
  return Object.keys(d).filter(function(k){ return d[k]; }).length;
}
function renderRouteProgress(){
  var el = $("#routeProgress");
  if (el) el.textContent = tf("Выполнено {a} из 3", { a: routeDoneCount() });
}
function buildRoute(){
  if (!state.routeSteps) pickRouteSteps();
  var steps = state.routeSteps, tm = TRANSPORTS[state.transport] || TRANSPORTS.car;
  var doneMap = state.routeDone[routeKey()] || {};
  var travelMin = 0, prev = null, html = "";
  steps.forEach(function(s, i){
    if (prev){
      var km = distKm(prev, s.place), mins = legMinutes(km, state.transport);
      travelMin += mins;
      html += '<div class="route-leg">' + tm.icon + " " + fmtDist(km) + " · ≈ " + fmtDur(mins) + (state.transport === "bus" ? t(" (примерно)") : "") + "</div>";
    }
    prev = s.place;
    html += '<div class="route-step" style="animation-delay:' + (i * 0.12).toFixed(2) + 's"><div class="route-dot">' + (i + 1) + '</div>' +
      '<div class="route-card"><div class="route-time">' + s.time + ' · ' + cityName(state.city) + '</div>' +
      '<h4>' + emojiImg(s.place.art, "route-img") + ' ' + s.place.name + '</h4>' +
      '<div class="route-task">' + s.note + '<br>🎯 ' + (s.taskText || s.place.task) + '</div>' +
      '<label class="route-check"><input type="checkbox" data-task-check="' + i + '"' + (doneMap[i] ? " checked" : "") + '> ' + t("Задание выполнено") + '</label></div></div>';
  });
  var totalMin = travelMin + steps.length * 60;
  html += '<div class="route-total"><span id="routeProgress">' + tf("Выполнено {a} из 3", { a: routeDoneCount() }) + '</span>' + tf(" · в дороге ≈ {tr} · весь вечер ≈ {tt} ({m})", { tr: fmtDur(travelMin), tt: fmtDur(totalMin), m: t(tm.label) }) + '</div>';
  $("#routeBox").innerHTML = html;
  $$("#routeBox [data-task-check]").forEach(function(cb){
    cb.addEventListener("change", function(){
      var key = routeKey();
      if (!state.routeDone[key]) state.routeDone[key] = {};
      state.routeDone[key][cb.getAttribute("data-task-check")] = cb.checked;
      lsSet("tirada_route_done", state.routeDone);
      renderRouteProgress();
      if (routeDoneCount() === 3){
        toast(t("Маршрут пройден полностью 🎉"));
        if (eventCooldownOk("tirada_ev_routedone", key, 7 * 24 * 3600000))
          writeEvent("route_done", tf("🌙 {name} завершил маршрут на вечер", { name: myDisplayName() }));
      }
    });
  });
}
$("#routeBtn").addEventListener("click", function(){
  state.routeSteps = null;
  buildRoute();
  countRouteBuilt();
});
$$("#transportSwitch .transport-btn").forEach(function(btn){
  btn.addEventListener("click", function(){
    state.transport = btn.getAttribute("data-transport");
    $$("#transportSwitch .transport-btn").forEach(function(b){ b.classList.toggle("active", b === btn); });
    buildRoute();
  });
});
$("#routeShareBtn").addEventListener("click", function(){
  if (!state.routeSteps) buildRoute();
  var tm = TRANSPORTS[state.transport] || TRANSPORTS.car;
  var text = tf("🌙 Мой маршрут на вечер в TiradA anon ({city}, {tr}):", { city: cityName(state.city), tr: t(tm.label) }) + "\n" +
    state.routeSteps.map(function(s, i){ return (i + 1) + ". " + s.time + " — " + s.place.name; }).join("\n") +
    "\n" + t("Залетай:") + " " + location.origin + location.pathname + "#route";
  if (navigator.share){
    navigator.share({ title: t("Маршрут на вечер — TiradA anon"), text: text }).catch(function(){});
  } else if (navigator.clipboard) {
    navigator.clipboard.writeText(text).then(function(){ toast(t("Маршрут скопирован — отправь друзьям 📤")); }, function(){ toast(t("Не вышло поделиться")); });
  } else toast(t("Не вышло поделиться"));
});

/* ================= Tasks system =================
   DAILY: one new task per day, chosen deterministically by date from a
   bank of 60 unique tasks — same all day, no repeats inside the cycle.
   WEEKLY QUEST: a 5-step chain; the theme is chosen deterministically by
   week number from 8 quests. Steps unlock one by one; finishing a quest
   earns a Profile badge. All progress is local (localStorage). */
var DAILY_TASKS = [
  "Сфоткай закат с самой высокой точки рядом с тобой",
  "Найди уличного кота и сфоткай его, как модель",
  "Покажи другу новое место, где он ещё не был",
  "Сфотографируй самое красивое дерево на своём маршруте",
  "Найди вывеску с самой смешной надписью и сфоткай",
  "Сделай фото отражения города в луже, окне или витрине",
  "Пройди 1000 шагов в сторону, где ты никогда не гулял",
  "Сфотографируй три круглых предмета за одну прогулку",
  "Найди стену с граффити и сделай фото на её фоне",
  "Поздоровайся с незнакомцем и пожелай ему хорошего вечера",
  "Сфоткай самую яркую вывеску в своём районе",
  "Найди место, где слышно музыку на улице, и постой там минуту",
  "Сделай селфи с самой старой дверью, которую найдёшь",
  "Сфотографируй свои ботинки в трёх разных местах за вечер",
  "Найди скамейку с лучшим видом и посиди на ней 5 минут без телефона",
  "Покажи другу место из своего детства и расскажи одну историю про него",
  "Сфоткай три разных фонаря и собери коллаж",
  "Найди лестницу и сфотографируй вид снизу вверх",
  "Сделай фото, где ты и тень друга — главные герои",
  "Найди цветок, растущий в самом неожиданном месте, и сфоткай",
  "Пройди целый квартал, не наступая на трещины в асфальте",
  "Сфотографируй небо ровно в момент, когда читаешь это, где бы ты ни был",
  "Найди зеркальную поверхность на улице и сделай групповое фото в отражении",
  "Угости друга кофе или мороженым без повода",
  "Сфоткай дом с самым необычным балконом",
  "Найди уличного музыканта или артиста и поддержи аплодисментами",
  "Сделай фото моста, перил или арки так, чтобы кадр уходил вдаль",
  "Найди и сфотографируй три предмета одного цвета за 10 минут",
  "Покажи новому человеку в компании своё любимое место в городе",
  "Сфоткай окно, в котором горит самый тёплый свет",
  "Придумай название для улицы, на которой стоишь, и запиши на видео почему",
  "Найди самую высокую точку рядом и сфотографируй город с неё",
  "Сделай фото, где вся компания прыгает одновременно",
  "Найди табличку с названием улицы и сфоткайся под ней",
  "Сфотографируй велосипед так, будто это реклама",
  "Прогуляйся 10 минут без наушников и послушай город",
  "Найди место, где пахнет свежеиспечённым, и купи там что-нибудь маленькое",
  "Сфоткай три разных вида транспорта в одном кадре или за один вечер",
  "Сделай фото заката через ветки дерева",
  "Найди фонтан или воду в городе и сфотографируй брызги на солнце или в огнях",
  "Научи друга одному слову на языке, которого он не знает",
  "Сфоткай самую смешную тень, которую найдёшь сегодня",
  "Найди дом номер 13 и сфотографируй его табличку",
  "Сделай фото компании в виде обложки музыкальной группы",
  "Найди и сфотографируй птицу крупным планом, насколько получится",
  "Пройди до конца улицы, на которой ты сейчас, и сфоткай, что там",
  "Сфоткай витрину, в которой отражается закат",
  "Обними дерево в парке и сделай фото — да, серьёзно",
  "Найди самое тихое место в радиусе 500 метров и постой там минуту",
  "Сфотографируй луну, если её видно, или самую яркую звезду",
  "Сделай другу комплимент про что-то конкретное — вслух, не в чате",
  "Найди старую вывеску или табличку, которой явно много лет, и сфоткай",
  "Сфоткай свои руки и руки друга на фоне города — кадр «мы здесь»",
  "Пройди 500 шагов с закрытыми… нет — с поднятой головой, не глядя под ноги и в телефон",
  "Найди место, где ты был ровно год назад, и сделай фото «тогда и сейчас» в голове",
  "Сфотографируй три окна, в которых видно, как люди живут: свет, цветы, силуэты",
  "Устрой мини-пикник: любой перекус на скамейке с лучшим видом",
  "Сфоткай первый попавшийся красный предмет — он твой талисман на вечер",
  "Найди улицу, названную в честь кого-то, и узнай, кто это был",
  "Сделай последнее фото вечера: вся компания и одна фраза, как прошла ночь",
  "Найди самую старую скамейку в парке и сфотографируй её табличку или следы времени",
  "Сфотографируй очередь: в пекарню, к банкомату, куда угодно — город в ожидании",
  "Пройди один квартал, считая все балконы с цветами, и сфоткай лучший",
  "Найди место, где город пахнет морем, хлебом или дождём, и постой там минуту",
  "Сделай фото вывески, где буква сломалась или погасла, — найди в этом новый смысл",
  "Покажи другу двор, в котором он точно никогда не был",
  "Сфотографируй три двери разных цветов за одну прогулку",
  "Найди уличный фонарь, который уже горит днём, и сфоткай его — город тоже устаёт",
  "Сделай селфи с отражением заката в окне машины",
  "Найди дерево, обнявшее забор, скамейку или знак, и сфотографируй их союз",
  "Прогуляйся до ближайшей воды и сфоткай, как город отражается в ней",
  "Найди граффити, где есть глаза, и сделай фото «город смотрит на тебя»",
  "Устрой гонку теней: чья тень длиннее на закате — зафиксируй фото",
  "Сфотографируй самый маленький домик или пристройку, что найдёшь",
  "Найди место, где слышно сразу три звука города, и запиши их на видео",
  "Покажи новому другу место, где ты впервые поцеловался или влюбился — без подробностей, просто место",
  "Сфоткай кота на крыше, балконе или подоконнике — высотного кота",
  "Пройди 300 шагов строго на север и сфотографируй, куда пришёл",
  "Найди лавку, где сидят старожилы, и поздоровайся с ними",
  "Сделай фото своей компании через витрину кафе — как кадр из фильма",
  "Сфотографируй небо через крону дерева — природную рамку",
  "Найди дом, где на балконе сушится что-то яркое, и сфоткай этот флаг вечера",
  "Купи самое дешёвое мороженое рядом и съешь его на лучшей скамейке",
  "Сфотографируй часы — уличные, на здании или на руке прохожего (с разрешения)",
  "Найди лестницу, уходящую в небо на фоне заката, и сфоткай силуэт",
  "Сделай фото, где все в компании показывают на одну точку вдали",
  "Прогуляйся по улице, где ты был сто раз, и найди деталь, которой раньше не замечал, — фото в студию",
  "Сфотографируй первый огонь, который зажёгся в окнах с наступлением темноты",
  "Найди место, где две улицы спорят: сфотографируй перекрёсток сверху или с угла",
  "Научи компанию одному жесту или слову из другого языка прямо на улице",
  "Сфоткай самую уютную подворотню или арку с тёплым светом",
  "Найди и сфотографируй велосипедную дорожку, уходящую вдаль",
  "Сделай групповое фото, где все стоят как супергерои на постере",
  "Найди старую афишу или объявление на столбе и сфотографируй — городская археология",
  "Сфотографируй свои и друга шаги: четыре ботинка в ряд на красивом асфальте",
  "Пройди вдоль забора или стены ровно 2 минуты и сфоткай, что за углом",
  "Найди место с эхом и проверь его хлопком — запиши на видео",
  "Сфоткай самую красивую цифру номера дома, что встретишь за вечер",
  "Покажи другу место, где город заканчивается и начинается природа",
  "Сделай фото полной луны сквозь ветки или между домами",
  "Найди уличную библиотеку, будку обмена книгами или полку — сфотографируй",
  "Сфотографируй компанию в лифте, на эскалаторе или в автобусе — движ в движении",
  "Найди цветок, пробившийся сквозь асфальт, и сфотографируй героя",
  "Устрой фотоохоту: первый, кто найдёт предмет на букву «К», выигрывает — фото-доказательство обязательно",
  "Сфоткай закат так, чтобы в кадре был силуэт друга в прыжке",
  "Найди место, где можно услышать тишину в центре города, и посиди там 3 минуты",
  "Сделай фото ночного неба и найди хотя бы одно созвездие",
  "Сфотографируй отражение неоновой вывески в мокром асфальте или луже",
  "Пройди целый мост пешком и сфотографируй оба берега",
  "Найди и сфотографируй самый необычный почтовый ящик или дверь подъезда",
  "Покажи другу закат с точки, где его ещё никто из компании не встречал",
  "Сфоткай три пары: парочки на скамейках — город влюблён (издалека, без лиц крупным планом)",
  "Найди место, где пахнет скошенной травой, и полежи на ней 5 минут",
  "Сделай фото своей тени на стене дома — уличный автопортрет",
  "Сфотографируй очередь огней: улицу фонарей, уходящую в перспективу",
  "Найди мемориальную табличку и узнай, кому она посвящена, — фото и один факт другу",
  "Угости незнакомца на лавочке конфетой или жвачкой — просто так",
  "Сфоткай компанию со спины на фоне города — постер вашего вечера",
  "Найди самую высокую пальму или дерево рядом и сфотографируй снизу вверх",
  "Пройди 10 минут, сворачивая только направо, и сфотографируй финальную точку",
  "Сделай первое фото ночи: ровно в момент, когда включаются уличные фонари",
  "Найди скамейку, с которой видно сразу два района города, и сфотографируй панораму",
  "Сфотографируй, как город готовится спать: закрывающиеся ставни, последние огни кафе"
];
var WEEK_QUESTS = [
  { theme:"Город в кадре", steps:[
    "Сфотографируй главную площадь своего города",
    "Сделай фото самого старого здания, которое найдёшь",
    "Поймай в кадр закат над городом",
    "Сфотографируй город ночью: огни и отражения",
    "Собери все 4 фото в один коллаж и покажи друзьям" ] },
  { theme:"Охотники за котами", steps:[
    "Найди и сфотографируй первого уличного кота",
    "Найди кота другого окраса",
    "Сфотографируй кота, который спит",
    "Найди кота рядом с вывеской или табличкой",
    "Сделай фото кота с другом в кадре (кот — главный)" ] },
  { theme:"Вкусная неделя", steps:[
    "Попробуй выпечку в месте, где ещё не был",
    "Найди самый дешёвый кофе в своём районе",
    "Купи что-то на рынке и сфотографируй прилавок",
    "Угости друга чем-то вкусным без повода",
    "Собери ужин из трёх мест: старт, основа, десерт" ] },
  { theme:"Выше и выше", steps:[
    "Найди лестницу минимум в 30 ступеней и поднимись",
    "Сфотографируй город с моста или эстакады",
    "Найди смотровую точку и сделай панораму",
    "Сфотографируй самое высокое здание рядом снизу вверх",
    "Встреть закат на самой высокой доступной точке" ] },
  { theme:"Добрые дела", steps:[
    "Сделай комплимент незнакомцу",
    "Помоги кому-то донести, показать дорогу или подсказать",
    "Оставь доброе послание на салфетке в кафе",
    "Угости друга маленьким сюрпризом",
    "Собери компанию и сделайте одно доброе дело вместе" ] },
  { theme:"Уличное искусство", steps:[
    "Найди граффити и сфотографируй его целиком",
    "Найди мурал с лицом или персонажем",
    "Сфотографируй необычную вывеску ручной работы",
    "Найди скульптуру или инсталляцию в городе",
    "Сделай своё фото на фоне лучшего стрит-арта недели" ] },
  { theme:"Вода и берега", steps:[
    "Найди ближайшую воду: море, реку, фонтан или озеро",
    "Сфотографируй отражение в воде",
    "Пройди вдоль воды 15 минут без остановки",
    "Найди мост и сфотографируй вид с него",
    "Встреть у воды закат или рассвет" ] },
  { theme:"Ночной город", steps:[
    "Сфотографируй самую яркую неоновую вывеску",
    "Найди улицу, которая ночью красивее, чем днём",
    "Сфотографируй луну или ночное небо над городом",
    "Найди ночное кафе или место, открытое после 23:00",
    "Сделай финальное ночное фото компании в огнях города" ] },
  { theme:"Закаты недели", steps:[
    "Встреть первый закат недели на открытой точке",
    "Сфотографируй закат через ветки, перила или решётку",
    "Найди закат, отражающийся в окнах дома",
    "Встреть закат у воды или на высоте — что ближе",
    "Собери компанию на финальный закат недели и сделайте общее фото" ] },
  { theme:"Скрытые дворы", steps:[
    "Найди двор, в который никогда не заходил, и загляни",
    "Сфотографируй самый уютный двор: скамейки, цветы, коты",
    "Найди арку или проход, сокращающий путь, — проверь сам",
    "Найди во дворе что-то из прошлого века и сфотографируй",
    "Покажи другу лучший найденный двор недели" ] },
  { theme:"Люди города", steps:[
    "Пожелай хорошего вечера трём незнакомцам",
    "Спроси у прохожего его любимое место в городе (и сходи туда)",
    "Сфотографируй уличного артиста, музыканта или художника (с разрешения)",
    "Помоги туристу или новому жителю сориентироваться",
    "Собери компанию из старых и новых знакомых на одной точке" ] },
  { theme:"Город на вкус и запах", steps:[
    "Найди пекарню по запаху с улицы и зайди",
    "Попробуй уличную еду, которую ещё не пробовал",
    "Найди место, где пахнет кофе на всю улицу, и выпей там кофе",
    "Купи сезонный фрукт на рынке и съешь его на скамейке",
    "Устрой дегустацию: три места — три маленьких вкуса за один вечер" ] }
];
function dayIndex(){ return Math.floor(Date.now() / 86400000); }
function todayKey(){ return new Date().toDateString(); }
function dailyTask(){ var i = dayIndex() % DAILY_TASKS.length; var C = contentI18n(); return (C && C.DAILY_TASKS && C.DAILY_TASKS[i]) || DAILY_TASKS[i]; }
function weekIndex(){ return Math.floor(dayIndex() / 7); }
function weekQuest(){ var idx = weekIndex() % WEEK_QUESTS.length; var C = contentI18n(); var T = C && C.WEEK_QUESTS && C.WEEK_QUESTS[idx]; return T ? { theme: T.theme, steps: T.steps } : WEEK_QUESTS[idx]; }
function renderTasks(){
  var dt = $("#dailyTaskText"); if (!dt) return;
  dt.textContent = dailyTask();
  var st = objOr(lsGet("tirada_streak", null), { last: "", streak: 0 });
  var doneToday = (st.last === todayKey());
  var btn = $("#dailyDoneBtn");
  btn.disabled = doneToday;
  btn.textContent = doneToday ? t("Выполнено ✓") : t("Выполнено 📸 — нужно фото");
  btn.classList.toggle("done", doneToday);
  /* Mirror the streak into the synced stats: XP and the series badges are
     computed from stats, including for the friends leaderboard. */
  if (state.stats.streak !== st.streak || st.streak > (state.stats.bestStreak || 0)){
    state.stats.streak = st.streak;
    state.stats.bestStreak = Math.max(state.stats.bestStreak || 0, st.streak);
    saveStats();
  }
  var line = tf("🔥 Серия: {n} {w} · бонус серии к XP: +{b}{tail}", { n: st.streak, w: pl(st.streak, "day"), b: streakBonusXp(st.streak), tail: doneToday ? t(" — так держать!") : t(" — отметь задание, чтобы серия росла") });
  $("#streakLine").textContent = line;
  var ps = $("#profileStreak"); if (ps) ps.textContent = line;
  var q = weekQuest();
  $("#questTheme").textContent = q.theme;
  var qs = objOr(lsGet("tirada_quest", null), { week: -1, done: 0 });
  if (qs.week !== weekIndex()){ qs = { week: weekIndex(), done: 0 }; lsSet("tirada_quest", qs); }
  $("#questFill").style.width = (qs.done / q.steps.length * 100) + "%";
  $("#questProgressText").textContent = tf("{a} из {b}", { a: qs.done, b: q.steps.length });
  $("#questSteps").innerHTML = q.steps.map(function(s, i){
    var cls = i < qs.done ? "done" : (i === qs.done ? "current" : "locked");
    var btnHtml = i === qs.done ? '<button class="btn-alt quest-btn" data-quest-step="' + i + '">' + t("Готово") + "</button>"
      : (i < qs.done ? '<span class="quest-check">✓</span>' : '<span class="quest-lock">🔒</span>');
    return '<div class="quest-step ' + cls + '"><span class="quest-num">' + (i + 1) + '</span><span class="quest-text">' + s + "</span>" + btnHtml + "</div>";
  }).join("");
  $$("#questSteps [data-quest-step]").forEach(function(b){
    b.addEventListener("click", function(){
      /* Quest steps count ONLY with a photo proof (camera flow, no place —
         the photo confirms the step and is never published). */
      startPhotoFlow(null, function(){
        var cur = lsGet("tirada_quest", { week: weekIndex(), done: 0 });
        if (cur.week !== weekIndex()) cur = { week: weekIndex(), done: 0 };
        cur.done = Math.min(weekQuest().steps.length, cur.done + 1);
        lsSet("tirada_quest", cur);
        state.stats.questSteps++;
        if (cur.done >= weekQuest().steps.length){
          lsSet("tirada_quest_badges", lsGet("tirada_quest_badges", 0) + 1);
          state.stats.quests++;
          saveStats(); renderStats();
          toast(t("Квест недели пройден! Бейдж в профиле 🏅"));
          fireConfetti();
          writeEvent("quest_done", tf("🏆 {name} прошёл квест «{q}»", { name: myDisplayName(), q: weekQuest().theme }));
        } else { saveStats(); renderStats(); toast(t("Шаг квеста засчитан 🗺️")); }
        renderTasks();
      });
    });
  });
}
$("#dailyDoneBtn").addEventListener("click", function(){
  var st = lsGet("tirada_streak", { last: "", streak: 0 });
  if (st.last === todayKey()) return;
  /* The daily task counts ONLY with a photo proof (camera flow, no place —
     the photo confirms the task and is never published). */
  startPhotoFlow(null, function(){
    var st2 = lsGet("tirada_streak", { last: "", streak: 0 });
    if (st2.last === todayKey()) return;
    var y = new Date(Date.now() - 86400000).toDateString();
    st2.streak = (st2.last === y) ? st2.streak + 1 : 1;
    st2.last = todayKey();
    lsSet("tirada_streak", st2);
    state.stats.tasks++;
    state.stats.streak = st2.streak;
    state.stats.bestStreak = Math.max(state.stats.bestStreak || 0, st2.streak);
    saveStats(); renderStats();
    renderTasks();
    toast(tf("Задание дня выполнено 🔥 Серия: {n}", { n: st2.streak }));
    fireConfetti();
    renderStreakChip();
  });
});

/* ================= AI day drop (v27, «ИИ-УМ») =================
   A fresh drop every day — 3 tasks, a quest of the day and an evening
   route theme — generated by Jarvis and published into the Supabase
   table daily_drops (one row per local calendar day, data jsonb in
   RU/HE/EN). The block lives at the top of the tasks box and degrades
   to NOTHING: no row for today, a network error or no client at all
   leaves it hidden and the boot untouched. Completing a drop task
   pays the task's own xp into stats.aiXp (counted by xpOfStats and
   synced like every other counter); the per-day done set lives in
   localStorage tirada_ai_day_done. */
var aiDayData = null; /* parsed drop for today; null while absent */
function aiDayKey(){
  var d = new Date(), p = function(n){ return (n < 10 ? "0" : "") + n; };
  return d.getFullYear() + "-" + p(d.getMonth() + 1) + "-" + p(d.getDate());
}
function aiText(o){ return o ? (o[LANG] || o.ru || o.en || o.he || "") : ""; }
function aiEsc(s){
  return String(s == null ? "" : s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}
function aiDayDone(){
  var v = lsGet("tirada_ai_day_done", null);
  if (!v || v.day !== aiDayKey() || !Array.isArray(v.ids)) return { day: aiDayKey(), ids: [] };
  return v;
}
function renderAiDay(){
  var box = $("#aiDayBox"); if (!box) return;
  var drop = aiDayData;
  if (!drop || !Array.isArray(drop.tasks) || !drop.tasks.length){
    box.hidden = true; box.innerHTML = ""; return;
  }
  var done = aiDayDone();
  var html = '<h3 class="tasks-title">' + t("🤖 ИИ дня") + "</h3>";
  html += drop.tasks.map(function(task){
    var isDone = done.ids.indexOf(task.id) >= 0;
    var btn = isDone
      ? '<button class="btn-alt quest-btn" data-ai-task="' + aiEsc(task.id) + '" disabled>' + t("Выполнено ✓") + "</button>"
      : '<button class="btn-alt quest-btn" data-ai-task="' + aiEsc(task.id) + '">' + t("Готово") + "</button>";
    return '<div class="ai-task' + (isDone ? " done" : "") + '">' +
      '<div class="ai-task-main"><div class="ai-task-title">' + aiEsc(aiText(task.title)) +
      ' <span class="ai-xp">+' + (+task.xp || 0) + " XP</span></div>" +
      '<div class="ai-task-desc">' + aiEsc(aiText(task.desc)) + "</div></div>" + btn + "</div>";
  }).join("");
  if (drop.quest)
    html += '<h3 class="tasks-title ai-sub"><span>' + t("🗺️ Квест дня:") + "</span> " + aiEsc(aiText(drop.quest.title)) + "</h3>" +
      '<div class="ai-line">' + aiEsc(aiText(drop.quest.desc)) + "</div>";
  if (drop.route_theme)
    html += '<h3 class="tasks-title ai-sub"><span>' + t("🌙 Тема маршрута на вечер:") + "</span> " + aiEsc(aiText(drop.route_theme.title)) + "</h3>" +
      '<div class="ai-line">' + aiEsc(aiText(drop.route_theme.desc)) + "</div>";
  box.innerHTML = html;
  box.hidden = false;
  $$("#aiDayBox [data-ai-task]").forEach(function(b){
    b.addEventListener("click", function(){ aiTaskComplete(b.getAttribute("data-ai-task")); });
  });
}
function aiTaskComplete(id){
  if (!aiDayData || !Array.isArray(aiDayData.tasks)) return;
  var task = null;
  aiDayData.tasks.forEach(function(x){ if (x.id === id) task = x; });
  if (!task) return;
  var done = aiDayDone();
  if (done.ids.indexOf(id) >= 0) return;
  done.ids.push(id);
  lsSet("tirada_ai_day_done", done);
  state.stats.aiXp = (state.stats.aiXp || 0) + (+task.xp || 0);
  saveStats(); renderStats();
  renderAiDay();
  toast(tf("Задание ИИ выполнено · +{xp} XP", { xp: +task.xp || 0 }));
  fireConfetti();
}
function loadAiDay(){
  var box = $("#aiDayBox"); if (!box) return;
  if (typeof db === "undefined" || !db){ box.hidden = true; return; }
  try {
    db.from("daily_drops").select("data").eq("day", aiDayKey())
      .then(function(res){
        if (res.error || !res.data || !res.data.length || !res.data[0].data){
          box.hidden = true; return;
        }
        aiDayData = res.data[0].data;
        renderAiDay();
      }, function(){ box.hidden = true; });
  } catch (e) { box.hidden = true; }
}

/* ================= Supabase cloud: auth, profile sync, presence, votes =================
   Real cloud accounts on top of the local ghost. Everything degrades
   gracefully: guests and offline keep the full local experience, and no
   network error ever breaks the UI. Fake people are never invented —
   the online counter and vote counts are real table reads. */
var db = window.TiradaDB || null;
var SUPA_CFG = window.TiradaSupaCfg || { url: "", key: "" };
var cloudUser = null, cloudSession = null, cloudSyncTimer = null,
    cloudHeartbeat = null, cloudVoteCounts = null, cloudBootedFor = null;
/* Favorites sync: true while this session has fav changes the cloud
   has not confirmed yet — applyRemoteProfile must not clobber them. */
var favsDirty = false;

function cloudStatsPayload(){
  return { nights: state.stats.nights, places: state.stats.places,
           routes: state.stats.routes, lastDealDay: state.stats.lastDealDay || "",
           photos: state.stats.photos || 0, tasks: state.stats.tasks || 0,
           questSteps: state.stats.questSteps || 0, quests: state.stats.quests || 0,
           votes: state.stats.votes || 0, streak: state.stats.streak || 0,
           bestStreak: state.stats.bestStreak || 0, aiXp: state.stats.aiXp || 0 };
}
/* Nicknames are unique case-insensitively in the DB (unique index on
   lower(name)). A clash surfaces as Postgres 23505 on the profile upsert —
   turn it into a plain, visible "nick is taken" message instead of a
   silent sync failure. */
function isNickTakenError(err){
  return !!err && (err.code === "23505" ||
    /duplicate key|unique constraint/i.test(err.message || ""));
}
var NICK_TAKEN_MSG = "Такой ник уже занят, придумай другой";
function cloudSyncNow(){
  if (!db || !cloudUser) return Promise.resolve();
  var payload = {
    id: cloudUser.id,
    name: state.nick || "Призрак",
    avatar: AVATARS[state.myAvatar % AVATARS.length].e,
    /* While the local photo wins (v26) state.avatarUrl is null, but
       the row must keep pointing at the cloud copy until the heal
       replaces it — echo the last stored URL instead of nulling the
       field the heal is about to repair. */
    avatar_url: state.avatarUrl || (localPhotoWins() ? lsGet("tirada_avatar_url", null) : null),
    mode: state.mode,
    city: state.city.id,
    stats: cloudStatsPayload(),
    favorites: Object.keys(state.favs)
  };
  return db.from("profiles").upsert(payload).then(function(res){
    if (res.error){
      console.warn("TiradA sync:", res.error.message);
      if (isNickTakenError(res.error)){
        showNickError(t(NICK_TAKEN_MSG));
        toast(t(NICK_TAKEN_MSG) + " 👻");
      }
    } else {
      favsDirty = false;
    }
  }, function(){});
}
function scheduleCloudSync(){
  if (!db || !cloudUser) return;
  if (cloudSyncTimer) clearTimeout(cloudSyncTimer);
  cloudSyncTimer = setTimeout(cloudSyncNow, 700);
}
function normalizeStats(s){
  var d = { nights: 0, places: [], routes: 0, lastDealDay: "", photos: 0,
            tasks: 0, questSteps: 0, quests: 0, votes: 0, streak: 0, bestStreak: 0, aiXp: 0 };
  if (!s) return d;
  return { nights: +s.nights || 0, places: Array.isArray(s.places) ? s.places : [],
           routes: +s.routes || 0, lastDealDay: s.lastDealDay || "", photos: +s.photos || 0,
           tasks: +s.tasks || 0, questSteps: +s.questSteps || 0, quests: +s.quests || 0,
           votes: +s.votes || 0, streak: +s.streak || 0, bestStreak: +s.bestStreak || 0,
           aiXp: +s.aiXp || 0 };
}
function applyCitySilent(id){
  state.city = cityById(id);
  state.filter = "all"; state.dealAlt = 0; state.routeRound = 0;
  state.routeSteps = null; state.search = "";
  $("#cityName").textContent = cityName(state.city);
  $("#routeCity").textContent = cityName(state.city);
  renderFilter(); renderPlaces(); updateCounter(); buildTicker(); buildRoute(); renderCityList();
  if (map && mapReady){
    clearRoute(); renderMapMarkers();
    map.jumpTo({ center: [state.city.lng, state.city.lat], zoom: 13 });
  }
}
/* v26 — THE avatar priority, one predicate for every seed and render
   (boot state, currentAvatarHtml, the avatar grid, applyRemoteProfile):
   this device's local photo wins exactly while the cloud has not
   confirmed it — i.e. its fingerprint differs from the one the last
   successful upload stamped into tirada_avatar_synced. Once synced,
   the local photo and the cloud copy are the same image and the cloud
   URL is the display source again (it is also the only source on
   devices that never picked a photo locally). */
function localPhotoWins(){
  return typeof state.avatarPhoto === "string" && !!state.avatarPhoto &&
    lsGet("tirada_avatar_synced", "") !== avatarPhotoHash(state.avatarPhoto);
}
/* The photo src the UI must show right now, per the priority above. */
function avatarDisplaySrc(){
  if (localPhotoWins()) return state.avatarPhoto;
  return state.avatarUrl || state.avatarPhoto || null;
}
/* Stable-enough fingerprint of the local photo dataURL: length plus a
   sampled FNV hash. Only ever compared for equality on this device —
   it answers "is THIS photo the one the cloud last confirmed?" */
function avatarPhotoHash(s){
  if (!s) return "";
  var h = 5381;
  for (var i = 0; i < s.length; i += 7) h = ((h * 33) ^ s.charCodeAt(i)) >>> 0;
  return s.length + ":" + h.toString(36);
}
var avatarHealStarted = false;
function healAvatarToCloud(){
  if (avatarHealStarted || !state.avatarPhoto) return;
  if (typeof db === "undefined" || !db || !cloudUser) return;
  avatarHealStarted = true;
  try {
    var bin = atob(String(state.avatarPhoto).split(",")[1] || "");
    var arr = new Uint8Array(bin.length);
    for (var i = 0; i < bin.length; i++) arr[i] = bin.charCodeAt(i);
    cloudUploadAvatar(new Blob([arr], { type: "image/jpeg" }), true);
  } catch (e) { avatarHealStarted = false; }
}
function applyRemoteProfile(row){
  if (!row) return;
  if (row.name){ state.nick = row.name; lsSet("tirada_nick", state.nick);
    var ni = $("#nickInput"); if (ni) ni.value = state.nick; }
  if (row.avatar){
    for (var i = 0; i < AVATARS.length; i++)
      if (AVATARS[i].e === row.avatar){ state.myAvatar = i; lsSet("tirada_avatar_idx", i); break; }
  }
  /* v24 — ONE truth for the avatar photo. This device's local photo is
     the copy the user picked and SAW at upload time; the cloud file is
     only its replica. The two could diverge (Yasha's bucket copy was
     baked rotated by a pre-v15 pipeline pass while his local copy is a
     different bake of the same photo), and the old code then silently
     swapped the displayed photo to the cloud bake the moment the
     profile landed — the "avatar blows out after opening the app from
     a push" report (2026-11-23). If the local photo was never
     confirmed synced to the cloud, it wins: keep showing it and
     re-upload it once (heal), so from then on cloud == local and the
     swap can never be visible again.
     v26 completes the rule: the priority now holds from the first
     frame (the boot seed is suppressed by the same predicate — see
     the state sanitising block), so there is no early cloud render
     left for this branch to swap away from. */
  if (localPhotoWins()){
    state.avatarUrl = null;
    /* The stored URL key is deliberately NOT cleared (v26): it is the
       last cloud URL this device knew, and cloudSyncNow echoes it back
       while the local photo wins, so a sync firing before the heal
       lands cannot wipe the cloud copy's URL from the profile row.
       The boot-time seed suppression makes the stale key harmless —
       it is never displayed while the local photo wins. */
    healAvatarToCloud();
  } else {
    state.avatarUrl = row.avatar_url || null;
    lsSet("tirada_avatar_url", state.avatarUrl);
  }
  if (row.stats){
    /* Monotonic merge: lifetime counters only ever grow, so take the max of
       cloud and local per counter (an older build's cloud stats must not
       wipe counters it never wrote) and union the opened-places list. */
    var rs = normalizeStats(row.stats), ls = state.stats;
    ["nights", "routes", "photos", "tasks", "questSteps", "quests", "votes", "streak", "bestStreak"].forEach(function(k){
      rs[k] = Math.max(rs[k] || 0, ls[k] || 0);
    });
    var seenP = {};
    rs.places.concat(ls.places || []).forEach(function(id){ seenP[id] = 1; });
    rs.places = Object.keys(seenP);
    state.stats = rs; saveStats();
  }
  if (Array.isArray(row.favorites)){
    if (favsDirty){
      /* This session has fav changes the cloud has not confirmed:
         union them with the cloud array (never lose a local toggle)
         and let the already-scheduled sync push the merged set back.
         Once a sync lands, the cloud array is the source of truth and
         replaces the local one — deletions included. */
      row.favorites.forEach(function(id){ state.favs[id] = 1; });
      lsSet("tirada_favs", state.favs);
      scheduleCloudSync();
    } else {
      state.favs = {};
      row.favorites.forEach(function(id){ state.favs[id] = 1; });
      lsSet("tirada_favs", state.favs);
    }
  }
  cloudProfileData = row.data || {};
  if (window.__pendingLangSave){ window.__pendingLangSave = false;
    /* Never throw here (v22): the city/mode application and the final
       renders below — and the rest of the signed-in chain — depend on
       this function completing. Guarded exactly like setLangChoice. */
    try { if (typeof cloudSaveLang === "function") cloudSaveLang(); } catch (e) {} }
  else if (row.data && row.data.lang){
    /* Cloud language applies only when THIS device has no explicit
       choice of its own (raw key absent — langChoiceGet() defaults to
       "auto", so the old "!LANG_CHOICE" test could never fire; and the
       old code called an undefined resolveLang() and repainted nothing,
       which would have left a mixed-language UI). Apply atomically:
       resolve, persist RAW (langChoiceGet reads the raw value, not
       lsSet's JSON), then repaint every surface via refreshI18n(). */
    var hasLocalChoice = false;
    try { hasLocalChoice = localStorage.getItem("tirada_lang_choice") !== null; } catch(e){}
    if (!hasLocalChoice){
      var rl = row.data.lang;
      LANG_CHOICE = (rl === "ru" || rl === "he" || rl === "en" || rl === "auto") ? rl : "auto";
      try { localStorage.setItem("tirada_lang_choice", LANG_CHOICE); } catch(e){}
      LANG = (LANG_CHOICE === "auto") ? navLang() : LANG_CHOICE;
      applyLang();
      if (typeof refreshI18n === "function") refreshI18n();
    }
  }
  if (row.city && row.city !== state.city.id && PLACES_BY_CITY[row.city]) applyCitySilent(row.city);
  if (row.mode && MODES[row.mode] && row.mode !== state.mode) setMode(row.mode);
  renderMyAvatar(); renderStats(); renderPlaces();
}

/* ---- Presence: honest online flag + heartbeat ---- */
function cloudPresence(on){
  if (!db || !cloudUser) return Promise.resolve();
  return db.from("profiles").update({ online: on, last_seen: new Date().toISOString() })
    .eq("id", cloudUser.id).then(function(){}, function(){});
}
/* ---- My coordinates → profile_locations (its own locked-down table):
   RLS there lets only me and my ACCEPTED friends read my row, so nobody
   else can harvest coordinates. The profiles table no longer carries
   lat/lng at all — neither the main profile upsert nor any read touches
   them. Throttle: pushed on the presence heartbeat, on sign-in and
   whenever the watch reports a move over ~50 m — and never more often
   than once per 30 s. Only REAL geolocation is shared (state.geo), never
   the demo fallback position. ---- */
var geoPushed = null, geoPushAt = 0, geoPushBusy = false;
function cloudGeoSync(){
  if (!db || !cloudUser || !state.geo || geoPushBusy) return;
  var now = Date.now();
  if (geoPushed && now - geoPushAt < 30000 && distKm(geoPushed, state.geo) < 0.05) return;
  geoPushBusy = true;
  var pt = { lat: state.geo.lat, lng: state.geo.lng };
  db.from("profile_locations").upsert({
      user_id: cloudUser.id, lat: pt.lat, lng: pt.lng,
      updated_at: new Date().toISOString()
    }, { onConflict: "user_id" })
    .then(function(res){
      geoPushBusy = false;
      if (!res.error){ geoPushed = pt; geoPushAt = Date.now(); }
    }, function(){ geoPushBusy = false; });
}
/* Coordinates of other ghosts, read from profile_locations. RLS returns
   rows only for accepted friends (and my own), so a plain id filter is
   enough — strangers' rows simply never come back. Returns {id:{lat,lng}}. */
function fetchFriendLocations(ids){
  if (!db || !ids || !ids.length) return Promise.resolve({});
  return db.from("profile_locations").select("user_id,lat,lng,updated_at").in("user_id", ids)
    .then(function(res){
      var out = {};
      if (!res.error && res.data) res.data.forEach(function(r){
        if (typeof r.lat === "number" && typeof r.lng === "number"){
          var t = Date.parse(r.updated_at);
          out[r.user_id] = { lat: r.lat, lng: r.lng, t: isNaN(t) ? Date.now() : t };
        }
      });
      return out;
    }, function(){ return {}; });
}
function cloudPresenceBeaconOff(){
  if (!cloudUser || !cloudSession) return;
  try {
    fetch(SUPA_CFG.url + "/rest/v1/profiles?id=eq." + encodeURIComponent(cloudUser.id), {
      method: "PATCH", keepalive: true,
      headers: { "apikey": SUPA_CFG.key, "Authorization": "Bearer " + cloudSession.access_token,
                 "Content-Type": "application/json", "Prefer": "return=minimal" },
      body: JSON.stringify({ online: false, last_seen: new Date().toISOString() })
    });
  } catch(e){}
}
function startHeartbeat(){
  stopHeartbeat();
  cloudHeartbeat = setInterval(function(){ cloudPresence(true); cloudGeoSync(); }, 30000);
}
function stopHeartbeat(){
  if (cloudHeartbeat){ clearInterval(cloudHeartbeat); cloudHeartbeat = null; }
}
window.addEventListener("beforeunload", cloudPresenceBeaconOff);
window.addEventListener("pagehide", cloudPresenceBeaconOff);
document.addEventListener("visibilitychange", function(){
  if (document.visibilityState === "visible") cloudPresence(true);
});
function refreshOnlineLine(){
  var el = $("#dealOnline");
  if (!el) return;
  if (!db || !cloudUser){ el.textContent = t("🔒 Кто сейчас в сети — видно после входа"); return; }
  el.textContent = t("Смотрю, кто в сети…");
  db.from("profiles").select("id", { count: "exact", head: true }).eq("online", true)
    .then(function(res){
      var el2 = $("#dealOnline"); if (!el2) return;
      if (res.error || typeof res.count !== "number"){ el2.textContent = t("Сейчас в сети: не удалось посчитать"); return; }
      el2.innerHTML = '<span class="online-dot"></span>' + tf("Сейчас в сети: <b>{n}</b>", { n: res.count });
    }, function(){ var el3 = $("#dealOnline"); if (el3) el3.textContent = t("Сейчас в сети: нет связи"); });
}

/* ---- Photo avatar → Storage bucket 'avatars' ---- */
function cloudUploadAvatar(blob, quiet){
  if (!db || !cloudUser || !blob) return;
  var path = cloudUser.id + "/avatar.jpg";
  db.storage.from("avatars").upload(path, blob, { upsert: true, contentType: "image/jpeg" })
    .then(function(res){
      if (res.error){ console.warn("TiradA avatar upload:", res.error.message); if (!quiet) toast(t("Фото не уехало в облако — останется на устройстве")); return; }
      var pub = db.storage.from("avatars").getPublicUrl(path);
      state.avatarUrl = pub.data.publicUrl + "?v=" + Date.now();
      lsSet("tirada_avatar_url", state.avatarUrl);
      /* The cloud now holds THIS device’s photo: mark it synced, so
         applyRemoteProfile never treats it as a divergent copy again. */
      if (state.avatarPhoto) lsSet("tirada_avatar_synced", avatarPhotoHash(state.avatarPhoto));
      renderMyAvatar(); renderAvatarGrid();
      cloudSyncNow();
      if (!quiet) toast(t("Фото-аватарка в облаке ☁️ Теперь она на всех устройствах"));
    }, function(){ if (!quiet) toast(t("Фото не уехало в облако — останется на устройстве")); });
}

/* ================= Place photos: camera proof, check-ins, galleries =================
   Photos are born in exactly three flows: the daily task, a weekly-quest
   step and the «Я здесь» check-in in a place sheet. The daily task and
   quest steps count ONLY with a photo; that photo is a proof and is never
   uploaded or published (those tasks have no place). A check-in photo may
   be published to the place gallery — only after the consent sheet:
   «Всем» (public), «Только друзьям» (friends) or «Не показывать» (nothing
   is uploaded). Photos are camera-only (capture="environment") and are
   re-encoded through canvas before upload (max 1280 px, JPEG 0.85), which
   also strips EXIF/geotags. Gallery signature is the author's ghost
   (avatar + «Призрак #N»), never the nick. */
var photoFlow = null;      /* { place, onDone } while the camera is open */
var consentFlow = null;    /* { place, onDone, blob, _url } in the consent sheet */
var galleryState = {};     /* placeId -> { photos, profiles, fires, mine } */
var viewerCtx = null;      /* { placeId, photo } */
var photoReported = lsGet("tirada_reported_photos", []);

function startPhotoFlow(place, onDone){
  if (!db || !cloudUser){
    toast(t("Войди, чтобы выполнять задания с фото и делать чек-ины 📸"));
    return;
  }
  var inp = $("#photoCamInput");
  if (!inp){ toast(t("Камера недоступна на этом устройстве")); return; }
  photoFlow = { place: place || null, onDone: onDone || function(){} };
  inp.value = "";
  inp.click();
}
function reencodePhoto(file){
  /* Same EXIF-orientation-safe decode as the avatar pipeline: gallery
     photos used to come out rotated for the same reason. */
  return loadOrientedSource(file).then(function(o){
    var max = 1280, w = o.w || 1, h = o.h || 1;
    var sc = Math.min(1, max / Math.max(w, h));
    var c = document.createElement("canvas");
    c.width = Math.max(1, Math.round(w * sc));
    c.height = Math.max(1, Math.round(h * sc));
    c.getContext("2d").drawImage(o.src, 0, 0, c.width, c.height);
    o.close();
    return new Promise(function(resolve, reject){
      if (c.toBlob) c.toBlob(function(b){ b ? resolve(b) : reject(new Error("encode")); }, "image/jpeg", 0.85);
      else reject(new Error("toBlob"));
    });
  });
}
var photoCamInp = $("#photoCamInput");
if (photoCamInp) photoCamInp.addEventListener("change", function(){
  var f = photoCamInp.files && photoCamInp.files[0];
  var flow = photoFlow; photoFlow = null;
  if (!flow) return;
  if (!f) return; /* camera cancelled — nothing counts, nothing breaks */
  reencodePhoto(f).then(function(blob){
    if (flow.place){
      flow.blob = blob;
      openPhotoConsent(flow);
    } else {
      flow.onDone(); /* proof-only photo: confirms, never uploaded */
    }
  }, function(){ toast(t("Не получилось прочитать фото — попробуй ещё раз 📸")); });
});

/* ---- Consent sheet ---- */
function openPhotoConsent(flow){
  consentFlow = flow;
  if (flow._url) URL.revokeObjectURL(flow._url);
  flow._url = URL.createObjectURL(flow.blob);
  $("#photoConsentImg").src = flow._url;
  $("#photoConsentText").textContent = tf("Фото у места «{place}». Показать его на странице места? Подпись — только твой призрак и его номер, без ника.", { place: flow.place.name });
  $("#photoConsent").hidden = false;
}
function finishConsent(vis){
  var flow = consentFlow; consentFlow = null;
  $("#photoConsent").hidden = true;
  if (flow && flow._url){ URL.revokeObjectURL(flow._url); flow._url = null; }
  if (!flow) return;
  if (vis === "none"){ flow.onDone(); return; }
  publishPhoto(flow.blob, flow.place, vis).then(function(ok){
    if (ok){
      state.stats.photos = (state.stats.photos || 0) + 1;
      saveStats(); renderStats(); loadMyPhotos();
      toast(t("Фото уже на странице места 📸"));
      if (currentSheetPlaceId === flow.place.id) loadPlaceGallery(flow.place.id);
    }
    flow.onDone();
  });
}
var pcClose = $("#photoConsentClose"), pcAll = $("#photoPubAll"),
    pcFriends = $("#photoPubFriends"), pcNone = $("#photoPubNone"),
    pcSheet = $("#photoConsent");
if (pcClose) pcClose.addEventListener("click", function(){ finishConsent("none"); });
if (pcAll) pcAll.addEventListener("click", function(){ finishConsent("public"); });
if (pcFriends) pcFriends.addEventListener("click", function(){ finishConsent("friends"); });
if (pcNone) pcNone.addEventListener("click", function(){ finishConsent("none"); });
if (pcSheet) pcSheet.addEventListener("click", function(e){ if (e.target === this) finishConsent("none"); });

function publishPhoto(blob, place, vis){
  if (!db || !cloudUser || !blob || !place) return Promise.resolve(false);
  var path = cloudUser.id + "/" + Date.now() + ".jpg";
  return db.storage.from("place-photos").upload(path, blob, { contentType: "image/jpeg" })
    .then(function(res){
      if (res.error){
        console.warn("TiradA photo upload:", res.error.message);
        toast(t("Фото не загрузилось в облако — чек-ин всё равно засчитан"));
        return false;
      }
      var url = db.storage.from("place-photos").getPublicUrl(path).data.publicUrl;
      var row = { place_id: place.id, place_name: place.name, user_id: cloudUser.id, url: url, visibility: vis };
      var afterInsert = function(r2){
        if (r2.error){
          console.warn("TiradA photo insert:", r2.error.message);
          toast(t("Фото не опубликовалось — чек-ин всё равно засчитан"));
          return false;
        }
        refreshCityPhotoCount();
        return true;
      };
      return db.from("place_photos").insert(row).then(function(r2){
        if (r2.error && /place_name/.test(r2.error.message || "")){
          /* place_name arrives with the parent's SQL — until then
             publish the old way instead of losing the photo. */
          delete row.place_name;
          return db.from("place_photos").insert(row).then(afterInsert, function(){ return false; });
        }
        return afterInsert(r2);
      }, function(){ return false; });
    }, function(){ toast(t("Фото не загрузилось в облако — чек-ин всё равно засчитан")); return false; });
}

/* ---- Place gallery ---- */
function acceptedFriendIds(){
  var out = {};
  if (!cloudUser) return out;
  friendsRows.forEach(function(r){
    if (r.status === "accepted")
      out[(r.requester === cloudUser.id) ? r.addressee : r.requester] = 1;
  });
  return out;
}
function loadPlaceGallery(placeId){
  var grid = $("#psPhotosGrid");
  if (!grid || !db) return;
  var myFriends = acceptedFriendIds();
  /* A photo with reports >= 3 is treated as hidden by the app itself:
     the backend RLS lets any signed-in user increment reports, but the
     resulting row may not flip hidden=true — so the gallery filters on
     both flags and such a photo is shown nowhere. */
  db.from("place_photos").select("id,place_id,user_id,url,visibility,reports,created_at")
    .eq("place_id", placeId).eq("hidden", false).lt("reports", 3)
    .order("created_at", { ascending: false }).limit(60)
    .then(function(res){
      if (placeId !== currentSheetPlaceId) return;
      var g2 = $("#psPhotosGrid"); if (!g2) return;
      if (res.error){ g2.innerHTML = '<div class="friend-empty">' + t("Фото пока недоступны") + '</div>'; return; }
      var rows = (res.data || []).filter(function(ph){
        if ((ph.reports || 0) >= 3 || ph.hidden) return false;
        if (ph.visibility === "public") return true;
        if (!cloudUser) return false;
        return ph.user_id === cloudUser.id || !!myFriends[ph.user_id];
      });
      if (!rows.length){
        g2.innerHTML = '<div class="friend-empty"><div class="empty-art">📸</div><div class="empty-title">' + t("Здесь пока тихо") + '</div><div class="empty-text">' + t("Стань первым призраком: жми «Я здесь» — и покажи это место своим фото.") + '</div></div>';
        return;
      }
      var st = { photos: rows, profiles: {}, fires: {}, mine: {} };
      galleryState[placeId] = st;
      g2.innerHTML = rows.map(function(ph){
        return '<button class="ps-photo-thumb" data-photo="' + ph.id + '"><img src="' + escHtml(ph.url) + '" alt="' + t("Фото призрака с места") + '" loading="lazy"></button>';
      }).join("");
      g2.querySelectorAll("[data-photo]").forEach(function(b){
        b.addEventListener("click", function(){ openPhotoViewer(placeId, b.getAttribute("data-photo")); });
      });
      var ids = rows.map(function(ph){ return ph.id; });
      db.from("photo_reactions").select("photo_id,user_id").in("photo_id", ids)
        .then(function(rr){
          if (!rr.error && rr.data) rr.data.forEach(function(r){
            st.fires[r.photo_id] = (st.fires[r.photo_id] || 0) + 1;
            if (cloudUser && r.user_id === cloudUser.id) st.mine[r.photo_id] = 1;
          });
        }, function(){});
      if (cloudUser){
        var aids = {};
        rows.forEach(function(ph){ aids[ph.user_id] = 1; });
        db.from("profiles").select("id,avatar,avatar_url").in("id", Object.keys(aids))
          .then(function(pr){
            if (!pr.error && pr.data) pr.data.forEach(function(p){ st.profiles[p.id] = p; });
          }, function(){});
      }
    }, function(){
      if (placeId !== currentSheetPlaceId) return;
      var g3 = $("#psPhotosGrid");
      if (g3) g3.innerHTML = '<div class="friend-empty">' + t("Фото пока недоступны") + '</div>';
    });
}

/* ---- Full-screen viewer: ghost signature, 🔥 reactions, reports ---- */
function fmtAgo(iso){
  var t = new Date(iso).getTime();
  if (!t) return "";
  var m = Math.max(1, Math.round((Date.now() - t) / 60000));
  if (m < 60) return tf("{n} {w} назад", { n: m, w: pl(m, "minute") });
  var h = Math.round(m / 60);
  if (h < 24) return tf("{n} {w} назад", { n: h, w: pl(h, "hour") });
  var d = Math.round(h / 24);
  return tf("{n} {w} назад", { n: d, w: pl(d, "day") });
}
function openPhotoViewer(placeId, photoId){
  var st = galleryState[placeId]; if (!st) return;
  var ph = null;
  st.photos.forEach(function(x){ if (x.id === photoId) ph = x; });
  if (!ph) return;
  viewerCtx = { placeId: placeId, photo: ph };
  $("#photoViewerImg").src = ph.url;
  var prof = st.profiles[ph.user_id];
  $("#photoViewerAuthor").innerHTML =
    '<span class="friend-ava pv-ava">' + (prof ? friendAvatarHtml(prof) : avatarFace(0)) + "</span>" +
    "<span>" + tf("Призрак #{n}", { n: ghostNumberFor(ph.user_id) }) + "</span>";
  $("#photoViewerTime").textContent = fmtAgo(ph.created_at);
  paintFireBtn();
  $("#photoViewer").hidden = false;
}
function closePhotoViewer(){ $("#photoViewer").hidden = true; viewerCtx = null; }
function paintFireBtn(){
  if (!viewerCtx) return;
  var st = galleryState[viewerCtx.placeId] || { fires: {}, mine: {} };
  $("#photoFireCount").textContent = st.fires[viewerCtx.photo.id] || 0;
  $("#photoFireBtn").classList.toggle("active", !!st.mine[viewerCtx.photo.id]);
}
var pvClose = $("#photoViewerClose"), pvFire = $("#photoFireBtn"),
    pvReport = $("#photoReportBtn"), pvBox = $("#photoViewer");
if (pvClose) pvClose.addEventListener("click", closePhotoViewer);
if (pvBox) pvBox.addEventListener("click", function(e){ if (e.target === this) closePhotoViewer(); });
if (pvFire) pvFire.addEventListener("click", function(){
  if (!viewerCtx) return;
  if (!db || !cloudUser){ toast(t("Войди, чтобы ставить 🔥")); return; }
  var st = galleryState[viewerCtx.placeId]; if (!st) return;
  var ph = viewerCtx.photo, has = !!st.mine[ph.id];
  var done = function(ok){
    if (!ok){ toast(t("Не получилось — попробуй ещё раз")); return; }
    if (has){ st.mine[ph.id] = 0; st.fires[ph.id] = Math.max(0, (st.fires[ph.id] || 1) - 1); }
    else { st.mine[ph.id] = 1; st.fires[ph.id] = (st.fires[ph.id] || 0) + 1; }
    paintFireBtn();
  };
  if (has)
    db.from("photo_reactions").delete().eq("photo_id", ph.id).eq("user_id", cloudUser.id)
      .then(function(r){ done(!r.error); }, function(){ done(false); });
  else
    db.from("photo_reactions").insert({ photo_id: ph.id, user_id: cloudUser.id })
      .then(function(r){ done(!r.error); }, function(){ done(false); });
});
if (pvReport) pvReport.addEventListener("click", function(){
  if (!viewerCtx) return;
  if (!db || !cloudUser){ toast(t("Войди, чтобы отправить жалобу")); return; }
  var ph = viewerCtx.photo;
  if (photoReported.indexOf(ph.id) >= 0){ toast(t("Ты уже жаловался на это фото 🚩")); return; }
  db.from("place_photos").select("reports").eq("id", ph.id).maybeSingle()
    .then(function(res){
      var nv = ((res.data && res.data.reports) || ph.reports || 0) + 1;
      db.from("place_photos").update({ reports: nv }).eq("id", ph.id).then(function(r2){
        if (r2.error){ toast(t("Не получилось отправить жалобу")); return; }
        photoReported.push(ph.id);
        lsSet("tirada_reported_photos", photoReported);
        if (nv >= 3){
          /* Best effort: flip the hidden flag too. Current RLS may reject
             it (the new row would violate the update policy) — that is
             fine, the app already treats reports >= 3 as hidden. */
          db.from("place_photos").update({ hidden: true }).eq("id", ph.id)
            .then(function(){}, function(){});
          toast(t("Фото скрыто после жалоб 🚩"));
          closePhotoViewer();
          loadPlaceGallery(ph.place_id);
        } else toast(t("Жалоба отправлена 🚩"));
      }, function(){ toast(t("Не получилось отправить жалобу")); });
    }, function(){ toast(t("Не получилось отправить жалобу")); });
});

/* ---- My photos (profile) ---- */
function loadMyPhotos(){
  var g = $("#myPhotosGuest"), u = $("#myPhotosUser"), list = $("#myPhotosList");
  if (!g || !u || !list) return;
  if (!db || !cloudUser){ g.hidden = false; u.hidden = true; return; }
  g.hidden = true; u.hidden = false;
  db.from("place_photos").select("id,place_id,url,visibility,created_at,reports,hidden")
    .eq("user_id", cloudUser.id)
    .order("created_at", { ascending: false }).limit(60)
    .then(function(res){
      if (res.error){ list.innerHTML = '<div class="friend-empty">' + t("Фото пока недоступны") + '</div>'; return; }
      var rows = res.data || [];
      if (!rows.length){
        list.innerHTML = '<div class="friend-empty"><div class="empty-art">📸</div><div class="empty-title">' + t("У тебя пока нет фото") + '</div><div class="empty-text">' + t("Открой место и жми «Я здесь» — твоё фото появится на его странице и здесь.") + '</div></div>';
        return;
      }
      list.innerHTML = rows.map(function(ph){
        var fp = findPlace(ph.place_id);
        return '<div class="my-photo-row">' +
          '<img class="my-photo-thumb" src="' + escHtml(ph.url) + '" alt="' + t("Моё фото с места") + '">' +
          '<span class="my-photo-info"><span class="my-photo-place">' + escHtml(fp ? fp.place.name : t("Место")) + '</span>' +
          '<span class="my-photo-meta">' + (ph.visibility === "friends" ? t("👻 только друзьям") : t("🌍 видят все")) + " · " + fmtAgo(ph.created_at) + ((ph.hidden || (ph.reports || 0) >= 3) ? t(" · 🚩 скрыто после жалоб") : "") + '</span></span>' +
          '<button class="friend-btn danger" data-mydel="' + ph.id + '" data-url="' + escHtml(ph.url) + '">' + t("Удалить") + "</button></div>";
      }).join("");
      list.querySelectorAll("[data-mydel]").forEach(function(b){
        b.addEventListener("click", function(){ deleteMyPhoto(b.getAttribute("data-mydel"), b.getAttribute("data-url")); });
      });
    }, function(){ list.innerHTML = '<div class="friend-empty">' + t("Фото пока недоступны") + '</div>'; });
}
function deleteMyPhoto(id, url){
  if (!db || !cloudUser) return;
  db.from("place_photos").delete().eq("id", id).eq("user_id", cloudUser.id)
    .then(function(res){
      if (res.error){ toast(t("Не получилось удалить фото")); return; }
      var marker = "/place-photos/", i = (url || "").indexOf(marker);
      if (i >= 0){
        var path = decodeURIComponent(url.slice(i + marker.length).split("?")[0]);
        db.storage.from("place-photos").remove([path]).then(function(){}, function(){});
      }
      toast(t("Фото удалено"));
      loadMyPhotos();
    }, function(){ toast(t("Не получилось удалить фото")); });
}
var myPhotosLoginBtn = $("#myPhotosLoginBtn");
if (myPhotosLoginBtn) myPhotosLoginBtn.addEventListener("click", function(){ $("#loginModal").hidden = false; });

/* ---- Voting: shared counts from the votes table ---- */
function gatheringKey(){
  var d = new Date();
  return "deal-" + d.getFullYear() + "-" + ("0" + (d.getMonth() + 1)).slice(-2) + "-" + ("0" + d.getDate()).slice(-2);
}
function cloudCastVote(placeId){
  if (!db || !cloudUser) return;
  db.from("votes").upsert(
    { gathering: gatheringKey(), place_id: placeId, user_id: cloudUser.id },
    { onConflict: "gathering,user_id" }
  ).then(function(res){ if (!res.error) refreshVoteCounts(); }, function(){});
}
function refreshVoteCounts(){
  if (!db || !cloudUser) return;
  db.from("votes").select("place_id").eq("gathering", gatheringKey()).then(function(res){
    if (res.error || !res.data) return;
    var counts = {};
    res.data.forEach(function(r){ counts[r.place_id] = (counts[r.place_id] || 0) + 1; });
    cloudVoteCounts = counts;
    $$("#dealBody [data-vcount]").forEach(function(el){
      el.textContent = counts[el.getAttribute("data-vcount")] || 0;
    });
  }, function(){});
}
function cloudLoadMyVote(){
  if (!db || !cloudUser) return Promise.resolve();
  return db.from("votes").select("place_id").eq("gathering", gatheringKey())
    .eq("user_id", cloudUser.id).maybeSingle().then(function(res){
      if (res.data && res.data.place_id){
        state.vote = { cityId: state.city.id, placeId: res.data.place_id };
        lsSet("tirada_vote", state.vote);
      }
    }, function(){});
}

/* ---- Friends: real friendships table (search, requests, accept, list) ----
   Rows live in public.friendships (requester/addressee/status). Profiles of
   the other side are read from public.profiles for avatar, nick, city and
   the online flag. "В деле" for a friend = the same presence signal the app
   already uses for everyone: profiles.online (heartbeat while signed in). */
var friendsRows = [], friendsProfiles = {}, friendSearchResults = [],
    friendsLoaded = false, friendsLoading = false;
/* Friends-at-places state (filled by computeFriendsAtPlaces):
   friendsAtPlace: placeId -> [{id, name}]; friendsPlaceOf: friendId ->
   {place, cityId, cityName}; friendsPlacesSig dedupes re-renders. */
var friendsAtPlace = {}, friendsPlaceOf = {}, friendsPlacesSig = "";

function escHtml(s){
  return String(s == null ? "" : s).replace(/[&<>"']/g, function(c){
    return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
  });
}
function friendAvatarHtml(p){
  if (p && p.avatar_url) return '<img class="avphoto" src="' + escHtml(p.avatar_url) + '" alt="">';
  var idx = 0;
  if (p && p.avatar){
    for (var i = 0; i < AVATARS.length; i++)
      if (AVATARS[i].e === p.avatar){ idx = i; break; }
  }
  return avatarFace(idx);
}
function friendCityName(p){
  if (p && p.city && PLACES_BY_CITY[p.city]) return cityName(cityById(p.city));
  return t("город не указан");
}
function friendMetaHtml(p){
  var on = !!(p && p.online);
  var html = '<span class="' + (on ? "friend-on" : "friend-off") + '">' +
    (on ? t("🟢 в сети") : t("⚪ не в сети")) + "</span> · " + escHtml(friendCityName(p));
  var spd = friendSpeedText(p);
  if (spd) html += ' · <span class="friend-speed">' + spd + "</span>";
  return html;
}
function friendRowHtml(p, actionsHtml){
  return '<div class="friend-row">' +
    '<span class="friend-ava">' + friendAvatarHtml(p) + '</span>' +
    '<span class="friend-info"><span class="friend-name">' + escHtml((p && p.name) || t("Призрак")) + '</span>' +
    '<span class="friend-meta">' + friendMetaHtml(p) + '</span></span>' +
    '<span class="friend-actions">' + actionsHtml + "</span></div>";
}
function friendRelation(otherId){
  if (!cloudUser) return null;
  for (var i = 0; i < friendsRows.length; i++){
    var r = friendsRows[i];
    if (r.requester !== otherId && r.addressee !== otherId) continue;
    if (r.status === "accepted") return { row: r, kind: "friend" };
    if (r.requester === cloudUser.id && r.addressee === otherId) return { row: r, kind: "out" };
    if (r.addressee === cloudUser.id && r.requester === otherId) return { row: r, kind: "in" };
  }
  return null;
}
function friendsLoad(){
  if (!db || !cloudUser){ renderFriends(); return Promise.resolve(); }
  if (friendsLoading) return Promise.resolve();
  friendsLoading = true;
  return db.from("friendships").select("*")
    .or("requester.eq." + cloudUser.id + ",addressee.eq." + cloudUser.id)
    .order("created_at", { ascending: false })
    .then(function(res){
      friendsLoading = false;
      if (res.error){ console.warn("TiradA friends:", res.error.message); renderFriends(); return; }
      friendsRows = res.data || [];
      var ids = {};
      friendsRows.forEach(function(r){
        ids[(r.requester === cloudUser.id) ? r.addressee : r.requester] = 1;
      });
      var list = Object.keys(ids);
      if (!list.length){
        friendsProfiles = {}; friendsLoaded = true;
        renderFriends(); renderFriendResults(); renderDealFriends();
        updateFriendsAtPlaces();
        return;
      }
      var doneLoad = function(pr){
        if (pr && !pr.error && pr.data) pr.data.forEach(function(p){ friendsProfiles[p.id] = p; });
        /* coordinates live in profile_locations now (accepted friends only) */
        return fetchFriendLocations(list).then(function(locs){
          trackSpeedsFromLocs(locs);
          Object.keys(locs).forEach(function(id){
            if (friendsProfiles[id]){ friendsProfiles[id].lat = locs[id].lat; friendsProfiles[id].lng = locs[id].lng; }
          });
          friendsLoaded = true; renderFriends(); renderFriendResults(); renderDealFriends();
          updateFriendsAtPlaces();
        });
      };
      return db.from("profiles").select("id,name,avatar,avatar_url,city,online,last_seen,mode,stats").in("id", list)
        .then(doneLoad, doneLoad);
    }, function(){ friendsLoading = false; renderFriends(); });
}
function bindFriendButtons(root){
  if (!root) return;
  root.querySelectorAll("[data-fadd]").forEach(function(b){
    b.addEventListener("click", function(){ friendsSend(b.getAttribute("data-fadd")); });
  });
  root.querySelectorAll("[data-faccept]").forEach(function(b){
    b.addEventListener("click", function(){ friendsAccept(b.getAttribute("data-faccept")); });
  });
  root.querySelectorAll("[data-fdecline]").forEach(function(b){
    b.addEventListener("click", function(){ friendsDelete(b.getAttribute("data-fdecline"), t("Заявка убрана")); });
  });
  root.querySelectorAll("[data-fremove]").forEach(function(b){
    b.addEventListener("click", function(){ friendsDelete(b.getAttribute("data-fremove"), t("Друг удалён")); });
  });
}
/* ---- Friends leaderboard (wave 3): you + accepted friends by XP ----
   Friend XP is computed from their cloud profiles.stats with the same
   xpOfStats() formula — nobody is invented, a friend without stats is 0. */
function renderLeaderboard(){
  var box = $("#leaderboardBox"), list = $("#leaderboardList");
  if (!box || !list) return;
  if (!cloudUser){ box.hidden = true; return; }
  var rows = [{ id: cloudUser.id, name: state.nick || t("Призрак"), me: true,
                avatarHtml: currentAvatarHtml(), stats: state.stats }];
  if (friendsLoaded){
    friendsRows.forEach(function(r){
      if (r.status !== "accepted") return;
      var oid = (r.requester === cloudUser.id) ? r.addressee : r.requester;
      var p = friendsProfiles[oid];
      if (p) rows.push({ id: oid, name: p.name || t("Призрак"), me: false,
                         avatarHtml: friendAvatarHtml(p), stats: p.stats });
    });
  }
  rows.forEach(function(r){ r.xp = xpOfStats(r.stats); r.lv = levelOf(r.xp); });
  rows.sort(function(a, b){ return b.xp - a.xp; });
  box.hidden = false;
  list.innerHTML = rows.map(function(r, i){
    return '<div class="lb-row' + (r.me ? " me" : "") + '">' +
      '<span class="lb-rank">' + (i + 1) + "</span>" +
      '<span class="friend-ava">' + r.avatarHtml + "</span>" +
      '<span class="friend-info"><span class="friend-name">' + escHtml(r.name) + (r.me ? t(" (ты)") : "") + "</span>" +
      '<span class="friend-meta">' + t("Уровень") + " " + r.lv.num + " · " + r.lv.name + "</span></span>" +
      '<span class="lb-xp">' + r.xp + " XP</span></div>";
  }).join("") + (rows.length < 2
    ? '<div class="friend-empty">' + t("Добавь друзей — и соревнуйтесь, кто больше в движе 🏆") + '</div>' : "");
}
/* ---- Incoming-request badge: profile tab + friends header ---- */
function pendingRequestsCount(){
  if (!cloudUser || !friendsLoaded) return 0;
  var n = 0;
  friendsRows.forEach(function(r){
    if (r.status === "pending" && r.addressee === cloudUser.id) n++;
  });
  return n;
}
function updateReqBadges(){
  var n = pendingRequestsCount();
  var t = $("#tabReqBadge"); if (t){ t.hidden = n === 0; t.textContent = n; }
  var f = $("#friendsReqBadge"); if (f){ f.hidden = n === 0; f.textContent = n; }
}
function renderFriends(){
  var g = $("#friendsGuest"), u = $("#friendsUser");
  if (!g || !u) return;
  updateReqBadges(); renderLeaderboard();
  if (!db || !cloudUser){ g.hidden = false; u.hidden = true; return; }
  g.hidden = true; u.hidden = false;
  var box = $("#friendSections");
  if (!box) return;
  if (!friendsLoaded){
    box.innerHTML = '<div class="skel-row"><span class="skel skel-ava"></span><span class="skel-lines"><span class="skel skel-line w60"></span><span class="skel skel-line w40"></span></span></div>' +
      '<div class="skel-row"><span class="skel skel-ava"></span><span class="skel-lines"><span class="skel skel-line w50"></span><span class="skel skel-line w35"></span></span></div>';
    return;
  }
  var inc = [], out = [], mine = [];
  friendsRows.forEach(function(r){
    var otherId = (r.requester === cloudUser.id) ? r.addressee : r.requester;
    var p = friendsProfiles[otherId] || { id: otherId, name: t("Призрак") };
    if (r.status === "accepted") mine.push({ row: r, p: p });
    else if (r.addressee === cloudUser.id) inc.push({ row: r, p: p });
    else out.push({ row: r, p: p });
  });
  var html = "";
  if (inc.length){
    html += '<div class="friend-sec-title">' + tf("Заявки тебе · {n}", { n: inc.length }) + "</div>" + inc.map(function(x){
      return friendRowHtml(x.p,
        '<button class="friend-btn ok" data-faccept="' + x.row.id + '">' + t("Принять") + '</button>' +
        '<button class="friend-btn" data-fdecline="' + x.row.id + '">' + t("Отклонить") + '</button>');
    }).join("");
  }
  html += '<div class="friend-sec-title">' + tf("Мои друзья · {n}", { n: mine.length }) + "</div>";
  html += mine.length ? mine.map(function(x){
    return friendRowHtml(x.p, '<button class="friend-btn danger" data-fremove="' + x.row.id + '">' + t("Удалить") + '</button>');
  }).join("") : '<div class="friend-empty"><div class="empty-art">👻</div><div class="empty-title">' + t("Пока ни одного друга") + '</div><div class="empty-text">' + t("Найди призрака по нику выше — и зови в друзья. Вместе движ виден лучше.") + '</div></div>';
  if (out.length){
    html += '<div class="friend-sec-title">' + tf("Ты позвал · {n}", { n: out.length }) + "</div>" + out.map(function(x){
      return friendRowHtml(x.p,
        '<span class="friend-wait">' + t("ждёт ответа…") + '</span>' +
        '<button class="friend-btn" data-fdecline="' + x.row.id + '">' + t("Отменить") + '</button>');
    }).join("");
  }
  box.innerHTML = html;
  bindFriendButtons(box);
}
function renderFriendResults(){
  var box = $("#friendResults");
  if (!box) return;
  if (!friendSearchResults.length){ box.innerHTML = ""; return; }
  box.innerHTML = '<div class="friend-sec-title">' + t("Нашлись") + '</div>' + friendSearchResults.map(function(p){
    var rel = friendRelation(p.id), act;
    if (!rel) act = '<button class="friend-btn ok" data-fadd="' + p.id + '">' + t("Добавить") + '</button>';
    else if (rel.kind === "friend") act = '<span class="friend-wait">' + t("вы друзья") + '</span>';
    else if (rel.kind === "out") act = '<span class="friend-wait">' + t("заявка отправлена") + '</span>';
    else act = '<button class="friend-btn ok" data-faccept="' + rel.row.id + '">' + t("Принять заявку") + '</button>';
    return friendRowHtml(p, act);
  }).join("");
  bindFriendButtons(box);
}
function friendsSearch(){
  if (!db || !cloudUser) return;
  var inp = $("#friendSearch");
  var q = ((inp && inp.value) || "").trim();
  if (q.length < 2){ toast(t("Введи хотя бы 2 символа ника")); return; }
  var pat = "%" + q.replace(/[%_\\]/g, "\\$&") + "%";
  var btn = $("#friendSearchBtn");
  if (btn) btn.disabled = true;
  db.from("profiles").select("id,name,avatar,avatar_url,city,online").ilike("name", pat).limit(20)
    .then(function(res){
      if (btn) btn.disabled = false;
      if (res.error){ toast(t("Поиск не сработал — попробуй ещё раз")); return; }
      friendSearchResults = (res.data || []).filter(function(p){ return p.id !== cloudUser.id; });
      friendSearchResults.forEach(function(p){ friendsProfiles[p.id] = p; });
      if (!friendSearchResults.length){
        $("#friendResults").innerHTML = '<div class="friend-empty"><div class="empty-art">🔍</div><div class="empty-title">' + t("Такого призрака нет") + '</div><div class="empty-text">' + t("Проверь ник буква в букву — или друг ещё не зарегистрировался.") + '</div></div>';
        return;
      }
      renderFriendResults();
    }, function(){ if (btn) btn.disabled = false; toast(t("Нет связи с сервером")); });
}
function friendsSend(otherId){
  if (!db || !cloudUser) return;
  if (otherId === cloudUser.id){ toast(t("Себя в друзья не добавить 😄")); return; }
  var rel = friendRelation(otherId);
  if (rel){
    toast(rel.kind === "friend" ? t("Вы уже друзья 👻")
        : rel.kind === "out" ? t("Заявка уже отправлена — ждём ответа")
        : t("Этот призрак уже позвал тебя — прими заявку в списке ниже"));
    return;
  }
  db.from("friendships").select("id,status,requester,addressee")
    .or("and(requester.eq." + cloudUser.id + ",addressee.eq." + otherId + "),and(requester.eq." + otherId + ",addressee.eq." + cloudUser.id + ")")
    .then(function(res){
      if (!res.error && res.data && res.data.length){
        var r = res.data[0];
        toast(r.status === "accepted" ? t("Вы уже друзья 👻")
            : r.requester === cloudUser.id ? t("Заявка уже отправлена — ждём ответа")
            : t("Этот призрак уже позвал тебя — прими заявку в списке ниже"));
        friendsLoaded = false; friendsLoad();
        return;
      }
      return db.from("friendships")
        .insert({ requester: cloudUser.id, addressee: otherId, status: "pending" })
        .then(function(ins){
          if (ins.error){
            toast(/duplicate|unique/i.test(ins.error.message || "") ? t("Такая заявка уже есть") : t("Не вышло отправить заявку"));
            friendsLoaded = false; friendsLoad();
            return;
          }
          toast(t("Заявка отправлена 👻"));
          friendsLoaded = false; friendsLoad(); renderFriendResults();
        }, function(){ toast(t("Нет связи с сервером")); });
    }, function(){ toast(t("Нет связи с сервером")); });
}
function friendsAccept(rowId){
  if (!db || !cloudUser) return;
  db.from("friendships").update({ status: "accepted" }).eq("id", rowId).eq("addressee", cloudUser.id)
    .then(function(res){
      if (res.error){ toast(t("Не вышло принять заявку")); return; }
      toast(t("Теперь вы друзья 👻"));
      friendsLoaded = false; friendsLoad(); renderFriendResults();
    }, function(){ toast(t("Нет связи с сервером")); });
}
function friendsDelete(rowId, okMsg){
  if (!db || !cloudUser) return;
  db.from("friendships").delete().eq("id", rowId)
    .then(function(res){
      if (res.error){ toast(t("Не вышло — попробуй ещё раз")); return; }
      if (okMsg) toast(okMsg);
      friendsLoaded = false; friendsLoad(); renderFriendResults();
    }, function(){ toast(t("Нет связи с сервером")); });
}
function friendsReset(){
  friendsRows = []; friendsProfiles = {}; friendSearchResults = [];
  friendsLoaded = false;
  var r = $("#friendResults"); if (r) r.innerHTML = "";
  renderFriends(); updateReqBadges();
  updateFriendsAtPlaces();
}
/* Accepted friends who are "in deal" right now (profiles.online) for the
   «Я в деле» overlay. Empty list → the overlay keeps its old empty text. */
function dealFriendsList(){
  if (!cloudUser) return [];
  var out = [];
  friendsRows.forEach(function(r){
    if (r.status !== "accepted") return;
    var otherId = (r.requester === cloudUser.id) ? r.addressee : r.requester;
    var p = friendsProfiles[otherId];
    if (p && p.online) out.push(p);
  });
  return out;
}
function renderDealFriends(){
  var box = $("#dealFriends"), empty = $("#dealEmpty");
  if (!box) return;
  var list = dealFriendsList();
  if (!list.length){ box.innerHTML = ""; if (empty) empty.hidden = false; return; }
  if (empty) empty.hidden = true;
  box.innerHTML = '<div class="deal-friends"><div class="friend-sec-title light">' + tf("Друзья сейчас в деле · {n}", { n: list.length }) + "</div>" +
    list.map(function(p){
      return '<div class="friend-row">' +
        '<span class="friend-ava">' + friendAvatarHtml(p) + '</span>' +
        '<span class="friend-info"><span class="friend-name">' + escHtml(p.name || t("Призрак")) + '</span>' +
        '<span class="friend-meta">' + friendMetaHtml(p) + '</span></span>' +
        '<span class="friend-indeal">🔥 ' + t("в деле") + '</span></div>';
    }).join("") + "</div>";
}
/* ================= Movement speed (derived on the client) =================
   Nobody stores a speed anywhere — it is computed HERE from two
   consecutive coordinate fixes of the same ghost. Friend fixes come from
   profile_locations (the position + its updated_at, re-polled every
   30 s); my own fixes come from the live geolocation watch. Rules:
   - the first sighting of a ghost gives NO speed (nothing to compare);
   - a move under 15 m is GPS noise → «на месте» (0 km/h);
   - over 200 km/h is a teleport / GPS glitch → no number, just a dash,
     and the baseline re-seats on the new point;
   - the number is rounded to whole km/h and the icon follows it:
     0 🧍 · 1–7 🚶 · 8–24 🏃 · 25+ 🚗. */
var speedTrack = {};      /* friend id -> {lat,lng,t,speed,dash} */
var mySpeedState = null;  /* same shape, for my own ghost */
function speedStep(prev, lat, lng, t){
  if (!prev) return { lat: lat, lng: lng, t: t, speed: null, dash: false };
  var dtH = (t - prev.t) / 3600000;
  if (!(dtH > 0)) return prev; /* the same fix re-polled: keep the estimate */
  var dKm = distKm(prev, { lat: lat, lng: lng });
  if (dKm < 0.015) return { lat: lat, lng: lng, t: t, speed: 0, dash: false };
  var v = dKm / dtH;
  if (v > 200) return { lat: lat, lng: lng, t: t, speed: null, dash: true };
  return { lat: lat, lng: lng, t: t, speed: v, dash: false };
}
function speedText(st){
  if (!st) return "";
  if (st.speed === null || st.speed === undefined) return st.dash ? t("⚡ телепорт · —") : "";
  var v = Math.round(st.speed);
  if (v <= 0) return t("🧍 на месте");
  if (v <= 7) return tf("🚶 идёт · {v} км/ч", { v: v });
  if (v <= 24) return tf("🏃 бежит · {v} км/ч", { v: v });
  return tf("🚗 едет · {v} км/ч", { v: v });
}
function speedLineHtml(st){
  var s = speedText(st);
  return s ? '<div class="pop-speed">' + s + "</div>" : "";
}
function trackSpeedsFromLocs(locs){
  Object.keys(locs || {}).forEach(function(id){
    var l = locs[id];
    if (typeof l.lat === "number" && typeof l.lng === "number")
      speedTrack[id] = speedStep(speedTrack[id], l.lat, l.lng, l.t || Date.now());
  });
}
/* A hidden ghost (mode ghost/offline) never shows a speed anywhere. */
function friendSpeedState(p){
  if (!p || !p.id) return null;
  if (p.mode === "ghost" || p.mode === "offline") return null;
  return speedTrack[p.id] || null;
}
function friendSpeedText(p){ return speedText(friendSpeedState(p)); }
function trackMySpeed(lat, lng){
  mySpeedState = speedStep(mySpeedState, lat, lng, Date.now());
  if (meMarker){
    var mp = meMarker.getPopup();
    if (mp) mp.setHTML(myPopupHtml()); /* keep the popup fresh even while closed */
  }
}

/* ---- Friends on the map: accepted friends as round ghosts ----
   Each friend's app writes its own REAL geolocation into the locked-down
   profile_locations table (see cloudGeoSync); RLS lets me read only my
   accepted friends' rows. Here we read accepted friends + their profiles,
   merge in the locations and reconcile maplibre markers: created once,
   moved in place, removed when someone unfriends, hides (mode
   ghost/offline) or has no coordinates.
   Refreshed on sign-in, when the map screen opens and every 30 s. */
var friendMapTimer = null, friendMapLoading = false;
function friendVisibleOnMap(p){
  return !!p && typeof p.lat === "number" && typeof p.lng === "number" &&
    p.mode !== "ghost" && p.mode !== "offline";
}
function friendLastSeenText(p){
  if (p.online) return t("🟢 в сети");
  if (!p.last_seen) return t("⚪ не в сети");
  var ts = new Date(p.last_seen).getTime();
  if (isNaN(ts)) return t("⚪ не в сети");
  var mins = Math.max(0, Math.round((Date.now() - ts) / 60000));
  if (mins < 2) return t("был(а) только что");
  if (mins < 60) return tf("был(а) {n} {w} назад", { n: mins, w: pl(mins, "minute") });
  var hrs = Math.round(mins / 60);
  if (hrs < 24) return tf("был(а) {n} {w} назад", { n: hrs, w: pl(hrs, "hour") });
  return t("был(а) давно");
}
function friendPopupHtml(p){
  return '<div class="pop-card">' +
    '<div class="pop-head friend"><div class="pop-name">' + escHtml(p.name || t("Призрак")) + '</div><span class="pop-tag">' + t("друг") + ' 👻</span></div>' +
    '<div class="pop-status">' + friendLastSeenText(p) + "</div>" +
    speedLineHtml(friendSpeedState(p)) +
    '<div class="pop-note">' + t("Твой друг-призрак — вы видите друг друга на карте.") + '</div></div>';
}
function friendGhostHtml(p){
  return '<div class="ghost-round friend' + (p.online ? "" : " off") + '">' + friendAvatarHtml(p) + "</div>";
}
function friendGhostEl(p){
  var el = document.createElement("div");
  el.className = "ghost-marker";
  el.innerHTML = friendGhostHtml(p);
  return el;
}
function syncFriendMarkers(byId){
  if (!map) return;
  var keep = {};
  Object.keys(byId).forEach(function(id){
    var p = byId[id];
    if (!friendVisibleOnMap(p)) return;
    keep[id] = 1;
    var m = friendMarkers[id];
    if (!m){
      m = new maplibregl.Marker({ element: friendGhostEl(p) })
        .setLngLat([p.lng, p.lat])
        .setPopup(makePopup(friendPopupHtml(p), 26))
        .addTo(map);
      friendMarkers[id] = m;
      m._avaKey = (p.avatar_url || p.avatar || "");
      m._wasOnline = !!p.online;
      return;
    }
    var cur = m.getLngLat();
    if (Math.abs(cur.lng - p.lng) > 1e-7 || Math.abs(cur.lat - p.lat) > 1e-7)
      m.setLngLat([p.lng, p.lat]);
    var avaKey = (p.avatar_url || p.avatar || "");
    if (m._avaKey !== avaKey){
      m.getElement().innerHTML = friendGhostHtml(p);
      m._avaKey = avaKey;
    } else if (!!p.online !== !!m._wasOnline){
      m.getElement().innerHTML = friendGhostHtml(p);
    }
    m._wasOnline = !!p.online;
    var pop = m.getPopup();
    if (pop) pop.setHTML(friendPopupHtml(p));
  });
  Object.keys(friendMarkers).forEach(function(id){
    if (!keep[id]){ friendMarkers[id].remove(); delete friendMarkers[id]; }
  });
}
function refreshFriendMarkers(){
  if (!db || !cloudUser || !map || friendMapLoading) return Promise.resolve();
  friendMapLoading = true;
  var finish = function(){ friendMapLoading = false; };
  return db.from("friendships").select("requester,addressee,status")
    .eq("status", "accepted")
    .or("requester.eq." + cloudUser.id + ",addressee.eq." + cloudUser.id)
    .then(function(res){
      if (res.error || !res.data){ finish(); return; }
      var ids = {};
      res.data.forEach(function(r){ ids[(r.requester === cloudUser.id) ? r.addressee : r.requester] = 1; });
      var list = Object.keys(ids);
      if (!list.length){ syncFriendMarkers({}); updateFriendsAtPlaces(); finish(); return; }
      return db.from("profiles")
        .select("id,name,avatar,avatar_url,online,last_seen,mode,stats")
        .in("id", list)
        .then(function(pr){
          if (pr.error || !pr.data){ finish(); return; }
          var byId = {};
          pr.data.forEach(function(p){ byId[p.id] = p; friendsProfiles[p.id] = p; });
          return fetchFriendLocations(list).then(function(locs){
            finish();
            trackSpeedsFromLocs(locs);
            Object.keys(locs).forEach(function(id){
              if (byId[id]){ byId[id].lat = locs[id].lat; byId[id].lng = locs[id].lng; }
              if (friendsProfiles[id]){ friendsProfiles[id].lat = locs[id].lat; friendsProfiles[id].lng = locs[id].lng; }
            });
            syncFriendMarkers(byId);
            updateFriendsAtPlaces();
            /* keep the friends list on the profile screen fresh too */
            var ps = $("#screen-profile");
            if (ps && ps.classList.contains("active")) renderFriends();
          });
        }, finish);
    }, finish);
}
function startFriendMapTimer(){
  stopFriendMapTimer();
  friendMapTimer = setInterval(function(){
    if (document.visibilityState === "visible") refreshFriendMarkers();
  }, 30000);
}
function stopFriendMapTimer(){
  if (friendMapTimer){ clearInterval(friendMapTimer); friendMapTimer = null; }
}
function clearFriendMarkers(){
  Object.keys(friendMarkers).forEach(function(id){ friendMarkers[id].remove(); });
  friendMarkers = {};
}

/* ================= Friends at places («Места» screen) =================
   An accepted friend whose real coordinates (profile_locations, merged
   into friendsProfiles by the 30 s location polls) sit within 150 m of
   a place — in ANY city, not just the selected one — is "hanging out"
   there. The Places screen then gets a shimmering strip at the very
   top («👻 Имя тусит: Место · Город», tap opens that place), places
   with friends float to the top of the list with a pulsing «Здесь»
   badge on the card, and the place sheet names who is there. Hidden
   ghosts (mode ghost/offline) never appear — same rule as the map.
   Recomputed on every friends/locations refresh; the list re-renders
   only when the set of matches actually changes. */
var FRIEND_PLACE_RADIUS_KM = 0.15;
function friendsAtPlaceNames(placeId){
  return (friendsAtPlace[placeId] || []).map(function(f){ return f.name; });
}
function computeFriendsAtPlaces(){
  friendsAtPlace = {}; friendsPlaceOf = {};
  Object.keys(friendsProfiles).forEach(function(id){
    var p = friendsProfiles[id];
    if (!p) return;
    var rel = friendRelation(id);
    if (!rel || rel.kind !== "friend") return;         /* accepted only */
    if (p.mode === "ghost" || p.mode === "offline") return;
    if (typeof p.lat !== "number" || typeof p.lng !== "number") return;
    var best = null, bestD = FRIEND_PLACE_RADIUS_KM;
    CITIES.forEach(function(c){
      (PLACES_BY_CITY[c.id] || []).forEach(function(pl){
        var d = distKm(p, pl);
        if (d <= bestD){ bestD = d; best = { place: pl, cityId: c.id, cityName: c.name }; }
      });
    });
    if (best){
      friendsPlaceOf[id] = best;
      (friendsAtPlace[best.place.id] = friendsAtPlace[best.place.id] || [])
        .push({ id: id, name: p.name || t("Призрак") });
    }
  });
  var sig = Object.keys(friendsPlaceOf).sort().map(function(id){
    return id + "@" + friendsPlaceOf[id].place.id;
  }).join("|");
  var changed = sig !== friendsPlacesSig;
  friendsPlacesSig = sig;
  return changed;
}
function renderFriendsPlacesBar(){
  var bar = $("#friendsPlacesBar");
  if (!bar) return;
  var ids = Object.keys(friendsPlaceOf);
  if (!ids.length){ bar.hidden = true; bar.innerHTML = ""; return; }
  bar.innerHTML = ids.map(function(id){
    var f = friendsPlaceOf[id], p = friendsProfiles[id];
    return '<button class="fp-chip" data-fp-place="' + f.place.id + '">' +
      '<span class="fp-ghost">👻</span>' +
      '<span class="fp-text"><b>' + escHtml((p && p.name) || t("Призрак")) + '</b> ' + t("тусит:") + ' ' +
      escHtml(f.place.name) + ' · ' + escHtml(cityName(cityById(f.cityId))) + '</span>' +
      '<span class="fp-arrow">→</span></button>';
  }).join("");
  bar.hidden = false;
  bar.querySelectorAll("[data-fp-place]").forEach(function(b){
    b.addEventListener("click", function(){ openPlaceSheetById(b.getAttribute("data-fp-place")); });
  });
}
function updateFriendsAtPlaces(){
  var changed = computeFriendsAtPlaces();
  renderFriendsPlacesBar();
  if (changed){
    var ps = $("#screen-places");
    if (ps && ps.classList.contains("active")) renderPlaces();
  }
  checkFriendsNear();
}
var friendsLoginBtn = $("#friendsLoginBtn");
if (friendsLoginBtn) friendsLoginBtn.addEventListener("click", function(){ $("#loginModal").hidden = false; });
var friendSearchBtn = $("#friendSearchBtn");
if (friendSearchBtn) friendSearchBtn.addEventListener("click", friendsSearch);
var friendSearchInp = $("#friendSearch");
if (friendSearchInp) friendSearchInp.addEventListener("keydown", function(e){
  if (e.key === "Enter"){ e.preventDefault(); friendsSearch(); }
});

/* ---- Friend by invite link: <origin>/?add=<my profile id> ----
   The link carries only a profile id (no nick — anonymity holds). The
   receiver gets a confirm sheet; a guest's id waits in sessionStorage
   and the sheet is offered right after sign-in. The ?add= param is
   scrubbed from the URL as soon as it is read. */
var pendingAddId = null, addFriendTarget = null;
(function(){
  try {
    var m = /[?&]add=([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})/.exec(location.search || "");
    if (m){
      pendingAddId = m[1];
      sessionStorage.setItem("tirada_pending_add", pendingAddId);
      var u = new URL(location.href);
      u.searchParams.delete("add");
      history.replaceState(null, "", u.pathname + u.search + u.hash);
    } else {
      pendingAddId = sessionStorage.getItem("tirada_pending_add");
    }
  } catch(e){}
})();
function maybeShowAddFriend(){
  if (!pendingAddId || !cloudUser) return;
  var id = pendingAddId;
  pendingAddId = null;
  try { sessionStorage.removeItem("tirada_pending_add"); } catch(e){}
  if (id === cloudUser.id) return;
  var rel = friendRelation(id);
  if (rel && rel.kind === "friend"){ toast(t("Вы уже друзья 👻")); return; }
  if (rel && rel.kind === "out"){ toast(t("Заявка этому призраку уже отправлена 👻")); return; }
  if (rel && rel.kind === "in"){ toast(t("Этот призрак уже позвал тебя — прими заявку в списке друзей 👻")); return; }
  addFriendTarget = id;
  var t = $("#addFriendText");
  if (t) t.textContent = tf("Добавить в друзья Призрака #{n}? Заявка уйдёт от твоего призрака. Когда её примут, вы будете видеть друг друга на карте.", { n: ghostNumberFor(id) });
  var sh = $("#addFriendSheet");
  if (sh) sh.hidden = false;
}
/* The one working invite: <origin>/?add=<my profile id> (wave 1). Every
   «Позвать друзей» surface uses this — no dead-end placeholders. */
function shareFriendInvite(){
  if (!cloudUser){ toast(t("Войди — и ссылка-приглашение станет твоей 👻")); $("#loginModal").hidden = false; return; }
  var link = location.origin + location.pathname + "?add=" + cloudUser.id;
  if (navigator.share){
    navigator.share({ title: "TiradA anon 👻", text: t("Добавляйся в друзья в TiradA anon — будем видеть друг друга на карте движа"), url: link }).catch(function(){});
  } else if (navigator.clipboard) {
    navigator.clipboard.writeText(link).then(function(){ toast(t("Ссылка-приглашение скопирована 🔗 Отправь её другу")); }, function(){ toast(link); });
  } else toast(link);
}
var friendInviteBtn = $("#friendInviteBtn");
if (friendInviteBtn) friendInviteBtn.addEventListener("click", shareFriendInvite);
var addFriendSheetEl = $("#addFriendSheet");
function closeAddFriendSheet(){ if (addFriendSheetEl) addFriendSheetEl.hidden = true; addFriendTarget = null; }
var addFriendCloseBtn = $("#addFriendClose");
if (addFriendCloseBtn) addFriendCloseBtn.addEventListener("click", closeAddFriendSheet);
var addFriendCancelBtn = $("#addFriendCancel");
if (addFriendCancelBtn) addFriendCancelBtn.addEventListener("click", closeAddFriendSheet);
if (addFriendSheetEl) addFriendSheetEl.addEventListener("click", function(e){ if (e.target === addFriendSheetEl) closeAddFriendSheet(); });
var addFriendSendBtn = $("#addFriendSend");
if (addFriendSendBtn) addFriendSendBtn.addEventListener("click", function(){
  var id = addFriendTarget;
  closeAddFriendSheet();
  if (id) friendsSend(id);
});

/* ---- Account UI ---- */
function renderAccount(){
  var g = $("#accountGuest"), u = $("#accountUser"), btn = $("#loginBtn");
  if (!g || !u || !btn) return;
  if (cloudUser){
    g.hidden = true; u.hidden = false;
    $("#accountEmail").textContent = cloudUser.email || "";
    btn.textContent = state.nick ? "👻 " + state.nick : "👻 " + t("В сети");
  } else {
    g.hidden = false; u.hidden = true;
    btn.textContent = t("Войти");
  }
  renderFriends();
  loadMyPhotos();
  refreshPushUI();
}
function cloudOnSignedIn(user){
  if (!user || cloudBootedFor === user.id) { renderAccount(); return; }
  cloudBootedFor = user.id;
  cloudUser = user;
  renderAccount();
  db.from("profiles").select("*").eq("id", user.id).maybeSingle()
    .then(function(res){
      if (res.data) applyRemoteProfile(res.data);
      renderAccount();
      return cloudSyncNow();
    }, function(){ return cloudSyncNow(); })
    .then(function(){ return cloudPresence(true); })
    .then(function(){ cloudGeoSync(); startHeartbeat(); return cloudLoadMyVote(); })
    .then(function(){ return friendsLoad(); }, function(){ return friendsLoad(); })
    .then(function(){ refreshFriendMarkers(); startFriendMapTimer(); maybeShowAddFriend(); },
          function(){ refreshFriendMarkers(); startFriendMapTimer(); maybeShowAddFriend(); })
    .then(function(){ repaintCoreSurfaces("profile-applied"); }, function(){ repaintCoreSurfaces("profile-applied"); });
}
/* ================= Cloud events (fan-out pushes) =================
   Live moments and milestones are written by the client into the
   events table; a database webhook hands each row to the send-push
   Edge Function, which pushes it to the actor's accepted friends
   (friend_near goes only to the author; level_up and badge also reach
   the author). The table arrives with the parent's SQL — until then
   the insert simply fails in silence and nothing breaks. Per-key
   cooldowns in localStorage keep one moment from spamming friends. */
function writeEvent(kind, text){
  if (!db || !cloudUser) return;
  try {
    db.from("events").insert({ user_id: cloudUser.id, kind: kind, text: text })
      .then(function(){}, function(){});
  } catch (e) {}
}
function eventCooldownOk(mapKey, id, ms){
  var m = lsGet(mapKey, {});
  var now = Date.now();
  if (m[id] && now - m[id] < ms) return false;
  m[id] = now; lsSet(mapKey, m);
  return true;
}
function myDisplayName(){ return state.nick || t("Призрак"); }
/* I am physically at a place (real geolocation only): tell friends,
   at most once per place per 2 hours. */
var selfPlaceCheckAt = 0;
function checkSelfAtPlace(){
  if (!db || !cloudUser || !state.geo) return;
  var now = Date.now();
  if (now - selfPlaceCheckAt < 60000) return;
  selfPlaceCheckAt = now;
  var best = null, bestD = FRIEND_PLACE_RADIUS_KM;
  CITIES.forEach(function(c){
    (PLACES_BY_CITY[c.id] || []).forEach(function(pl){
      var d = distKm(state.geo, pl);
      if (d <= bestD){ bestD = d; best = { place: pl, cityName: c.name }; }
    });
  });
  if (!best) return;
  if (!eventCooldownOk("tirada_ev_atplace", best.place.id, 2 * 3600000)) return;
  writeEvent("at_place", "👻 " + myDisplayName() + " тусит: " + best.place.name + " · " + best.cityName);
}
/* An accepted friend is within 500 m of me: the event is written from
   MY name, so the function pushes it only back to me. Once per friend
   per hour. */
function checkFriendsNear(){
  if (!db || !cloudUser || !state.geo) return;
  Object.keys(friendsProfiles).forEach(function(id){
    var p = friendsProfiles[id];
    if (!p || typeof p.lat !== "number" || typeof p.lng !== "number") return;
    if (p.mode === "ghost" || p.mode === "offline") return;
    var rel = friendRelation(id);
    if (!rel || rel.kind !== "friend") return;
    if (distKm(state.geo, p) > 0.5) return;
    if (!eventCooldownOk("tirada_ev_near", id, 3600000)) return;
    writeEvent("friend_near", "👻 " + (p.name || "Призрак") + " рядом с тобой");
  });
}

/* ================= Web Push notifications =================
   Free Web Push (no Firebase): the browser subscription lives in the
   push_subscriptions table (RLS: each user manages only their own
   rows), and a Supabase Edge Function (send-push, fired by a database
   webhook on public.friendships) delivers «новая заявка в друзья» and
   «вы теперь друзья». The VAPID public key is safe to ship in the
   client; the private key never leaves the function's env. */
var VAPID_PUBLIC_KEY = "BMDuNZYxROMcehS42c_mdrJfBpMHqXVre6-A5JW7l0usgCNxZfTxBONkpVLRXjU_BlJdd1dI6zEElT-6qO6Z-Fs";
var pushReg = null;
function pushSupported(){
  return "serviceWorker" in navigator && "PushManager" in window && "Notification" in window;
}
/* iOS: web push exists only from 16.4 and only inside the installed
   home-screen app — in plain Safari there is no PushManager at all,
   so detect that case and say honestly what to do instead of
   claiming push is "not supported". No App Store build: the user's
   rule forbids the paid developer account. */
function isIOS(){
  return /iphone|ipad|ipod/i.test(navigator.userAgent || "") ||
    (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
}
function isStandalone(){
  return window.navigator.standalone === true ||
    (window.matchMedia && window.matchMedia("(display-mode: standalone)").matches);
}
function urlB64ToUint8(b64){
  var pad = "=".repeat((4 - (b64.length % 4)) % 4);
  var raw = atob((b64 + pad).replace(/-/g, "+").replace(/_/g, "/"));
  var out = new Uint8Array(raw.length);
  for (var i = 0; i < raw.length; i++) out[i] = raw.charCodeAt(i);
  return out;
}
if (pushSupported()){
  navigator.serviceWorker.register("sw.js").then(function(reg){
    pushReg = reg; refreshPushUI();
  }, function(err){ console.warn("TiradA SW:", err && err.message); });
}
function refreshPushUI(){
  var btn = $("#pushBtn"), note = $("#pushNote");
  if (!btn) return;
  if (isIOS() && !isStandalone()){
    btn.disabled = true;
    btn.textContent = t("🔔 Уведомления — после установки");
    if (note) note.textContent = t("На iPhone сначала добавь приложение на домашний экран: «Поделиться» → «На экран „Домой“». Пуши на iOS работают только из установленной иконки (iOS 16.4 и новее) — таковы правила Apple, App Store для этого не нужен.");
    return;
  }
  if (!pushSupported()){
    btn.disabled = true;
    btn.textContent = t("🔕 Не поддерживается здесь");
    if (note) note.textContent = t("Этот браузер не умеет веб-пуши. Chrome на Android и на компьютере — умеет.");
    return;
  }
  if (!cloudUser){
    btn.disabled = true;
    btn.textContent = t("🔔 Включить уведомления");
    if (note) note.textContent = t("Войди в аккаунт — и уведомления будут прилетать пушем, даже когда приложение закрыто. Работают и без геолокации: пуш — это не GPS.");
    return;
  }
  if (Notification.permission === "denied"){
    btn.disabled = true;
    btn.textContent = t("🔕 Заблокированы в браузере");
    if (note) note.textContent = t("Разрешение на уведомления отклонено — его можно вернуть в настройках сайта в браузере.");
    return;
  }
  btn.disabled = false;
  var regP = pushReg ? Promise.resolve(pushReg) : navigator.serviceWorker.ready;
  regP.then(function(reg){ return reg.pushManager.getSubscription(); }).then(function(sub){
    var b2 = $("#pushBtn"), n2 = $("#pushNote");
    if (!b2) return;
    if (sub){
      b2.textContent = t("🔔 Уведомления включены");
      b2.setAttribute("data-on", "1");
      if (n2) n2.textContent = t("Пуши летят на это устройство. Тап по кнопке — выключить. Работают и без геолокации.");
    } else {
      b2.textContent = t("🔔 Включить уведомления");
      b2.removeAttribute("data-on");
      if (n2) n2.textContent = t("Все события — заявки, друзья в сети и на карте, фото, чекины и вехи — пушем на это устройство. Работают и без геолокации.");
    }
  }, function(){});
}
function pushToggle(){
  if (!pushSupported() || !cloudUser || !db) return;
  var regP = pushReg ? Promise.resolve(pushReg) : navigator.serviceWorker.ready;
  regP.then(function(reg){
    return reg.pushManager.getSubscription().then(function(sub){
      if (sub){
        var ep = sub.endpoint;
        return sub.unsubscribe().then(function(){
          return db.from("push_subscriptions").delete().eq("endpoint", ep);
        }).then(function(){
          toast(t("Уведомления выключены 🔕"));
          refreshPushUI();
        });
      }
      return Notification.requestPermission().then(function(perm){
        if (perm !== "granted"){ toast(t("Без разрешения пуши не прилетят 🔔")); refreshPushUI(); return; }
        return reg.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: urlB64ToUint8(VAPID_PUBLIC_KEY)
        }).then(function(nsub){
          var j = nsub.toJSON();
          return db.from("push_subscriptions").upsert({
            user_id: cloudUser.id,
            endpoint: nsub.endpoint,
            p256dh: (j.keys || {}).p256dh || "",
            auth: (j.keys || {}).auth || ""
          }, { onConflict: "endpoint" }).then(function(res){
            if (res && res.error) toast(t("Не вышло сохранить подписку — попробуй ещё раз"));
            else toast(t("Уведомления включены 🔔"));
            refreshPushUI();
          });
        });
      });
    });
  }).catch(function(){ toast(t("Что-то пошло не так с уведомлениями")); refreshPushUI(); });
}
var pushBtnEl = $("#pushBtn");
if (pushBtnEl) pushBtnEl.addEventListener("click", pushToggle);

if (db){
  db.auth.getSession().then(function(r){
    var s = r.data && r.data.session;
    cloudSession = s || null;
    if (s && s.user) cloudOnSignedIn(s.user); else renderAccount();
  }, function(){ renderAccount(); }).then(function(){ repaintCoreSurfaces("auth-settled"); }, function(){ repaintCoreSurfaces("auth-settled"); });
  db.auth.onAuthStateChange(function(ev, session){
    cloudSession = session || null;
    if (ev === "SIGNED_IN" && session && session.user) cloudOnSignedIn(session.user);
    if (ev === "SIGNED_OUT"){
      cloudUser = null; cloudBootedFor = null; cloudVoteCounts = null;
      stopHeartbeat(); stopFriendMapTimer(); clearFriendMarkers();
      geoPushed = null; geoPushAt = 0;
      friendsReset(); renderAccount();
    }
  });
} else {
  renderAccount();
}
var accountLoginBtn = $("#accountLoginBtn");
if (accountLoginBtn) accountLoginBtn.addEventListener("click", function(){ $("#loginModal").hidden = false; });
var accountLogoutBtn = $("#accountLogoutBtn");
if (accountLogoutBtn) accountLogoutBtn.addEventListener("click", function(){
  if (!db) return;
  cloudPresence(false).then(function(){ return db.auth.signOut(); }).then(function(){
    toast(t("Ты вышел. Призрак снова только на этом устройстве 👻"));
  }, function(){ toast(t("Не вышло выйти — попробуй ещё раз")); });
});

/* ---- Auth modal ---- */
var modal = $("#loginModal");
var authMode = "in";
function authShowError(msg){
  var e = $("#authError");
  if (!msg){ e.hidden = true; e.textContent = ""; return; }
  e.textContent = msg; e.hidden = false;
}
function authErrorText(err){
  var m = (err && err.message) || "";
  if (/Invalid login credentials/i.test(m)) return t("Неверный email или пароль. Проверь и попробуй ещё раз.");
  if (/already registered/i.test(m)) return t("Этот email уже зарегистрирован. Переключись на вкладку «Вход».");
  if (/at least 6 characters/i.test(m)) return t("Пароль слишком короткий — нужно минимум 6 символов.");
  if (/invalid format|validate email|invalid email/i.test(m)) return t("Email выглядит неправильно — проверь адрес.");
  if (/Failed to fetch|NetworkError|network|Load failed/i.test(m)) return t("Нет связи с сервером. Проверь интернет и попробуй ещё раз.");
  if (/rate limit|too many/i.test(m)) return t("Слишком много попыток подряд. Подожди минутку.");
  return t("Что-то пошло не так. Попробуй ещё раз.");
}
function setAuthMode(m){
  authMode = m;
  $("#authTabIn").classList.toggle("active", m === "in");
  $("#authTabUp").classList.toggle("active", m === "up");
  $("#authName").hidden = (m !== "up");
  $("#authPass").setAttribute("autocomplete", m === "up" ? "new-password" : "current-password");
  $("#authSubmit").textContent = (m === "up") ? t("Создать призрака") : t("Войти");
  $("#authNote").textContent = (m === "up")
    ? t("Пароль — минимум 6 символов. Подтверждение почты не нужно: входи сразу.")
    : t("Нет аккаунта? Жми «Регистрация» — это 20 секунд.");
  var lf = $("#authLangField"); if (lf) lf.hidden = (m !== "up");
  var lsel = $("#authLang"); if (lsel) lsel.value = LANG_CHOICE || "auto";
  authShowError(null);
}
$("#authTabIn").addEventListener("click", function(){ setAuthMode("in"); });
$("#authTabUp").addEventListener("click", function(){ setAuthMode("up"); });
$("#loginBtn").addEventListener("click", function(){
  if (cloudUser){ showScreen("profile"); return; }
  setAuthMode("in");
  modal.hidden = false;
});
$("#loginClose").addEventListener("click", function(){ modal.hidden = true; });
modal.addEventListener("click", function(e){ if (e.target === modal) modal.hidden = true; });
$("#authSubmit").addEventListener("click", function(){
  if (!db){ authShowError(t("Облако сейчас недоступно. Приложение работает и без входа 👻")); return; }
  var email = $("#authEmail").value.trim();
  var pass = $("#authPass").value;
  var name = $("#authName").value.trim();
  if (!email || email.indexOf("@") < 1){ authShowError(t("Введи email — настоящий, с @.")); return; }
  if (!pass || pass.length < 6){ authShowError(t("Пароль слишком короткий — нужно минимум 6 символов.")); return; }
  if (authMode === "up" && name){
    var nchk = validateNick(name);
    if (!nchk.ok){ authShowError(nchk.error); return; }
    name = nchk.value;
  }
  var btn = $("#authSubmit");
  btn.disabled = true;
  btn.textContent = t("Секунду…");
  authShowError(null);
  if (authMode === "up"){
    var langSel = $("#authLang");
    if (langSel){ window.__pendingLangSave = true; setLangChoice(langSel.value || "auto"); }
  }
  var done = function(){ btn.disabled = false; setAuthMode(authMode); };
  if (authMode === "up"){
    if (name){ state.nick = name; lsSet("tirada_nick", state.nick); var ni2 = $("#nickInput"); if (ni2) ni2.value = name; renderMyAvatar(); }
    db.auth.signUp({ email: email, password: pass, options: { data: { name: name || undefined } } })
      .then(function(res){
        if (res.error){ done(); authShowError(authErrorText(res.error)); return; }
        var finishUp = function(){
          done();
          modal.hidden = true;
          if (res.data && res.data.session) toast(t("Аккаунт создан — ты в сети, призрак 👻"));
          else toast(t("Аккаунт создан! Теперь войди по email и паролю."));
        };
        /* The account exists now, but the chosen nick may already be taken
           (unique index on lower(name)): check while we can still show the
           error right here in the auth form. If it is taken, the account
           stays — only the nick falls back until a free one is picked in
           the profile. */
        if (name && res.data && res.data.session && res.data.user){
          var pat = name.replace(/[%_\\]/g, "\\$&");
          db.from("profiles").select("id").ilike("name", pat).limit(5)
            .then(function(q){
              var taken = !q.error && q.data && q.data.some(function(r){ return r.id !== res.data.user.id; });
              if (taken){
                done();
                state.nick = ""; lsSet("tirada_nick", "");
                var ni3 = $("#nickInput"); if (ni3) ni3.value = "";
                renderMyAvatar();
                authShowError(t(NICK_TAKEN_MSG) + t(". Аккаунт создан — после входа придумай другой ник в профиле."));
                showNickError(t(NICK_TAKEN_MSG));
                return;
              }
              finishUp();
            }, function(){ finishUp(); });
          return;
        }
        finishUp();
      }, function(err){ done(); authShowError(authErrorText(err)); });
  } else {
    db.auth.signInWithPassword({ email: email, password: pass })
      .then(function(res){
        done();
        if (res.error){ authShowError(authErrorText(res.error)); return; }
        modal.hidden = true;
        toast(t("С возвращением, призрак 👻"));
      }, function(err){ done(); authShowError(authErrorText(err)); });
  }
});
["authEmail", "authPass", "authName"].forEach(function(id){
  var inp = document.getElementById(id);
  if (inp) inp.addEventListener("keydown", function(e){
    if (e.key === "Enter"){ e.preventDefault(); $("#authSubmit").click(); }
  });
});


/* ================= Language: settings sheet, static i18n, refresh =================
   The ONLY language switch in the app lives in Profile → ⚙️ Settings
   (plus the language field on the sign-up form). setLangChoice() (core
   i18n block at the top) stores the choice, re-resolves LANG and calls
   refreshI18n() here to repaint every dynamic surface. */
function applyStaticI18n(){
  $$("[data-i18n]").forEach(function(el){ el.textContent = t(el.getAttribute("data-i18n")); });
  $$("[data-i18n-ph]").forEach(function(el){ el.setAttribute("placeholder", t(el.getAttribute("data-i18n-ph"))); });
  $$("[data-i18n-aria]").forEach(function(el){ el.setAttribute("aria-label", t(el.getAttribute("data-i18n-aria"))); });
  $$("[data-i18n-alt]").forEach(function(el){ el.setAttribute("alt", t(el.getAttribute("data-i18n-alt"))); });
  document.title = t("TiradA anon — куда тусить в городе. Прямо сейчас. Анонимно.");
  /* The city name in the header chip and the route header is dynamic
     (no data-i18n key) and was only repainted on city change / manual
     language switch — after a plain reload it stayed in Russian while
     the rest of the UI was already in the saved language. Localize it
     here too, so a boot applies ONE language to everything at once. */
  if (typeof state !== "undefined" && state && state.city){
    var cn3 = $("#cityName"); if (cn3) cn3.textContent = cityName(state.city);
    var rc3 = $("#routeCity"); if (rc3) rc3.textContent = cityName(state.city);
  }
  /* The info sheet's title lives in INFO_I18N (not I18N_UI): localize its
     placeholder too, so nothing on screen keeps the previous language. */
  var it3 = $("#infoTitle");
  if (it3) it3.textContent = (LANG !== "ru" && typeof INFO_I18N !== "undefined" && INFO_I18N[LANG] && INFO_I18N[LANG].about && INFO_I18N[LANG].about.title) || "О приложении";
}
function refreshI18n(){
  document.documentElement.lang = LANG;
  document.documentElement.dir = (LANG === "he") ? "rtl" : "ltr";
  applyStaticI18n();
  renderLangOptions();
  var cn = $("#cityName"); if (cn) cn.textContent = cityName(state.city);
  var rc = $("#routeCity"); if (rc) rc.textContent = cityName(state.city);
  renderCityList();
  if ($("#welcomeSheet") && !$("#welcomeSheet").hidden) renderWelcomeCities();
  renderMyAvatar(); renderAvatarGrid(); renderStats(); renderTasks(); renderAiDay();
  renderFilter(); renderPlaces(); updateCounter(); buildTicker();
  state.routeSteps = null; buildRoute();
  renderFriends(); renderFriendsPlacesBar(); renderAccount(); refreshPushUI();
  renderWxChip(); renderStreakChip(); renderSoundBox();
  /* The auth modal's submit/note are only (re)written by setAuthMode on
     open/tab-switch — repaint them too, so no surface keeps the previous
     language after a switch or a cloud-language apply. */
  if (typeof setAuthMode === "function" && $("#authSubmit")) setAuthMode(authMode || "in");
  setMode(state.mode);
  if (meMarker){
    updateMeMarker();
    var mp = meMarker.getPopup();
    if (mp) mp.setHTML(myPopupHtml());
  }
}
function renderLangOptions(){
  $$("#settingsSheet [data-lang-opt]").forEach(function(b){
    b.classList.toggle("active", (b.getAttribute("data-lang-opt") || "auto") === (LANG_CHOICE || "auto"));
  });
  var as2 = $("#authLang"); if (as2) as2.value = LANG_CHOICE || "auto";
}
var settingsBtnEl = $("#settingsBtn");
if (settingsBtnEl) settingsBtnEl.addEventListener("click", function(){
  /* Same open-first rule as the info sheet (v21): unhide before any
     fill work, so a fill failure can never keep the sheet shut. */
  $("#settingsSheet").hidden = false;
  try { renderLangOptions(); } catch (e){}
});
var settingsCloseEl = $("#settingsClose");
if (settingsCloseEl) settingsCloseEl.addEventListener("click", function(){ $("#settingsSheet").hidden = true; });
var settingsSheetEl = $("#settingsSheet");
if (settingsSheetEl) settingsSheetEl.addEventListener("click", function(e){ if (e.target === this) this.hidden = true; });
$$("#settingsSheet [data-lang-opt]").forEach(function(b){
  b.addEventListener("click", function(){
    setLangChoice(b.getAttribute("data-lang-opt") || "auto");
    renderLangOptions();
  });
});
/* Language in the cloud profile (profiles.data.lang): saved on every
   choice while signed in, applied on sign-in when this device has no
   explicit choice of its own. "auto" is stored as-is. */
var cloudProfileData = {};
/* v22: this MUST stay a function declaration, never an assignment.
   `cloudSaveLang = function(){...}` was an assignment to an undeclared
   identifier inside this strict-mode IIFE: in a real browser it threw
   ReferenceError at load and aborted the whole script at that line —
   boot, the footer bindings and everything below never ran (the
   v16–v21 "half-dead app" bug; jsdom could not see it because its
   window proxy resolves any name). As a declaration it is hoisted, so
   every call site — setLangChoice, applyRemoteProfile — is safe no
   matter when it runs. */
function cloudSaveLang(){
  if (!db || !cloudUser) return;
  var data = {};
  try { data = JSON.parse(JSON.stringify(cloudProfileData || {})); } catch(e){}
  data.lang = LANG_CHOICE || "auto";
  cloudProfileData = data;
  db.from("profiles").update({ data: data }).eq("id", cloudUser.id).then(function(){}, function(){});
};

/* ================= Footer: info stubs & creators anchor ================= */
var INFO = {
  about: { emoji:"📱", title:"О приложении",
    body:"TiradA anon — живой радар движа по городам Израиля. Показывает, где город тусит прямо сейчас, собирает маршрут на вечер и зовёт друзей одной ссылкой. Ты на карте — призрак: без имени и фото, открываешься только своим." },
  privacy: { emoji:"🔒", title:"Политика конфиденциальности",
    sections:[
      { h:"Что мы храним", t:"Ник, аватарку, статистику и голоса — в облаке, чтобы твой призрак жил на всех устройствах. Без входа всё хранится только на этом телефоне." },
      { h:"Геолокация", t:"Только если ты сам её разрешил. Координаты лежат в отдельной закрытой таблице: их видишь только ты и твои принятые друзья — чтобы видеть призраков друг друга на карте." },
      { h:"Кто тебя видит", t:"На карте — только принятые друзья. «Невидимка» и «Оффлайн» прячут тебя полностью, «Не беспокоить» — ты на карте, но звать тебя нельзя." },
      { h:"Места и движ", t:"Места и проценты движа в превью — демонстрационные данные. Это не слежка за реальными людьми." },
      { h:"Фото", t:"Загруженная аватарка хранится в облаке и видна тем, кто видит твоего призрака." },
      { h:"Выход", t:"Выйти из аккаунта можно в профиле. Гостевой призрак живёт только на этом устройстве." }
    ] }
};
var infoModal = $("#infoModal");
/* Bulletproof diagnostics render (v20): the «Диагностика запуска» block
   exists to be readable exactly when the app is half-dead — so its own
   render must never throw into the click handler. Worst case it
   degrades to a one-line stub that still names the build and says the
   journal could not be read. */
function renderBootDiag(){
  try { return bootDiagHtml(); }
  catch (e){
    try { tracePush("error", "bootDiag render: " + ((e && e.message) || e)); } catch (e2){}
    var msg = String((e && e.message) || e || "?").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    return "<b>" + t("Диагностика запуска") + "</b><br>" + tf("Сборка: js {b} · журнал не прочитался ({m})", { b: APP_BUILD, m: msg });
  }
}
$$("[data-info]").forEach(function(btn){
  btn.addEventListener("click", function(){
    /* OPEN FIRST, fill after (v21). The v19 handler filled the sheet
       and rendered the diagnostics BEFORE unhiding the modal, all
       unguarded — one throw (the diagnostics read live DOM/storage
       state) and «О приложении» never opened on that device, with the
       evidence locked inside the very sheet that wouldn't open. v20
       armored the fill and moved the unhide to the end; v21 makes the
       unhide the unconditional FIRST step: whatever the fill does,
       the user gets a visible sheet, and each fill step fails alone. */
    infoModal.hidden = false;
    var key = btn.getAttribute("data-info");
    var d = null;
    try {
      d = INFO[key] || null;
      if (d && LANG !== "ru" && typeof INFO_I18N !== "undefined" && INFO_I18N[LANG] && INFO_I18N[LANG][key]){
        var LI = INFO_I18N[LANG][key];
        d = { emoji: d.emoji, title: LI.title, body: LI.body,
              sections: LI.sections ? LI.sections.map(function(x){ return { h: x[0], t: x[1] }; }) : null };
      }
    } catch (e) {
      try { tracePush("error", "info sheet data: " + ((e && e.message) || e)); } catch (e2){}
    }
    try {
      if (d){
        $("#infoEmoji").textContent = d.emoji;
        $("#infoTitle").textContent = d.title;
      }
    } catch (e) {
      try { tracePush("error", "info sheet head: " + ((e && e.message) || e)); } catch (e2){}
    }
    try {
      var bodyEl = $("#infoBody");
      if (d && bodyEl){
        if (d.sections){
          bodyEl.innerHTML = d.sections.map(function(s){
            return '<div class="info-sec"><h4>' + s.h + "</h4><p>" + s.t + "</p></div>";
          }).join("");
        } else {
          bodyEl.textContent = d.body || "";
        }
      }
    } catch (e) {
      try { tracePush("error", "info sheet body: " + ((e && e.message) || e)); } catch (e2){}
    }
    try {
      var diagEl = $("#bootDiag");
      if (diagEl){
        if (key === "about"){ diagEl.innerHTML = renderBootDiag(); diagEl.hidden = false; }
        else diagEl.hidden = true;
      }
    } catch (e) {
      try { tracePush("error", "info sheet diag: " + ((e && e.message) || e)); } catch (e2){}
    }
  });
});
$("#infoClose").addEventListener("click", function(){ infoModal.hidden = true; });
$("#infoOk").addEventListener("click", function(){ infoModal.hidden = true; });
infoModal.addEventListener("click", function(e){ if (e.target === infoModal) infoModal.hidden = true; });
$("#linkCreators").addEventListener("click", function(){
  /* Not a modal: it scrolls the profile to the credits block. If the
     credits are already on screen the tap legitimately "does nothing"
     visible — that is the designed effect, not a dead button. */
  showScreen("profile");
  setTimeout(function(){
    try {
      var el = $("#footerCredits");
      if (el) el.scrollIntoView({ behavior:"smooth", block:"center" });
    } catch (e){}
  }, 120);
});

/* ================= Welcome (first visit) & geo button ================= */
function renderWelcomeCities(){
  var q = (($("#welcomeSearch") && $("#welcomeSearch").value) || "").trim().toLowerCase();
  var list = CITIES.filter(function(c){ return !q || c.name.toLowerCase().indexOf(q) >= 0 || cityName(c).toLowerCase().indexOf(q) >= 0; });
  $("#welcomeCityList").innerHTML = list.length ? list.map(function(c){
    var n = PLACES_BY_CITY[c.id].length;
    return '<button class="city-item" data-wcity="' + c.id + '"><span>' + cityName(c) + '</span><span class="city-item-meta">' + n + " " + placeWord(n) + "</span></button>";
  }).join("") : '<div class="places-empty">' + t("Город не нашёлся 👻") + '</div>';
  $$("#welcomeCityList [data-wcity]").forEach(function(it){
    it.addEventListener("click", function(){
      lsSet("tirada_welcomed", true);
      $("#welcomeSheet").hidden = true;
      setCity(it.getAttribute("data-wcity"));
    });
  });
}
$("#welcomeSearch").addEventListener("input", renderWelcomeCities);
$("#welcomeClose").addEventListener("click", function(){
  lsSet("tirada_welcomed", true);
  $("#welcomeSheet").hidden = true;
});
$("#welcomeGeo").addEventListener("click", function(){
  lsSet("tirada_welcomed", true);
  $("#welcomeSheet").hidden = true;
  requestGeo(true);
});
$("#geoBtn").addEventListener("click", function(){ requestGeo(true); });

/* ================= Go =================
   Every boot step runs in its OWN try/catch (v18). The steps paint
   independent surfaces — city list, profile avatar, stats, tasks,
   places, header counter, ticker, route, map — and a failure in any
   one of them (legacy local state, a damaged storage key, a future
   bug) must never again take the whole app down with it: on the v17
   prod, one unguarded throw in an early step left returning users
   with a dead counter, no ticker, an empty map and empty tasks.
   Failures stay loud in the console, silent in the UI.
   v19: every step ALSO leaves a line in the boot trace
   (localStorage "tirada_boot_errors", see the diagnostics block at
   the top of this file) — failures immediately, successes as one
   summary line — and the four critical surfaces are re-checked after
   window load, after auth settles and by a watchdog (below). */
/* bootStep and bootStepOk/bootStepFail are defined at the TOP of this
   file (right after tracePush) since v22 — see the comment there. */
/* ================= v28: confetti, sky, weather, sound, feedback =================
   Everything in this block follows the v28 loop discipline: no new
   periodic loops except the ones with idempotent starters (ticker
   fade lives with the ticker), one-shot rAF only for confetti, and
   every audio graph is created at most once and torn down on mute. */

/* ---- Confetti: tiny canvas burst, no libraries. Single-flight,
   stops when the page hides, respects prefers-reduced-motion. ---- */
var confettiRunning = false;
function fireConfetti(){
  if (confettiRunning) return;
  try { if (window.matchMedia && matchMedia("(prefers-reduced-motion: reduce)").matches) return; } catch (e) {}
  var cv = $("#confettiCanvas");
  if (!cv) {
    /* The canvas sits before the scripts in the HTML, but if a
       stitched page ever lacks it, build it on the spot — a missed
       celebration must never become a silent no-op. */
    try {
      cv = document.createElement("canvas");
      cv.id = "confettiCanvas";
      document.body.appendChild(cv);
    } catch (e) { return; }
  }
  var ctx = null;
  try { ctx = cv.getContext("2d"); } catch (e) {}
  if (!ctx) return;
  confettiRunning = true;
  cv.width = window.innerWidth || 360; cv.height = window.innerHeight || 640;
  cv.hidden = false;
  var colors = ["#ff1e1e", "#ff7a1a", "#ffd23c", "#7ee2a0", "#ffffff"];
  var parts = [];
  for (var i = 0; i < 90; i++){
    parts.push({ x: cv.width / 2 + (Math.random() - 0.5) * cv.width * 0.45, y: cv.height * 0.35,
      vx: (Math.random() - 0.5) * 9, vy: -(Math.random() * 7 + 4),
      w: 5 + Math.random() * 6, h: 8 + Math.random() * 8,
      r: Math.random() * Math.PI, vr: (Math.random() - 0.5) * 0.3, c: colors[i % colors.length] });
  }
  var t0 = Date.now();
  (function frame(){
    var el = Date.now() - t0;
    ctx.clearRect(0, 0, cv.width, cv.height);
    parts.forEach(function(pt){
      pt.x += pt.vx; pt.y += pt.vy; pt.vy += 0.22; pt.vx *= 0.99; pt.r += pt.vr;
      ctx.save(); ctx.translate(pt.x, pt.y); ctx.rotate(pt.r);
      ctx.fillStyle = pt.c; ctx.globalAlpha = Math.max(0, 1 - el / 2200);
      ctx.fillRect(-pt.w / 2, -pt.h / 2, pt.w, pt.h); ctx.restore();
    });
    if (el < 2300 && !document.hidden) requestAnimationFrame(frame);
    else { ctx.clearRect(0, 0, cv.width, cv.height); cv.hidden = true; confettiRunning = false; }
  })();
}

/* ---- Living sky: a fixed layer UNDER the UI (pointer-events:none,
   it can never intercept a tap). Phase by local hour: night 22–05
   stars, morning 05–10 a small red sun, day 10–17 a soft glow,
   evening 17–22 a warm sunset gradient. Cheap: pure CSS gradients,
   the only animation is an opacity twinkle on the star layer. ---- */
function applySkyPhase(){
  var h = new Date().getHours();
  var ph = (h >= 22 || h < 5) ? "night" : (h < 10 ? "morning" : (h < 17 ? "day" : "evening"));
  if (document.body && document.body.getAttribute("data-sky") !== ph)
    document.body.setAttribute("data-sky", ph);
}

/* ---- Weather: Open-Meteo (no key) for the current position/city.
   Chip in the topbar: icon + temperature, condition in the title.
   30-minute cache; any failure simply hides the chip. Rain codes
   switch the rain ambience layer on. ---- */
var wxState = null;
var WX_RAIN_CODES = { 51:1, 53:1, 55:1, 56:1, 57:1, 61:1, 63:1, 65:1, 66:1, 67:1, 80:1, 81:1, 82:1, 95:1, 96:1, 99:1 };
function wxInfo(code){
  if (code === 0) return { i: "☀️", k: "Ясно" };
  if (code === 1) return { i: "🌤️", k: "Преимущественно ясно" };
  if (code === 2) return { i: "⛅", k: "Переменная облачность" };
  if (code === 3) return { i: "☁️", k: "Облачно" };
  if (code === 45 || code === 48) return { i: "🌫️", k: "Туман" };
  if (code >= 51 && code <= 57) return { i: "🌦️", k: "Морось" };
  if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) return { i: "🌧️", k: "Дождь" };
  if ((code >= 71 && code <= 77) || code === 85 || code === 86) return { i: "🌨️", k: "Снег" };
  if (code >= 95) return { i: "⛈️", k: "Гроза" };
  return { i: "🌡️", k: "Погода" };
}
function renderWxChip(){
  var chip = $("#wxChip"); if (!chip) return;
  if (!wxState || typeof wxState.t !== "number"){ chip.hidden = true; return; }
  var info = wxInfo(wxState.code);
  chip.hidden = false;
  chip.textContent = info.i + " " + Math.round(wxState.t) + "°";
  chip.title = t(info.k);
  chip.setAttribute("aria-label", t("Погода") + ": " + t(info.k) + ", " + Math.round(wxState.t) + "°");
}
function loadWeather(){
  if (typeof fetch !== "function") return;
  var c = null;
  try { c = mePos(); } catch (e) {}
  if (!c || typeof c.lat !== "number") return;
  var cache = lsGet("tirada_wx_cache", null);
  if (cache && typeof cache.at === "number" && Date.now() - cache.at < 30 * 60000 &&
      Math.abs(cache.lat - c.lat) < 0.05 && Math.abs(cache.lng - c.lng) < 0.05){
    wxState = cache; renderWxChip(); updateRainAmbience(); return;
  }
  var url = "https://api.open-meteo.com/v1/forecast?latitude=" + c.lat.toFixed(4) + "&longitude=" + c.lng.toFixed(4) +
    "&current=temperature_2m,weather_code&timezone=auto";
  fetch(url).then(function(r){ return r.json(); }).then(function(j){
    if (j && j.current && typeof j.current.temperature_2m === "number"){
      wxState = { t: j.current.temperature_2m, code: j.current.weather_code | 0, at: Date.now(), lat: c.lat, lng: c.lng };
      lsSet("tirada_wx_cache", wxState);
    }
    renderWxChip(); updateRainAmbience();
  }).catch(function(){ renderWxChip(); });
}

/* ---- Streak chip in the topbar (the streak itself already lives
   in tirada_streak / stats; this is only its visible face). ---- */
function currentStreak(){
  var st = objOr(lsGet("tirada_streak", null), { streak: 0 });
  return Math.max((state.stats && state.stats.streak) || 0, st.streak || 0);
}
function renderStreakChip(){
  var el = $("#streakChip"); if (!el) return;
  var n = currentStreak();
  el.hidden = !(n > 0);
  if (n > 0){ el.textContent = "🔥 " + n; el.title = t("Стрик") + ": " + n; }
}

/* ---- Sound: Yasha's track as a barely-audible background loop
   (~0.15 — "on the edge of hearing"), plus synthesized ambience.
   Nothing plays before the first user gesture; preferences persist;
   the master switch silences EVERYTHING. Music is lazy: the file
   is not even requested until the first play. ---- */
var soundOn = lsGet("tirada_sound_on", true) === true;
var musicOn = lsGet("tirada_music_on", true) === true;
var musicAudio = null, musicArmed = false;
function ensureMusic(){
  if (musicAudio) return musicAudio;
  try {
    musicAudio = new Audio();
    musicAudio.loop = true;
    musicAudio.volume = 0.3;
    musicAudio.preload = "none";
  } catch (e) { musicAudio = null; }
  return musicAudio;
}
function applySoundState(){
  var m = ensureMusic();
  if (m){
    try {
      if (soundOn && musicOn && musicArmed){
        if (!m.src) m.src = "assets/music.mp3";
        var pr = m.play(); if (pr && pr.catch) pr.catch(function(){});
      } else m.pause();
    } catch (e) {}
  }
  applyAmbienceState();
}
function armSoundOnFirstGesture(){
  var arm = function(){
    musicArmed = true; /* listener stays: every later tap retries play() if the first attempt was blocked or the phone was silent */
    applySoundState();
  };
  document.addEventListener("pointerdown", arm);
  document.addEventListener("keydown", arm);
}
function renderSoundBox(){
  var s1 = $("#sndToggle"), s2 = $("#musicToggle");
  if (s1){ s1.textContent = soundOn ? t("🔊 Звук: вкл") : t("🔊 Звук: выкл"); s1.setAttribute("data-on", soundOn ? "1" : "0"); }
  if (s2){ s2.textContent = musicOn ? t("🎵 Музыка: вкл") : t("🎵 Музыка: выкл"); s2.setAttribute("data-on", musicOn ? "1" : "0"); }
}
/* Ambience: WebAudio-synthesized layers, no files. Rain = band-passed
   noise; wind (parks/beaches/views) = low-passed noise with a slow
   LFO; crowd (cafes/bars/markets) = mid-band noise, quieter still.
   Rain from the weather wins over the place layer. One graph at a
   time; switching or muting tears it down. */
var ambCtx = null, ambNodes = null, ambKind = null, ambPlaceKind = null, ambRainOn = false;
function ambDesired(){ if (!soundOn) return null; if (ambRainOn) return "rain"; return ambPlaceKind; }
function stopAmbience(){
  if (ambNodes){
    try { ambNodes.src.stop(); } catch (e) {}
    try { if (ambNodes.lfo) ambNodes.lfo.stop(); } catch (e) {}
    ambNodes = null;
  }
  ambKind = null;
}
function applyAmbienceState(){
  var want = ambDesired();
  if (want === ambKind) return;
  stopAmbience();
  if (!want || !musicArmed) return;
  var AC = window.AudioContext || window.webkitAudioContext;
  if (!AC) return;
  try {
    ambCtx = ambCtx || new AC();
    if (ambCtx.state === "suspended") ambCtx.resume();
    var len = ambCtx.sampleRate * 2;
    var buf = ambCtx.createBuffer(1, len, ambCtx.sampleRate);
    var d = buf.getChannelData(0);
    for (var i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
    var src = ambCtx.createBufferSource(); src.buffer = buf; src.loop = true;
    var filt = ambCtx.createBiquadFilter();
    var gain = ambCtx.createGain();
    var lfo = null;
    if (want === "rain"){ filt.type = "bandpass"; filt.frequency.value = 1400; filt.Q.value = 0.4; gain.gain.value = 0.05; }
    else if (want === "wind"){ filt.type = "lowpass"; filt.frequency.value = 420; gain.gain.value = 0.045; }
    else { filt.type = "bandpass"; filt.frequency.value = 700; filt.Q.value = 0.6; gain.gain.value = 0.028; }
    if (want === "wind" || want === "crowd"){
      lfo = ambCtx.createOscillator();
      lfo.frequency.value = want === "wind" ? 0.13 : 0.4;
      var lg = ambCtx.createGain(); lg.gain.value = want === "wind" ? 160 : 120;
      lfo.connect(lg); lg.connect(filt.frequency); lfo.start();
    }
    src.connect(filt); filt.connect(gain); gain.connect(ambCtx.destination);
    src.start();
    ambNodes = { src: src, lfo: lfo };
    ambKind = want;
  } catch (e) { ambKind = null; }
}
function updateAmbientForPlace(p){
  if (!p) ambPlaceKind = null;
  else if (p.type === "park" || p.type === "beach" || p.type === "prom" || p.type === "view" || p.type === "roof" || p.type === "stage") ambPlaceKind = "wind";
  else if (p.type === "cafe" || p.type === "bar" || p.type === "hookah" || p.type === "market" || p.type === "club") ambPlaceKind = "crowd";
  else ambPlaceKind = null;
  applyAmbienceState();
}
function updateRainAmbience(){
  ambRainOn = !!(wxState && WX_RAIN_CODES[wxState.code]);
  applyAmbienceState();
}

/* ---- Feedback: «Сообщить / предложить» → the feedback table.
   If the table is not there yet (or the network is gone) the error
   is friendly and points at Yasha's Telegram instead. ---- */
var fbType = "bug";
function openFeedbackSheet(){
  var sh = $("#feedbackSheet"); if (!sh) return;
  var ta = $("#fbText"); if (ta) ta.placeholder = t("Опиши, что случилось или что хочешь предложить…");
  sh.hidden = false;
}
function closeFeedbackSheet(){ var sh = $("#feedbackSheet"); if (sh) sh.hidden = true; }
function submitFeedback(){
  var ta = $("#fbText");
  var txt = ta ? String(ta.value || "").trim() : "";
  if (!txt){ toast(t("Напиши хоть пару слов 🙂")); return; }
  var btn = $("#fbSend"); if (btn) btn.disabled = true;
  var done = function(ok){
    if (btn) btn.disabled = false;
    if (ok){
      if (ta) ta.value = "";
      closeFeedbackSheet();
      toast(t("Отправлено! Яша увидит это в базе 🙏"));
      fireConfetti();
    } else {
      toast(t("Не отправилось — нет связи с базой. Напиши Яше напрямую: @black_prince_18"));
    }
  };
  if (typeof db === "undefined" || !db){ done(false); return; }
  try {
    db.from("feedback").insert({ user_id: (typeof cloudUser !== "undefined" && cloudUser) ? cloudUser.id : null, type: fbType, text: txt, lang: LANG })
      .then(function(res){ done(!(res && res.error)); }, function(){ done(false); });
  } catch (e) { done(false); }
}
function bindV28Ui(){
  var st = $("#sndToggle");
  if (st) st.addEventListener("click", function(){
    soundOn = !soundOn; lsSet("tirada_sound_on", soundOn);
    musicArmed = true; /* the tap itself is the gesture */
    renderSoundBox(); applySoundState();
  });
  var mt = $("#musicToggle");
  if (mt) mt.addEventListener("click", function(){
    musicOn = !musicOn; lsSet("tirada_music_on", musicOn);
    musicArmed = true;
    renderSoundBox(); applySoundState();
  });
  var fb = $("#feedbackBtn");
  if (fb) fb.addEventListener("click", openFeedbackSheet);
  var fc = $("#feedbackClose");
  if (fc) fc.addEventListener("click", closeFeedbackSheet);
  var fsh = $("#feedbackSheet");
  if (fsh) fsh.addEventListener("click", function(e){ if (e.target === fsh) closeFeedbackSheet(); });
  var fs = $("#fbSend");
  if (fs) fs.addEventListener("click", submitFeedback);
  var ft = $("#fbTypes");
  if (ft) ft.addEventListener("click", function(e){
    var b = e.target && e.target.closest ? e.target.closest("[data-fbtype]") : null;
    if (!b) return;
    fbType = b.getAttribute("data-fbtype") || "bug";
    ft.querySelectorAll(".fb-type").forEach(function(x){ x.classList.toggle("sel", x === b); });
  });
}

tracePush("trace", "boot start");
bootStep("applyStaticI18n", applyStaticI18n);
bootStep("setAuthMode", function(){ if (typeof setAuthMode === "function") setAuthMode("in"); }); /* auth modal strings in the boot language too — atomic from the first paint */
bootStep("seedStatsWave3", seedStatsWave3);
bootStep("renderCityList", renderCityList);
bootStep("renderMyAvatar", renderMyAvatar);
bootStep("renderAvatarGrid", renderAvatarGrid);
bootStep("renderStats", renderStats);
/* The four surfaces whose death defined the v17/v18 bug paint BEFORE
   the heavier work (tasks, route, map): whatever happens later in the
   boot, the header counter, the ticker, the city list and the avatar
   are already on screen. */
bootStep("updateCounter", updateCounter);
bootStep("buildTicker", buildTicker);
bootStep("renderTasks", renderTasks);
bootStep("loadAiDay", loadAiDay);
bootStep("nickInit", function(){
  var nickInit = $("#nickInput"); if (nickInit) nickInit.value = state.nick || "";
});
/* Core UI first, map LAST: the counter, ticker, places list and route
   must be alive even if map initialisation fails outright (it is fully
   guarded now, but boot order is the second line of defence — a dead
   map must never again take the header and the list down with it). */
bootStep("renderFilter", renderFilter);
bootStep("renderPlaces", renderPlaces);
bootStep("refreshCityPhotoCount", refreshCityPhotoCount);
bootStep("buildRoute", buildRoute);
bootStep("initMap", initMap);
bootStep("requestGeo", function(){ requestGeo(false); });
bootStep("welcome", function(){
  if (!lsGet("tirada_welcomed", false) && !location.hash){
    renderWelcomeCities();
    setTimeout(function(){ $("#welcomeSheet").hidden = false; }, 500);
  }
});
/* Deep links: #places #route #profile #map #deal #city=eilat — used by
   previews/screenshots AND by push notifications (v23): the service
   worker navigates/focuses the app to index.html#<screen> per event
   type, and the hashchange listener below makes that navigation land
   on the right screen even when the app is already open (a hash-only
   navigation does not reboot the page, so boot alone is not enough). */
function applyDeepLink(fromBoot){
  var h = location.hash || "";
  if (!h) return;
  if (fromBoot) document.body.classList.add("shots");
  var cm = h.match(/city=([a-z]+)/);
  if (cm && PLACES_BY_CITY[cm[1]]) setCity(cm[1]);
  var vm = h.match(/vote=([a-z0-9,\-]+)/);
  if (vm) state.voteLink = vm[1].split(",").filter(Boolean);
  if (h.indexOf("places") >= 0) showScreen("places");
  else if (h.indexOf("route") >= 0) showScreen("route");
  else if (h.indexOf("profile") >= 0) showScreen("profile");
  else if (h.indexOf("map") >= 0) showScreen("map");
  if (h.indexOf("deal") >= 0) openDeal();
}
bootStep("v28init", function(){
  applySkyPhase();
  renderStreakChip();
  renderSoundBox();
  armSoundOnFirstGesture();
  bindV28Ui();
  loadWeather();
});
bootStep("deepLink", function(){ applyDeepLink(true); });
window.addEventListener("hashchange", function(){
  try { applyDeepLink(false); } catch (e) { /* a bad hash must never break the app */ }
});
tracePush("boot", "complete, ok: " + bootStepOk.join(", ") + (bootStepFail.length ? " | FAILED: " + bootStepFail.join(", ") : ""));
/* Self-repair (v19): if anything in this environment still managed to
   leave a critical surface dead — a cache-stitched build the guard
   could not detect, a paint that never committed, an async wipe —
   revive it on the same load: once the window finishes loading, and
   once more on a 3 s watchdog. repaintCoreSurfaces() only touches
   surfaces that are actually dead and traces what it revived. */
if (document.readyState === "complete") repaintCoreSurfaces("window-load");
else window.addEventListener("load", function(){ repaintCoreSurfaces("window-load"); });
setTimeout(function(){ repaintCoreSurfaces("watchdog-3s"); }, 3000);
/* v20: two more revival points, aimed at how the v19 live check actually
   failed — the page was painted in a throttled/background browser where
   first paints and image loads never committed until an interaction.
   The late pass also forces the avatar repair: a face image still
   pending after 8 s is treated as never-arriving and swapped for the
   always-renderable glyph. Becoming visible again re-checks everything
   for the same reason. */
setTimeout(function(){ repaintCoreSurfaces("watchdog-8s"); repairAvatarFace(true); }, 8000);
/* v28 — ONE resume path for every return (visibility, bfcache
   pageshow, focus): repaint dead surfaces, resume the single
   ticker cycle, refresh the avatar node and the sky phase. It
   starts NO other loop and re-runs NO boot step: every periodic
   loop in the app is a guarded single instance (heartbeat, friend
   map, route dash, heat tick, ticker fade), so a resume can never
   stack a second copy of anything — the «effects ×10» failure of
   the push-entry path. While hidden, the visual loops pause. */
function onAppResume(why){
  repaintCoreSurfaces(why);
  startTickerFade();
  try { renderMyAvatar(); } catch (e) {}
  try { applySkyPhase(); } catch (e) {}
  try {
    var rc = $("#routeChip");
    if (rc && !rc.hidden && map && mapReady) startRouteDash();
  } catch (e) {}
}
document.addEventListener("visibilitychange", function(){
  if (document.hidden){ stopTickerFade(); stopRouteDash(); }
  else onAppResume("visible-again");
});
window.addEventListener("pageshow", function(e){ if (e.persisted) onAppResume("pageshow"); });
window.addEventListener("focus", function(){ startTickerFade(); });
})();

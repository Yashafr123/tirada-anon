/* ===== TiradA anon — preview v2 (demo data, all Israel) ===== */
(function(){
"use strict";

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
   circles while the CDN wakes up. */
AVATARS.forEach(function(av){ var im = new Image(); im.src = emojiUrl(av.e); });
function avatarFace(idx){
  var av = AVATARS[idx % AVATARS.length];
  return '<span class="avface" style="background:' + av.bg + '">' + emojiImg(av.e, "avimg") + '</span>';
}
/* CDN fallback: if an emoji image fails, swap it for the font glyph */
document.addEventListener("error", function(ev){
  var t = ev.target;
  if (t && t.tagName === "IMG" && t.getAttribute("data-emoji")){
    var s = document.createElement("span");
    s.className = t.className + " avfont";
    s.textContent = t.getAttribute("data-emoji");
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
    ["Парк «Ямит»","park",42],["Кафе «Соколь»","cafe",44],["Бар «Холон Найт»","bar",57]
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
    ["Парк «Кфар-Саба»","park",41],["Кафе «Вайцман»","cafe",46],["Бар «Саба Найт»","bar",55]
  ],
  hadera: [
    ["Пляж «Гиват Ольга»","beach",67,32.4430,34.8850],["Парк «Нахаль Хадера»","park",42,32.4230,34.9330],
    ["Кафе «Герберт Самуэль»","cafe",44],["Бар «Хадера Найт»","bar",54]
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
    ["Парк «Ган а-Эмек»","park",36],["Бар «Эмек Найт»","bar",52]
  ],
  kiryatshmona: [
    ["Парк «Ган а-Захав»","park",44,33.2050,35.5680],["Смотровая «Манара»","view",40,33.1960,35.5450],
    ["Кафе «Шмона»","cafe",41],["Бар «Шмона Найт»","bar",50]
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
    ["Смотровая «Институт Вейцмана»","view",45,31.9070,34.8090],["Парк «Ган а-Мошава»","park",38],["Бар «Реховот Найт»","bar",58]
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
    ["Кафе «Рош»","cafe",43],["Бар «Рош Найт»","bar",52]
  ],
  givatayim: [
    ["Кафе «Вайцман»","cafe",49],["Смотровая «Планетарий»","view",43,32.0700,34.8050],
    ["Парк Гиватаима","park",41],["Бар «Гиватаим Найт»","bar",55]
  ],
  hodhasharon: [
    ["Парк «Ход-ха-Шарон»","park",47,32.1550,34.8850],["Кафе «Матаим»","cafe",45],["Бар «Ход Найт»","bar",53]
  ],
  kiryatata: [
    ["Маркет «Шаарей а-Кирья»","market",46],["Кафе «Ата»","cafe",42],["Парк «Ган а-Ир»","park",36],["Бар «Ата Найт»","bar",51]
  ],
  nahariya: [
    ["Пляж «Галей Галиль»","beach",70,33.0090,35.0910],["Променад «Гаатон»","prom",62,33.0080,35.0980],
    ["Кафе «Соколь»","cafe",47],["Бар «Нагария Найт»","bar",56]
  ],
  kiryatgat: [
    ["Маркет «Биг Гат»","market",48],["Кафе «Гат»","cafe",44],["Парк «Ган а-Шалом»","park",37],["Бар «Гат Найт»","bar",54]
  ],
  kiryatmotzkin: [
    ["Парк «Хай-Парк»","park",52,32.8440,35.0860],["Кафе «Моцкин»","cafe",44],["Бар «Моцкин Найт»","bar",53]
  ],
  kiryatbialik: [
    ["Парк «Эйн Афек»","park",45,32.8460,35.1120],["Кафе «Бялик»","cafe",43],["Бар «Бялик Найт»","bar",50]
  ],
  kiryatyam: [
    ["Пляж «Звулун»","beach",68,32.8510,35.0590],["Променад Кирьят-Ям","prom",55],["Кафе «Ям»","cafe",42]
  ],
  maaleadumim: [
    ["Кафе «Адумим»","cafe",44],["Смотровая «Музей Кастеля»","view",40,31.7720,35.2940],
    ["Парк «Ган а-Цви»","park",35],["Бар «Адумим Найт»","bar",51]
  ],
  netivot: [
    ["Маркет «Биг Нетивот»","market",47],["Кафе «Нетивот»","cafe",43],["Парк «Ган а-Шалом»","park",34],["Бар «Нетивот Найт»","bar",52]
  ],
  arad: [
    ["Кафе «Муза»","cafe",52,31.2610,35.2130],["Смотровая «Мицпе Моав»","view",44,31.2550,35.2350],
    ["Парк «Ган а-Шалом»","park",33],["Бар «Арад Найт»","bar",49]
  ],
  ofakim: [
    ["Парк Офаким","park",38,31.3140,34.6220],["Кафе «Офаким»","cafe",41],["Бар «Офаким Найт»","bar",50]
  ],
  yehud: [
    ["Кафе «Йехуд»","cafe",44],["Парк «Ган а-Ир»","park",35],["Бар «Йехуд Найт»","bar",51]
  ],
  oryehuda: [
    ["Кафе «Ор»","cafe",43],["Парк «Ган а-Тайасим»","park",36],["Бар «Ор Найт»","bar",50]
  ],
  nesciona: [
    ["Маркет «Биг Нес-Циона»","market",49],["Кафе «Нес»","cafe",47],["Парк «Ган а-Мошава»","park",38],["Бар «Нес Найт»","bar",55]
  ],
  elad: [
    ["Кафе «Эльад»","cafe",40],["Парк Эльада","park",36],["Бар «Эльад Найт»","bar",47]
  ],
  ramathasharon: [
    ["Кафе «Соколь»","cafe",51,32.1460,34.8410],["Парк «Ган а-Неве»","park",39],["Бар «Шарон Найт»","bar",56]
  ],
  tira: [
    ["Кафе «Тира»","cafe",46],["Кальянная «Тира»","hookah",50],["Парк «Ган а-Ир»","park",35]
  ],
  arraba: [
    ["Кафе «Аррабе»","cafe",43],["Кальянная «Аррабе»","hookah",48],["Парк «Оливковая роща»","park",34]
  ],
  sderot: [
    ["Кафе «Сдерот»","cafe",44],["Парк «Ган а-Музика»","park",36],["Бар «Сдерот Найт»","bar",51]
  ],
  tayibe: [
    ["Кафе «Тайбе»","cafe",45],["Кальянная «Тайбе»","hookah",49],["Парк «Ган а-Ир»","park",34]
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
    ["Кафе «Умм»","cafe",45],["Смотровая «Джебель Искандар»","view",43,32.5230,35.1560],["Парк «Ган а-Ир»","park",33]
  ],
  tamra: [
    ["Кафе «Тамра»","cafe",43],["Кальянная «Тамра»","hookah",47],["Парк «Ган а-Ир»","park",33]
  ],
  beeryaakov: [
    ["Кафе «Беэр»","cafe",42],["Парк «Ган а-Мошава»","park",35],["Бар «Беэр Найт»","bar",49]
  ],
  kiryatmalakhi: [
    ["Кафе «Малахи»","cafe",42],["Парк «Ган а-Ир»","park",34],["Бар «Малахи Найт»","bar",50]
  ],
  yokneam: [
    ["Кафе «Йокнеам»","cafe",44],["Смотровая «Тель Йокнеам»","view",39,32.6650,35.1080],["Парк «Ган а-Ир»","park",35]
  ],
  kafrqasim: [
    ["Кафе «Касем»","cafe",43],["Кальянная «Касем»","hookah",47],["Парк «Ган а-Шалом»","park",33]
  ],
  qalansawa: [
    ["Кафе «Калансуа»","cafe",42],["Кальянная «Калансуа»","hookah",46],["Парк «Ган а-Ир»","park",32]
  ],
  ariel: [
    ["Кафе «Ариэль»","cafe",43],["Смотровая «Ариэль»","view",40,32.1060,35.1840],["Парк «Ган а-Ир»","park",34]
  ],
  maalot: [
    ["Парк «Озеро Монфорт»","park",46,33.0070,35.2860],["Кафе «Маалот»","cafe",42],["Смотровая «Монфорт»","view",41,33.0430,35.2250]
  ],
  mitzperamon: [
    ["Смотровая «Махтеш Рамон»","view",58,30.6110,34.8020],["Променад «Альберт»","prom",50,30.6100,34.8000],["Кафе «Ха-Махтеш»","cafe",45]
  ],
  migdalhaemek: [
    ["Кафе «Мигдаль»","cafe",41],["Парк «Ган а-Ир»","park",34],["Бар «Мигдаль Найт»","bar",49]
  ],
  nofhagalil: [
    ["Кафе «Ноф»","cafe",43],["Смотровая «Гора Двора»","view",40,32.7000,35.3550],["Парк «Ган а-Цви»","park",34]
  ],
  rahat: [
    ["Рынок Рахата","market",48,31.3930,34.7550],["Кафе «Рахат»","cafe",42],["Парк «Ган а-Шалом»","park",32]
  ],
  baqa: [
    ["Кафе «Бака»","cafe",43],["Кальянная «Бака»","hookah",46],["Парк «Ган а-Ир»","park",33]
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
    ["Парк «Висячие мосты»","park",47,32.7630,35.0500],["Кафе «Нешер»","cafe",42],["Бар «Нешер Найт»","bar",50]
  ],
  kfaryona: [
    ["Кафе «Йона»","cafe",42],["Парк «Ган а-Йона»","park",35],["Бар «Йона Найт»","bar",49]
  ],
  harish: [
    ["Кафе «Хариш»","cafe",41],["Парк «Ган а-Ир»","park",34],["Бар «Хариш Найт»","bar",48]
  ],
  modiinillit: [
    ["Кафе «Модиин-Илит»","cafe",37],["Парк «Ган а-Ир»","park",31]
  ],
  beitarillit: [
    ["Кафе «Бейтар»","cafe",38],["Парк «Ган а-Ир»","park",32],["Смотровая «Гиват а-Бейтар»","view",30]
  ],
  givatshmuel: [
    ["Кафе «Гиват»","cafe",46],["Парк «Ган а-Шмуэль»","park",37],["Бар «Шмуэль Найт»","bar",52]
  ],
  ganeitikva: [
    ["Кафе «Ганей»","cafe",44],["Парк «Ган а-Ир»","park",36],["Бар «Ганей Найт»","bar",50]
  ],
  tiratcarmel: [
    ["Пляж «Тират-Кармель»","beach",64,32.7570,34.9550],["Кафе «Тират»","cafe",42],["Парк «Ган а-Ир»","park",34]
  ]
};

function buildPlaces(city){
  if (city.id === "karmiel"){
    return KARMIEL_PLACES.map(function(p,i){
      var t = TYPES[p.type];
      return { id:"karmiel-"+i, name:p.name, type:p.type, typeLabel:p.typeLabel || t.label,
        lat:p.lat, lng:p.lng, heat:p.heat, rating:p.rating, tags:p.tags, song:p.song, task:p.task,
        art:p.art || t.art, grad:t.grad };
    });
  }
  var raw = RAW[city.id] || [];
  return raw.map(function(r,i){
    var t = TYPES[r[1]];
    var rand = rng(hashStr(city.id + "|" + r[0]));
    var lat = (typeof r[3] === "number") ? r[3] : city.lat + (rand() - 0.5) * 0.042;
    var lng = (typeof r[4] === "number") ? r[4] : city.lng + (rand() - 0.5) * 0.052;
    var rating = Math.round((4.2 + rand() * 0.7) * 10) / 10;
    var song = t.songs[Math.floor(rand() * t.songs.length)];
    var task = t.tasks[Math.floor(rand() * t.tasks.length)];
    return { id:city.id + "-" + i, name:r[0], type:r[1], typeLabel:t.label,
      lat:lat, lng:lng, heat:r[2], rating:rating, tags:t.tags.slice(), song:song, task:task,
      art:t.art, grad:t.grad };
  });
}
var PLACES_BY_CITY = {};
CITIES.forEach(function(c){ PLACES_BY_CITY[c.id] = buildPlaces(c); });

/* ================= State & helpers ================= */
function lsGet(k, d){ try { var v = localStorage.getItem(k); return v ? JSON.parse(v) : d; } catch(e){ return d; } }
function lsSet(k, v){ try { localStorage.setItem(k, JSON.stringify(v)); } catch(e){} }
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
  stats: lsGet("tirada_stats", { nights: 0, places: [], routes: 0, lastDealDay: "" }),
  vote: lsGet("tirada_vote", null),
  voteLink: null,
  routeDone: lsGet("tirada_route_done", {}),
  geo: null
};
function places(){ return PLACES_BY_CITY[state.city.id]; }
function $(s){ return document.querySelector(s); }
function $$(s){ return Array.prototype.slice.call(document.querySelectorAll(s)); }
function heatClass(h){ return h>=70 ? "hot" : (h>=40 ? "mid" : "low"); }
function heatLabel(h){ return h>=70 ? "🔥 жарко" : (h>=40 ? "средне" : "пусто"); }
function distKm(a,b){
  var R=6371, dLat=(b.lat-a.lat)*Math.PI/180, dLng=(b.lng-a.lng)*Math.PI/180;
  var x=Math.sin(dLat/2)*Math.sin(dLat/2)+Math.cos(a.lat*Math.PI/180)*Math.cos(b.lat*Math.PI/180)*Math.sin(dLng/2)*Math.sin(dLng/2);
  return R*2*Math.atan2(Math.sqrt(x),Math.sqrt(1-x));
}
function fmtDist(km){ return km<1 ? Math.round(km*1000)+" м" : km.toFixed(1).replace(".",",")+" км"; }
function fmtRating(r){ return String(r).replace(".",","); }
function mePos(){
  if (state.geo) return state.geo; /* real position when geolocation is granted */
  return { lat: state.city.lat + 0.0022, lng: state.city.lng + 0.0022 };
}

/* ================= Stable heat =================
   Heat is a deterministic function of the place id and the current
   15-minute window: it does NOT jump on re-renders or reloads inside the
   window, the fake-live drift is the same ±2 everywhere, and every
   counter/card/popup reads the number from this one source. */
function heatWindow(){ return Math.floor(Date.now() / 900000); }
function heatOf(p){
  var drift = (hashStr(p.id + "@" + heatWindow()) % 5) - 2;
  return Math.max(6, Math.min(97, p.heat + drift));
}

/* ================= Russian plurals ================= */
function pluralRu(n, forms){
  var m10 = n % 10, m100 = n % 100;
  if (m10 === 1 && m100 !== 11) return forms[0];
  if (m10 >= 2 && m10 <= 4 && (m100 < 10 || m100 >= 20)) return forms[1];
  return forms[2];
}
function hotWord(n){ return pluralRu(n, ["место жаркое", "места жарких", "мест жарких"]); }
function placeWord(n){ return pluralRu(n, ["место", "места", "мест"]); }

/* Honest distance label: straight-line, and says from whom */
function distFromText(p){
  return (state.geo ? "от тебя" : "от центра города") + " · по прямой: " + fmtDist(distKm(mePos(), p));
}

/* ================= Place details (demo data, deterministic) ================= */
var STREET_POOL = ["ул. Герцль","ул. Вайцман","ул. Бен-Гурион","ул. Жаботински","ул. Бялик","ул. Соколов","ул. Ротшильд","ул. Дизенгоф","ул. Аленби","ул. Левински"];
function placeAddress(p){
  var r = rng(hashStr("addr|" + p.id));
  return STREET_POOL[Math.floor(r() * STREET_POOL.length)] + ", " + (1 + Math.floor(r() * 120));
}
var HOURS = { bar:[18,3], club:[21,4], cafe:[8,23], beach:[0,24], park:[6,23], view:[0,24], prom:[0,24], roof:[17,2], hookah:[16,2], stage:[10,22], market:[7,19] };
function fmtHour(h){ h = ((h % 24) + 24) % 24; return (h < 10 ? "0" : "") + h + ":00"; }
function hoursText(p){
  var hh = HOURS[p.type] || [9,22];
  if (hh[0] === 0 && hh[1] === 24) return "Круглосуточно";
  return fmtHour(hh[0]) + "–" + fmtHour(hh[1]);
}
function openStatus(p){
  var hh = HOURS[p.type] || [9,22], o = hh[0], c = hh[1];
  if (o === 0 && c === 24) return { open: true, text: "Открыто сейчас · круглосуточно" };
  var d = new Date(), now = d.getHours() + d.getMinutes() / 60, open;
  if (c > o) open = (now >= o && now < c); else open = (now >= o || now < c);
  if (open) return { open: true, text: "Открыто сейчас · до " + fmtHour(c) };
  return { open: false, text: "Откроется в " + fmtHour(o) };
}
var PRICES = { bar:"₪₪", club:"₪₪₪", cafe:"₪", beach:"Бесплатно", park:"Бесплатно", view:"Бесплатно", prom:"Бесплатно", roof:"₪₪₪", hookah:"₪₪", stage:"₪₪", market:"₪" };
function priceOf(p){ return PRICES[p.type] || "₪"; }
function isFree(p){ return priceOf(p) === "Бесплатно"; }
function ageOf(p){ return (p.type === "bar" || p.type === "club" || p.type === "roof") ? "18+" : "Можно всем"; }

/* ================= Favorites & personal stats (local, from real actions) ================= */
function saveStats(){ lsSet("tirada_stats", state.stats); scheduleCloudSync(); }
function toggleFav(id){
  if (state.favs[id]) delete state.favs[id]; else state.favs[id] = 1;
  lsSet("tirada_favs", state.favs);
  scheduleCloudSync();
  renderPlaces();
  toast(state.favs[id] ? "Добавлено в избранное ❤️" : "Убрано из избранного");
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
function renderStats(){
  var nEl = $("#statNights"), pEl = $("#statPlaces"), rEl = $("#statRoutes"), box = $("#achievements");
  if (!nEl) return;
  var np = state.stats.places.length;
  nEl.textContent = state.stats.nights;
  pEl.textContent = np;
  rEl.textContent = state.stats.routes;
  if (!box) return;
  var ach = [
    { icon:"🏆", name:"Первый движ", have: np >= 1, need: "открой первое место" },
    { icon:"🗺️", name:"Исследователь", have: np >= 5, need: "ещё " + (5 - np) + " " + placeWord(Math.max(0, 5 - np)) },
    { icon:"🔥", name:"7 ночей в деле", have: state.stats.nights >= 7, need: "ещё " + (7 - state.stats.nights) + " ночей" },
    { icon:"🏅", name:"Квест недели", have: lsGet("tirada_quest_badges", 0) >= 1, need: "пройди квест недели на экране «Маршрут»" }
  ];
  box.innerHTML = ach.map(function(a){
    return '<span class="achip' + (a.have ? "" : " locked") + '">' + a.icon + " " + a.name +
      (a.have ? "" : '<small>не хватает: ' + a.need + "</small>") + "</span>";
  }).join("");
}

/* ================= Place detail sheet ================= */
function openPlaceSheet(p){
  if (!p) return;
  markPlaceOpened(p.id);
  var h = heatOf(p), st = openStatus(p), fav = !!state.favs[p.id];
  $("#placeSheetBody").innerHTML =
    '<div class="ps-art" style="background:' + p.grad + '">' + emojiImg(p.art, "ps-art-img") +
      '<button class="sheet-close ps-close" id="psClose" aria-label="Закрыть">✕</button>' +
      '<span class="art-heat ' + heatClass(h) + '">' + heatLabel(h) + " · " + h + "%</span></div>" +
    '<div class="ps-body">' +
      '<div class="ps-name">' + p.name + "</div>" +
      '<div class="ps-sub">' + p.typeLabel + " · ★ " + fmtRating(p.rating) + "</div>" +
      '<div class="ps-open ' + (st.open ? "is-open" : "is-closed") + '">' + st.text + "</div>" +
      '<div class="ps-rows">' +
        '<div class="ps-row"><span>📍 Адрес</span><b>' + placeAddress(p) + ", " + state.city.name + "</b></div>" +
        '<div class="ps-row"><span>🕐 Часы</span><b>' + hoursText(p) + "</b></div>" +
        '<div class="ps-row"><span>💸 Цены</span><b>' + priceOf(p) + "</b></div>" +
        '<div class="ps-row"><span>🔞 Возраст</span><b>' + ageOf(p) + "</b></div>" +
        '<div class="ps-row"><span>📏 Расстояние</span><b>' + distFromText(p) + "</b></div>" +
        '<div class="ps-row"><span>♪ Звучит</span><b>' + p.song + "</b></div>" +
      "</div>" +
      '<div class="ps-task">🎯 ' + p.task + "</div>" +
      '<div class="ps-actions">' +
        '<button class="btn-yes" id="psRoute">🚗 Маршрут</button>' +
        '<button class="btn-alt ps-fav' + (fav ? " active" : "") + '" id="psFav">' + (fav ? "❤️ В избранном" : "🤍 В избранное") + "</button>" +
      "</div>" +
    "</div>";
  $("#placeSheet").hidden = false;
  $("#psClose").addEventListener("click", closePlaceSheet);
  $("#psRoute").addEventListener("click", function(){ closePlaceSheet(); routeTo(p); });
  $("#psFav").addEventListener("click", function(){ toggleFav(p.id); openPlaceSheet(p); });
}
function closePlaceSheet(){ $("#placeSheet").hidden = true; }
function openPlaceSheetById(id){
  var f = findPlace(id);
  if (!f) return;
  if (f.cityId !== state.city.id) setCity(f.cityId);
  openPlaceSheet(f.place);
}
$("#placeSheet").addEventListener("click", function(e){ if (e.target === this) closePlaceSheet(); });

/* ================= My avatar: emoji face or own photo ================= */
function currentAvatarHtml(){
  if (state.avatarUrl) return '<img class="avphoto" src="' + state.avatarUrl + '" alt="Аватарка призрака">';
  if (state.avatarPhoto) return '<img class="avphoto" src="' + state.avatarPhoto + '" alt="Аватарка призрака">';
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
  }, function(){}, { enableHighAccuracy: false, maximumAge: 60000, timeout: 20000 });
}
function applyGeo(lat, lng){
  state.geo = { lat: lat, lng: lng };
  var gb = $("#geoBtn"); if (gb) gb.hidden = true;
  var near = nearestCity(state.geo);
  if (near && near.id !== state.city.id && distKm(state.geo, near) <= 30) setCity(near.id);
  if (meMarker) meMarker.setLngLat([lng, lat]);
  if (map) map.flyTo({ center: [lng, lat], zoom: Math.max(map.getZoom(), 15), duration: 800 });
  startGeoWatch();
}
function requestGeo(manual){
  if (!navigator.geolocation){
    if (manual) toast("Геолокация недоступна — демо-режим 👻");
    return;
  }
  navigator.geolocation.getCurrentPosition(function(pos){
    applyGeo(pos.coords.latitude, pos.coords.longitude);
  }, function(){
    if (manual || !geoToastShown){ toast("Геолокация выключена — демо-режим 👻"); geoToastShown = true; }
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
var map = null, mapReady = false, meMarker = null, placeMarkers = {}, badgeMarkers = [];

/* Map markers v3.6 (Snap Map style): places = small round badges by heat with a white
   SVG icon of the place type; the ONLY ghost on the map is you — a round avatar
   (Emoji CDN face on a gradient). No demo people. */
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
  el.innerHTML = ghostHtml();
  return el;
}
function updateMeMarker(){
  if (meMarker) meMarker.getElement().innerHTML = ghostHtml();
}
function myPopupHtml(){
  return '<div class="pop-name">Это ты — призрак</div>' +
    '<div class="pop-status">' + MODES[state.mode].mapStatus + '</div>' +
    '<div class="pop-note">Сменить вид и режим — на экране «Профиль».</div>';
}
function popupHtml(p){
  var h = heatOf(p);
  return '<div class="pop-name">' + p.name + '</div>' +
    '<div><span class="pop-heat">' + heatLabel(h) + '</span> · движ ' + h + '%</div>' +
    '<div>★ ' + fmtRating(p.rating) + ' · ' + distFromText(p) + '</div>' +
    '<div class="pop-song">♪ ' + p.song + '</div>' +
    '<button class="pop-btn route-btn" data-route-place="' + p.id + '">🚗 Маршрут сюда</button>' +
    '<button class="pop-btn" data-place-open="' + p.id + '">Смотреть место →</button>';
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
  PLACES_BY_CITY[city.id].forEach(function(p){
    p._band = heatClass(heatOf(p)); /* badge restyles only when the band flips */
    var m = new maplibregl.Marker({ element: badgeEl(p) })
      .setLngLat([p.lng, p.lat])
      .setPopup(makePopup(popupHtml(p), 20))
      .addTo(map);
    badgeMarkers.push(m);
    if (city.id === state.city.id) placeMarkers[p.id] = m;
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
  /* Country dots: every place of every city as one GeoJSON circle layer */
  var feats = [];
  CITIES.forEach(function(c){
    PLACES_BY_CITY[c.id].forEach(function(p){
      feats.push({
        type: "Feature",
        geometry: { type: "Point", coordinates: [p.lng, p.lat] },
        properties: { id: p.id, name: p.name, city: c.name, heat: heatOf(p), band: heatClass(heatOf(p)) }
      });
    });
  });
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
  map.on("click", "places-dots", function(e){
    var f = e.features && e.features[0];
    if (!f) return;
    var pr = f.properties;
    if (dotPopup) dotPopup.remove();
    dotPopup = makePopup('<div class="pop-name">' + pr.name + '</div><div>' + pr.city + ' · движ ' + pr.heat + '%</div>' +
      '<button class="pop-btn" data-place-open="' + pr.id + '">Смотреть место →</button>', 12);
    dotPopup.setLngLat(f.geometry.coordinates).addTo(map);
  });
  map.on("mouseenter", "places-dots", function(){ map.getCanvas().style.cursor = "pointer"; });
  map.on("mouseleave", "places-dots", function(){ map.getCanvas().style.cursor = ""; });
  /* Route layers (OSRM): white casing, neon red line, flowing dot pulse */
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
  refreshMapMode();
}
function initMap(){
  if (typeof maplibregl === "undefined" || !window.TIRADA_MAP_STYLE){
    $("#map").innerHTML = '<div style="padding:24px;color:#a3a3ad;font-size:14px">Карта не загрузилась (нет сети) — но места на экране «Места» на месте.</div>';
    return;
  }
  map = new maplibregl.Map({
    container: "map",
    style: window.TIRADA_MAP_STYLE,
    bounds: [[34.05, 29.45], [35.95, 33.35]], /* whole country first: Israel dotted with places; zoom into a city for badges */
    fitBoundsOptions: { padding: 8 },
    minZoom: 6, maxZoom: 18,
    attributionControl: false, /* no attribution bar (Yasha's call) */
    dragRotate: false, pitchWithRotate: false, touchPitch: false,
    fadeDuration: 0
  });
  window.__tiradaMap = map; /* audit/debug hook */
  map.touchZoomRotate.disableRotation();
  map.scrollZoom.disable();
  map.getContainer().addEventListener("focusin", function(){ map.scrollZoom.enable(); });
  map.getContainer().addEventListener("focusout", function(){ map.scrollZoom.disable(); });
  map.on("load", initMapLayers);
  setTimeout(function(){ if (!mapReady && map.isStyleLoaded()) initMapLayers(); }, 3000);
  var me = mePos();
  meMarker = new maplibregl.Marker({ element: ghostEl() })
    .setLngLat([me.lng, me.lat])
    .setPopup(makePopup(myPopupHtml(), 30))
    .addTo(map);
  /* tap on your own avatar = center on yourself + refresh REAL geolocation */
  meMarker.getElement().addEventListener("click", function(){
    var p = mePos();
    map.flyTo({ center: [p.lng, p.lat], zoom: Math.max(map.getZoom(), 15), duration: 700 });
    requestGeo(true);
  });
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
  if (min < 60) return Math.max(1, Math.round(min)) + " мин";
  return Math.floor(min / 60) + " ч " + Math.round(min % 60) + " мин";
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
  showRouteChip("Строю маршрут…", "до «" + place.name + "»");
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
        tm.label + " до «" + place.name + "»");
    })
    .catch(function(){
      if (timer) clearTimeout(timer);
      if (req !== routeReq) return;
      drawRouteLine(buildArc(me, place));
      showRouteChip("По прямой: " + fmtDist(distKm(me, place)),
        "до «" + place.name + "» · дороги сейчас недоступны");
    });
}
$("#routeChipX").addEventListener("click", function(){ clearRoute(); });

/* ================= Places feed ================= */
function renderFilter(){
  var present = {};
  places().forEach(function(p){ present[p.type] = true; });
  var chips = ['<button class="filter-chip' + (state.filter === "all" ? " active" : "") + '" data-type="all">Все</button>'];
  chips.push('<button class="filter-chip' + (state.filter === "fav" ? " active" : "") + '" data-type="fav">❤️ Избранное</button>');
  chips.push('<button class="filter-chip' + (state.filter === "free" ? " active" : "") + '" data-type="free">🆓 Бесплатно</button>');
  Object.keys(TYPES).forEach(function(k){
    if (present[k]) chips.push('<button class="filter-chip' + (state.filter === k ? " active" : "") + '" data-type="' + k + '">' + TYPES[k].label + '</button>');
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
  var h = heatOf(p), hc = heatClass(h);
  var badge = (p.id === TOP_ID) ? '<span class="art-badge">👑 ТОП движа</span>'
    : (h >= 85 ? '<span class="art-badge heat-badge">⚡ Сейчас жарко</span>' : '');
  var fav = !!state.favs[p.id];
  return '<article class="place-card' + (p.id === TOP_ID ? ' top-card' : '') + '" data-id="' + p.id + '" style="animation-delay:' + (Math.min(i, 10) * 0.06).toFixed(2) + 's">' +
    '<div class="place-art" style="background:' + p.grad + '">' + emojiImg(p.art, "art-img") + badge +
    '<button class="fav-btn' + (fav ? " active" : "") + '" data-fav="' + p.id + '" aria-label="В избранное">' + (fav ? "❤️" : "🤍") + '</button>' +
    '<span class="art-heat ' + hc + '">' + heatLabel(h) + ' · ' + h + '%</span></div>' +
    '<div class="place-body">' +
      '<div class="place-top"><div><div class="place-name">' + p.name + '</div>' +
      '<div class="place-type">' + p.typeLabel + ' · ' + distFromText(p) + '</div></div>' +
      '<div class="place-rating">★ ' + fmtRating(p.rating) + '</div></div>' +
      '<div class="heat-row"><div class="heat-bar"><div class="heat-fill ' + hc + '" style="width:' + h + '%"></div></div>' +
      '<div class="heat-label ' + hc + '">' + heatLabel(h) + ' · ' + h + '%</div></div>' +
      '<div class="tags">' + p.tags.map(function(t){ return '<span class="tag">' + t + '</span>'; }).join("") + '</div>' +
      '<div class="song">♪ <b>' + p.song + '</b> — звучит в этом месте</div>' +
      '<button class="btn-route-to" data-route-card="' + p.id + '">🚗 Маршрут</button>' +
    '</div></article>';
}
function renderPlaces(){
  TOP_ID = hottest()[0] ? hottest()[0].id : null;
  var all = places();
  var list = all.slice();
  if (state.filter === "fav") list = list.filter(function(p){ return !!state.favs[p.id]; });
  else if (state.filter === "free") list = list.filter(isFree);
  else if (state.filter !== "all") list = list.filter(function(p){ return p.type === state.filter; });
  if (state.search) list = list.filter(function(p){ return p.name.toLowerCase().indexOf(state.search) >= 0; });
  if (state.sort === "near") list.sort(function(a,b){ return distKm(mePos(), a) - distKm(mePos(), b); });
  else if (state.sort === "rating") list.sort(function(a,b){ return b.rating - a.rating; });
  else list.sort(function(a,b){ return heatOf(b) - heatOf(a); });
  $("#placesCount").textContent = "Показано " + list.length + " из " + all.length + " · " + state.city.name;
  if (!list.length){
    $("#placesList").innerHTML = '<div class="places-empty">' +
      (state.filter === "fav" ? "Избранное пока пусто 👻<br>Тапни 🤍 на карточке места — и оно будет жить здесь."
        : "В этой подборке в городе " + state.city.name + ' пока тихо 👻<br>Загляни в «Все» — движ точно где-то есть.') + "</div>";
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
  if (lbl){ lbl.textContent = heatLabel(h) + " · " + h + "%"; lbl.className = "heat-label " + hc; }
  if (art){ art.textContent = heatLabel(h) + " · " + h + "%"; art.className = "art-heat " + hc; }
}

/* ================= Counter & ticker ================= */
function hotCount(){ return places().filter(function(p){ return heatOf(p) >= 70; }).length; }
function updateCounter(){
  var hot = hotCount(), total = places().length;
  $("#counterText").innerHTML = "в городе: <b>" + hot + " " + hotWord(hot) + "</b> сейчас • всего " + total + " " + placeWord(total) + " на радаре";
}
function buildTicker(){
  var top = hottest();
  var items = [];
  if (top[0]) items.push("🔥 <i>" + top[0].name + "</i> сейчас на пике — движ " + heatOf(top[0]) + "%");
  items.push("📍 <i>" + state.city.name + "</i>: " + hotCount() + " " + hotWord(hotCount()) + " прямо сейчас");
  if (top[1]) items.push("⚡ <i>" + top[1].name + "</i> — движ " + heatOf(top[1]) + "%, почти пик");
  if (top[2]) items.push("♪ В <i>" + top[2].name + "</i> звучит " + top[2].song);
  if (top[0]) items.push("🌙 Маршрут на вечер по городу <i>" + state.city.name + "</i> уже собран");
  var html = items.map(function(t){ return '<span class="tick-item">' + t + '</span>'; }).join("");
  $("#tickerTrack").innerHTML = html + html;
}

/* ================= Fake-live heat =================
   Heat no longer mutates randomly: heatOf() derives it from the place id
   and the 15-minute window, so every surface shows the SAME number and it
   only changes when the window flips. This tick just re-syncs the DOM
   when a new window starts (and stays silent while the map is moving). */
var lastHeatWindow = heatWindow(), tickN = 0;
setInterval(function(){
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
  $("#modeStatusProfile").textContent = MODES[mode].status;
  if (meMarker){
    updateMeMarker();
    var mp = meMarker.getPopup();
    if (mp && mp.isOpen()) mp.setHTML(myPopupHtml());
  }
}
$$("[data-modeswitch] .mode-btn").forEach(function(btn){
  btn.addEventListener("click", function(){
    setMode(btn.getAttribute("data-mode"));
    if (state.mode === "offline") toast("Ты исчез с карты 👻");
    if (state.mode === "ghost") toast("Режим невидимки: ты — просто силуэт");
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
  if (nickEl) nickEl.textContent = state.nick || "Призрак";
  updateMeMarker();
}
function renderAvatarGrid(){
  var grid = $("#avatarGrid");
  if (!grid) return;
  var hasPhoto = !!(state.avatarUrl || state.avatarPhoto);
  var html = AVATARS.map(function(av, i){
    var sel = (!hasPhoto && state.myAvatar === i) ? " selected" : "";
    return '<button class="avatar-cell' + sel + '" data-avatar="' + i + '">' + avatarFace(i) + "</button>";
  }).join("");
  if (hasPhoto)
    html += '<button class="avatar-cell selected" data-avatar="photo"><img class="avphoto" src="' + (state.avatarUrl || state.avatarPhoto) + '" alt="Моё фото"></button>';
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
$("#avatarFile").addEventListener("change", function(){
  var file = this.files && this.files[0];
  this.value = "";
  if (!file) return;
  var url = URL.createObjectURL(file);
  var img = new Image();
  img.onload = function(){
    var S = 256, cv = document.createElement("canvas");
    cv.width = S; cv.height = S;
    var side = Math.min(img.width, img.height);
    cv.getContext("2d").drawImage(img, (img.width - side) / 2, (img.height - side) / 2, side, side, 0, 0, S, S);
    URL.revokeObjectURL(url);
    state.avatarPhoto = cv.toDataURL("image/jpeg", 0.85);
    lsSet("tirada_avatar_photo", state.avatarPhoto);
    renderMyAvatar(); renderAvatarGrid();
    toast("Фото-аватарка готова 👻 Она уже на карте");
    if (window.TiradaDB && typeof cloudUploadAvatar === "function"){
      cv.toBlob(function(blob){ if (blob) cloudUploadAvatar(blob); }, "image/jpeg", 0.85);
    }
  };
  img.onerror = function(){ URL.revokeObjectURL(url); toast("Не вышло прочитать фото"); };
  img.src = url;
});
/* ================= Nick validation =================
   A ghost name may be written in Russian, Hebrew or Latin letters —
   plus digits, a space, a hyphen and an underscore. Length 2–24.
   Anything else is rejected with a plain-language reason; characters
   are never silently stripped or cut. */
var NICK_RE = /^[A-Za-zА-Яа-яЁё\u0590-\u05FF0-9 _-]+$/;
function validateNick(raw){
  var v = (raw == null ? "" : String(raw)).trim();
  if (!v) return { ok: false, error: "Ник не может быть пустым" };
  if (v.length < 2) return { ok: false, error: "Ник слишком короткий — нужно минимум 2 символа" };
  if (v.length > 24) return { ok: false, error: "Ник слишком длинный — максимум 24 символа" };
  if (!NICK_RE.test(v)) return { ok: false, error: "В нике можно только буквы (русские, иврит или латиница), цифры, пробел, дефис и подчёркивание" };
  return { ok: true, value: v };
}
window.__validateNick = validateNick;
$("#nickInput").addEventListener("change", function(){
  if (!this.value.trim()){
    state.nick = "";
    this.value = "";
    lsSet("tirada_nick", state.nick);
    renderMyAvatar();
    scheduleCloudSync();
    renderAccount();
    toast("Ник сброшен");
    return;
  }
  var chk = validateNick(this.value);
  if (!chk.ok){
    toast(chk.error);
    this.value = state.nick || "";
    return;
  }
  state.nick = chk.value;
  this.value = state.nick;
  lsSet("tirada_nick", state.nick);
  renderMyAvatar();
  scheduleCloudSync();
  renderAccount();
  toast("Ник сохранён: " + state.nick);
});
$("#shareGeoBtn").addEventListener("click", function(){
  if (!state.geo){ toast("Сначала включи геолокацию"); return; }
  var link = "https://maps.google.com/?q=" + state.geo.lat + "," + state.geo.lng;
  if (navigator.share){
    navigator.share({ title: "Я здесь 👻", text: "Моя геопозиция в TiradA anon", url: link }).catch(function(){});
  } else if (navigator.clipboard) {
    navigator.clipboard.writeText(link).then(function(){ toast("Ссылка на геопозицию скопирована 📍"); }, function(){ toast(link); });
  } else toast(link);
});

/* ================= Tabs / screens ================= */
function showScreen(name){
  $$(".tab").forEach(function(t){ t.classList.toggle("active", t.getAttribute("data-screen") === name); });
  $$(".screen").forEach(function(s){ s.classList.toggle("active", s.id === "screen-" + name); });
  if (name === "map" && map) setTimeout(function(){ map.resize(); }, 60);
  if (name === "profile" && typeof cloudUser !== "undefined" && cloudUser) friendsLoad();
}
$$(".tab").forEach(function(t){
  t.addEventListener("click", function(){ showScreen(t.getAttribute("data-screen")); });
});

/* ================= City picker ================= */
function renderCityList(){
  var q = (($("#citySearch") && $("#citySearch").value) || "").trim().toLowerCase();
  var list = CITIES.filter(function(c){ return !q || c.name.toLowerCase().indexOf(q) >= 0; });
  $("#cityList").innerHTML = list.length ? list.map(function(c){
    var n = PLACES_BY_CITY[c.id].length;
    return '<button class="city-item' + (c.id === state.city.id ? " current" : "") + '" data-city="' + c.id + '">' +
      '<span>' + c.name + '</span><span class="city-item-meta">' + n + ' ' + placeWord(n) + (c.id === state.city.id ? " · ты здесь" : "") + '</span></button>';
  }).join("") : '<div class="places-empty">Город не нашёлся 👻</div>';
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
  $("#cityName").textContent = state.city.name;
  $("#routeCity").textContent = state.city.name;
  $("#citySheet").hidden = true;
  var cs = $("#citySearch"); if (cs) cs.value = "";
  renderFilter(); renderPlaces(); updateCounter(); buildTicker(); buildRoute();
  if (map){
    clearRoute();
    renderMapMarkers();
    map.flyTo({ center: [state.city.lng, state.city.lat], zoom: 13, duration: 1100 });
  }
  renderCityList();
  scheduleCloudSync();
  toast("Ты теперь призрак в городе " + state.city.name + " 👻");
}
$("#citySearch").addEventListener("input", function(){ renderCityList(); });
$("#cityBtn").addEventListener("click", function(){ $("#citySheet").hidden = false; });
$("#cityClose").addEventListener("click", function(){ $("#citySheet").hidden = true; });
$("#citySheet").addEventListener("click", function(e){ if (e.target === this) this.hidden = true; });

/* ================= Deal overlay ================= */
function hottest(){ return places().slice().sort(function(a,b){ return heatOf(b) - heatOf(a); }); }
/* Voting for the meetup place: the 3 hottest places of the city (or the 3
   from a shared #vote= link). Only YOUR honest local vote is stored and
   shown — no invented percentages, no fake friends' votes. */
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
  var mine = (state.vote && state.vote.cityId === state.city.id) ? state.vote.placeId : null;
  var mineName = null;
  cands.forEach(function(p){ if (p.id === mine) mineName = p.name; });
  return '<div class="vote-box"><h4>🗳️ Куда идём?</h4>' +
    '<div class="vote-list">' + cands.map(function(p){
      var cnt = (typeof cloudUser !== "undefined" && cloudUser)
        ? '<span class="vote-count" data-vcount="' + p.id + '">' + ((typeof cloudVoteCounts !== "undefined" && cloudVoteCounts && cloudVoteCounts[p.id]) || 0) + "</span>"
        : "";
      return '<button class="vote-btn' + (p.id === mine ? " chosen" : "") + '" data-vote="' + p.id + '">' +
        '<span>' + p.name + '</span>' + cnt + '<span class="vote-heat">' + heatOf(p) + "%</span></button>";
    }).join("") + "</div>" +
    (mineName
      ? '<div class="vote-mine">Твой голос: <b>' + mineName + "</b></div>"
      : '<div class="vote-mine dim">Тапни место — это будет твой голос</div>') +
    '<button class="btn-alt vote-share" id="voteShare">Позвать голосовать 👻</button></div>';
}
function renderDeal(place){
  $("#dealBody").innerHTML =
    '<div class="indeal-card">' +
    '<div class="deal-online" id="dealOnline"></div>' +
    '<div id="dealFriends"></div>' +
    '<div class="deal-empty" id="dealEmpty">' +
      '<div class="deal-empty-emoji">🤫</div>' +
      '<h4>Пока никто из твоих друзей не в деле</h4>' +
      '<p class="deal-empty-text">Здесь будут друзья-призраки, когда сами нажмут «Я в деле». Позови их — и вечер соберётся сам.</p>' +
      '<button class="btn-yes" id="dealInvite">Позвать друзей 👻</button>' +
    '</div>' +
    '<div class="deal-meet"><div style="text-align:center"><span class="deal-top-badge">🏆 Топ выбор радара</span></div>' +
    '<div class="meet-place">📍 А движ уже есть: ' + place.name + '</div>' +
    '<div class="meet-meta">Город ' + state.city.name + ' · сейчас там ' + heatLabel(heatOf(place)).replace("🔥 ","") + ' (движ ' + heatOf(place) + '%), ' +
      distFromText(place) + '. Можно стартовать отсюда — друзья подтянутся по ссылке.</div>' +
    '<div class="indeal-actions">' +
    '<button class="btn-route-deal" id="dealRoute">🚗 Маршрут</button>' +
    '<button class="btn-alt" id="dealAlt">Другое место</button></div></div>' +
    voteHtml() + '</div>';
  $("#dealInvite").addEventListener("click", function(){
    var shareData = {
      title: "TiradA anon",
      text: "Я в деле 👻 Собираемся: " + state.city.name + ", " + place.name + ". Залетай!",
      url: location.href
    };
    if (navigator.share){
      navigator.share(shareData).catch(function(err){
        if (!err || err.name !== "AbortError") toast("Ссылка-приглашение скоро появится 👻");
      });
    } else {
      toast("Ссылка-приглашение скоро появится 👻");
    }
  });
  $("#dealRoute").addEventListener("click", function(){ routeTo(place); });
  $("#dealAlt").addEventListener("click", function(){
    state.dealAlt++;
    renderDeal(hottest()[state.dealAlt % 3]);
  });
  $$("#dealBody [data-vote]").forEach(function(btn){
    btn.addEventListener("click", function(){
      state.vote = { cityId: state.city.id, placeId: btn.getAttribute("data-vote") };
      lsSet("tirada_vote", state.vote);
      cloudCastVote(state.vote.placeId);
      renderDeal(place);
      toast("Голос принят 🗳️");
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
      navigator.share({ title: "TiradA anon — голосуем", text: "Куда идём сегодня? Голосуй в TiradA anon 👻", url: url }).catch(function(){});
    } else if (navigator.clipboard) {
      navigator.clipboard.writeText(url).then(function(){ toast("Ссылка голосования скопирована 🗳️"); }, function(){ toast("Ссылка: " + url); });
    } else toast("Ссылка: " + url);
  });
}
function openDeal(){
  countDealNight();
  var fab = $("#fabDeal");
  if (fab){
    fab.classList.add("in-deal");
    var lb = fab.querySelector(".fab-label");
    if (lb) lb.textContent = "Ты в деле";
  }
  state.dealAlt = 0;
  $("#dealOverlay").hidden = false;
  $("#dealBody").innerHTML = '<div class="searching">Смотрю, где в городе ' + state.city.name + ' сейчас жарче всего<span class="dots"></span></div>';
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
  var all = places();
  var chill = all.filter(function(p){ return p.tags.indexOf("тихо") >= 0 || p.tags.indexOf("вкусно") >= 0; });
  var calm  = all.filter(function(p){ return p.tags.indexOf("романтика") >= 0; });
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
    { time:"19:30", place:take(chill, state.routeRound),     note:"Старт — спокойно зайти в вечер." },
    { time:"21:00", place:take(hot, state.routeRound),       note:"Пик ночи — туда, где жарче всего." },
    { time:"22:40", place:take(calm, state.routeRound + 1),  note:"Финал — красиво и без суеты." }
  ];
  /* Route tasks: bank = all type tasks (22) + ROUTE_TASKS (16) = 38 unique;
     inside one route a task never repeats. */
  var pool = [];
  Object.keys(TYPES).forEach(function(k){ TYPES[k].tasks.forEach(function(t){ pool.push(t); }); });
  ROUTE_TASKS.forEach(function(t){ pool.push(t); });
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
  if (el) el.textContent = "Выполнено " + routeDoneCount() + " из 3";
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
      html += '<div class="route-leg">' + tm.icon + " " + fmtDist(km) + " · ≈ " + fmtDur(mins) + (state.transport === "bus" ? " (примерно)" : "") + "</div>";
    }
    prev = s.place;
    html += '<div class="route-step" style="animation-delay:' + (i * 0.12).toFixed(2) + 's"><div class="route-dot">' + (i + 1) + '</div>' +
      '<div class="route-card"><div class="route-time">' + s.time + ' · ' + state.city.name + '</div>' +
      '<h4>' + emojiImg(s.place.art, "route-img") + ' ' + s.place.name + '</h4>' +
      '<div class="route-task">' + s.note + '<br>🎯 ' + (s.taskText || s.place.task) + '</div>' +
      '<label class="route-check"><input type="checkbox" data-task-check="' + i + '"' + (doneMap[i] ? " checked" : "") + '> Задание выполнено</label></div></div>';
  });
  var totalMin = travelMin + steps.length * 60;
  html += '<div class="route-total"><span id="routeProgress">Выполнено ' + routeDoneCount() + ' из 3</span> · в дороге ≈ ' + fmtDur(travelMin) +
    ' · весь вечер ≈ ' + fmtDur(totalMin) + ' (' + tm.label + ')</div>';
  $("#routeBox").innerHTML = html;
  $$("#routeBox [data-task-check]").forEach(function(cb){
    cb.addEventListener("change", function(){
      var key = routeKey();
      if (!state.routeDone[key]) state.routeDone[key] = {};
      state.routeDone[key][cb.getAttribute("data-task-check")] = cb.checked;
      lsSet("tirada_route_done", state.routeDone);
      renderRouteProgress();
      if (routeDoneCount() === 3) toast("Маршрут пройден полностью 🎉");
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
  var text = "🌙 Мой маршрут на вечер в TiradA anon (" + state.city.name + ", " + tm.label + "):\n" +
    state.routeSteps.map(function(s, i){ return (i + 1) + ". " + s.time + " — " + s.place.name; }).join("\n") +
    "\nЗалетай: " + location.origin + location.pathname + "#route";
  if (navigator.share){
    navigator.share({ title: "Маршрут на вечер — TiradA anon", text: text }).catch(function(){});
  } else if (navigator.clipboard) {
    navigator.clipboard.writeText(text).then(function(){ toast("Маршрут скопирован — отправь друзьям 📤"); }, function(){ toast("Не вышло поделиться"); });
  } else toast("Не вышло поделиться");
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
  "Сделай последнее фото вечера: вся компания и одна фраза, как прошла ночь"
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
    "Сделай финальное ночное фото компании в огнях города" ] }
];
function dayIndex(){ return Math.floor(Date.now() / 86400000); }
function todayKey(){ return new Date().toDateString(); }
function dailyTask(){ return DAILY_TASKS[dayIndex() % DAILY_TASKS.length]; }
function weekIndex(){ return Math.floor(dayIndex() / 7); }
function weekQuest(){ return WEEK_QUESTS[weekIndex() % WEEK_QUESTS.length]; }
function renderTasks(){
  var dt = $("#dailyTaskText"); if (!dt) return;
  dt.textContent = dailyTask();
  var st = lsGet("tirada_streak", { last: "", streak: 0 });
  var doneToday = (st.last === todayKey());
  var btn = $("#dailyDoneBtn");
  btn.disabled = doneToday;
  btn.textContent = doneToday ? "Выполнено ✓" : "Выполнено";
  btn.classList.toggle("done", doneToday);
  var line = "🔥 Серия: " + st.streak + " " + pluralRu(st.streak, ["день", "дня", "дней"]) + (doneToday ? " — так держать!" : " — отметь задание, чтобы серия росла");
  $("#streakLine").textContent = line;
  var ps = $("#profileStreak"); if (ps) ps.textContent = line;
  var q = weekQuest();
  $("#questTheme").textContent = q.theme;
  var qs = lsGet("tirada_quest", { week: -1, done: 0 });
  if (qs.week !== weekIndex()){ qs = { week: weekIndex(), done: 0 }; lsSet("tirada_quest", qs); }
  $("#questFill").style.width = (qs.done / q.steps.length * 100) + "%";
  $("#questProgressText").textContent = qs.done + " из " + q.steps.length;
  $("#questSteps").innerHTML = q.steps.map(function(s, i){
    var cls = i < qs.done ? "done" : (i === qs.done ? "current" : "locked");
    var btnHtml = i === qs.done ? '<button class="btn-alt quest-btn" data-quest-step="' + i + '">Готово</button>'
      : (i < qs.done ? '<span class="quest-check">✓</span>' : '<span class="quest-lock">🔒</span>');
    return '<div class="quest-step ' + cls + '"><span class="quest-num">' + (i + 1) + '</span><span class="quest-text">' + s + "</span>" + btnHtml + "</div>";
  }).join("");
  $$("#questSteps [data-quest-step]").forEach(function(b){
    b.addEventListener("click", function(){
      var cur = lsGet("tirada_quest", { week: weekIndex(), done: 0 });
      if (cur.week !== weekIndex()) cur = { week: weekIndex(), done: 0 };
      cur.done = Math.min(weekQuest().steps.length, cur.done + 1);
      lsSet("tirada_quest", cur);
      if (cur.done >= weekQuest().steps.length){
        lsSet("tirada_quest_badges", lsGet("tirada_quest_badges", 0) + 1);
        renderStats();
        toast("Квест недели пройден! Бейдж в профиле 🏅");
      } else toast("Шаг квеста засчитан 🗺️");
      renderTasks();
    });
  });
}
$("#dailyDoneBtn").addEventListener("click", function(){
  var st = lsGet("tirada_streak", { last: "", streak: 0 });
  if (st.last === todayKey()) return;
  var y = new Date(Date.now() - 86400000).toDateString();
  st.streak = (st.last === y) ? st.streak + 1 : 1;
  st.last = todayKey();
  lsSet("tirada_streak", st);
  renderTasks();
  toast("Задание дня выполнено 🔥 Серия: " + st.streak);
});

/* ================= Supabase cloud: auth, profile sync, presence, votes =================
   Real cloud accounts on top of the local ghost. Everything degrades
   gracefully: guests and offline keep the full local experience, and no
   network error ever breaks the UI. Fake people are never invented —
   the online counter and vote counts are real table reads. */
var db = window.TiradaDB || null;
var SUPA_CFG = window.TiradaSupaCfg || { url: "", key: "" };
var cloudUser = null, cloudSession = null, cloudSyncTimer = null,
    cloudHeartbeat = null, cloudVoteCounts = null, cloudBootedFor = null;

function cloudStatsPayload(){
  return { nights: state.stats.nights, places: state.stats.places,
           routes: state.stats.routes, lastDealDay: state.stats.lastDealDay || "" };
}
function cloudSyncNow(){
  if (!db || !cloudUser) return Promise.resolve();
  var payload = {
    id: cloudUser.id,
    name: state.nick || "Призрак",
    avatar: AVATARS[state.myAvatar % AVATARS.length].e,
    avatar_url: state.avatarUrl || null,
    mode: state.mode,
    city: state.city.id,
    stats: cloudStatsPayload(),
    favorites: Object.keys(state.favs)
  };
  return db.from("profiles").upsert(payload).then(function(res){
    if (res.error) console.warn("TiradA sync:", res.error.message);
  }, function(){});
}
function scheduleCloudSync(){
  if (!db || !cloudUser) return;
  if (cloudSyncTimer) clearTimeout(cloudSyncTimer);
  cloudSyncTimer = setTimeout(cloudSyncNow, 700);
}
function normalizeStats(s){
  var d = { nights: 0, places: [], routes: 0, lastDealDay: "" };
  if (!s) return d;
  return { nights: +s.nights || 0, places: Array.isArray(s.places) ? s.places : [],
           routes: +s.routes || 0, lastDealDay: s.lastDealDay || "" };
}
function applyCitySilent(id){
  state.city = cityById(id);
  state.filter = "all"; state.dealAlt = 0; state.routeRound = 0;
  state.routeSteps = null; state.search = "";
  $("#cityName").textContent = state.city.name;
  $("#routeCity").textContent = state.city.name;
  renderFilter(); renderPlaces(); updateCounter(); buildTicker(); buildRoute(); renderCityList();
  if (map && mapReady){
    clearRoute(); renderMapMarkers();
    map.jumpTo({ center: [state.city.lng, state.city.lat], zoom: 13 });
  }
}
function applyRemoteProfile(row){
  if (!row) return;
  if (row.name){ state.nick = row.name; lsSet("tirada_nick", state.nick);
    var ni = $("#nickInput"); if (ni) ni.value = state.nick; }
  if (row.avatar){
    for (var i = 0; i < AVATARS.length; i++)
      if (AVATARS[i].e === row.avatar){ state.myAvatar = i; lsSet("tirada_avatar_idx", i); break; }
  }
  state.avatarUrl = row.avatar_url || null;
  lsSet("tirada_avatar_url", state.avatarUrl);
  if (row.stats){ state.stats = normalizeStats(row.stats); saveStats(); }
  if (Array.isArray(row.favorites)){
    state.favs = {};
    row.favorites.forEach(function(id){ state.favs[id] = 1; });
    lsSet("tirada_favs", state.favs);
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
  cloudHeartbeat = setInterval(function(){ cloudPresence(true); }, 30000);
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
  if (!db || !cloudUser){ el.textContent = "🔒 Кто сейчас в сети — видно после входа"; return; }
  el.textContent = "Смотрю, кто в сети…";
  db.from("profiles").select("id", { count: "exact", head: true }).eq("online", true)
    .then(function(res){
      var el2 = $("#dealOnline"); if (!el2) return;
      if (res.error || typeof res.count !== "number"){ el2.textContent = "Сейчас в сети: не удалось посчитать"; return; }
      el2.innerHTML = "🟢 Сейчас в сети: <b>" + res.count + "</b>";
    }, function(){ var el3 = $("#dealOnline"); if (el3) el3.textContent = "Сейчас в сети: нет связи"; });
}

/* ---- Photo avatar → Storage bucket 'avatars' ---- */
function cloudUploadAvatar(blob){
  if (!db || !cloudUser || !blob) return;
  var path = cloudUser.id + "/avatar.jpg";
  db.storage.from("avatars").upload(path, blob, { upsert: true, contentType: "image/jpeg" })
    .then(function(res){
      if (res.error){ console.warn("TiradA avatar upload:", res.error.message); toast("Фото не уехало в облако — останется на устройстве"); return; }
      var pub = db.storage.from("avatars").getPublicUrl(path);
      state.avatarUrl = pub.data.publicUrl + "?v=" + Date.now();
      lsSet("tirada_avatar_url", state.avatarUrl);
      renderMyAvatar(); renderAvatarGrid();
      cloudSyncNow();
      toast("Фото-аватарка в облаке ☁️ Теперь она на всех устройствах");
    }, function(){ toast("Фото не уехало в облако — останется на устройстве"); });
}

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
  if (p && p.city && PLACES_BY_CITY[p.city]) return cityById(p.city).name;
  return "город не указан";
}
function friendMetaHtml(p){
  var on = !!(p && p.online);
  return '<span class="' + (on ? "friend-on" : "friend-off") + '">' +
    (on ? "🟢 в сети" : "⚪ не в сети") + "</span> · " + escHtml(friendCityName(p));
}
function friendRowHtml(p, actionsHtml){
  return '<div class="friend-row">' +
    '<span class="friend-ava">' + friendAvatarHtml(p) + '</span>' +
    '<span class="friend-info"><span class="friend-name">' + escHtml((p && p.name) || "Призрак") + '</span>' +
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
        return;
      }
      return db.from("profiles").select("id,name,avatar,avatar_url,city,online").in("id", list)
        .then(function(pr){
          if (!pr.error && pr.data) pr.data.forEach(function(p){ friendsProfiles[p.id] = p; });
          friendsLoaded = true; renderFriends(); renderFriendResults(); renderDealFriends();
        }, function(){ friendsLoaded = true; renderFriends(); renderFriendResults(); renderDealFriends(); });
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
    b.addEventListener("click", function(){ friendsDelete(b.getAttribute("data-fdecline"), "Заявка убрана"); });
  });
  root.querySelectorAll("[data-fremove]").forEach(function(b){
    b.addEventListener("click", function(){ friendsDelete(b.getAttribute("data-fremove"), "Друг удалён"); });
  });
}
function renderFriends(){
  var g = $("#friendsGuest"), u = $("#friendsUser");
  if (!g || !u) return;
  if (!db || !cloudUser){ g.hidden = false; u.hidden = true; return; }
  g.hidden = true; u.hidden = false;
  var box = $("#friendSections");
  if (!box) return;
  if (!friendsLoaded){ box.innerHTML = '<div class="friend-empty">Загружаю друзей…</div>'; return; }
  var inc = [], out = [], mine = [];
  friendsRows.forEach(function(r){
    var otherId = (r.requester === cloudUser.id) ? r.addressee : r.requester;
    var p = friendsProfiles[otherId] || { id: otherId, name: "Призрак" };
    if (r.status === "accepted") mine.push({ row: r, p: p });
    else if (r.addressee === cloudUser.id) inc.push({ row: r, p: p });
    else out.push({ row: r, p: p });
  });
  var html = "";
  if (inc.length){
    html += '<div class="friend-sec-title">Заявки тебе · ' + inc.length + "</div>" + inc.map(function(x){
      return friendRowHtml(x.p,
        '<button class="friend-btn ok" data-faccept="' + x.row.id + '">Принять</button>' +
        '<button class="friend-btn" data-fdecline="' + x.row.id + '">Отклонить</button>');
    }).join("");
  }
  html += '<div class="friend-sec-title">Мои друзья · ' + mine.length + "</div>";
  html += mine.length ? mine.map(function(x){
    return friendRowHtml(x.p, '<button class="friend-btn danger" data-fremove="' + x.row.id + '">Удалить</button>');
  }).join("") : '<div class="friend-empty">Пока пусто. Найди призрака по нику выше — и зови в друзья 👻</div>';
  if (out.length){
    html += '<div class="friend-sec-title">Ты позвал · ' + out.length + "</div>" + out.map(function(x){
      return friendRowHtml(x.p,
        '<span class="friend-wait">ждёт ответа…</span>' +
        '<button class="friend-btn" data-fdecline="' + x.row.id + '">Отменить</button>');
    }).join("");
  }
  box.innerHTML = html;
  bindFriendButtons(box);
}
function renderFriendResults(){
  var box = $("#friendResults");
  if (!box) return;
  if (!friendSearchResults.length){ box.innerHTML = ""; return; }
  box.innerHTML = '<div class="friend-sec-title">Нашлись</div>' + friendSearchResults.map(function(p){
    var rel = friendRelation(p.id), act;
    if (!rel) act = '<button class="friend-btn ok" data-fadd="' + p.id + '">Добавить</button>';
    else if (rel.kind === "friend") act = '<span class="friend-wait">вы друзья</span>';
    else if (rel.kind === "out") act = '<span class="friend-wait">заявка отправлена</span>';
    else act = '<button class="friend-btn ok" data-faccept="' + rel.row.id + '">Принять заявку</button>';
    return friendRowHtml(p, act);
  }).join("");
  bindFriendButtons(box);
}
function friendsSearch(){
  if (!db || !cloudUser) return;
  var inp = $("#friendSearch");
  var q = ((inp && inp.value) || "").trim();
  if (q.length < 2){ toast("Введи хотя бы 2 символа ника"); return; }
  var pat = "%" + q.replace(/[%_\\]/g, "\\$&") + "%";
  var btn = $("#friendSearchBtn");
  if (btn) btn.disabled = true;
  db.from("profiles").select("id,name,avatar,avatar_url,city,online").ilike("name", pat).limit(20)
    .then(function(res){
      if (btn) btn.disabled = false;
      if (res.error){ toast("Поиск не сработал — попробуй ещё раз"); return; }
      friendSearchResults = (res.data || []).filter(function(p){ return p.id !== cloudUser.id; });
      friendSearchResults.forEach(function(p){ friendsProfiles[p.id] = p; });
      if (!friendSearchResults.length){
        $("#friendResults").innerHTML = '<div class="friend-empty">Никого с таким ником не нашлось 👻</div>';
        return;
      }
      renderFriendResults();
    }, function(){ if (btn) btn.disabled = false; toast("Нет связи с сервером"); });
}
function friendsSend(otherId){
  if (!db || !cloudUser) return;
  if (otherId === cloudUser.id){ toast("Себя в друзья не добавить 😄"); return; }
  var rel = friendRelation(otherId);
  if (rel){
    toast(rel.kind === "friend" ? "Вы уже друзья 👻"
        : rel.kind === "out" ? "Заявка уже отправлена — ждём ответа"
        : "Этот призрак уже позвал тебя — прими заявку в списке ниже");
    return;
  }
  db.from("friendships").select("id,status,requester,addressee")
    .or("and(requester.eq." + cloudUser.id + ",addressee.eq." + otherId + "),and(requester.eq." + otherId + ",addressee.eq." + cloudUser.id + ")")
    .then(function(res){
      if (!res.error && res.data && res.data.length){
        var r = res.data[0];
        toast(r.status === "accepted" ? "Вы уже друзья 👻"
            : r.requester === cloudUser.id ? "Заявка уже отправлена — ждём ответа"
            : "Этот призрак уже позвал тебя — прими заявку в списке ниже");
        friendsLoaded = false; friendsLoad();
        return;
      }
      return db.from("friendships")
        .insert({ requester: cloudUser.id, addressee: otherId, status: "pending" })
        .then(function(ins){
          if (ins.error){
            toast(/duplicate|unique/i.test(ins.error.message || "") ? "Такая заявка уже есть" : "Не вышло отправить заявку");
            friendsLoaded = false; friendsLoad();
            return;
          }
          toast("Заявка отправлена 👻");
          friendsLoaded = false; friendsLoad(); renderFriendResults();
        }, function(){ toast("Нет связи с сервером"); });
    }, function(){ toast("Нет связи с сервером"); });
}
function friendsAccept(rowId){
  if (!db || !cloudUser) return;
  db.from("friendships").update({ status: "accepted" }).eq("id", rowId).eq("addressee", cloudUser.id)
    .then(function(res){
      if (res.error){ toast("Не вышло принять заявку"); return; }
      toast("Теперь вы друзья 👻");
      friendsLoaded = false; friendsLoad(); renderFriendResults();
    }, function(){ toast("Нет связи с сервером"); });
}
function friendsDelete(rowId, okMsg){
  if (!db || !cloudUser) return;
  db.from("friendships").delete().eq("id", rowId)
    .then(function(res){
      if (res.error){ toast("Не вышло — попробуй ещё раз"); return; }
      if (okMsg) toast(okMsg);
      friendsLoaded = false; friendsLoad(); renderFriendResults();
    }, function(){ toast("Нет связи с сервером"); });
}
function friendsReset(){
  friendsRows = []; friendsProfiles = {}; friendSearchResults = [];
  friendsLoaded = false;
  var r = $("#friendResults"); if (r) r.innerHTML = "";
  renderFriends();
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
  box.innerHTML = '<div class="deal-friends"><div class="friend-sec-title light">Друзья сейчас в деле · ' + list.length + "</div>" +
    list.map(function(p){
      return '<div class="friend-row">' +
        '<span class="friend-ava">' + friendAvatarHtml(p) + '</span>' +
        '<span class="friend-info"><span class="friend-name">' + escHtml(p.name || "Призрак") + '</span>' +
        '<span class="friend-meta">' + friendMetaHtml(p) + '</span></span>' +
        '<span class="friend-indeal">🔥 в деле</span></div>';
    }).join("") + "</div>";
}
var friendsLoginBtn = $("#friendsLoginBtn");
if (friendsLoginBtn) friendsLoginBtn.addEventListener("click", function(){ $("#loginModal").hidden = false; });
var friendSearchBtn = $("#friendSearchBtn");
if (friendSearchBtn) friendSearchBtn.addEventListener("click", friendsSearch);
var friendSearchInp = $("#friendSearch");
if (friendSearchInp) friendSearchInp.addEventListener("keydown", function(e){
  if (e.key === "Enter"){ e.preventDefault(); friendsSearch(); }
});

/* ---- Account UI ---- */
function renderAccount(){
  var g = $("#accountGuest"), u = $("#accountUser"), btn = $("#loginBtn");
  if (!g || !u || !btn) return;
  if (cloudUser){
    g.hidden = true; u.hidden = false;
    $("#accountEmail").textContent = cloudUser.email || "";
    btn.textContent = state.nick ? "👻 " + state.nick : "👻 В сети";
  } else {
    g.hidden = false; u.hidden = true;
    btn.textContent = "Войти";
  }
  renderFriends();
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
    .then(function(){ startHeartbeat(); return cloudLoadMyVote(); })
    .then(function(){ friendsLoad(); }, function(){ friendsLoad(); });
}
if (db){
  db.auth.getSession().then(function(r){
    var s = r.data && r.data.session;
    cloudSession = s || null;
    if (s && s.user) cloudOnSignedIn(s.user); else renderAccount();
  }, function(){ renderAccount(); });
  db.auth.onAuthStateChange(function(ev, session){
    cloudSession = session || null;
    if (ev === "SIGNED_IN" && session && session.user) cloudOnSignedIn(session.user);
    if (ev === "SIGNED_OUT"){
      cloudUser = null; cloudBootedFor = null; cloudVoteCounts = null;
      stopHeartbeat(); friendsReset(); renderAccount();
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
    toast("Ты вышел. Призрак снова только на этом устройстве 👻");
  }, function(){ toast("Не вышло выйти — попробуй ещё раз"); });
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
  if (/Invalid login credentials/i.test(m)) return "Неверный email или пароль. Проверь и попробуй ещё раз.";
  if (/already registered/i.test(m)) return "Этот email уже зарегистрирован. Переключись на вкладку «Вход».";
  if (/at least 6 characters/i.test(m)) return "Пароль слишком короткий — нужно минимум 6 символов.";
  if (/invalid format|validate email|invalid email/i.test(m)) return "Email выглядит неправильно — проверь адрес.";
  if (/Failed to fetch|NetworkError|network|Load failed/i.test(m)) return "Нет связи с сервером. Проверь интернет и попробуй ещё раз.";
  if (/rate limit|too many/i.test(m)) return "Слишком много попыток подряд. Подожди минутку.";
  return "Что-то пошло не так. Попробуй ещё раз.";
}
function setAuthMode(m){
  authMode = m;
  $("#authTabIn").classList.toggle("active", m === "in");
  $("#authTabUp").classList.toggle("active", m === "up");
  $("#authName").hidden = (m !== "up");
  $("#authPass").setAttribute("autocomplete", m === "up" ? "new-password" : "current-password");
  $("#authSubmit").textContent = (m === "up") ? "Создать призрака" : "Войти";
  $("#authNote").textContent = (m === "up")
    ? "Пароль — минимум 6 символов. Подтверждение почты не нужно: входи сразу."
    : "Нет аккаунта? Жми «Регистрация» — это 20 секунд.";
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
  if (!db){ authShowError("Облако сейчас недоступно. Приложение работает и без входа 👻"); return; }
  var email = $("#authEmail").value.trim();
  var pass = $("#authPass").value;
  var name = $("#authName").value.trim();
  if (!email || email.indexOf("@") < 1){ authShowError("Введи email — настоящий, с @."); return; }
  if (!pass || pass.length < 6){ authShowError("Пароль слишком короткий — нужно минимум 6 символов."); return; }
  if (authMode === "up" && name){
    var nchk = validateNick(name);
    if (!nchk.ok){ authShowError(nchk.error); return; }
    name = nchk.value;
  }
  var btn = $("#authSubmit");
  btn.disabled = true;
  btn.textContent = "Секунду…";
  authShowError(null);
  var done = function(){ btn.disabled = false; setAuthMode(authMode); };
  if (authMode === "up"){
    if (name){ state.nick = name; lsSet("tirada_nick", state.nick); var ni2 = $("#nickInput"); if (ni2) ni2.value = name; renderMyAvatar(); }
    db.auth.signUp({ email: email, password: pass, options: { data: { name: name || undefined } } })
      .then(function(res){
        done();
        if (res.error){ authShowError(authErrorText(res.error)); return; }
        modal.hidden = true;
        if (res.data && res.data.session) toast("Аккаунт создан — ты в сети, призрак 👻");
        else toast("Аккаунт создан! Теперь войди по email и паролю.");
      }, function(err){ done(); authShowError(authErrorText(err)); });
  } else {
    db.auth.signInWithPassword({ email: email, password: pass })
      .then(function(res){
        done();
        if (res.error){ authShowError(authErrorText(res.error)); return; }
        modal.hidden = true;
        toast("С возвращением, призрак 👻");
      }, function(err){ done(); authShowError(authErrorText(err)); });
  }
});
["authEmail", "authPass", "authName"].forEach(function(id){
  var inp = document.getElementById(id);
  if (inp) inp.addEventListener("keydown", function(e){
    if (e.key === "Enter"){ e.preventDefault(); $("#authSubmit").click(); }
  });
});

/* ================= Footer: info stubs & creators anchor ================= */
var INFO = {
  about: { emoji:"📱", title:"О приложении",
    body:"TiradA anon — живой радар движа по городам Израиля. Показывает, где город тусит прямо сейчас, собирает маршрут на вечер и зовёт друзей одной ссылкой. Ты на карте — призрак: без имени и фото, открываешься только своим." },
  privacy: { emoji:"🔒", title:"Политика конфиденциальности",
    body:"В демо-превью места — демонстрационные данные, а других людей на карте нет: только ты. Геолокация, если ты её разрешил, остаётся на твоём устройстве и никуда не отправляется. В полной версии здесь будет честный текст о том, какие данные нужны радару и как их удалить в один тап." }
};
var infoModal = $("#infoModal");
$$("[data-info]").forEach(function(btn){
  btn.addEventListener("click", function(){
    var d = INFO[btn.getAttribute("data-info")];
    if (!d) return;
    $("#infoEmoji").textContent = d.emoji;
    $("#infoTitle").textContent = d.title;
    $("#infoBody").textContent = d.body;
    infoModal.hidden = false;
  });
});
$("#infoClose").addEventListener("click", function(){ infoModal.hidden = true; });
$("#infoOk").addEventListener("click", function(){ infoModal.hidden = true; });
infoModal.addEventListener("click", function(e){ if (e.target === infoModal) infoModal.hidden = true; });
$("#linkCreators").addEventListener("click", function(){
  showScreen("profile");
  setTimeout(function(){
    var el = $("#creatorsBlock");
    if (el) el.scrollIntoView({ behavior:"smooth", block:"center" });
  }, 120);
});

/* ================= Welcome (first visit) & geo button ================= */
function renderWelcomeCities(){
  var q = (($("#welcomeSearch") && $("#welcomeSearch").value) || "").trim().toLowerCase();
  var list = CITIES.filter(function(c){ return !q || c.name.toLowerCase().indexOf(q) >= 0; });
  $("#welcomeCityList").innerHTML = list.length ? list.map(function(c){
    var n = PLACES_BY_CITY[c.id].length;
    return '<button class="city-item" data-wcity="' + c.id + '"><span>' + c.name + '</span><span class="city-item-meta">' + n + " " + placeWord(n) + "</span></button>";
  }).join("") : '<div class="places-empty">Город не нашёлся 👻</div>';
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

/* ================= Go ================= */
renderCityList();
renderMyAvatar();
renderAvatarGrid();
renderStats();
renderTasks();
var nickInit = $("#nickInput"); if (nickInit) nickInit.value = state.nick || "";
initMap();
requestGeo(false);
renderFilter();
renderPlaces();
updateCounter();
buildTicker();
buildRoute();
if (!lsGet("tirada_welcomed", false) && !location.hash){
  renderWelcomeCities();
  setTimeout(function(){ $("#welcomeSheet").hidden = false; }, 500);
}

/* deep-link for previews/screenshots: #places #route #profile #deal #city=eilat */
(function(){
  var h = location.hash || "";
  if (h) document.body.classList.add("shots");
  var cm = h.match(/city=([a-z]+)/);
  if (cm && PLACES_BY_CITY[cm[1]]) setCity(cm[1]);
  var vm = h.match(/vote=([a-z0-9,\-]+)/);
  if (vm) state.voteLink = vm[1].split(",").filter(Boolean);
  if (h.indexOf("places") >= 0) showScreen("places");
  else if (h.indexOf("route") >= 0) showScreen("route");
  else if (h.indexOf("profile") >= 0) showScreen("profile");
  if (h.indexOf("deal") >= 0) openDeal();
})();
})();

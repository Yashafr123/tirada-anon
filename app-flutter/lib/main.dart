// TiradA anon — native app (Flutter), v2.0.8.
//
// A premium design system over the same product: token-driven colors,
// spacing and type (Inter / Montserrat / Unbounded), a shared component
// library (Pressable, FireButton, GlassCard, RadarSweep, LevelRing…),
// an animated first-launch intro, and a rich feature pack (badges,
// titles, leaderboard, filters, confetti). Same Supabase backend, same
// local on-phone persistence, same assets and data contracts as v2.0.4.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File, HttpClient;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show rootBundle, HapticFeedback;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const kSupaUrl = 'https://qrlyuvnfkrufnnladclf.supabase.co';
const kSupaAnon =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFybHl1dm5ma3J1Zm5ubGFkY2xmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUzNDA5OTQsImV4cCI6MjExMDkxNjk5NH0.JyIVlJjLG7co0kv215Jesykwy9XCMqpRlqY3Nh-lKrw';

/* ============================== TOKENS ============================== */

/* Single source of truth for the whole visual language. Every screen is
   built from these values — no raw hex, no off-scale spacing anywhere. */
class T {
  T._();

  /* Color */
  static const bg = Color(0xFF0B0B0D);
  static const surface = Color(0xFF141418);
  static const surfaceHi = Color(0xFF1B1B21);
  static const stroke = Color(0x59E11D1D); // rgba(225,29,29,.35)
  static const fire = Color(0xFFE11D1D);
  static const ember = Color(0xFFFF7A1A);
  static const gold = Color(0xFFFFB03A);
  static const online = Color(0xFF22C55E);
  static const text = Color(0xFFF5F5F7);
  static const muted = Color(0xFF9A9AA3);
  static const faint = Color(0xFF5C5C66);
  static const salmon = Color(0xFFFF8A7A);

  /* Gradients */
  static const fireGrad = LinearGradient(
    colors: [fire, ember],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const fireGradV = LinearGradient(
    colors: [fire, ember],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const emberGrad = LinearGradient(
    colors: [ember, gold],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const goldGrad = LinearGradient(
    colors: [gold, ember],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const glassGrad = LinearGradient(
    colors: [Color(0x14FFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const borderGrad = LinearGradient(
    colors: [Color(0x99FF7A1A), Color(0x59E11D1D), Color(0x26E11D1D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /* Radii */
  static const rCard = 24.0;
  static const rSheet = 28.0;
  static const rButton = 20.0;
  static const rPill = 999.0;

  /* Spacing scale — the only allowed steps: 4·8·12·16·20·24·32 */
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;

  /* Shadows */
  static List<BoxShadow> get glowRed => [
        BoxShadow(
          color: fire.withOpacity(0.45),
          blurRadius: 22,
          offset: const Offset(0, 6),
        ),
      ];
  static List<BoxShadow> get glowEmber => [
        BoxShadow(
          color: ember.withOpacity(0.40),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
  static List<BoxShadow> get cardDepth => [
        BoxShadow(
          color: Colors.black.withOpacity(0.45),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: fire.withOpacity(0.10),
          blurRadius: 18,
          offset: const Offset(0, 4),
        ),
      ];

  /* Motion */
  static const dFast = Duration(milliseconds: 120);
  static const dMed = Duration(milliseconds: 220);
  static const dSlow = Duration(milliseconds: 380);
  static const dEpic = Duration(milliseconds: 600);
  static const cOut = Curves.easeOutCubic;
  static const cSpring = Cubic(0.2, 0.9, 0.25, 1.2);
  static const cPage = Curves.easeInOutCubicEmphasized;

  /* Type scale — families: Unbounded (display), Montserrat (heads),
     Inter (UI/body). Sizes: display 28/24 · h 20/17 · body 15/13 · micro 11 */
  static TextStyle display(double size, {Color color = text}) => TextStyle(
        fontFamily: 'Unbounded',
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.12,
        color: color,
      );
  static TextStyle displayBlack(double size, {Color color = text}) =>
      TextStyle(
        fontFamily: 'Unbounded',
        fontSize: size,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.3,
        height: 1.12,
        color: color,
      );
  static TextStyle head(double size, {Color color = text}) => TextStyle(
        fontFamily: 'Montserrat',
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.1,
        height: 1.2,
        color: color,
      );
  static TextStyle body(double size,
          {Color color = text, FontWeight w = FontWeight.w500}) =>
      TextStyle(
        fontFamily: 'Inter',
        fontSize: size,
        fontWeight: w,
        height: 1.35,
        color: color,
      );
  static TextStyle micro({Color color = muted}) => TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.2,
        color: color,
      );
  static TextStyle num(double size, {Color color = text}) => TextStyle(
        fontFamily: 'Montserrat',
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
      );
}

/* Legacy aliases — kept so data/logic code reads unchanged; all values
   now flow from the token class above. */
const kBg = T.bg;
const kSurface = T.surface;
const kSurface2 = T.surfaceHi;
const kRed = T.fire;
const kOrange = T.ember;
const kGreen = T.online;
const kText = T.text;
const kMuted = T.muted;
Color get kBorder => T.stroke;

/* Global haptics switch (Profile → Настройки, persisted as haptics_on). */
bool hapticsOn = true;

void tick() {
  if (hapticsOn) HapticFeedback.lightImpact();
}

void tickSelect() {
  if (hapticsOn) HapticFeedback.selectionClick();
}

void tickMedium() {
  if (hapticsOn) HapticFeedback.mediumImpact();
}

/* FCM background handler — must be a top-level function. No UI work here,
   just the mandatory Firebase init for the background isolate. */
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: kSupaUrl, anonKey: kSupaAnon);
  // Firebase is an enhancement, never a gate: a missing/broken
  // google-services.json must not stop the app from starting.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
  } catch (_) {}
  runApp(const TiradaApp());
}

SupabaseClient get supa => Supabase.instance.client;
String get myUid => supa.auth.currentUser!.id;
String? get myUidOrNull => supa.auth.currentUser?.id;

/* Last real location seen by the map — shared with the «Я в деле» sheet. */
final ValueNotifier<LatLng?> myLocationNotifier = ValueNotifier<LatLng?>(null);

/* Real geolocation (v2.0.8). Before this, the only position source was
   MapLibre's requestMyLocationLatLng() — which silently returns null
   forever when the app never asked for the location permission, so the
   owner was never prompted and never appeared on the map. This service
   owns the whole flow: permission request → GPS-service check → one fix
   → a live position stream that keeps myLocationNotifier fed for every
   consumer (presence writer, distances, "near me" sort, map centering,
   the native puck). Every step is guarded: location must never crash
   the app, for guests either. */
class LocationService {
  static bool _starting = false;
  static bool _deniedHintShown = false;
  static bool _gpsOffHintShown = false;
  static StreamSubscription<Position>? _sub;

  /* Idempotent: safe to call from HomePage init and again when the Map
     tab is first opened. Hints are shown at most once per session. */
  static Future<void> ensureLocation([BuildContext? context]) async {
    try {
      var status = await Permission.location.status;
      if (status.isDenied) {
        status = await Permission.location.request();
      }
      if (status.isPermanentlyDenied) {
        if (!_deniedHintShown && context != null && context.mounted) {
          _deniedHintShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Геолокация выключена для приложения — без неё карта тебя не видит',
              ),
              action: SnackBarAction(
                label: 'Настройки',
                onPressed: () {
                  openAppSettings();
                },
              ),
            ),
          );
        }
        return;
      }
      if (!status.isGranted && !status.isLimited) {
        return; // soft-denied: the system prompt already had its say
      }
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        if (!_gpsOffHintShown && context != null && context.mounted) {
          _gpsOffHintShown = true;
          snack(
            context,
            'Включи геолокацию на телефоне — тогда карта покажет, где ты',
          );
        }
        return;
      }
      if (_sub != null || _starting) return; // stream already (being) started
      _starting = true;
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
        myLocationNotifier.value = LatLng(pos.latitude, pos.longitude);
      } catch (_) {}
      try {
        _sub = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            distanceFilter: 25,
          ),
        ).listen(
          (pos) {
            myLocationNotifier.value = LatLng(pos.latitude, pos.longitude);
          },
          onError: (_) {},
        );
      } catch (_) {}
      _starting = false;
    } catch (_) {
      _starting = false;
    }
  }
}

Future<void> openLink(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

/* ---------------- models & helpers (mirrors the web app) ---------------- */

class Place {
  final String id, city, name, type;
  final double lat, lng;
  final double? rating;
  final int? reviews;
  final int? priceLevel;
  final String address;
  const Place({
    required this.id,
    required this.city,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    this.rating,
    this.reviews,
    this.priceLevel,
    this.address = '',
  });
  factory Place.fromJson(Map<String, dynamic> j) => Place(
        id: j['id'] as String,
        city: j['city'] as String,
        name: j['name'] as String,
        type: j['type'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        rating: (j['rating'] as num?)?.toDouble(),
        reviews: (j['reviews'] as num?)?.toInt(),
        priceLevel: (j['priceLevel'] as num?)?.toInt(),
        address: (j['address'] as String?) ?? '',
      );
}

class City {
  final String id, name;
  final double lat, lng;
  const City(this.id, this.name, this.lat, this.lng);
  factory City.fromJson(Map<String, dynamic> j) => City(
        j['id'] as String,
        j['name'] as String,
        (j['lat'] as num).toDouble(),
        (j['lng'] as num).toDouble(),
      );
}

const kTypeEmoji = <String, String>{
  'park': '🌳', 'cafe': '☕', 'bar': '🍸', 'restaurant': '🍽️', 'club': '🎧',
  'beach': '🏖️', 'view': '🌇', 'sport': '🏀', 'culture': '🎭',
  'market': '🛍️', 'other': '📍',
};

Color typeColor(String t) {
  switch (t) {
    case 'park':
      return const Color(0xFF35D07F);
    case 'cafe':
      return const Color(0xFFFFB84D);
    case 'bar':
      return const Color(0xFFB78CFF);
    case 'restaurant':
      return const Color(0xFFFF7A59);
    case 'club':
      return const Color(0xFFFF4DD2);
    case 'beach':
      return const Color(0xFF4DC9FF);
    case 'view':
      return const Color(0xFFFFD24D);
    case 'sport':
      return const Color(0xFF6CFF6C);
    case 'culture':
      return const Color(0xFFFF6C8A);
    case 'market':
      return const Color(0xFF6CE8FF);
    default:
      return kRed;
  }
}

String priceText(Place p) {
  final pl = p.priceLevel;
  if (pl == null) {
    // OSM rows carry no price: show the per-type estimate, marked with ≈.
    final est = estPriceLevel(p);
    if (est == 0) return 'Бесплатно';
    return '≈${'₪' * est.clamp(1, 4)}';
  }
  if (pl == 0) return 'Бесплатно';
  return '₪' * pl.clamp(1, 4);
}

/* Per-type price level estimate (0..3) for places without price data —
   parks and viewpoints are free, clubs and restaurants cost the most. */
int estPriceLevel(Place p) {
  switch (p.type) {
    case 'park':
    case 'view':
    case 'beach':
    case 'sport':
      return 0;
    case 'culture':
    case 'market':
    case 'other':
      return 1;
    case 'cafe':
    case 'bar':
      return 2;
    case 'restaurant':
    case 'club':
      return 3;
    default:
      return 1;
  }
}

/* Effective price level: real data first, estimate as the fallback. */
int effPriceLevel(Place p) => p.priceLevel ?? estPriceLevel(p);

/* Human shekel range per price level (per person, rough city prices). */
String priceRangeText(int level) {
  switch (level.clamp(0, 4)) {
    case 0:
      return 'бесплатно';
    case 1:
      return '~30–60 ₪';
    case 2:
      return '~60–120 ₪';
    case 3:
      return '~120–200 ₪';
    default:
      return '200+ ₪';
  }
}

/* Full price label for the place sheet: shekels + range, estimate marked. */
String priceDetailText(Place p) {
  final lvl = effPriceLevel(p);
  if (lvl == 0) return 'Бесплатно';
  final est = p.priceLevel == null ? '≈' : '';
  return '$est${'₪' * lvl.clamp(1, 4)} · ${priceRangeText(lvl)} на человека';
}

/* Ghost label with the same numbering the profile uses:
   1000 + stableHash(uid) % 9000. */
String ghostLabelFor(String uid) => 'Призрак #${1000 + stableHash(uid) % 9000}';

/* «Сколько людей отдыхает сейчас» — a deterministic estimate from the
   place type, the hour and its vibe, seeded by the place id so it does
   not flicker between rebuilds within the same hour. */
int crowdOf(Place p) {
  final h = DateTime.now().hour;
  final seed = stableHash('${p.id}|crowd|$h') % 13;
  var n = (vibeOf(p) - 18) * 0.85 + seed;
  switch (p.type) {
    case 'club':
    case 'bar':
      n *= 1.7;
    case 'restaurant':
    case 'cafe':
      n *= 1.25;
    case 'market':
      n *= 1.1;
    case 'park':
    case 'beach':
      n *= 0.8;
    case 'view':
    case 'culture':
      n *= 0.55;
  }
  if (h >= 2 && h < 8) n *= 0.15; // deep night: almost everyone is home
  return n.round().clamp(0, 260);
}

/* Deterministic small hash (FNV-1a) — stable across runs. */
int stableHash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0x7fffffff;
  }
  return h;
}

/* «Движ» of a place right now: rating + per-place hash + time of day. */
int vibeOf(Place p) {
  final h = DateTime.now().hour;
  var v = 30 + ((p.rating ?? 3.8) - 3.0) * 22 + (stableHash(p.id) % 25);
  final night = h >= 20 || h <= 1;
  final evening = h >= 17 && h < 20;
  if (night || evening) {
    final boost = night ? 18.0 : 10.0;
    final hot = p.type == 'bar' || p.type == 'club' || p.type == 'restaurant';
    v += hot ? boost : boost * 0.4;
  }
  return v.round().clamp(5, 98);
}

String vibeWord(int v) => v >= 70 ? 'жарко' : (v >= 45 ? 'средне' : 'спокойно');

/* Open-Meteo weathercode → condition emoji (night-aware for clear sky). */
String wxEmojiFor(int? code, int hour) {
  if (code == null) return '☀️';
  final night = hour >= 20 || hour < 6;
  if (code == 0) return night ? '🌙' : '☀️';
  if (code == 1 || code == 2) return '🌤️';
  if (code == 3) return '☁️';
  if (code == 45 || code == 48) return '🌫️';
  if (code >= 95) return '⛈️';
  if ((code >= 71 && code <= 77) || code == 85 || code == 86) return '❄️';
  if (code >= 51) return '🌧️';
  return '🌤️';
}

double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * r * math.asin(math.min(1, math.sqrt(a)));
}

String fmtKm(double km) => km.toStringAsFixed(1).replaceAll('.', ',');

void snack(BuildContext context, String text) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text)));
}

/* ---------------- v2.0.6 services: XP bus, sharing, steps, pushes -------- */

/* Widgets deep in the tree (place sheet, deal sheet, tournament) cannot
   reach HomePage's stats directly, so bonus XP is posted here and
   HomePage drains the bus into stats.aiXp. */
class AiXpBus {
  static final ValueNotifier<int> pending = ValueNotifier<int>(0);
  static void credit(int xp) {
    if (xp != 0) pending.value += xp;
  }
}

/* Share through the system sheet and earn XP: +5 per share, max 10 paid
   shares a day (tracked in prefs so it survives restarts). */
Future<void> shareWithXp(BuildContext context, String text) async {
  try {
    await Share.share(text);
  } catch (_) {}
  var granted = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    final today = dayKey();
    var cnt = prefs.getString('share_xp_day') == today
        ? (prefs.getInt('share_xp_count') ?? 0)
        : 0;
    if (cnt < 10) {
      await prefs.setString('share_xp_day', today);
      await prefs.setInt('share_xp_count', cnt + 1);
      granted = true;
    }
  } catch (_) {}
  if (!context.mounted) return;
  if (granted) {
    AiXpBus.credit(5);
    snack(context, '🔗 +5 XP за шаринг');
  } else {
    snack(context, 'Лимит шаринга на сегодня исчерпан');
  }
}

/* Daily city quest: a deterministic 3-step quest generated from the real
   places of the selected city, seeded by (city + local date). Steps are
   completed by real actions — check-in, photo upload, favorite — which
   call CityQuest.mark() from the HomePage handlers. State lives in prefs
   (cityquest_day / cityquest_city / cityquest_steps / cityquest_done);
   finishing all three pays a one-time +50 aiXp bonus. */
class CityQuest {
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static Future<Map<String, dynamic>> ensure(
      List<Place> places, City city) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('cityquest_steps');
    if (prefs.getString('cityquest_day') == dayKey() &&
        prefs.getString('cityquest_city') == city.id &&
        raw != null) {
      try {
        return (jsonDecode(raw) as Map).cast<String, dynamic>();
      } catch (_) {}
    }
    final rng = math.Random(stableHash('${city.id}|${dayKey()}'));
    final pool = [...places]..shuffle(rng);
    Place? pick(Set<String> used, {bool newType = true}) {
      final usedTypes = <String>{
        for (final q in pool)
          if (used.contains(q.id)) q.type,
      };
      for (final q in pool) {
        if (used.contains(q.id)) continue;
        if (newType && usedTypes.contains(q.type)) continue;
        return q;
      }
      for (final q in pool) {
        if (!used.contains(q.id)) return q;
      }
      return null;
    }

    final used = <String>{};
    final a = pick(used);
    if (a != null) used.add(a.id);
    final b = pick(used);
    if (b != null) used.add(b.id);
    final c = pick(used);
    final steps = <Map<String, dynamic>>[
      if (a != null)
        {'kind': 'checkin', 'place': a.id, 'name': a.name, 'done': false},
      if (b != null)
        {'kind': 'photo', 'place': b.id, 'name': b.name, 'done': false},
      if (c != null)
        {'kind': 'fav', 'place': c.id, 'name': c.name, 'done': false},
    ];
    final quest = <String, dynamic>{'steps': steps, 'bonus': false};
    await prefs.setString('cityquest_day', dayKey());
    await prefs.setString('cityquest_city', city.id);
    await prefs.setString('cityquest_steps', jsonEncode(quest));
    await prefs.setBool('cityquest_done', false);
    revision.value++;
    return quest;
  }

  /* Mark the step matching (kind, place). Returns true exactly once —
     when this call completes the whole quest and the bonus is due. */
  static Future<bool> mark(
      String kind, Place place, List<Place> places, City city) async {
    try {
      final quest = await ensure(places, city);
      final steps = (quest['steps'] as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      var changed = false;
      for (final st in steps) {
        if (st['kind'] == kind && st['place'] == place.id && st['done'] != true) {
          st['done'] = true;
          changed = true;
        }
      }
      if (!changed) return false;
      quest['steps'] = steps;
      final prefs = await SharedPreferences.getInstance();
      final allDone = steps.every((st) => st['done'] == true);
      var bonusDue = false;
      if (allDone && quest['bonus'] != true) {
        quest['bonus'] = true;
        bonusDue = true;
        await prefs.setBool('cityquest_done', true);
      }
      await prefs.setString('cityquest_steps', jsonEncode(quest));
      revision.value++;
      return bonusDue;
    } catch (_) {
      return false;
    }
  }
}

/* Steps → XP. The pedometer reports a cumulative counter since boot, so
   we remember the counter value at the start of the day (steps_base) and
   pay +5 aiXp per full 1000 steps, capped at +50 XP a day (10 milestones,
   steps_credited). Everything fails silently: no sensor, no permission —
   the card just says so. */
class StepsTracker {
  static final ValueNotifier<int> today = ValueNotifier<int>(0);
  static final ValueNotifier<int> xpToday = ValueNotifier<int>(0);
  static final ValueNotifier<bool> available = ValueNotifier<bool>(true);
  static void Function(int xp)? onCredit;
  static bool _started = false;

  static Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('steps_day') == dayKey()) {
        xpToday.value = (prefs.getInt('steps_credited') ?? 0) * 5;
      }
      final perm = await Permission.activityRecognition.request();
      if (!perm.isGranted) {
        available.value = false;
        return;
      }
      Pedometer.stepCountStream.listen(
        _onEvent,
        onError: (_) => available.value = false,
      );
    } catch (_) {
      available.value = false;
    }
  }

  static Future<void> _onEvent(StepCount e) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayKey = dayKey();
      if (prefs.getString('steps_day') != todayKey) {
        await prefs.setString('steps_day', todayKey);
        await prefs.setInt('steps_base', e.steps);
        await prefs.setInt('steps_credited', 0);
      }
      var base = prefs.getInt('steps_base') ?? e.steps;
      if (e.steps < base) {
        // Sensor counter reset (reboot): re-base instead of going negative.
        base = e.steps;
        await prefs.setInt('steps_base', base);
      }
      final steps = e.steps - base;
      today.value = steps;
      final milestones = math.min(steps ~/ 1000, 10);
      final credited = prefs.getInt('steps_credited') ?? 0;
      xpToday.value = milestones * 5;
      if (milestones > credited) {
        await prefs.setInt('steps_credited', milestones);
        onCredit?.call((milestones - credited) * 5);
      }
    } catch (_) {}
  }
}

/* FCM pushes: permission, device token registration into device_tokens,
   foreground messages surfaced to HomePage through [foreground]. */
class PushService {
  static final ValueNotifier<RemoteMessage?> foreground =
      ValueNotifier<RemoteMessage?>(null);
  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;
    _inited = true;
    try {
      final m = FirebaseMessaging.instance;
      await m.requestPermission();
      FirebaseMessaging.onMessage.listen((msg) => foreground.value = msg);
      m.onTokenRefresh.listen(_saveToken);
      await registerCurrent();
    } catch (_) {}
  }

  static Future<void> registerCurrent() async {
    try {
      final t = await FirebaseMessaging.instance.getToken();
      if (t != null) await _saveToken(t);
    } catch (_) {}
  }

  static Future<void> _saveToken(String token) async {
    final uid = myUidOrNull;
    if (uid == null) return; // guests have no row to attach a token to
    try {
      await supa.from('device_tokens').upsert({
        'user_id': uid,
        'token': token,
        'platform': 'android',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {}
  }
}

/* Pick an image and re-encode it as JPEG. Decoding + re-encoding strips
   EXIF (GPS coordinates included) — the same privacy trick as the web
   app's canvas re-encode. Returns null when the user cancels. */
Future<Uint8List?> pickAndProcessImage(ImageSource source) async {
  try {
    final x = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 92,
    );
    if (x == null) return null;
    final bytes = await x.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    return Uint8List.fromList(img.encodeJpg(decoded, quality: 88));
  } catch (_) {
    return null;
  }
}

/* XP — the exact formula of the web app (xpOfStats + LEVELS). */
const kLevels = <(int, String)>[
  (0, 'Новичок'),
  (100, 'Бродяга'),
  (250, 'Тусовщик'),
  (500, 'Призрак района'),
  (900, 'Призрак города'),
  (1500, 'Легенда ночей'),
  (2500, 'Хранитель движа'),
  (4000, 'Миф'),
];

Map<String, dynamic> normStats(dynamic raw) {
  final s = <String, dynamic>{
    'nights': 0, 'places': <dynamic>[], 'routes': 0, 'lastDealDay': '',
    'photos': 0, 'tasks': 0, 'questSteps': 0, 'quests': 0, 'votes': 0,
    'streak': 0, 'bestStreak': 0, 'aiXp': 0,
  };
  if (raw is Map) {
    for (final k in s.keys) {
      if (raw[k] != null) s[k] = raw[k];
    }
  }
  return s;
}

int statInt(Map<String, dynamic> s, String k) => (s[k] as num?)?.toInt() ?? 0;

int xpOfStats(Map<String, dynamic> raw) {
  final s = normStats(raw);
  final best = math.max(statInt(s, 'bestStreak'), statInt(s, 'streak'));
  final b = math.min(math.max(0, best), 30);
  return statInt(s, 'tasks') * 20 +
      statInt(s, 'questSteps') * 15 +
      statInt(s, 'quests') * 100 +
      statInt(s, 'routes') * 40 +
      statInt(s, 'nights') * 30 +
      statInt(s, 'photos') * 25 +
      statInt(s, 'votes') * 5 +
      statInt(s, 'aiXp') +
      b * b * 2;
}

(int, String, int?) levelOf(int xp) {
  var i = 0;
  while (i + 1 < kLevels.length && xp >= kLevels[i + 1].$1) {
    i++;
  }
  return (i + 1, kLevels[i].$2, i + 1 < kLevels.length ? kLevels[i + 1].$1 : null);
}

int dayIndex() => DateTime.now().millisecondsSinceEpoch ~/ 86400000;

String dayKey() {
  final d = DateTime.now();
  String p(int n) => n < 10 ? '0$n' : '$n';
  return '${d.year}-${p(d.month)}-${p(d.day)}';
}

String aiText(dynamic o) {
  if (o is Map) {
    return (o['ru'] ?? o['en'] ?? o['he'] ?? '').toString();
  }
  return o?.toString() ?? '';
}

/* ============================ COMPONENTS ============================ */

/* The one card surface: token color, token radius, layered depth. */
BoxDecoration cardDecoration() => BoxDecoration(
      color: T.surface,
      borderRadius: BorderRadius.circular(T.rCard),
      border: Border.all(color: T.stroke),
      boxShadow: T.cardDepth,
    );

/* Gradient hairline divider (replaces flat Dividers). */
Widget hairline({double opacity = 1}) => Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            T.fire.withOpacity(0.35 * opacity),
            Colors.transparent,
          ],
        ),
      ),
    );

Widget sectionLabel(String text, {Color color = T.muted}) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text.toUpperCase(), style: T.micro(color: color)),
    );

/* Dark bg with dark-red radial glows in the corners + faint radar rings
   behind the hero area (brand motif, echoes the logo). */
class GlowBackground extends StatelessWidget {
  final Widget child;
  final bool radar;
  const GlowBackground({super.key, required this.child, this.radar = false});

  Widget _blob(Color c, double opacity) => Container(
        width: 340,
        height: 340,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [c.withOpacity(opacity), c.withOpacity(0)],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ColoredBox(color: T.bg, child: SizedBox.expand()),
        Positioned(top: -130, left: -110, child: _blob(T.fire, 0.20)),
        Positioned(bottom: -150, right: -120, child: _blob(T.ember, 0.13)),
        Positioned(top: 220, right: -170, child: _blob(T.fire, 0.10)),
        if (radar)
          const Positioned(
            top: -70,
            right: -70,
            child: RadarSweep(size: 300, opacity: 0.10),
          ),
        child,
      ],
    );
  }
}

/* Universal press feedback: spring scale to .965 + haptic. Wrap any
   tappable; [onTap] null = disabled (40% opacity handled by callers). */
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool strong;
  const Pressable({super.key, required this.child, this.onTap, this.strong = false});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (mounted && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: enabled
          ? () {
              widget.strong ? tickMedium() : tick();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down && enabled ? 0.965 : 1,
        duration: T.dFast,
        curve: T.cSpring,
        child: widget.child,
      ),
    );
  }
}

/* Primary CTA: fire gradient, glow, and a light sheen that sweeps across
   every few seconds. The button you want to press. */
class FireButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool small;
  const FireButton({super.key, required this.text, required this.onPressed, this.small = false});

  @override
  State<FireButton> createState() => _FireButtonState();
}

class _FireButtonState extends State<FireButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )..repeat();
  bool _down = false;

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final radius = BorderRadius.circular(widget.small ? 14 : T.rButton);
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: AnimatedScale(
        scale: _down && enabled ? 0.965 : 1,
        duration: T.dFast,
        curve: T.cSpring,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: T.fireGrad,
            borderRadius: radius,
            boxShadow: enabled ? T.glowRed : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTapDown: enabled ? (_) => setState(() => _down = true) : null,
              onTapUp: enabled ? (_) => setState(() => _down = false) : null,
              onTapCancel: enabled ? () => setState(() => _down = false) : null,
              onTap: enabled
                  ? () {
                      tick();
                      widget.onPressed!();
                    }
                  : null,
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: widget.small ? 10 : 16,
                      horizontal: widget.small ? 16 : 22,
                    ),
                    child: Center(
                      child: Text(
                        widget.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: Colors.white,
                          fontSize: widget.small ? 13.5 : 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                  if (enabled)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: radius,
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _sheen,
                            builder: (_, __) {
                              final t = _sheen.value;
                              if (t > 0.28) return const SizedBox.shrink();
                              final x = -1.6 + (t / 0.28) * 3.2;
                              return Align(
                                alignment: Alignment(x, 0),
                                child: Transform.rotate(
                                  angle: 0.5,
                                  child: Container(
                                    width: 46,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0),
                                          Colors.white.withOpacity(0.28),
                                          Colors.white.withOpacity(0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* Secondary CTA: dark glass + red border. */
class GhostButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool small;
  const GhostButton({super.key, required this.text, required this.onPressed, this.small = false});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(small ? 14 : T.rButton);
    return Opacity(
      opacity: onPressed != null ? 1 : 0.4,
      child: Pressable(
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: T.surface,
            gradient: T.glassGrad,
            borderRadius: radius,
            border: Border.all(color: T.fire.withOpacity(0.65), width: 1.3),
            boxShadow: [
              BoxShadow(color: T.fire.withOpacity(0.16), blurRadius: 14),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: small ? 10 : 15,
              horizontal: small ? 16 : 22,
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: T.text,
                fontSize: small ? 13.5 : 15.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* Back-compat name used across screens: primary → FireButton,
   secondary → GhostButton. One implementation, zero duplication. */
class PressButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool primary;
  final bool small;
  const PressButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.primary = true,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) => primary
      ? FireButton(text: text, onPressed: onPressed, small: small)
      : GhostButton(text: text, onPressed: onPressed, small: small);
}

/* Small pill action (chips that behave like buttons). */
class PillButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  const PillButton({super.key, required this.text, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: T.dMed,
        curve: T.cOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? T.fireGrad : null,
          color: selected ? null : T.surface,
          borderRadius: BorderRadius.circular(T.rPill),
          border: Border.all(color: selected ? Colors.transparent : T.stroke),
          boxShadow: selected ? T.glowRed : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: selected ? Colors.white : T.text,
          ),
        ),
      ),
    );
  }
}

/* Glass card: surface + gradient border + top highlight + layered depth.
   The gradient border is done with the padding trick: outer box paints
   the border gradient, inner box (inset 1px) paints the surface. */
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool gradientBorder;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(T.s16),
    this.radius = T.rCard,
    this.gradientBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradientBorder ? T.borderGrad : null,
        color: gradientBorder ? null : T.surface,
        borderRadius: BorderRadius.circular(radius),
        border: gradientBorder ? null : Border.all(color: T.stroke),
        boxShadow: T.cardDepth,
      ),
      padding: gradientBorder ? const EdgeInsets.all(1) : EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          color: T.surface,
          gradient: T.glassGrad,
          borderRadius: BorderRadius.circular(radius - (gradientBorder ? 1 : 0)),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

/* Vibe color scale: calm → warm → hot. */
Color vibeColor(int v) =>
    v >= 70 ? T.fire : (v >= 45 ? T.ember : const Color(0xFF8FD0FF));

class VibeBadge extends StatelessWidget {
  final int vibe;
  const VibeBadge({super.key, required this.vibe});

  @override
  Widget build(BuildContext context) {
    final c = vibeColor(vibe);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔥', style: TextStyle(fontSize: 11, color: c)),
            const SizedBox(width: 2),
            AnimatedNumber(
              value: vibe,
              suffix: '%',
              style: T.num(16, color: c),
            ),
          ],
        ),
        Text('движ', style: T.body(9.5, color: T.faint, w: FontWeight.w600)),
      ],
    );
  }
}

/* Pulsing online dot (green). */
class OnlineDot extends StatefulWidget {
  final double size;
  const OnlineDot({super.key, this.size = 9});

  @override
  State<OnlineDot> createState() => _OnlineDotState();
}

class _OnlineDotState extends State<OnlineDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: T.online,
            boxShadow: [
              BoxShadow(
                color: T.online.withOpacity(0.35 + _c.value * 0.45),
                blurRadius: 6 + _c.value * 6,
                spreadRadius: _c.value * 1.6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* Pulsing LIVE dot (red). */
class PulseDot extends StatefulWidget {
  final double size;
  const PulseDot({super.key, this.size = 9});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = 0.75 + _c.value * 0.45;
          return Container(
            width: widget.size * t,
            height: widget.size * t,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: T.fire,
              boxShadow: [
                BoxShadow(
                  color: T.fire.withOpacity(0.8),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/* Counts up/down to [value] with an ease-out — numbers feel alive. */
class AnimatedNumber extends StatelessWidget {
  final int value;
  final TextStyle style;
  final String suffix;
  const AnimatedNumber({
    super.key,
    required this.value,
    required this.style,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: T.dEpic,
      curve: T.cOut,
      builder: (_, v, __) => Text('$v$suffix', style: style),
    );
  }
}

/* Gradient progress with animated width and a glowing head dot. */
class GradientProgress extends StatelessWidget {
  final double value; // 0..1
  final double height;
  const GradientProgress({super.key, required this.value, this.height = 10});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: T.dEpic,
      curve: T.cOut,
      builder: (_, v, __) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: Stack(
          children: [
            Container(height: height, color: T.surfaceHi),
            FractionallySizedBox(
              widthFactor: v,
              child: Container(
                height: height,
                decoration: const BoxDecoration(gradient: T.fireGrad),
              ),
            ),
            if (v > 0.02)
              Align(
                alignment: Alignment(v * 2 - 1, 0),
                child: Container(
                  width: height + 3,
                  height: height + 3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: T.gold,
                    boxShadow: [
                      BoxShadow(color: T.ember.withOpacity(0.9), blurRadius: 8),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/* Level ring: gradient arc + glow, level number in the center. */
class LevelRing extends StatelessWidget {
  final int level;
  final double progress; // 0..1 to next level
  final double size;
  const LevelRing({super.key, required this.level, required this.progress, this.size = 76});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0, 1)),
      duration: T.dEpic,
      curve: T.cOut,
      builder: (_, v, __) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _LevelRingPainter(v),
          child: Center(
            child: Text(
              '$level',
              style: T.displayBlack(size * 0.36, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelRingPainter extends CustomPainter {
  final double progress;
  _LevelRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 5;
    final track = Paint()
      ..color = T.surfaceHi
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, r, track);
    if (progress <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: r);
    final glow = Paint()
      ..shader = T.fireGradV.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7)
      ..color = T.fire.withOpacity(0.55);
    canvas.drawArc(rect, -math.pi / 2, progress * math.pi * 2, false, glow);
    final arc = Paint()
      ..shader = T.fireGradV.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, progress * math.pi * 2, false, arc);
  }

  @override
  bool shouldRepaint(_LevelRingPainter old) => old.progress != progress;
}

/* Rotating radar sweep + rings — the brand motif from the logo. */
class RadarSweep extends StatefulWidget {
  final double size;
  final double opacity;
  const RadarSweep({super.key, required this.size, this.opacity = 0.16});

  @override
  State<RadarSweep> createState() => _RadarSweepState();
}

class _RadarSweepState extends State<RadarSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          size: Size.square(widget.size),
          painter: _RadarPainter(_c.value * math.pi * 2, widget.opacity),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double angle;
  final double opacity;
  _RadarPainter(this.angle, this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final ringPaint = Paint()
      ..color = T.fire.withOpacity(opacity * 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final f in [0.33, 0.66, 1.0]) {
      canvas.drawCircle(center, r * f, ringPaint);
    }
    final cross = Paint()
      ..color = T.fire.withOpacity(opacity * 0.5)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(center.dx - r, center.dy), Offset(center.dx + r, center.dy), cross);
    canvas.drawLine(Offset(center.dx, center.dy - r), Offset(center.dx, center.dy + r), cross);
    final rect = Rect.fromCircle(center: center, radius: r);
    final sweep = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          T.fire.withOpacity(0),
          T.fire.withOpacity(opacity * 1.6),
        ],
        stops: const [0.75, 1.0],
        transform: GradientRotation(angle),
      ).createShader(rect);
    canvas.drawCircle(center, r, sweep);
    canvas.drawCircle(
      center,
      3,
      Paint()..color = T.ember.withOpacity(opacity * 2.2),
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.angle != angle || old.opacity != opacity;
}

/* Semicircle vibe gauge with an animated fill arc. */
class VibeGauge extends StatelessWidget {
  final int vibe;
  final double size;
  const VibeGauge({super.key, required this.vibe, this.size = 132});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: vibe / 100),
      duration: T.dEpic,
      curve: T.cOut,
      builder: (_, v, __) => SizedBox(
        width: size,
        height: size * 0.62,
        child: CustomPaint(
          painter: _GaugePainter(v, vibeColor(vibe)),
          child: Align(
            alignment: const Alignment(0, 0.55),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$vibe%', style: T.displayBlack(24, color: vibeColor(vibe))),
                Text('движ места', style: T.body(11, color: T.faint, w: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double t;
  final Color color;
  _GaugePainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final rect = Rect.fromLTWH(8, 8, w - 16, (w - 16));
    final track = Paint()
      ..color = T.surfaceHi
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, track);
    if (t <= 0) return;
    final glow = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(rect, math.pi, math.pi * t, false, glow);
    final arc = Paint()
      ..shader = T.fireGrad.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi * t, false, arc);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.t != t || old.color != color;
}

/* Custom geometric nav icons — one 2px stroke language, drawn, not emoji. */
enum NavGlyph { pin, flame, route, ghost }

class NavIcon extends StatelessWidget {
  final NavGlyph glyph;
  final Color color;
  final double size;
  final bool filled;
  const NavIcon({
    super.key,
    required this.glyph,
    required this.color,
    this.size = 23,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _NavIconPainter(glyph, color, filled),
      );
}

class _NavIconPainter extends CustomPainter {
  final NavGlyph glyph;
  final Color color;
  final bool filled;
  _NavIconPainter(this.glyph, this.color, this.filled);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    Offset p(double x, double y) => Offset(x * s, y * s);
    switch (glyph) {
      case NavGlyph.pin:
        final path = Path()
          ..moveTo(12 * s, 21.5 * s)
          ..cubicTo(12 * s, 21.5 * s, 5 * s, 14.8 * s, 5 * s, 10.2 * s)
          ..cubicTo(5 * s, 6.2 * s, 8.1 * s, 3 * s, 12 * s, 3 * s)
          ..cubicTo(15.9 * s, 3 * s, 19 * s, 6.2 * s, 19 * s, 10.2 * s)
          ..cubicTo(19 * s, 14.8 * s, 12 * s, 21.5 * s, 12 * s, 21.5 * s);
        canvas.drawPath(path, filled ? fill : stroke);
        canvas.drawCircle(p(12, 10.2), 3 * s, filled ? (Paint()..color = T.bg) : stroke);
      case NavGlyph.flame:
        final path = Path()
          ..moveTo(12 * s, 2.8 * s)
          ..cubicTo(13.4 * s, 6 * s, 17.8 * s, 8.6 * s, 17.8 * s, 13.4 * s)
          ..cubicTo(17.8 * s, 17.6 * s, 15.2 * s, 20.6 * s, 12 * s, 20.6 * s)
          ..cubicTo(8.8 * s, 20.6 * s, 6.2 * s, 17.6 * s, 6.2 * s, 13.4 * s)
          ..cubicTo(6.2 * s, 10.4 * s, 7.6 * s, 8.4 * s, 9 * s, 6.6 * s)
          ..cubicTo(9.4 * s, 8.4 * s, 10.2 * s, 9.4 * s, 11.2 * s, 10 * s)
          ..cubicTo(10.6 * s, 7.2 * s, 11 * s, 4.8 * s, 12 * s, 2.8 * s);
        canvas.drawPath(path, filled ? fill : stroke);
      case NavGlyph.route:
        canvas.drawCircle(p(6, 18.5), 3 * s, stroke);
        canvas.drawCircle(p(18, 5.5), 3 * s, stroke);
        final path = Path()
          ..moveTo(6 * s, 15.5 * s)
          ..lineTo(6 * s, 11 * s)
          ..cubicTo(6 * s, 7.5 * s, 18 * s, 10.5 * s, 18 * s, 8.5 * s);
        canvas.drawPath(path, stroke);
        canvas.drawCircle(p(6, 18.5), 1.1 * s, fill);
        canvas.drawCircle(p(18, 5.5), 1.1 * s, fill);
      case NavGlyph.ghost:
        final path = Path()
          ..moveTo(5.5 * s, 20.5 * s)
          ..lineTo(5.5 * s, 11 * s)
          ..cubicTo(5.5 * s, 6.6 * s, 8.4 * s, 3.5 * s, 12 * s, 3.5 * s)
          ..cubicTo(15.6 * s, 3.5 * s, 18.5 * s, 6.6 * s, 18.5 * s, 11 * s)
          ..lineTo(18.5 * s, 20.5 * s)
          ..lineTo(15.3 * s, 17.8 * s)
          ..lineTo(12 * s, 20.5 * s)
          ..lineTo(8.7 * s, 17.8 * s)
          ..close();
        canvas.drawPath(path, filled ? fill : stroke);
        if (!filled) {
          canvas.drawCircle(p(9.6, 10.5), 1.3 * s, fill);
          canvas.drawCircle(p(14.4, 10.5), 1.3 * s, fill);
        }
    }
  }

  @override
  bool shouldRepaint(_NavIconPainter old) =>
      old.glyph != glyph || old.color != color || old.filled != filled;
}

/* Shimmering skeleton block for loading states. */
class ShimmerBox extends StatefulWidget {
  final double height;
  final double radius;
  const ShimmerBox({super.key, required this.height, this.radius = 18});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.4 + _c.value * 2.8, 0),
              end: Alignment(-0.4 + _c.value * 2.8, 0),
              colors: const [T.surface, T.surfaceHi, T.surface],
            ),
          ),
        ),
      ),
    );
  }
}

/* Fade + rise stagger for list items, first build only, capped. */
class StaggerIn extends StatefulWidget {
  final int index;
  final Widget child;
  const StaggerIn({super.key, required this.index, required this.child});

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: T.dSlow,
  );
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: T.cOut);

  @override
  void initState() {
    super.initState();
    final delay = math.min(widget.index, 10) * 30;
    if (delay == 0) {
      _c.forward();
    } else {
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - _a.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/* Empty state: big emoji, Unbounded title, quiet hint. */
class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String hint;
  const EmptyState({super.key, required this.emoji, required this.title, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: T.s24, vertical: T.s32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: T.s12),
          Text(title, textAlign: TextAlign.center, style: T.display(17)),
          const SizedBox(height: T.s8),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: T.body(13, color: T.muted),
          ),
        ],
      ),
    );
  }
}

/* App icon (the neon emblem) wrapped in a red halo. */
Widget glowIcon(double size) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.24),
      boxShadow: [
        BoxShadow(color: T.fire.withOpacity(0.55), blurRadius: 46, spreadRadius: 4),
        BoxShadow(color: T.ember.withOpacity(0.25), blurRadius: 90, spreadRadius: 18),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset('assets/icon.png', height: size, width: size),
    ),
  );
}

/* Bottom-sheet shell: drag handle + token surface + top gradient border. */
class SheetShell extends StatelessWidget {
  final Widget child;
  const SheetShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(T.rSheet)),
        border: Border(top: BorderSide(color: T.stroke, width: 1.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: T.s12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: T.muted.withOpacity(0.4),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/* ---------------- confetti ---------------- */

/* Lightweight particle burst — fire colors, ~40 particles, one-shot. */
class ConfettiBurst extends StatefulWidget {
  final VoidCallback? onDone;
  const ConfettiBurst({super.key, this.onDone});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _Particle {
  final double angle, speed, size, spin, delay;
  final Color color;
  final bool circle;
  const _Particle(this.angle, this.speed, this.size, this.spin, this.delay, this.color, this.circle);
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1150),
  );
  late final List<_Particle> _parts;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    const colors = [T.fire, T.ember, T.gold, Color(0xFFFF5A3C), Colors.white];
    _parts = [
      for (var i = 0; i < 42; i++)
        _Particle(
          rnd.nextDouble() * math.pi * 2,
          120 + rnd.nextDouble() * 260,
          4 + rnd.nextDouble() * 5,
          (rnd.nextDouble() - 0.5) * 9,
          rnd.nextDouble() * 0.12,
          colors[i % colors.length],
          rnd.nextBool(),
        ),
    ];
    _c.forward().whenComplete(() => widget.onDone?.call());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(_parts, _c.value),
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> parts;
  final double t;
  _ConfettiPainter(this.parts, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.42);
    for (final p in parts) {
      final lt = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (lt <= 0) continue;
      final ease = 1 - math.pow(1 - lt, 2).toDouble();
      final dx = math.cos(p.angle) * p.speed * ease;
      final dy = math.sin(p.angle) * p.speed * ease + 190 * lt * lt;
      final pos = origin + Offset(dx, dy);
      final alpha = (1 - lt * lt).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withOpacity(alpha);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * lt);
      if (p.circle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.62),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

/* Fire a confetti burst over the current screen. */
void fireConfetti(BuildContext context) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => ConfettiBurst(onDone: () => entry.remove()),
  );
  overlay.insert(entry);
}

/* ---------------- app shell ---------------- */

class TiradaApp extends StatelessWidget {
  const TiradaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TiradA anon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: T.bg,
        colorScheme: const ColorScheme.dark(
          primary: T.fire,
          secondary: T.ember,
          surface: T.surface,
          onSurface: T.text,
        ),
        textTheme: TextTheme(
          displaySmall: T.display(24),
          headlineMedium: T.head(20),
          headlineSmall: T.head(17),
          titleMedium: T.body(15, w: FontWeight.w600),
          bodyMedium: T.body(15),
          bodySmall: T.body(13, color: T.muted),
          labelSmall: T.micro(),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: T.ember,
          selectionColor: Color(0x55E11D1D),
          selectionHandleColor: T.fire,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: T.text,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: T.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: T.s16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: T.fire.withOpacity(0.25)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: T.fire.withOpacity(0.25)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: T.fire, width: 1.4),
          ),
          hintStyle: T.body(14, color: T.faint),
        ),
        cardTheme: CardThemeData(
          color: T.surface,
          elevation: 6,
          shadowColor: T.fire.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(T.rCard),
            side: const BorderSide(color: T.stroke),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: T.surfaceHi,
          contentTextStyle: T.body(13.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: T.stroke),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: WidgetStateProperty.all(false),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supa.auth.onAuthStateChange,
      builder: (context, snap) {
        final session = snap.data?.session ?? supa.auth.currentSession;
        // Guest mode: the app opens straight into the map/places for
        // everyone — an account is optional (friends, presence, sync).
        // The key makes HomePage reload its state on sign-in/sign-out.
        return HomePage(key: ValueKey(session?.user.id ?? 'guest'));
      },
    );
  }
}

/* ---------------- first-launch intro ---------------- */

/* Cold-start wow, ~1.6 s, tap to skip: the neon emblem scales in with a
   glow bloom, one radar sweep turns behind it, the wordmark lands in
   Unbounded — then control hands over to Home. Shown once per cold start
   (it lives in HomePage state, above the data-loading skeleton). */
class SplashIntro extends StatefulWidget {
  final VoidCallback onDone;
  const SplashIntro({super.key, required this.onDone});

  @override
  State<SplashIntro> createState() => _SplashIntroState();
}

class _SplashIntroState extends State<SplashIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(_finish);
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _finish,
        child: GlowBackground(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final logoT = T.cSpring.transform(
                Interval(0, 0.55, curve: Curves.linear).transform(_c.value),
              );
              final textT = Interval(0.35, 0.85, curve: T.cOut).transform(_c.value);
              return Stack(
                alignment: Alignment.center,
                children: [
                  const RadarSweep(size: 300, opacity: 0.16),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: 0.7 + logoT * 0.3,
                        child: Opacity(
                          opacity: logoT.clamp(0, 1),
                          child: glowIcon(128),
                        ),
                      ),
                      const SizedBox(height: T.s24),
                      Opacity(
                        opacity: textT,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - textT)),
                          child: Text.rich(
                            TextSpan(children: [
                              const TextSpan(text: 'TiradA '),
                              TextSpan(
                                text: 'anon',
                                style: T.displayBlack(25, color: T.ember),
                              ),
                            ]),
                            style: T.displayBlack(25),
                          ),
                        ),
                      ),
                      const SizedBox(height: T.s8),
                      Opacity(
                        opacity: textT,
                        child: Text(
                          'живой радар движа твоего города',
                          style: T.body(13, color: T.muted),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    left: T.s24,
                    right: T.s24,
                    bottom: 46,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _c.value,
                        minHeight: 3,
                        backgroundColor: T.surfaceHi,
                        valueColor: const AlwaysStoppedAnimation(T.ember),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/* ---------------- login ---------------- */

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _nick = TextEditingController();
  bool _busy = false;
  String? _error;

  /* A signed-in user must have a profile row (the web app creates one at
     sign-up; without it the name/friends/presence have nothing to bind to). */
  Future<void> _ensureProfile() async {
    final user = supa.auth.currentUser;
    if (user == null) return;
    try {
      final existing = await supa
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      if (existing != null) return;
      var nick = _nick.text.trim();
      if (nick.isEmpty) {
        nick = (user.email ?? 'ghost').split('@').first;
      }
      try {
        await supa.from('profiles').insert({
          'id': user.id,
          'name': nick,
          'avatar': '👻',
          'mode': 'visible',
          'city': 'karmiel',
          'stats': normStats(null),
          'favorites': <String>[],
        });
      } catch (_) {
        // Nick taken (unique index on lower(name)) — retry with a suffix.
        await supa.from('profiles').insert({
          'id': user.id,
          'name': '$nick${100 + (DateTime.now().millisecond % 900)}',
          'avatar': '👻',
          'mode': 'visible',
          'city': 'karmiel',
          'stats': normStats(null),
          'favorites': <String>[],
        });
      }
    } catch (_) {}
  }

  Future<void> _go(bool signUp) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (signUp) {
        await supa.auth.signUp(
          email: _email.text.trim(),
          password: _pass.text,
        );
      } else {
        await supa.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _pass.text,
        );
      }
      await _ensureProfile();
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Что-то пошло не так. Проверь интернет.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        radar: true,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(child: glowIcon(140)),
                const SizedBox(height: 22),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'TiradA '),
                    TextSpan(
                      text: 'anon',
                      style: T.displayBlack(26, color: T.ember),
                    ),
                  ]),
                  textAlign: TextAlign.center,
                  style: T.displayBlack(26),
                ),
                const SizedBox(height: 8),
                Text(
                  'твой город · твои правила',
                  textAlign: TextAlign.center,
                  style: T.body(14, color: T.muted),
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: _nick,
                  decoration: const InputDecoration(
                    hintText: 'Ник (только для нового аккаунта)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pass,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Пароль'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: kRed),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                PressButton(
                  text: _busy ? 'Секунду…' : '🚀 Войти',
                  onPressed: _busy ? null : () => _go(false),
                ),
                const SizedBox(height: 12),
                PressButton(
                  text: '✨ Создать аккаунт',
                  primary: false,
                  onPressed: _busy ? null : () => _go(true),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Тот же аккаунт, что и на сайте tirada-anon.vercel.app',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kMuted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                  child: const Text(
                    'Смотреть без аккаунта',
                    style: TextStyle(color: kMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------- home: shared state + shell ---------------- */

class Friend {
  final String id, name;
  final String? avatar, avatarUrl, mode, cityId;
  final bool online;
  final double? lat, lng;
  const Friend({
    required this.id,
    required this.name,
    this.avatar,
    this.avatarUrl,
    this.mode,
    this.cityId,
    this.online = false,
    this.lat,
    this.lng,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0; // 0 map · 1 places · 2 route · 3 profile
  bool _mapTabOpened = false;
  List<Place> _places = [];
  List<City> _cities = [];
  City? _city;
  Map<String, dynamic>? _profile;
  Map<String, dynamic> _stats = normStats(null);
  final Set<String> _favs = {};
  bool _loading = true;
  bool _introDone = false;
  int? _temp;
  String _wxEmoji = '☀️';
  List<Friend> _friends = [];
  int _tickerIdx = 0;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _load();
    SharedPreferences.getInstance().then((p) {
      hapticsOn = p.getBool('haptics_on') ?? true;
    });
    // v2.0.6 services: bonus-XP bus, steps→XP, FCM pushes.
    AiXpBus.pending.addListener(_drainAiXp);
    StepsTracker.onCredit = (xp) => AiXpBus.credit(xp);
    StepsTracker.start();
    PushService.init();
    PushService.foreground.addListener(_onForegroundPush);
    // v2.0.8: ask for location up front and start the live GPS feed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) LocationService.ensureLocation(context);
    });
    _tickerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _tickerIdx++);
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    AiXpBus.pending.removeListener(_drainAiXp);
    PushService.foreground.removeListener(_onForegroundPush);
    super.dispose();
  }

  /* Bonus XP posted by deep widgets (sharing, steps, city quest) lands
     in stats here, where stats actually live. */
  void _drainAiXp() {
    final v = AiXpBus.pending.value;
    if (v <= 0 || !mounted) return;
    AiXpBus.pending.value = 0;
    _addAiXp(v);
  }

  /* Foreground push → in-app banner, unless the user muted that type in
     Profile → «Уведомления» (prefs notif_<type>, default on). */
  Future<void> _onForegroundPush() async {
    final msg = PushService.foreground.value;
    if (msg == null || !mounted) return;
    try {
      final type = (msg.data['type'] as String?) ?? '';
      const known = {'quest', 'friends', 'votes', 'photos', 'streak', 'rain', 'steps'};
      if (known.contains(type)) {
        final prefs = await SharedPreferences.getInstance();
        if (!(prefs.getBool('notif_$type') ?? true)) return;
      }
    } catch (_) {}
    if (!mounted) return;
    final title = msg.notification?.title ?? 'TiradA anon';
    final body = msg.notification?.body ?? '';
    snack(context, body.isEmpty ? '🔔 $title' : '🔔 $title — $body');
  }

  Future<void> _load() async {
    try {
      final placesRaw = await rootBundle.loadString('assets/places.json');
      final citiesRaw = await rootBundle.loadString('assets/cities.json');
      final places = (jsonDecode(placesRaw) as List)
          .map((e) => Place.fromJson(e as Map<String, dynamic>))
          .toList();
      final cities = (jsonDecode(citiesRaw) as List)
          .map((e) => City.fromJson(e as Map<String, dynamic>))
          .toList();
      cities.sort((a, b) =>
          (a.id == 'karmiel' ? 0 : 1).compareTo(b.id == 'karmiel' ? 0 : 1));
      Map<String, dynamic>? profile;
      final uid = myUidOrNull;
      if (uid != null) {
        try {
          profile = await supa
              .from('profiles')
              .select()
              .eq('id', uid)
              .maybeSingle();
        } catch (_) {}
      }
      // Local database (on-phone): the guest's favorites and stats live in
      // SharedPreferences and survive restarts; for a signed-in user the
      // cloud profile wins and the local copy is refreshed from it.
      final prefs = await SharedPreferences.getInstance();
      final localFavs = prefs.getStringList('local_favs') ?? <String>[];
      final localStatsRaw = prefs.getString('local_stats');
      if (!mounted) return;
      setState(() {
        _places = places;
        _cities = cities;
        _city = cities.firstWhere(
          (c) => c.id == (profile?['city'] as String? ?? 'karmiel'),
          orElse: () => cities.first,
        );
        _profile = profile;
        if (profile != null) {
          _stats = normStats(profile['stats']);
          final favs = profile['favorites'];
          if (favs is List) {
            _favs.addAll(favs.map((e) => e.toString()));
          }
        } else {
          // Guest (or offline): restore the on-phone copy.
          if (localStatsRaw != null) {
            try {
              _stats = normStats(jsonDecode(localStatsRaw));
            } catch (_) {}
          }
          _favs.addAll(localFavs);
        }
        _loading = false;
      });
      if (profile != null) {
        _persistLocal();
        PushService.registerCurrent(); // FCM token → device_tokens
      }
      if (_city != null) _fetchTemp(_city!);
      _loadFriends();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Place> get _cityPlaces =>
      _city == null ? [] : _places.where((p) => p.city == _city!.id).toList();

  /* Write favorites + stats to the on-phone database. */
  Future<void> _persistLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('local_favs', _favs.toList());
      await prefs.setString('local_stats', jsonEncode(normStats(_stats)));
    } catch (_) {}
  }

  Future<void> _toggleFav(Place p) async {
    HapticFeedback.selectionClick();
    final adding = !_favs.contains(p.id);
    setState(() {
      if (_favs.contains(p.id)) {
        _favs.remove(p.id);
      } else {
        _favs.add(p.id);
      }
    });
    if (adding) _cityQuestMark('fav', p);
    _persistLocal(); // on-phone database first — works for guests too
    final uid = myUidOrNull;
    if (uid == null) return;
    try {
      await supa
          .from('profiles')
          .update({'favorites': _favs.toList()}).eq('id', uid);
    } catch (_) {}
  }

  Future<void> _saveStats() async {
    _persistLocal(); // on-phone database first — works for guests too
    final uid = myUidOrNull;
    if (uid == null) return;
    try {
      await supa
          .from('profiles')
          .update({'stats': normStats(_stats)}).eq('id', uid);
    } catch (_) {}
  }

  void _bumpStat(String key, int delta) {
    setState(() => _stats[key] = statInt(_stats, key) + delta);
    _saveStats();
  }

  void _addAiXp(int xp) {
    setState(() => _stats['aiXp'] = statInt(_stats, 'aiXp') + xp);
    _saveStats();
  }

  /* Friends for the «Я в деле» sheet (profiles of accepted friendships). */
  Future<void> _loadFriends() async {
    final uid = myUidOrNull;
    if (uid == null) {
      if (mounted) setState(() => _friends = []);
      return;
    }
    try {
      final fr = await supa
          .from('friendships')
          .select('requester, addressee')
          .eq('status', 'accepted')
          .or('requester.eq.$uid, addressee.eq.$uid');
      final ids = <String>{};
      for (final r in fr as List) {
        final other = r['requester'] == uid ? r['addressee'] : r['requester'];
        if (other is String) ids.add(other);
      }
      if (ids.isEmpty) {
        if (mounted) setState(() => _friends = []);
        return;
      }
      final profs = await supa
          .from('profiles')
          .select('id, name, avatar, avatar_url, online, mode, city')
          .inFilter('id', ids.toList());
      if (!mounted) return;
      setState(() {
        _friends = [
          for (final p in profs as List)
            Friend(
              id: p['id'] as String,
              name: (p['name'] as String?) ?? 'Призрак',
              avatar: p['avatar'] as String?,
              avatarUrl: p['avatar_url'] as String?,
              mode: p['mode'] as String?,
              cityId: p['city'] as String?,
              online: p['online'] == true,
            ),
        ];
      });
    } catch (_) {}
  }

  /* Current temperature + condition from Open-Meteo (free, no key).
     Hidden on failure. */
  Future<void> _fetchTemp(City c) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${c.lat}&longitude=${c.lng}&current=temperature_2m,weathercode',
      );
      final req = await client.getUrl(uri);
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final cur = data['current'] as Map?;
      final t = cur?['temperature_2m'];
      final code = (cur?['weathercode'] as num?)?.toInt();
      if (t is num && mounted) {
        setState(() {
          _temp = t.round();
          _wxEmoji = wxEmojiFor(code, DateTime.now().hour);
        });
      }
    } catch (_) {}
  }

  /* «Я здесь» check-in: the place joins stats.places; the first check-in
     of a day also counts that night (lastDealDay semantics, conservative:
     streak is left to its own logic). */
  /* City-quest tracker: real actions complete the daily city quest;
     finishing it pays the +50 XP bonus once (CityQuest.mark guards). */
  Future<void> _cityQuestMark(String kind, Place p) async {
    final city = _city;
    if (city == null) return;
    final bonusDue = await CityQuest.mark(kind, p, _cityPlaces, city);
    if (bonusDue && mounted) {
      _addAiXp(50);
      fireConfetti(context);
      snack(context, '🏙️ Квест города выполнен · +50 XP');
    }
  }

  /* Photo published from the place sheet: stats + city quest step. */
  void _onPhotoUploaded(Place p) {
    _bumpStat('photos', 1);
    _cityQuestMark('photo', p);
  }

  void _checkIn(Place p) {
    final places = (normStats(_stats)['places'] as List)
        .map((e) => e.toString())
        .toList();
    var changed = false;
    if (!places.contains(p.id)) {
      places.add(p.id);
      _stats['places'] = places;
      changed = true;
    }
    if (_stats['lastDealDay'] != dayKey()) {
      _stats['lastDealDay'] = dayKey();
      _stats['nights'] = statInt(_stats, 'nights') + 1;
      changed = true;
    }
    if (changed) {
      setState(() {});
      _saveStats();
    }
    _cityQuestMark('checkin', p);
  }

  Future<void> _setHaptics(bool on) async {
    hapticsOn = on;
    if (mounted) setState(() {});
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('haptics_on', on);
    } catch (_) {}
  }

  void _onCity(City c) {
    setState(() {
      _city = c;
      _temp = null;
    });
    _fetchTemp(c);
  }

  void _openTasks() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TasksPage(
          stats: _stats,
          onTaskDone: () => _bumpStat('tasks', 1),
          onAiXp: _addAiXp,
          cityPlaces: _cityPlaces,
          city: _city,
        ),
      ),
    );
  }

  Future<void> _openDeal() async {
    HapticFeedback.mediumImpact();
    await _loadFriends();
    if (!mounted || _city == null) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DealSheet(
        places: _cityPlaces,
        city: _city!,
        cities: _cities,
        friends: _friends,
        signedIn: myUidOrNull != null,
        onRoute: () => setState(() => _tab = 2),
      ),
    );
  }

  void _showCityPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.7,
        ),
        child: SheetShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Выбери город', style: T.head(18)),
              ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _cities.length,
                itemBuilder: (_, i) {
                  final c = _cities[i];
                  final sel = c.id == _city?.id;
                  return ListTile(
                    leading: const Text('📍', style: TextStyle(fontSize: 18)),
                    title: Text(
                      c.name,
                      style: TextStyle(
                        fontWeight: sel ? FontWeight.w900 : FontWeight.w600,
                        color: sel ? kOrange : kText,
                      ),
                    ),
                    trailing: sel
                        ? const Icon(Icons.check, color: kRed, size: 20)
                        : null,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _onCity(c);
                    },
                  );
                },
              ),
            ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  /* ---------- shell pieces: header / LIVE bar / ticker / nav ---------- */

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(color: kRed.withOpacity(0.55), blurRadius: 14),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.asset('assets/icon.png', width: 36, height: 36),
            ),
          ),
          const SizedBox(width: 10),
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'TiradA '),
              TextSpan(text: 'anon', style: T.head(19, color: T.fire)),
            ]),
            style: T.head(19),
          ),
          const Spacer(),
          if (_city != null)
            GestureDetector(
              onTap: _showCityPicker,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: kBorder),
                ),
                child: Text(
                  '📍 ${_city!.name} ▾',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (_temp != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: kOrange.withOpacity(0.5)),
              ),
              child: Text(
                '$_wxEmoji $_temp°',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _tab = 3);
            },
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [kRed, kOrange]),
                boxShadow: [
                  BoxShadow(color: kRed.withOpacity(0.55), blurRadius: 14),
                ],
              ),
              child: const Text('👻', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveBar() {
    final places = _cityPlaces;
    final hot = places.where((p) => vibeOf(p) >= 70).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
      child: Row(
        children: [
          const PulseDot(),
          const SizedBox(width: 8),
          const Text(
            'LIVE',
            style: TextStyle(
              color: kRed,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'в городе: '),
                TextSpan(
                  text: '$hot мест жарких',
                  style: const TextStyle(
                    color: kOrange,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: ' сейчас • всего ${places.length} мест на радаре'),
              ]),
              maxLines: 2,
              style: const TextStyle(color: kText, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _tickerMessages() {
    final places = [..._cityPlaces]
      ..sort((a, b) => vibeOf(b).compareTo(vibeOf(a)));
    if (places.isEmpty || _city == null) return ['👻 Радар включён…'];
    final hot = places.where((p) => vibeOf(p) >= 70).length;
    return [
      '🔥 ${places.first.name} — самый живой движ по радару сейчас…',
      '📍 ${_city!.name}: ${places.length} мест на радаре, $hot жарких прямо сейчас',
      '👻 Жми 🔥 внизу — город сам соберёт твою ночь',
    ];
  }

  Widget _ticker() {
    final msgs = _tickerMessages();
    final msg = msgs[_tickerIdx % msgs.length];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: kRed.withOpacity(0.10),
        border: Border(
          top: BorderSide(color: kRed.withOpacity(0.25)),
          bottom: BorderSide(color: kRed.withOpacity(0.25)),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: Text(
          msg,
          key: ValueKey(msg),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5, color: kText),
        ),
      ),
    );
  }

  Widget _navSlot(int idx, NavGlyph glyph, String label) {
    final active = _tab == idx;
    return Pressable(
      onTap: () {
        setState(() => _tab = idx);
        // First time the Map tab is opened: re-run the location flow
        // (the permission may have been granted in Settings meanwhile).
        if (idx == 0 && !_mapTabOpened) {
          _mapTabOpened = true;
          LocationService.ensureLocation(context);
        }
      },
      child: AnimatedContainer(
        duration: T.dMed,
        curve: T.cOut,
        padding: EdgeInsets.symmetric(
          horizontal: active ? 14 : 11,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: active ? T.fire.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(T.rPill),
          border: Border.all(
            color: active ? T.fire.withOpacity(0.6) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavIcon(
              glyph: glyph,
              color: active ? T.ember : T.muted,
              filled: active,
              size: 22,
            ),
            if (active) ...[
              const SizedBox(width: 7),
              Text(label, style: T.body(12.5, w: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bottomNav() {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF101014),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: kRed.withOpacity(0.30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _navSlot(0, NavGlyph.pin, 'Карта'),
            _navSlot(1, NavGlyph.flame, 'Места'),
            _DealFab(onTap: _openDeal),
            _navSlot(2, NavGlyph.route, 'Маршрут'),
            _navSlot(3, NavGlyph.ghost, 'Профиль'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_introDone) {
      // First-launch wow: animated intro replaces the cold-start spinner.
      return SplashIntro(
        onDone: () {
          if (mounted) setState(() => _introDone = true);
        },
      );
    }
    if (_loading) {
      return const Scaffold(
        body: GlowBackground(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(T.s16, T.s24, T.s16, T.s16),
              child: Column(
                children: [
                  ShimmerBox(height: 54),
                  SizedBox(height: T.s12),
                  ShimmerBox(height: 96),
                  SizedBox(height: T.s12),
                  ShimmerBox(height: 96),
                  SizedBox(height: T.s12),
                  ShimmerBox(height: 96),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            _liveBar(),
            _ticker(),
            Expanded(
              // IndexedStack: tabs are built once and kept alive — the
              // MapLibre widget is never recreated on tab switches.
              child: IndexedStack(
                index: _tab,
                children: [
                  MapTab(
                    places: _cityPlaces,
                    cities: _cities,
                    city: _city,
                    onCity: _onCity,
                    favs: _favs,
                    onToggleFav: _toggleFav,
                    onCheckIn: _checkIn,
                    onPhotoUploaded: _onPhotoUploaded,
                  ),
                  PlacesTab(
                    places: _cityPlaces,
                    city: _city,
                    favs: _favs,
                    onToggleFav: _toggleFav,
                    onOpenTasks: _openTasks,
                    onCheckIn: _checkIn,
                    onPhotoUploaded: _onPhotoUploaded,
                  ),
                  RouteTab(
                    places: _cityPlaces,
                    city: _city,
                    onTaskDone: () => _bumpStat('tasks', 1),
                    onRouteBuilt: () => _bumpStat('routes', 1),
                  ),
                  ProfileTab(
                    profile: _profile,
                    stats: _stats,
                    favs: _favs,
                    places: _places,
                    city: _city,
                    onProfileChanged: (p) => setState(() => _profile = p),
                    onOpenTasks: _openTasks,
                    hapticsValue: hapticsOn,
                    onToggleHaptics: _setHaptics,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }
}

/* Raised pulsing center FAB — «Ты в деле». */
class _DealFab extends StatefulWidget {
  final VoidCallback onTap;
  const _DealFab({required this.onTap});

  @override
  State<_DealFab> createState() => _DealFabState();
}

class _DealFabState extends State<_DealFab> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, child) {
              final s = 1 + _c.value * 0.07;
              return Transform.scale(scale: s, child: child);
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                const RadarSweep(size: 86, opacity: 0.13),
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: T.fireGradV,
                    boxShadow: [
                      BoxShadow(
                        color: T.fire.withOpacity(0.65),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const NavIcon(
                    glyph: NavGlyph.flame,
                    color: Colors.white,
                    filled: true,
                    size: 29,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Ты в деле',
            style: TextStyle(
              color: kRed,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- «Я в деле» sheet + poll ---------------- */

class DealSheet extends StatefulWidget {
  final List<Place> places;
  final City city;
  final List<City> cities;
  final List<Friend> friends;
  final bool signedIn;
  final VoidCallback onRoute;
  const DealSheet({
    super.key,
    required this.places,
    required this.city,
    required this.cities,
    required this.friends,
    required this.signedIn,
    required this.onRoute,
  });

  @override
  State<DealSheet> createState() => _DealSheetState();
}

class _DealSheetState extends State<DealSheet> {
  int _rec = 0;
  String? _myVote;

  List<Place> get _candidates {
    final sorted = [...widget.places]
      ..sort((a, b) => vibeOf(b).compareTo(vibeOf(a)));
    return sorted.take(3).toList();
  }

  int _baseVotes(Place p) => stableHash('${p.id}|${dayKey()}') % 4;

  String _cityName(String? id) {
    if (id == null) return widget.city.name;
    for (final c in widget.cities) {
      if (c.id == id) return c.name;
    }
    return widget.city.name;
  }

  @override
  Widget build(BuildContext context) {
    final cand = _candidates;
    final inDeal = widget.friends.where((f) => f.online).toList();
    final onlineCount =
        widget.signedIn ? inDeal.length + 1 : 1; // guest: just himself
    final recPlace = cand.isEmpty ? null : cand[_rec % cand.length];
    return SheetShell(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Stack(
              alignment: Alignment.center,
              children: [
                RadarSweep(size: 118, opacity: 0.13),
                Text('🔥', textAlign: TextAlign.center, style: TextStyle(fontSize: 38)),
              ],
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Я в '),
                TextSpan(text: 'деле', style: T.display(23, color: T.ember)),
              ]),
              textAlign: TextAlign.center,
              style: T.display(23),
            ),
            const SizedBox(height: 6),
            const Text(
              'Один тап — и город сам собирает твою ночь.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const OnlineDot(),
                const SizedBox(width: 7),
                Text('Сейчас в сети: ', style: T.body(14, w: FontWeight.w600)),
                AnimatedNumber(value: onlineCount, style: T.num(15)),
              ],
            ),
            const SizedBox(height: 18),
            sectionLabel('Друзья сейчас в деле · ${inDeal.length}',
                color: const Color(0xFFFF8A7A)),
            if (!widget.signedIn)
              const Text(
                'Ты пока гость 👻 Войди в аккаунт — и здесь будут друзья, которые сейчас в деле.',
                style: TextStyle(color: kMuted, fontSize: 13),
              ),
            if (widget.signedIn && inDeal.isEmpty)
              const Text(
                'Пока никто из друзей не в деле. Будь первым 🔥',
                style: TextStyle(color: kMuted, fontSize: 13),
              ),
            for (final f in inDeal)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: kSurface2,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kRed.withOpacity(0.22)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: kSurface,
                      backgroundImage:
                          f.avatarUrl != null ? NetworkImage(f.avatarUrl!) : null,
                      child: f.avatarUrl == null
                          ? Text(f.avatar ?? '👻',
                              style: const TextStyle(fontSize: 19))
                          : null,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.mode == 'ghost' ? 'Призрак' : f.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'в сети · ${_cityName(f.cityId)}',
                            style: const TextStyle(color: kGreen, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      '🔥 в деле',
                      style: TextStyle(
                        color: kOrange,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            if (recPlace != null) ...[
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kRed, kOrange]),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(color: kRed.withOpacity(0.5), blurRadius: 14),
                    ],
                  ),
                  child: const Text(
                    '🏆 Топ выбор радара',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '📍 А движ уже есть: ${recPlace.name}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Builder(builder: (_) {
                final v = vibeOf(recPlace);
                final origin = myLocationNotifier.value;
                final d = haversineKm(
                  origin?.latitude ?? widget.city.lat,
                  origin?.longitude ?? widget.city.lng,
                  recPlace.lat,
                  recPlace.lng,
                );
                return Text(
                  'Город ${widget.city.name} · сейчас там ${vibeWord(v)} (движ $v%), '
                  'от тебя · по прямой: ${fmtKm(d)} км. '
                  'Можно стартовать отсюда — друзья подтянутся по ссылке.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kMuted, fontSize: 13),
                );
              }),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: PressButton(
                      text: '🚗 Маршрут',
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onRoute();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PressButton(
                      text: 'Другое место',
                      primary: false,
                      onPressed: cand.length < 2
                          ? null
                          : () => setState(() => _rec++),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            GlassCard(
              gradientBorder: true,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '🗳️ Куда идём?',
                    textAlign: TextAlign.center,
                    style: T.head(17),
                  ),
                  const SizedBox(height: 12),
                  for (final p in cand)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _myVote = p.id);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: kSurface2,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _myVote == p.id
                                ? kRed
                                : kRed.withOpacity(0.22),
                            width: _myVote == p.id ? 1.6 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: kRed.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(999),
                                border:
                                    Border.all(color: kRed.withOpacity(0.6)),
                              ),
                              child: Text(
                                '${_baseVotes(p) + (_myVote == p.id ? 1 : 0)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${vibeOf(p)}%',
                              style: const TextStyle(
                                color: kOrange,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Text(
                    'Тапни место — это будет твой голос',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  PressButton(
                    text: 'Позвать голосовать 👻',
                    primary: false,
                    onPressed: () => shareWithXp(
                      context,
                      'Голосование за движ в TiradA anon 👻 Присоединяйся: https://tirada-anon.vercel.app',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- place sheet (rich) ---------------- */

void showPlaceSheet(
  BuildContext context,
  Place p, {
  required Set<String> favs,
  required void Function(Place) onToggleFav,
  required List<Place> cityPlaces,
  required City? city,
  void Function(Place)? onCheckIn,
  void Function(Place)? onPhotoUploaded,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => PlaceSheet(
      place: p,
      favs: favs,
      onToggleFav: onToggleFav,
      cityPlaces: cityPlaces,
      city: city,
      onCheckIn: onCheckIn,
      onPhotoUploaded: onPhotoUploaded,
    ),
  );
}

class PlaceSheet extends StatefulWidget {
  final Place place;
  final Set<String> favs;
  final void Function(Place) onToggleFav;
  final List<Place> cityPlaces;
  final City? city;
  final void Function(Place)? onCheckIn;
  final void Function(Place)? onPhotoUploaded;
  const PlaceSheet({
    super.key,
    required this.place,
    required this.favs,
    required this.onToggleFav,
    required this.cityPlaces,
    required this.city,
    this.onCheckIn,
    this.onPhotoUploaded,
  });

  @override
  State<PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<PlaceSheet> {
  late Place _place;
  bool _here = false;
  List<Map<String, dynamic>> _photos = [];
  Map<String, int> _fires = {};
  final Set<String> _myFires = {};
  List<Map<String, dynamic>> _reviews = [];
  int _crowdFriends = 0;
  bool _uploading = false;
  int _myRating = 5;
  final TextEditingController _reviewCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _place = widget.place;
    _loadPhotos();
    _loadReviews();
    _loadCrowd();
  }

  @override
  void dispose() {
    _reviewCtl.dispose();
    super.dispose();
  }

  /* Read-only ghost gallery — same query shape as the web app:
     place_photos (hidden=false, reports<3, newest first), visibility
     filtered on the client, 🔥 counts from photo_reactions. */
  Future<void> _loadPhotos() async {
    try {
      final rows = await supa
          .from('place_photos')
          .select('id,place_id,user_id,url,visibility,reports,created_at')
          .eq('place_id', _place.id)
          .eq('hidden', false)
          .lt('reports', 3)
          .order('created_at', ascending: false)
          .limit(30);
      final uid = myUidOrNull;
      final visible = <Map<String, dynamic>>[
        for (final r in rows as List)
          if (r['visibility'] == 'public' || (uid != null && r['user_id'] == uid))
            (r as Map).cast<String, dynamic>(),
      ];
      final fires = <String, int>{};
      final mine = <String>{};
      if (visible.isNotEmpty) {
        try {
          final rr = await supa
              .from('photo_reactions')
              .select('photo_id, user_id')
              .inFilter('photo_id', visible.map((e) => e['id']).toList());
          for (final r in rr as List) {
            final id = r['photo_id'].toString();
            fires[id] = (fires[id] ?? 0) + 1;
            if (uid != null && r['user_id'] == uid) mine.add(id);
          }
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _photos = visible;
        _fires = fires;
        _myFires
          ..clear()
          ..addAll(mine);
      });
    } catch (_) {
      // Gallery is best-effort (RLS may hide it from guests) — stay silent.
    }
  }

  void _swap(Place p) {
    setState(() {
      _place = p;
      _here = false;
      _photos = [];
      _fires = {};
      _myFires.clear();
      _reviews = [];
      _crowdFriends = 0;
    });
    _loadPhotos();
    _loadReviews();
    _loadCrowd();
  }

  /* Ghost reviews (place_reviews): latest first; average over the
     fetched window. Fails silently — reviews are an enhancement. */
  Future<void> _loadReviews() async {
    try {
      final rows = await supa
          .from('place_reviews')
          .select('id, place_id, user_id, ghost, rating, text, created_at')
          .eq('place_id', _place.id)
          .order('created_at', ascending: false)
          .limit(50);
      if (!mounted) return;
      setState(() {
        _reviews = [
          for (final r in rows as List) (r as Map).cast<String, dynamic>(),
        ];
      });
    } catch (_) {}
  }

  /* Friends physically at this place right now: live rows in
     profile_locations within ~80 m (excluding me). Best-effort. */
  Future<void> _loadCrowd() async {
    try {
      final uid = myUidOrNull;
      final rows = await supa
          .from('profile_locations')
          .select('user_id, lat, lng')
          .limit(300);
      var n = 0;
      for (final r in rows as List) {
        if (r['user_id'] == uid) continue;
        final lat = (r['lat'] as num?)?.toDouble();
        final lng = (r['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;
        if (haversineKm(lat, lng, _place.lat, _place.lng) < 0.08) n++;
      }
      if (mounted) setState(() => _crowdFriends = n);
    } catch (_) {}
  }

  /* 🔥 on a gallery photo: one reaction per user, tap toggles. */
  Future<void> _toggleFire(Map<String, dynamic> ph) async {
    final uid = myUidOrNull;
    if (uid == null) {
      snack(context, 'Войди, чтобы ставить 🔥');
      return;
    }
    final id = ph['id'].toString();
    final mine = _myFires.contains(id);
    tickSelect();
    setState(() {
      if (mine) {
        _myFires.remove(id);
        _fires[id] = math.max(0, (_fires[id] ?? 1) - 1);
      } else {
        _myFires.add(id);
        _fires[id] = (_fires[id] ?? 0) + 1;
      }
    });
    try {
      if (mine) {
        await supa
            .from('photo_reactions')
            .delete()
            .eq('photo_id', ph['id'])
            .eq('user_id', uid);
      } else {
        await supa.from('photo_reactions').insert({
          'photo_id': ph['id'],
          'user_id': uid,
        });
      }
    } catch (_) {}
  }

  Future<void> _submitReview() async {
    final uid = myUidOrNull;
    if (uid == null) return;
    try {
      await supa.from('place_reviews').insert({
        'place_id': _place.id,
        'user_id': uid,
        'ghost': ghostLabelFor(uid),
        'rating': _myRating,
        'text': _reviewCtl.text.trim(),
      });
      _reviewCtl.clear();
      if (!mounted) return;
      snack(context, 'Отзыв опубликован 👻');
      _loadReviews();
    } catch (_) {
      if (mounted) snack(context, 'Отзыв не отправился — попробуй ещё раз');
    }
  }

  /* Publish a photo to this place: pick → EXIF-stripped re-encode →
     consent sheet (Всем / Только друзьям / Не показывать) → upload to
     the place-photos bucket → place_photos row → stats via HomePage. */
  Future<void> _addPhoto() async {
    final uid = myUidOrNull;
    if (uid == null) {
      snack(context, 'Войди, чтобы добавлять фото');
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      );
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SheetShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('📷', style: TextStyle(fontSize: 20)),
              title: Text('Камера', style: T.body(15, w: FontWeight.w600)),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Text('🖼️', style: TextStyle(fontSize: 20)),
              title: Text('Галерея', style: T.body(15, w: FontWeight.w600)),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final bytes = await pickAndProcessImage(source);
    if (bytes == null || !mounted) return;
    final vis = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SheetShell(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(T.s20, T.s4, T.s20, T.s16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Кто увидит фото?', style: T.head(16)),
              const SizedBox(height: T.s12),
              FireButton(
                text: '🌍 Всем',
                small: true,
                onPressed: () => Navigator.of(context).pop('public'),
              ),
              const SizedBox(height: T.s8),
              GhostButton(
                text: '👻 Только друзьям',
                small: true,
                onPressed: () => Navigator.of(context).pop('friends'),
              ),
              const SizedBox(height: T.s8),
              GhostButton(
                text: 'Не показывать',
                small: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
    if (vis == null || !mounted) return; // «Не показывать» = cancel
    setState(() => _uploading = true);
    try {
      final path =
          '${_place.id}/$uid-${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supa.storage.from('place-photos').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      final url = supa.storage.from('place-photos').getPublicUrl(path);
      await supa.from('place_photos').insert({
        'place_id': _place.id,
        'user_id': uid,
        'url': url,
        'visibility': vis,
      });
      widget.onPhotoUploaded?.call(_place);
      if (!mounted) return;
      fireConfetti(context);
      snack(context, 'Фото опубликовано 📸 · +25 XP за фото');
      _loadPhotos();
    } catch (_) {
      if (mounted) snack(context, 'Фото не загрузилось — попробуй ещё раз');
    }
    if (mounted) setState(() => _uploading = false);
  }

  Widget _stars(double rating) {
    final full = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            Icons.star_rounded,
            size: 17,
            color: i < full ? T.gold : T.faint.withOpacity(0.5),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _place;
    final v = vibeOf(p);
    final fav = widget.favs.contains(p.id);
    final similar = widget.cityPlaces
        .where((e) => e.type == p.type && e.id != p.id)
        .toList()
      ..sort((a, b) => vibeOf(b).compareTo(vibeOf(a)));
    return SheetShell(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(T.s20, T.s4, T.s20, T.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: typeColor(p.type).withOpacity(0.16),
                    boxShadow: [
                      BoxShadow(
                        color: typeColor(p.type).withOpacity(0.45),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Text(
                    kTypeEmoji[p.type] ?? '📍',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: T.s12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(p.name, style: T.head(19)),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    fav ? Icons.favorite : Icons.favorite_border,
                    color: fav ? T.fire : T.muted,
                    size: 27,
                  ),
                  onPressed: () {
                    tickSelect();
                    widget.onToggleFav(p);
                    setState(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: T.s8),
            Center(child: VibeGauge(vibe: v)),
            const SizedBox(height: T.s4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (p.rating != null) ...[
                  _stars(p.rating!),
                  const SizedBox(width: T.s8),
                  Text(
                    '${p.rating!.toStringAsFixed(1)}${p.reviews != null ? ' · ${p.reviews} отзывов' : ''}',
                    style: T.body(13, color: T.muted),
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: T.online.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(T.rPill),
                      border: Border.all(color: T.online.withOpacity(0.5)),
                    ),
                    child: Text(
                      '✨ новое место',
                      style: T.body(11.5, color: T.online, w: FontWeight.w700),
                    ),
                  ),
                const SizedBox(width: T.s12),
                Text(
                  priceDetailText(p),
                  style: T.num(12.5, color: T.gold),
                ),
              ],
            ),
            // Address + live distance (hidden gracefully until the map
            // has a real position) + how many people are here now.
            ValueListenableBuilder<LatLng?>(
              valueListenable: myLocationNotifier,
              builder: (_, origin, __) {
                final dist = origin == null
                    ? null
                    : haversineKm(
                        origin.latitude, origin.longitude, p.lat, p.lng);
                if (p.address.isEmpty && dist == null) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: T.s8),
                  child: Text(
                    [
                      if (p.address.isNotEmpty) '📍 ${p.address}',
                      if (dist != null) '· ${fmtKm(dist)} км от тебя',
                    ].join(' '),
                    textAlign: TextAlign.center,
                    style: T.body(12.5, color: T.muted),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              '👥 Сейчас отдыхают: ~${crowdOf(p)}'
              '${_crowdFriends > 0 ? ' · друзья рядом: $_crowdFriends' : ''}',
              textAlign: TextAlign.center,
              style: T.body(12.5, color: T.salmon, w: FontWeight.w600),
            ),
            const SizedBox(height: T.s16),
            Row(
              children: [
                Expanded(
                  child: _here
                      ? GhostButton(
                          text: '✓ Ты здесь',
                          small: true,
                          onPressed: () {},
                        )
                      : FireButton(
                          text: '✓ Я здесь',
                          small: true,
                          onPressed: () {
                            widget.onCheckIn?.call(p);
                            setState(() => _here = true);
                            fireConfetti(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Чек-ин засчитан · место в твоей статистике 👻'),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(width: T.s12),
                Expanded(
                  child: GhostButton(
                    text: 'Поделиться',
                    small: true,
                    onPressed: () => shareWithXp(
                      context,
                      '${p.name} — движ ${vibeOf(p)}% в TiradA anon 🔥',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: T.s12),
            GhostButton(
              text: _uploading ? 'Загрузка…' : '📸 Добавить фото',
              small: true,
              onPressed: _uploading ? () {} : _addPhoto,
            ),
            if (_photos.isNotEmpty) ...[
              const SizedBox(height: T.s20),
              sectionLabel('📸 Фото призраков здесь', color: T.salmon),
              SizedBox(
                height: 92,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  itemBuilder: (_, i) {
                    final ph = _photos[i];
                    final fires = _fires[ph['id'].toString()] ?? 0;
                    final mine = _myFires.contains(ph['id'].toString());
                    return GestureDetector(
                      onTap: () => _toggleFire(ph),
                      child: Container(
                      width: 92,
                      margin: const EdgeInsets.only(right: T.s8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              ph['url'].toString(),
                              width: 92,
                              height: 92,
                              fit: BoxFit.cover,
                              cacheWidth: 220,
                              errorBuilder: (_, __, ___) => Container(
                                color: T.surfaceHi,
                                child: const Center(child: Text('👻')),
                              ),
                            ),
                          ),
                          if (fires > 0)
                            Positioned(
                              right: 5,
                              bottom: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: mine
                                      ? T.fire.withOpacity(0.88)
                                      : Colors.black.withOpacity(0.65),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '🔥 $fires',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: T.s4),
              Text(
                'тап по фото — поставить 🔥',
                style: T.body(11, color: T.faint),
              ),
            ],
            // ---- ghost reviews ----
            const SizedBox(height: T.s20),
            sectionLabel('💬 Отзывы призраков', color: T.salmon),
            if (_reviews.isEmpty)
              Text(
                'Пока тихо — стань первым призраком с отзывом.',
                style: T.body(12.5, color: T.muted),
              )
            else ...[
              Builder(builder: (_) {
                final avg = _reviews.fold<double>(
                        0, (a, r) => a + ((r['rating'] as num?)?.toDouble() ?? 0)) /
                    _reviews.length;
                return Row(
                  children: [
                    _stars(avg),
                    const SizedBox(width: T.s8),
                    Text(
                      '${avg.toStringAsFixed(1)} · ${_reviews.length} отзывов призраков',
                      style: T.body(12.5, color: T.muted),
                    ),
                  ],
                );
              }),
              const SizedBox(height: T.s8),
              for (final r in _reviews.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: T.s8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('👻', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: T.s8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  (r['ghost'] as String?) ?? 'Призрак',
                                  style: T.body(12.5, w: FontWeight.w700),
                                ),
                                const SizedBox(width: T.s8),
                                Text(
                                  '⭐' * ((r['rating'] as num?)?.toInt() ?? 0),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                            if ((r['text'] as String? ?? '').isNotEmpty)
                              Text(
                                r['text'].toString(),
                                style: T.body(13, color: T.muted),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (myUidOrNull != null) ...[
              const SizedBox(height: T.s8),
              Row(
                children: [
                  for (var i = 1; i <= 5; i++)
                    GestureDetector(
                      onTap: () => setState(() => _myRating = i),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Icon(
                          Icons.star_rounded,
                          size: 26,
                          color: i <= _myRating
                              ? T.gold
                              : T.faint.withOpacity(0.5),
                        ),
                      ),
                    ),
                  const SizedBox(width: T.s8),
                  Expanded(
                    child: TextField(
                      controller: _reviewCtl,
                      decoration: const InputDecoration(
                        hintText: '✍️ Оставить отзыв…',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: T.s8),
              GhostButton(
                text: '✍️ Оставить отзыв',
                small: true,
                onPressed: _submitReview,
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: T.s8),
                child: GhostButton(
                  text: 'Войди, чтобы оставить отзыв',
                  small: true,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const LoginPage()),
                  ),
                ),
              ),
            if (similar.isNotEmpty) ...[
              const SizedBox(height: T.s20),
              sectionLabel('Похожие места', color: T.salmon),
              SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: similar.length.clamp(0, 8),
                  itemBuilder: (_, i) {
                    final sp = similar[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: T.s8),
                      child: Pressable(
                        onTap: () => _swap(sp),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 9),
                          decoration: BoxDecoration(
                            color: T.surfaceHi,
                            borderRadius: BorderRadius.circular(T.rPill),
                            border: Border.all(color: T.stroke),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${kTypeEmoji[sp.type] ?? '📍'} ${sp.name}',
                                style: T.body(13, w: FontWeight.w600),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                '${vibeOf(sp)}%',
                                style: T.num(12.5, color: vibeColor(vibeOf(sp))),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/* ---------------- map tab: places, friends, presence ---------------- */

class MapTab extends StatefulWidget {
  final List<Place> places;
  final List<City> cities;
  final City? city;
  final void Function(City) onCity;
  final Set<String> favs;
  final void Function(Place) onToggleFav;
  final void Function(Place)? onCheckIn;
  final void Function(Place)? onPhotoUploaded;
  const MapTab({
    super.key,
    required this.places,
    required this.cities,
    required this.city,
    required this.onCity,
    required this.favs,
    required this.onToggleFav,
    this.onCheckIn,
    this.onPhotoUploaded,
  });

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  MapLibreMapController? _ctl;
  String? _style;
  bool _styleReady = false;
  bool _centeredOnUser = false;
  final Map<String, Place> _symbolPlace = {};
  final Map<String, Friend> _symbolFriend = {};
  final List<Symbol> _placeSymbols = [];
  final List<Symbol> _friendSymbols = [];
  final Map<String, Uint8List> _markerCache = {};
  final Map<String, Uint8List> _pinCache = {};
  bool _pinsRegistered = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/map-style.json').then((s) {
      if (mounted) setState(() => _style = s);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(MapTab old) {
    super.didUpdateWidget(old);
    if (old.city?.id != widget.city?.id && _styleReady) {
      _ctl?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(widget.city!.lat, widget.city!.lng),
          13,
        ),
      );
      _drawPlaces();
    }
  }

  /* Place pins (v2.0.8): neutral gray discs with a type emblem, per the
     owner's ask («серые точки, а на них эмблемы: бокал, чашка кофе,
     дерево»). Hot places (vibe >= 70) keep the radar feel via a brand-red
     halo ring around the same gray disc. One bitmap per (type, hot) is
     painted once and registered with the map; places are then cheap
     symbols. Only the selected city's places are drawn (widget.places
     is already city-filtered), same as the old circles. */
  Future<Uint8List> _placePin(String type, {required bool hot}) async {
    final cacheKey = hot ? '$type|hot' : type;
    final cached = _pinCache[cacheKey];
    if (cached != null) return cached;
    const double size = 120;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
    final center = const Offset(size / 2, size / 2);
    if (hot) {
      canvas.drawCircle(
        center,
        57,
        Paint()..color = T.fire.withOpacity(0.16),
      );
      canvas.drawCircle(
        center,
        51,
        Paint()
          ..color = T.fire
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6,
      );
    }
    canvas.drawCircle(
      center,
      42,
      Paint()..color = const Color(0xFF9AA1A9),
    );
    canvas.drawCircle(
      center,
      42,
      Paint()
        ..color = const Color(0xFF3A3F45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: kPinEmoji[type] ?? kPinEmoji['other'],
        style: const TextStyle(fontSize: 50),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    final pic = recorder.endRecording();
    final img = await pic.toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List();
    _pinCache[cacheKey] = bytes;
    return bytes;
  }

  Future<void> _ensurePinImages() async {
    final ctl = _ctl;
    if (ctl == null || _pinsRegistered) return;
    _pinsRegistered = true;
    for (final type in kPinEmoji.keys) {
      await ctl.addImage('pin-$type', await _placePin(type, hot: false));
      await ctl.addImage('pin-$type-hot', await _placePin(type, hot: true));
    }
  }

  Future<void> _drawPlaces() async {
    final ctl = _ctl;
    if (ctl == null || !_styleReady) return;
    await _ensurePinImages();
    // Remove only our own symbols — clearSymbols() would also wipe the
    // friend avatars that _refreshFriends manages separately.
    for (final s in _placeSymbols) {
      try {
        await ctl.removeSymbol(s);
      } catch (_) {}
    }
    _placeSymbols.clear();
    _symbolPlace.clear();
    for (final p in widget.places) {
      final hot = vibeOf(p) >= 70;
      final type = kPinEmoji.containsKey(p.type) ? p.type : 'other';
      final sym = await ctl.addSymbol(
        SymbolOptions(
          geometry: LatLng(p.lat, p.lng),
          iconImage: hot ? 'pin-$type-hot' : 'pin-$type',
          iconSize: 0.45,
        ),
      );
      _symbolPlace[sym.id] = p;
      _placeSymbols.add(sym);
    }
  }

  Future<Uint8List> _friendMarker(Friend f) async {
    final cacheKey = '${f.id}|${f.avatarUrl ?? f.avatar ?? ''}';
    final cached = _markerCache[cacheKey];
    if (cached != null) return cached;
    const double size = 112;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
    final center = const Offset(size / 2, size / 2);
    ui.Image? photo;
    if (f.avatarUrl != null && f.avatarUrl!.isNotEmpty) {
      try {
        final client = HttpClient();
        final req = await client.getUrl(Uri.parse(f.avatarUrl!));
        final resp = await req.close();
        final bytes = await resp.fold<BytesBuilder>(
          BytesBuilder(),
          (b, d) => b..add(d),
        );
        final codec = await ui.instantiateImageCodec(bytes.takeBytes());
        photo = (await codec.getNextFrame()).image;
      } catch (_) {
        photo = null;
      }
    }
    if (photo != null) {
      final src = Rect.fromLTWH(0, 0, photo.width.toDouble(), photo.height.toDouble());
      final side = math.min(photo.width, photo.height).toDouble();
      final crop = Rect.fromLTWH(
        (photo.width - side) / 2,
        (photo.height - side) / 2,
        side,
        side,
      );
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: 48)),
      );
      canvas.drawImageRect(
        photo,
        crop.isEmpty ? src : crop,
        Rect.fromCircle(center: center, radius: 48),
        Paint(),
      );
      canvas.restore();
    } else {
      canvas.drawCircle(center, 48, Paint()..color = kSurface2);
      final tp = TextPainter(
        text: TextSpan(
          text: f.mode == 'ghost' ? '👻' : (f.avatar ?? '👤'),
          style: const TextStyle(fontSize: 50),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    }
    canvas.drawCircle(
      center,
      50,
      Paint()
        ..color = f.online ? kGreen : kMuted
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    final pic = recorder.endRecording();
    final img = await pic.toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List();
    _markerCache[cacheKey] = bytes;
    return bytes;
  }

  Future<void> _refreshFriends() async {
    final ctl = _ctl;
    if (ctl == null || !_styleReady) return;
    final uid = myUidOrNull;
    if (uid == null) return; // guest: no friends/presence without an account
    try {
      final fr = await supa
          .from('friendships')
          .select('requester, addressee')
          .eq('status', 'accepted')
          .or('requester.eq.$uid, addressee.eq.$uid');
      final ids = <String>{};
      for (final r in fr as List) {
        final other =
            r['requester'] == uid ? r['addressee'] : r['requester'];
        if (other is String) ids.add(other);
      }
      if (ids.isEmpty) return;
      final profs = await supa
          .from('profiles')
          .select('id, name, avatar, avatar_url, online, mode')
          .inFilter('id', ids.toList());
      final locs = await supa
          .from('profile_locations')
          .select('user_id, lat, lng')
          .inFilter('user_id', ids.toList());
      final locMap = <String, (double, double)>{};
      for (final l in locs as List) {
        locMap[l['user_id'] as String] = (
          (l['lat'] as num).toDouble(),
          (l['lng'] as num).toDouble(),
        );
      }
      // Remove only the previous friend markers — clearSymbols() would
      // also erase the place pins drawn by _drawPlaces (v2.0.8).
      for (final s in _friendSymbols) {
        try {
          await ctl.removeSymbol(s);
        } catch (_) {}
      }
      _friendSymbols.clear();
      _symbolFriend.clear();
      final added = <Symbol>[];
      for (final p in profs as List) {
        final id = p['id'] as String;
        final loc = locMap[id];
        if (loc == null) continue;
        final mode = p['mode'] as String?;
        if (mode == 'offline') continue;
        final friend = Friend(
          id: id,
          name: (p['name'] as String?) ?? 'Призрак',
          avatar: p['avatar'] as String?,
          avatarUrl: p['avatar_url'] as String?,
          mode: mode,
          online: p['online'] == true,
          lat: loc.$1,
          lng: loc.$2,
        );
        final marker = await _friendMarker(friend);
        await ctl.addImage('friend-$id', marker);
        final sym = await ctl.addSymbol(
          SymbolOptions(
            geometry: LatLng(friend.lat!, friend.lng!),
            iconImage: 'friend-$id',
            iconSize: 0.55,
            iconOpacity: 0, // faded in below — no popping
          ),
        );
        _symbolFriend[sym.id] = friend;
        added.add(sym);
      }
      if (added.isNotEmpty) {
        _friendSymbols.addAll(added);
        _fadeInSymbols(added);
      }
    } catch (_) {}
  }

  /* Friend markers fade in over ~270 ms instead of popping onto the map. */
  Future<void> _fadeInSymbols(List<Symbol> syms) async {
    final ctl = _ctl;
    if (ctl == null) return;
    for (var step = 1; step <= 6; step++) {
      await Future<void>.delayed(const Duration(milliseconds: 45));
      if (!mounted) return;
      for (final s in syms) {
        try {
          await ctl.updateSymbol(s, SymbolOptions(iconOpacity: step / 6));
        } catch (_) {}
      }
    }
  }

  Future<void> _presence() async {
    final ctl = _ctl;
    if (ctl == null) return;
    try {
      final pos = await ctl.requestMyLocationLatLng();
      if (pos == null) return;
      myLocationNotifier.value = pos; // shared with the «Я в деле» sheet
      final uid = myUidOrNull;
      if (uid == null) return; // guest: nowhere to write presence
      await supa.from('profile_locations').upsert({
        'user_id': uid,
        'lat': pos.latitude,
        'lng': pos.longitude,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      await supa.from('profiles').update({
        'online': true,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', uid);
    } catch (_) {}
  }

  void _onMapCreated(MapLibreMapController ctl) {
    _ctl = ctl;
    _pinsRegistered = false; // new controller → pin images must re-register
    ctl.onSymbolTapped.add((s) {
      final p = _symbolPlace[s.id];
      if (p != null && mounted) {
        showPlaceSheet(
          context,
          p,
          favs: widget.favs,
          onToggleFav: widget.onToggleFav,
          cityPlaces: widget.places,
          city: widget.city,
          onCheckIn: widget.onCheckIn,
          onPhotoUploaded: widget.onPhotoUploaded,
        );
        return;
      }
      final f = _symbolFriend[s.id];
      if (f != null && mounted) _showFriend(f);
    });
  }

  void _showFriend(Friend f) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: kSurface2,
              backgroundImage:
                  f.avatarUrl != null ? NetworkImage(f.avatarUrl!) : null,
              child: f.avatarUrl == null
                  ? Text(f.avatar ?? '👤', style: const TextStyle(fontSize: 26))
                  : null,
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  f.mode == 'ghost' ? 'Призрак' : f.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  f.online ? 'Сейчас в сети' : 'Был(а) недавно',
                  style: TextStyle(color: f.online ? kGreen : kMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final city = widget.city;
    if (_style == null || city == null) {
      return const Center(child: CircularProgressIndicator(color: kRed));
    }
    final hot = widget.places.where((p) => vibeOf(p) >= 70).length;
    return Stack(
      children: [
        MapLibreMap(
          styleString: _style!,
          initialCameraPosition: CameraPosition(
            target: LatLng(city.lat, city.lng),
            zoom: 13,
          ),
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: () {
        _styleReady = true;
        _drawPlaces();
        _refreshFriends();
        _presence().then((_) {
          // First open: center on the user when we have a real position;
          // otherwise the initial camera already sits on the city.
          final pos = myLocationNotifier.value;
          if (pos != null && !_centeredOnUser && mounted) {
            _centeredOnUser = true;
            _ctl?.animateCamera(
              CameraUpdate.newLatLngZoom(pos, 14),
            );
          }
        });
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 30), (_) {
          _refreshFriends();
          _presence();
        });
      },
          myLocationEnabled: true,
          myLocationTrackingMode: MyLocationTrackingMode.none,
          compassEnabled: false,
          attributionButtonMargins: const math.Point(-100, -100),
          trackCameraPosition: true,
        ),
        // Floating glass chip over the map: city pulse at a glance.
        Positioned(
          left: T.s12,
          bottom: T.s12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(T.rPill),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: T.s12, vertical: T.s8),
                decoration: BoxDecoration(
                  color: T.surface.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(T.rPill),
                  border: Border.all(color: T.stroke),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PulseDot(size: 7),
                    const SizedBox(width: T.s8),
                    Text(
                      '${city.name} · ${widget.places.length} мест · $hot жарких',
                      style: T.body(12, w: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/* ---------------- places tab ---------------- */

/* Map pin emblems (v2.0.8): gray discs carry one glyph per place type.
   Separate from kTypeEmoji (list/card glyphs) — the pin set follows the
   owner's exact picks: бокал 🍷, чашка кофе ☕, дерево 🌳… */
const kPinEmoji = <String, String>{
  'restaurant': '🍽️', 'cafe': '☕', 'bar': '🍷', 'park': '🌳',
  'beach': '🏖️', 'culture': '🎭', 'sport': '⚽', 'club': '🎵',
  'view': '🌆', 'market': '🛍️', 'other': '📍',
};

const kTypeNames = <String, String>{
  'park': 'Парки', 'cafe': 'Кафе', 'bar': 'Бары', 'restaurant': 'Рестораны',
  'club': 'Клубы', 'beach': 'Пляжи', 'view': 'Смотровые', 'sport': 'Спорт',
  'culture': 'Культура', 'market': 'Магазины', 'other': 'Разное',
};

class PlacesTab extends StatefulWidget {
  final List<Place> places;
  final City? city;
  final Set<String> favs;
  final void Function(Place) onToggleFav;
  final VoidCallback onOpenTasks;
  final void Function(Place)? onCheckIn;
  final void Function(Place)? onPhotoUploaded;
  const PlacesTab({
    super.key,
    required this.places,
    required this.city,
    required this.favs,
    required this.onToggleFav,
    required this.onOpenTasks,
    this.onCheckIn,
    this.onPhotoUploaded,
  });

  @override
  State<PlacesTab> createState() => _PlacesTabState();
}

class _PlacesTabState extends State<PlacesTab> {
  String _q = '';
  String? _type;
  String _sort = 'vibe';
  bool _hotOnly = false;
  Map<String, dynamic>? _drop;

  static const _sortLabels = {
    'vibe': 'По движу',
    'dist': '📍 Рядом со мной',
    'rating': 'По рейтингу',
    'price': 'По цене',
    'name': 'А–Я',
  };

  @override
  void initState() {
    super.initState();
    _loadDrop();
  }

  /* AI day banner data — same daily_drops read as the Tasks page. */
  Future<void> _loadDrop() async {
    try {
      final row = await supa
          .from('daily_drops')
          .select('data')
          .eq('day', dayKey())
          .maybeSingle();
      if (row != null && row['data'] is Map && mounted) {
        setState(() => _drop = (row['data'] as Map).cast<String, dynamic>());
      }
    } catch (_) {}
  }

  void _openPlace(Place p) {
    showPlaceSheet(
      context,
      p,
      favs: widget.favs,
      onToggleFav: widget.onToggleFav,
      cityPlaces: widget.places,
      city: widget.city,
      onCheckIn: widget.onCheckIn,
      onPhotoUploaded: widget.onPhotoUploaded,
    );
  }

  List<Place> get _filtered {
    var list = widget.places.where((p) {
      if (_q.isNotEmpty &&
          !p.name.toLowerCase().contains(_q.toLowerCase())) {
        return false;
      }
      if (_type != null && p.type != _type) return false;
      if (_hotOnly && vibeOf(p) < 70) return false;
      return true;
    }).toList();
    switch (_sort) {
      case 'dist':
        final origin = myLocationNotifier.value;
        if (origin == null) {
          // No position yet: fall back to vibe instead of fake distances.
          list.sort((a, b) => vibeOf(b).compareTo(vibeOf(a)));
        } else {
          list.sort((a, b) =>
              haversineKm(origin.latitude, origin.longitude, a.lat, a.lng)
                  .compareTo(haversineKm(
                      origin.latitude, origin.longitude, b.lat, b.lng)));
        }
      case 'rating':
        list.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      case 'price':
        list.sort((a, b) => effPriceLevel(a).compareTo(effPriceLevel(b)));
      case 'name':
        list.sort((a, b) => a.name.compareTo(b.name));
      default:
        list.sort((a, b) => vibeOf(b).compareTo(vibeOf(a)));
    }
    return list;
  }

  void _dice() {
    final hot = widget.places.where((p) => vibeOf(p) >= 70).toList();
    final pool = hot.isNotEmpty ? hot : widget.places;
    if (pool.isEmpty) return;
    tickMedium();
    _openPlace(pool[math.Random().nextInt(pool.length)]);
  }

  Widget _filterChip(String? type, String label) {
    final sel = _type == type;
    return Padding(
      padding: const EdgeInsets.only(right: T.s8),
      child: PillButton(
        text: label,
        selected: sel,
        onTap: () => setState(() => _type = sel ? null : type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final all = widget.places;
    final hotCount = all.where((p) => vibeOf(p) >= 70).length;
    final avgVibe = all.isEmpty
        ? 0
        : (all.map(vibeOf).reduce((a, b) => a + b) / all.length).round();
    final top3 = [...all]..sort((a, b) => vibeOf(b).compareTo(vibeOf(a)));
    final typesPresent = kTypeEmoji.keys.where(
      (t) => all.any((p) => p.type == t),
    );
    final aiTasks = (_drop?['tasks'] as List?) ?? [];
    final routeTheme = _drop?['route_theme'];

    return GlowBackground(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(T.s16, T.s12, T.s16, T.s4),
            child: Row(
              children: [
                Text(widget.city?.name ?? '', style: T.head(20)),
                const SizedBox(width: T.s8),
                Text(
                  '${all.length} мест',
                  style: T.body(13, color: T.muted),
                ),
                const Spacer(),
                Pressable(
                  onTap: _dice,
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: T.surface,
                      border: Border.all(color: T.stroke),
                    ),
                    child: const Text('🎲', style: TextStyle(fontSize: 17)),
                  ),
                ),
                const SizedBox(width: T.s8),
                SizedBox(
                  width: 132,
                  child: PressButton(
                    text: '🎯 Задачник',
                    small: true,
                    onPressed: widget.onOpenTasks,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: T.s12),
              itemCount: list.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_drop != null && routeTheme != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              T.s16, T.s8, T.s16, T.s4),
                          child: Pressable(
                            onTap: widget.onOpenTasks,
                            child: GlassCard(
                              gradientBorder: true,
                              padding: const EdgeInsets.all(T.s16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  sectionLabel('🤖 ИИ дня', color: T.salmon),
                                  Text(
                                    '🌙 ${aiText(routeTheme['title'])}',
                                    style: T.head(16),
                                  ),
                                  if (aiTasks.isNotEmpty) ...[
                                    const SizedBox(height: T.s4),
                                    Text(
                                      'Первое задание: ${aiText((aiTasks.first as Map)['title'])}',
                                      style: T.body(13, color: T.muted),
                                    ),
                                  ],
                                  const SizedBox(height: T.s4),
                                  Text(
                                    'Открыть задачник →',
                                    style: T.body(12.5,
                                        color: T.ember, w: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            T.s16, T.s8, T.s16, T.s4),
                        child: GlassCard(
                          padding: const EdgeInsets.all(T.s16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              sectionLabel('Город сейчас', color: T.salmon),
                              Row(
                                children: [
                                  _cityStat('${all.length}', 'мест на радаре'),
                                  _cityStat('$hotCount', 'жарких сейчас'),
                                  _cityStat('$avgVibe%', 'средний движ'),
                                ],
                              ),
                              const SizedBox(height: T.s12),
                              hairline(),
                              const SizedBox(height: T.s12),
                              for (final p in top3.take(3))
                                Pressable(
                                  onTap: () => _openPlace(p),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: T.s4),
                                    child: Row(
                                      children: [
                                        Text(
                                          kTypeEmoji[p.type] ?? '📍',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(width: T.s8),
                                        Expanded(
                                          child: Text(
                                            p.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: T.body(13.5,
                                                w: FontWeight.w600),
                                          ),
                                        ),
                                        VibeBadge(vibe: vibeOf(p)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: T.s16, vertical: T.s4),
                        child: TextField(
                          decoration:
                              const InputDecoration(hintText: 'Поиск места…'),
                          onChanged: (v) => setState(() => _q = v),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: T.s16, vertical: 2),
                          children: [
                            _filterChip(null, 'Все'),
                            for (final t in typesPresent)
                              _filterChip(
                                t,
                                '${kTypeEmoji[t]} ${kTypeNames[t] ?? t}',
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            T.s16, T.s4, T.s16, T.s4),
                        child: Row(
                          children: [
                            PopupMenuButton<String>(
                              color: T.surfaceHi,
                              initialValue: _sort,
                              onSelected: (v) => setState(() => _sort = v),
                              itemBuilder: (_) => [
                                for (final e in _sortLabels.entries)
                                  PopupMenuItem(
                                    value: e.key,
                                    child: Text(e.value, style: T.body(13.5)),
                                  ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: T.surface,
                                  borderRadius: BorderRadius.circular(T.rPill),
                                  border: Border.all(color: T.stroke),
                                ),
                                child: Text(
                                  '↕ ${_sortLabels[_sort]} ▾',
                                  style: T.body(12.5, w: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: T.s8),
                            PillButton(
                              text: '🔥 Только жаркие',
                              selected: _hotOnly,
                              onTap: () =>
                                  setState(() => _hotOnly = !_hotOnly),
                            ),
                            const Spacer(),
                            Text(
                              'Найдено: ${list.length}',
                              style: T.body(12, color: T.faint),
                            ),
                          ],
                        ),
                      ),
                      if (list.isEmpty)
                        const EmptyState(
                          emoji: '👻',
                          title: 'Здесь пока тихо',
                          hint: 'Попробуй другой фильтр, поиск или город.',
                        ),
                    ],
                  );
                }
                final p = list[i - 1];
                final fav = widget.favs.contains(p.id);
                return StaggerIn(
                  index: i - 1,
                  child: Pressable(
                    onTap: () => _openPlace(p),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: T.s16, vertical: 5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: T.s16, vertical: T.s12),
                      decoration: cardDecoration(),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: typeColor(p.type).withOpacity(0.16),
                              boxShadow: [
                                BoxShadow(
                                  color: typeColor(p.type).withOpacity(0.45),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Text(
                              kTypeEmoji[p.type] ?? '📍',
                              style: const TextStyle(fontSize: 21),
                            ),
                          ),
                          const SizedBox(width: T.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: T.body(15, w: FontWeight.w700),
                                ),
                                const SizedBox(height: 3),
                                ValueListenableBuilder<LatLng?>(
                                  valueListenable: myLocationNotifier,
                                  builder: (_, origin, __) {
                                    final d = origin == null
                                        ? null
                                        : haversineKm(origin.latitude,
                                            origin.longitude, p.lat, p.lng);
                                    return Text(
                                      [
                                        if (p.rating != null)
                                          '⭐ ${p.rating!.toStringAsFixed(1)}'
                                        else
                                          '✨ новое',
                                        if (priceText(p).isNotEmpty)
                                          priceText(p),
                                        if (d != null) '📍 ${fmtKm(d)} км',
                                        if (p.address.isNotEmpty) p.address,
                                      ].join(' · '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: T.body(12.5, color: T.muted),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: T.s8),
                          VibeBadge(vibe: vibeOf(p)),
                          IconButton(
                            icon: Icon(
                              fav ? Icons.favorite : Icons.favorite_border,
                              color: fav ? T.fire : T.muted,
                            ),
                            onPressed: () => widget.onToggleFav(p),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _cityStat(String value, String label) => Expanded(
        child: Column(
          children: [
            Text(value, style: T.num(19, color: T.ember)),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: T.body(10.5, color: T.faint, w: FontWeight.w600),
            ),
          ],
        ),
      );
}

/* ---------------- route tab ---------------- */

class RouteTab extends StatefulWidget {
  final List<Place> places;
  final City? city;
  final VoidCallback onTaskDone;
  final VoidCallback onRouteBuilt;
  const RouteTab({
    super.key,
    required this.places,
    required this.city,
    required this.onTaskDone,
    required this.onRouteBuilt,
  });

  @override
  State<RouteTab> createState() => _RouteTabState();
}

class _RouteTabState extends State<RouteTab> {
  String _transport = 'car';
  int _seed = 0;
  List<dynamic> _routeTasks = [];
  final Set<int> _done = {};
  bool _counted = false;
  List<Map<String, dynamic>> _savedRoutes = [];
  Map<String, dynamic>? _viewSaved;

  static const _speeds = {'walk': 5.0, 'bus': 18.0, 'car': 30.0};
  static const _icons = {'walk': '🚶', 'bus': '🚌', 'car': '🚗'};

  @override
  void initState() {
    super.initState();
    _seed = dayIndex();
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/tasks.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _routeTasks = (data['route'] as List?) ?? [];
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt('route_seed_${dayKey()}');
      if (saved != null) _seed = saved;
      final tr = prefs.getString('route_transport_${dayKey()}');
      if (tr != null && _speeds.containsKey(tr)) _transport = tr;
      final sr = prefs.getString('saved_routes');
      if (sr != null) {
        _savedRoutes = (jsonDecode(sr) as List)
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  List<Place> get _route {
    final saved = _viewSaved;
    if (saved != null) {
      return [
        for (final e in (saved['places'] as List? ?? []))
          Place(
            id: e['id'].toString(),
            city: (e['city'] ?? '').toString(),
            name: e['name'].toString(),
            type: e['type'].toString(),
            lat: (e['lat'] as num).toDouble(),
            lng: (e['lng'] as num).toDouble(),
          ),
      ];
    }
    final pool = [...widget.places]
      ..sort((a, b) => vibeOf(b).compareTo(vibeOf(a)));
    final top = pool.take(12).toList();
    if (top.length <= 3) return top;
    final start = _seed % top.length;
    final picks = <Place>[];
    for (final off in [0, 4, 8]) {
      final p = top[(start + off) % top.length];
      if (!picks.contains(p)) picks.add(p);
    }
    var k = 1;
    while (picks.length < 3 && k < top.length) {
      final p = top[(start + k) % top.length];
      if (!picks.contains(p)) picks.add(p);
      k++;
    }
    return picks;
  }

  String _descFor(int i) {
    switch (i) {
      case 0:
        return 'Старт — спокойно зайти в вечер.';
      case 1:
        return 'Пик ночи — туда, где жарче всего.';
      default:
        return 'Финал — закрепить ночь красиво.';
    }
  }

  String _timeFor(int i) {
    final mins = 19 * 60 + 30 + i * 90;
    final h = (mins ~/ 60) % 24;
    final m = mins % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Future<void> _reshuffle() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _seed++;
      _done.clear();
      _counted = false;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('route_seed_${dayKey()}', _seed);
    } catch (_) {}
  }

  void _toggleDone(int i, List<Place> route) {
    HapticFeedback.selectionClick();
    final wasDone = _done.contains(i);
    setState(() {
      if (wasDone) {
        _done.remove(i);
      } else {
        _done.add(i);
      }
    });
    if (!wasDone) {
      widget.onTaskDone();
      if (_done.length >= route.length && route.isNotEmpty && !_counted) {
        _counted = true;
        widget.onRouteBuilt();
        fireConfetti(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Маршрут пройден целиком · +40 XP 🎉')),
        );
      }
    }
  }

  Future<void> _saveRoute() async {
    final route = _route;
    if (route.isEmpty) return;
    final entry = <String, dynamic>{
      'day': dayKey(),
      'cityName': widget.city?.name ?? '',
      'transport': _transport,
      'places': [
        for (final p in route)
          {
            'id': p.id,
            'city': p.city,
            'name': p.name,
            'type': p.type,
            'lat': p.lat,
            'lng': p.lng,
          },
      ],
    };
    setState(() => _savedRoutes = [entry, ..._savedRoutes].take(12).toList());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_routes', jsonEncode(_savedRoutes));
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Маршрут сохранён 💾')),
      );
    }
  }

  Widget _transportPill(String id, String label) {
    final sel = _transport == id;
    return GestureDetector(
      onTap: () async {
        tickSelect();
        setState(() => _transport = id);
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('route_transport_${dayKey()}', id);
        } catch (_) {}
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: sel ? const LinearGradient(colors: [kRed, kOrange]) : null,
          color: sel ? null : kSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: sel ? Colors.transparent : kBorder),
          boxShadow: sel
              ? [BoxShadow(color: kRed.withOpacity(0.45), blurRadius: 14)]
              : null,
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
        ),
      ),
    );
  }

  Widget _legRow(Place a, Place b) {
    final km = haversineKm(a.lat, a.lng, b.lat, b.lng);
    final mins = (km / (_speeds[_transport] ?? 30) * 60).round();
    final dist = km < 1
        ? '${(km * 1000).round()} м'
        : '${fmtKm(km)} км';
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Center(
            child: Container(width: 3, height: 30, color: kRed.withOpacity(0.55)),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${_icons[_transport]} $dist · ≈ $mins мин',
          style: const TextStyle(color: kMuted, fontSize: 12.5),
        ),
      ],
    );
  }

  Widget _stopCard(int i, Place p, List<Place> route) {
    final task = _routeTasks.isEmpty
        ? 'Сделай фото, которое расскажет про это место без слов.'
        : _routeTasks[(_seed + i) % _routeTasks.length].toString();
    final done = _done.contains(i);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [kRed, kOrange]),
                boxShadow: [
                  BoxShadow(color: kRed.withOpacity(0.55), blurRadius: 14),
                ],
              ),
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ),
            if (i < route.length - 1)
              Container(width: 3, height: 14, color: kRed.withOpacity(0.55)),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(15),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_timeFor(i)} · ${widget.city?.name ?? ''}',
                  style: const TextStyle(
                    color: kRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${kTypeEmoji[p.type] ?? '📍'} ${p.name}',
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _descFor(i),
                  style: const TextStyle(color: kMuted, fontSize: 13),
                ),
                const SizedBox(height: 7),
                Text(
                  '🎯 $task',
                  style: const TextStyle(fontSize: 13.5, height: 1.35),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _toggleDone(i, route),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: kSurface2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: done ? kGreen : kRed.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: done ? kGreen : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: done ? kGreen : kMuted,
                              width: 1.6,
                            ),
                          ),
                          child: done
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.black)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Задание выполнено',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: done ? kGreen : kText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    return GlowBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Маршрут на '),
              TextSpan(text: 'вечер', style: T.display(20, color: T.ember)),
            ]),
            style: T.display(20),
          ),
          const SizedBox(height: 6),
          Text(
            'Три точки, три задания — ночь собрана по городу ${widget.city?.name ?? ''}. '
            'Не нравится расклад — пересобери.',
            style: const TextStyle(color: kMuted, fontSize: 13.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _transportPill('walk', '🚶 Пешком'),
              const SizedBox(width: 8),
              _transportPill('bus', '🚌 Автобус'),
              const SizedBox(width: 8),
              _transportPill('car', '🚗 Машина'),
            ],
          ),
          const SizedBox(height: 14),
          PressButton(
            text: '🎲 Пересобрать маршрут',
            primary: false,
            onPressed: _reshuffle,
          ),
          const SizedBox(height: T.s12),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  text: '💾 Сохранить маршрут',
                  small: true,
                  onPressed: _saveRoute,
                ),
              ),
              if (_viewSaved != null) ...[
                const SizedBox(width: T.s8),
                Expanded(
                  child: GhostButton(
                    text: 'К обычному',
                    small: true,
                    onPressed: () => setState(() {
                      _viewSaved = null;
                      _done.clear();
                      _counted = false;
                    }),
                  ),
                ),
              ],
            ],
          ),
          if (_viewSaved != null) ...[
            const SizedBox(height: T.s12),
            Text(
              '🗺️ Сохранённый маршрут · ${_viewSaved!['day']} · ${_viewSaved!['cityName']}',
              style: T.body(12.5, color: T.ember, w: FontWeight.w700),
            ),
          ],
          if (_savedRoutes.isNotEmpty) ...[
            const SizedBox(height: T.s20),
            sectionLabel('Мои маршруты', color: T.salmon),
            for (final e in _savedRoutes)
              Pressable(
                onTap: () => setState(() {
                  _viewSaved = _viewSaved == e ? null : e;
                  _done.clear();
                  _counted = false;
                  final tr = e['transport']?.toString();
                  if (tr != null && _speeds.containsKey(tr)) {
                    _transport = tr;
                  }
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: T.s8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: T.s16, vertical: T.s12),
                  decoration: BoxDecoration(
                    color: T.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _viewSaved == e ? T.fire : T.stroke,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_icons[e['transport']] ?? '🚗'} ${e['cityName']} · ${e['day']}',
                        style: T.body(13, w: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        (e['places'] as List? ?? [])
                            .map((x) => x['name'].toString())
                            .join(' → '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: T.body(12, color: T.muted),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 20),
          if (route.isEmpty)
            const Text(
              'В этом городе пока нет мест для маршрута.',
              style: TextStyle(color: kMuted),
            ),
          for (var i = 0; i < route.length; i++) ...[
            _stopCard(i, route[i], route),
            if (i < route.length - 1) _legRow(route[i], route[i + 1]),
          ],
        ],
      ),
    );
  }
}

/* «Выполнено» pill — replaces the stock Material Chip. */
class DonePill extends StatelessWidget {
  const DonePill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: T.online.withOpacity(0.14),
        borderRadius: BorderRadius.circular(T.rPill),
        border: Border.all(color: T.online.withOpacity(0.55)),
      ),
      child: Text(
        'Выполнено ✓',
        style: T.body(12.5, color: T.online, w: FontWeight.w700),
      ),
    );
  }
}

/* ---------------- tasks page: AI day, daily task, week quest ---------------- */

/* ---------------- v2.0.6: steps card, city quest, photo tournament ----- */

/* «👟 Шаги сегодня» — live pedometer card (Profile + Tasks). */
class StepsCard extends StatelessWidget {
  const StepsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: StepsTracker.available,
      builder: (_, available, __) => ValueListenableBuilder<int>(
        valueListenable: StepsTracker.today,
        builder: (_, steps, __) => ValueListenableBuilder<int>(
          valueListenable: StepsTracker.xpToday,
          builder: (_, xp, __) => Container(
            padding: const EdgeInsets.all(T.s16),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('👟 Шаги сегодня', style: T.head(15)),
                    const Spacer(),
                    Text(
                      '$steps',
                      style: T.num(19, color: T.ember),
                    ),
                  ],
                ),
                const SizedBox(height: T.s12),
                GradientProgress(value: (steps % 1000) / 1000),
                const SizedBox(height: 9),
                Text(
                  !available
                      ? 'Нет доступа к шагам — разреши физическую активность, и шаги начнут давать XP'
                      : 'Каждые 1000 шагов = +5 XP (до +50 в день) · '
                          'до следующего +5 XP: ${1000 - (steps % 1000)} шагов · сегодня +$xp XP',
                  style: T.body(12, color: T.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* «🏙️ Квест города» — today's deterministic city quest with live
   progress read from the CityQuest prefs state. */
class CityQuestCard extends StatefulWidget {
  final List<Place> places;
  final City? city;
  const CityQuestCard({super.key, required this.places, required this.city});

  @override
  State<CityQuestCard> createState() => _CityQuestCardState();
}

class _CityQuestCardState extends State<CityQuestCard> {
  Map<String, dynamic>? _quest;

  @override
  void initState() {
    super.initState();
    _reload();
    CityQuest.revision.addListener(_reload);
  }

  @override
  void dispose() {
    CityQuest.revision.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final city = widget.city;
    if (city == null || widget.places.isEmpty) return;
    final q = await CityQuest.ensure(widget.places, city);
    if (mounted) setState(() => _quest = q);
  }

  String _stepLabel(Map<String, dynamic> st) {
    switch (st['kind']) {
      case 'checkin':
        return 'Зачекинься: ${st['name']}';
      case 'photo':
        return 'Сфотографируй: ${st['name']}';
      case 'fav':
        return 'Добавь в избранное: ${st['name']}';
      default:
        return '${st['name']}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _quest;
    if (widget.city == null || q == null) return const SizedBox.shrink();
    final steps = (q['steps'] as List? ?? [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
    if (steps.isEmpty) return const SizedBox.shrink();
    final allDone = steps.every((st) => st['done'] == true);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '🏙️ Квест города — ${widget.city!.name}',
                  style: T.head(15),
                ),
              ),
              if (allDone) const DonePill(),
            ],
          ),
          const SizedBox(height: T.s8),
          for (final st in steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    st['done'] == true ? '✅ ' : '⬜ ',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Expanded(
                    child: Text(
                      _stepLabel(st),
                      style: T.body(
                        14,
                        color: st['done'] == true ? T.muted : T.text,
                        w: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            allDone
                ? 'Квест выполнен · +50 XP уже твои 🎉'
                : 'Все три шага за день — бонус +50 XP. Шаги засчитываются сами: чек-ин, фото и сердечко у нужных мест.',
            style: T.body(12, color: T.muted),
          ),
        ],
      ),
    );
  }
}

/* «🏆 Фото дня» — daily photo tournament for the selected city: today's
   place_photos ranked by 🔥 from photo_reactions. Yesterday's winner, if
   it is the current user, is credited +25 aiXp once (prefs flag). */
class PhotoTournamentCard extends StatefulWidget {
  final List<Place> places;
  final void Function(int xp) onAiXp;
  const PhotoTournamentCard({
    super.key,
    required this.places,
    required this.onAiXp,
  });

  @override
  State<PhotoTournamentCard> createState() => _PhotoTournamentCardState();
}

class _PhotoTournamentCardState extends State<PhotoTournamentCard> {
  List<Map<String, dynamic>> _photos = [];
  Map<String, int> _fires = {};
  final Set<String> _myFires = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
    _creditYesterdayWinner();
  }

  String _placeName(String placeId) => widget.places
      .where((e) => e.id == placeId)
      .map((e) => e.name)
      .firstOrNull ?? 'Место';

  Future<List<Map<String, dynamic>>> _photosBetween(
      DateTime from, DateTime to) async {
    final ids = widget.places.map((e) => e.id).toList();
    if (ids.isEmpty) return [];
    final rows = await supa
        .from('place_photos')
        .select('id, place_id, user_id, url, visibility, reports, created_at')
        .eq('hidden', false)
        .lt('reports', 3)
        .gte('created_at', from.toUtc().toIso8601String())
        .lt('created_at', to.toUtc().toIso8601String())
        .inFilter('place_id', ids)
        .order('created_at', ascending: false)
        .limit(60);
    final uid = myUidOrNull;
    return [
      for (final r in rows as List)
        if (r['visibility'] == 'public' || (uid != null && r['user_id'] == uid))
          (r as Map).cast<String, dynamic>(),
    ];
  }

  Future<Map<String, int>> _fireCounts(List<Map<String, dynamic>> photos,
      {Set<String>? mineOut}) async {
    final fires = <String, int>{};
    if (photos.isEmpty) return fires;
    try {
      final rr = await supa
          .from('photo_reactions')
          .select('photo_id, user_id')
          .inFilter('photo_id', photos.map((e) => e['id']).toList());
      final uid = myUidOrNull;
      for (final r in rr as List) {
        final id = r['photo_id'].toString();
        fires[id] = (fires[id] ?? 0) + 1;
        if (mineOut != null && uid != null && r['user_id'] == uid) {
          mineOut.add(id);
        }
      }
    } catch (_) {}
    return fires;
  }

  Future<void> _load() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final photos = await _photosBetween(start, start.add(const Duration(days: 1)));
      final mine = <String>{};
      final fires = await _fireCounts(photos, mineOut: mine);
      photos.sort((a, b) => (fires[b['id'].toString()] ?? 0)
          .compareTo(fires[a['id'].toString()] ?? 0));
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _fires = fires;
        _myFires
          ..clear()
          ..addAll(mine);
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _creditYesterdayWinner() async {
    final uid = myUidOrNull;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yStart = today.subtract(const Duration(days: 1));
      final flag =
          'tour_winner_credited_${yStart.year}-${yStart.month}-${yStart.day}';
      if (prefs.getBool(flag) == true) return;
      final photos = await _photosBetween(yStart, today);
      if (photos.isEmpty) return;
      final fires = await _fireCounts(photos);
      photos.sort((a, b) => (fires[b['id'].toString()] ?? 0)
          .compareTo(fires[a['id'].toString()] ?? 0));
      if (photos.first['user_id'] == uid) {
        await prefs.setBool(flag, true);
        widget.onAiXp(25);
        if (mounted) {
          snack(context, '🏆 Твоё фото выиграло вчерашний турнир · +25 XP');
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleFire(Map<String, dynamic> ph) async {
    final uid = myUidOrNull;
    if (uid == null) {
      snack(context, 'Войди, чтобы ставить 🔥');
      return;
    }
    final id = ph['id'].toString();
    final mine = _myFires.contains(id);
    tickSelect();
    setState(() {
      if (mine) {
        _myFires.remove(id);
        _fires[id] = math.max(0, (_fires[id] ?? 1) - 1);
      } else {
        _myFires.add(id);
        _fires[id] = (_fires[id] ?? 0) + 1;
      }
      _photos.sort((a, b) => (_fires[b['id'].toString()] ?? 0)
          .compareTo(_fires[a['id'].toString()] ?? 0));
    });
    try {
      if (mine) {
        await supa
            .from('photo_reactions')
            .delete()
            .eq('photo_id', ph['id'])
            .eq('user_id', uid);
      } else {
        await supa.from('photo_reactions').insert({
          'photo_id': ph['id'],
          'user_id': uid,
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🏆 Фото дня — турнир', style: T.head(15)),
          const SizedBox(height: T.s4),
          Text(
            'Фото призраков города за сегодня. Больше 🔥 — выше место; лидер дня завтра получит +25 XP.',
            style: T.body(12, color: T.muted),
          ),
          const SizedBox(height: T.s12),
          if (!_loaded)
            const ShimmerBox(height: 64)
          else if (_photos.isEmpty)
            Text(
              'Сегодня пока нет фото — открой место и стань первым 📸',
              style: T.body(13, color: T.muted),
            )
          else
            for (var i = 0; i < _photos.take(10).length; i++)
              Builder(builder: (_) {
                final ph = _photos[i];
                final id = ph['id'].toString();
                final fires = _fires[id] ?? 0;
                final mine = _myFires.contains(id);
                final leader = i == 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: T.s8),
                  padding: const EdgeInsets.all(T.s8),
                  decoration: BoxDecoration(
                    color: T.surfaceHi,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: leader ? T.gold : T.stroke,
                      width: leader ? 1.4 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          ph['url'].toString(),
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          cacheWidth: 140,
                          errorBuilder: (_, __, ___) => Container(
                            width: 54,
                            height: 54,
                            color: T.surface,
                            child: const Center(child: Text('👻')),
                          ),
                        ),
                      ),
                      const SizedBox(width: T.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${leader ? '👑 ' : ''}${_placeName(ph['place_id'].toString())}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: T.body(13.5, w: FontWeight.w700),
                            ),
                            Text(
                              leader
                                  ? '🏆 Фото дня · ${ghostLabelFor(ph['user_id'].toString())}'
                                  : ghostLabelFor(ph['user_id'].toString()),
                              style: T.body(11.5, color: T.muted),
                            ),
                          ],
                        ),
                      ),
                      Pressable(
                        onTap: () => _toggleFire(ph),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 7),
                          decoration: BoxDecoration(
                            color: mine
                                ? T.fire.withOpacity(0.22)
                                : T.surface,
                            borderRadius: BorderRadius.circular(T.rPill),
                            border: Border.all(
                                color: mine ? T.fire : T.stroke),
                          ),
                          child: Text(
                            '🔥 $fires',
                            style: T.num(12.5,
                                color: mine ? T.ember : T.text),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
        ],
      ),
    );
  }
}

class TasksPage extends StatefulWidget {
  final Map<String, dynamic> stats;
  final VoidCallback onTaskDone;
  final void Function(int xp) onAiXp;
  final List<Place> cityPlaces;
  final City? city;
  const TasksPage({
    super.key,
    required this.stats,
    required this.onTaskDone,
    required this.onAiXp,
    required this.cityPlaces,
    required this.city,
  });

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<dynamic> _daily = [];
  List<dynamic> _week = [];
  Map<String, dynamic>? _drop;
  final Set<String> _aiDone = {};
  bool _dailyDone = false;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    StepsTracker.start();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/tasks.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs!.getString('ai_done_${dayKey()}');
    if (saved != null) {
      _aiDone.addAll((jsonDecode(saved) as List).map((e) => e.toString()));
    }
    _dailyDone = _prefs!.getString('daily_done_day') == dayKey();
    try {
      final row = await supa
          .from('daily_drops')
          .select('data')
          .eq('day', dayKey())
          .maybeSingle();
      if (row != null && row['data'] is Map) {
        _drop = (row['data'] as Map).cast<String, dynamic>();
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _daily = (data['daily'] as List?) ?? [];
      _week = (data['week'] as List?) ?? [];
    });
  }

  Future<void> _completeAi(Map<String, dynamic> task) async {
    final id = task['id'].toString();
    if (_aiDone.contains(id)) return;
    setState(() => _aiDone.add(id));
    await _prefs?.setString(
      'ai_done_${dayKey()}',
      jsonEncode(_aiDone.toList()),
    );
    final xp = (task['xp'] as num?)?.toInt() ?? 0;
    widget.onAiXp(xp);
    if (mounted) {
      fireConfetti(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Задание ИИ выполнено · +$xp XP')),
      );
    }
  }

  Future<void> _completeDaily() async {
    if (_dailyDone) return;
    setState(() => _dailyDone = true);
    await _prefs?.setString('daily_done_day', dayKey());
    widget.onTaskDone();
    if (mounted) {
      fireConfetti(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Задание дня выполнено · +20 XP')),
      );
    }
  }

  Widget _taskCard(Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: cardDecoration(),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    final dailyTask = _daily.isEmpty
        ? null
        : _daily[dayIndex() % _daily.length].toString();
    final weekQuest = _week.isEmpty
        ? null
        : (_week[(dayIndex() ~/ 7) % _week.length] as Map).cast<String, dynamic>();
    final aiTasks = (_drop?['tasks'] as List?) ?? [];
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text('🎯 Задачник', style: T.display(20)),
                ],
              ),
              if (_drop != null && aiTasks.isNotEmpty) ...[
                const SizedBox(height: 8),
                sectionLabel('🤖 ИИ дня', color: const Color(0xFFFF8A7A)),
                for (final t in aiTasks)
                  _taskCard(
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${aiText(t['title'])}  ·  +${(t['xp'] as num?)?.toInt() ?? 0} XP',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                aiText(t['desc']),
                                style: const TextStyle(color: kMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        _aiDone.contains(t['id'].toString())
                            ? const DonePill()
                            : PressButton(
                                text: 'Готово ✓',
                                small: true,
                                onPressed: () =>
                                    _completeAi(t as Map<String, dynamic>),
                              ),
                      ],
                    ),
                  ),
                if (_drop!['quest'] != null) ...[
                  sectionLabel('🗺️ Квест дня: ${aiText(_drop!['quest']['title'])}',
                      color: const Color(0xFFFF8A7A)),
                  Text(
                    aiText(_drop!['quest']['desc']),
                    style: const TextStyle(color: kMuted),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_drop!['route_theme'] != null) ...[
                  sectionLabel(
                      '🌙 Тема маршрута: ${aiText(_drop!['route_theme']['title'])}',
                      color: const Color(0xFFFF8A7A)),
                  Text(
                    aiText(_drop!['route_theme']['desc']),
                    style: const TextStyle(color: kMuted),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
              CityQuestCard(places: widget.cityPlaces, city: widget.city),
              PhotoTournamentCard(
                places: widget.cityPlaces,
                onAiXp: widget.onAiXp,
              ),
              const StepsCard(),
              const SizedBox(height: 10),
              sectionLabel('🎯 Задание дня', color: const Color(0xFFFF8A7A)),
              _taskCard(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        dailyTask ?? 'Загрузка…',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _dailyDone
                        ? const DonePill()
                        : PressButton(
                            text: 'Готово ✓',
                            small: true,
                            onPressed: _completeDaily,
                          ),
                  ],
                ),
              ),
              if (weekQuest != null) ...[
                sectionLabel('🗓️ Квест недели: ${weekQuest['theme']}',
                    color: const Color(0xFFFF8A7A)),
                for (final s in (weekQuest['steps'] as List? ?? []))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🔴 ', style: TextStyle(fontSize: 10)),
                        Expanded(child: Text(s.toString())),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------- badges, titles, levels, leaderboard ---------------- */

class BadgeDef {
  final String emoji, name, condition;
  final int current, threshold;
  const BadgeDef(this.emoji, this.name, this.condition, this.current, this.threshold);
  bool get unlocked => current >= threshold;
  double get progress =>
      threshold <= 0 ? 1 : (current / threshold).clamp(0.0, 1.0);
}

List<BadgeDef> badgesOf(Map<String, dynamic> stats) {
  final places = (stats['places'] as List?)?.length ?? 0;
  final streak = math.max(statInt(stats, 'streak'), statInt(stats, 'bestStreak'));
  return [
    BadgeDef('🌙', 'Первая ночь', '1 ночь в деле', statInt(stats, 'nights'), 1),
    BadgeDef('🎉', 'Тусовщик', '5 ночей в деле', statInt(stats, 'nights'), 5),
    BadgeDef('🧭', 'Исследователь', '10 мест открыто', places, 10),
    BadgeDef('📸', 'Фотограф города', '1 фото в городе', statInt(stats, 'photos'), 1),
    BadgeDef('👁️', 'Глаз города', '5 фото в городе', statInt(stats, 'photos'), 5),
    BadgeDef('🗺️', 'Маршрутник', '3 маршрута построено', statInt(stats, 'routes'), 3),
    BadgeDef('🏛️', 'Архитектор ночей', '10 маршрутов', statInt(stats, 'routes'), 10),
    BadgeDef('🔥', 'Серия 3', 'серия 3 дня подряд', streak, 3),
    BadgeDef('☄️', 'Серия 7', 'серия 7 дней подряд', streak, 7),
    BadgeDef('🗳️', 'Голос города', '10 голосов', statInt(stats, 'votes'), 10),
    BadgeDef('🎯', 'Квестер', '1 квест пройден', statInt(stats, 'quests'), 1),
    BadgeDef('👑', 'Легенда', '1500 XP', xpOfStats(stats), 1500),
  ];
}

class TitleDef {
  final String name, hint;
  final bool unlocked;
  const TitleDef(this.name, this.hint, this.unlocked);
}

List<TitleDef> titlesOf(Map<String, dynamic> stats) {
  final xp = xpOfStats(stats);
  final places = (stats['places'] as List?)?.length ?? 0;
  return [
    TitleDef('Бродяга', '100 XP', xp >= 100),
    TitleDef('Призрак района', '500 XP', xp >= 500),
    TitleDef('Исследователь города', '25 мест открыто', places >= 25),
    TitleDef('Архитектор ночей', '5 маршрутов', statInt(stats, 'routes') >= 5),
    TitleDef('Король ночей', '10 ночей в деле', statInt(stats, 'nights') >= 10),
    TitleDef('Легенда ночей', '1500 XP', xp >= 1500),
    TitleDef('Хранитель движа', '2500 XP', xp >= 2500),
  ];
}

/* The one title shown under the nick — highest earned wins. */
String? ghostTitle(Map<String, dynamic> stats, String cityName) {
  final xp = xpOfStats(stats);
  final places = (stats['places'] as List?)?.length ?? 0;
  if (xp >= 2500) return 'Хранитель движа · $cityName';
  if (xp >= 1500) return 'Легенда ночей · $cityName';
  if (statInt(stats, 'nights') >= 10) return 'Король ночей · $cityName';
  if (places >= 25) return 'Исследователь · $cityName';
  if (statInt(stats, 'routes') >= 5) return 'Архитектор ночей · $cityName';
  if (xp >= 500) return 'Призрак · $cityName';
  if (xp >= 100) return 'Бродяга · $cityName';
  return null;
}

class BadgesPage extends StatefulWidget {
  final Map<String, dynamic> stats;
  final String cityName;
  const BadgesPage({super.key, required this.stats, required this.cityName});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  List<Map<String, dynamic>>? _board;
  bool _boardFailed = false;

  bool get _signedIn => myUidOrNull != null;

  @override
  void initState() {
    super.initState();
    if (_signedIn) _loadBoard();
  }

  Future<void> _loadBoard() async {
    try {
      final rows = await supa
          .from('profiles')
          .select('id, name, avatar, avatar_url, stats')
          .limit(80);
      final list = <Map<String, dynamic>>[
        for (final r in rows as List)
          {
            ...(r as Map).cast<String, dynamic>(),
            'xp': xpOfStats(r['stats']),
          },
      ]..sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));
      if (!mounted) return;
      setState(() => _board = list.take(10).toList());
    } catch (_) {
      if (mounted) setState(() => _boardFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stats;
    final xp = xpOfStats(s);
    final (lvNum, _, nextXp) = levelOf(xp);
    final badges = badgesOf(s);
    final titles = titlesOf(s);
    final myTitle = ghostTitle(s, widget.cityName);
    return Scaffold(
      body: GlowBackground(
        radar: true,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(T.s16, T.s8, T.s16, T.s24),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text('🏆 Награды', style: T.display(19)),
                ],
              ),
              const SizedBox(height: T.s8),
              sectionLabel(
                'Награды · открыто ${badges.where((b) => b.unlocked).length} из ${badges.length}',
                color: T.salmon,
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: T.s8,
                  mainAxisSpacing: T.s8,
                  childAspectRatio: 0.74,
                ),
                itemCount: badges.length,
                itemBuilder: (_, i) {
                  final b = badges[i];
                  return StaggerIn(
                    index: i,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: T.s8, vertical: T.s12),
                      decoration: BoxDecoration(
                        color: T.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: b.unlocked ? T.fire : T.stroke.withOpacity(0.5),
                        ),
                        boxShadow: b.unlocked
                            ? [
                                BoxShadow(
                                  color: T.fire.withOpacity(0.22),
                                  blurRadius: 14,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: b.unlocked ? T.fireGradV : null,
                              color: b.unlocked ? null : T.surfaceHi,
                              border: b.unlocked
                                  ? null
                                  : Border.all(color: T.faint.withOpacity(0.4)),
                            ),
                            child: Opacity(
                              opacity: b.unlocked ? 1 : 0.45,
                              child: Text(
                                b.emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(height: T.s8),
                          Text(
                            b.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: T.body(11,
                                w: FontWeight.w700,
                                color: b.unlocked ? T.text : T.muted),
                          ),
                          const Spacer(),
                          GradientProgress(value: b.progress, height: 5),
                          const SizedBox(height: T.s4),
                          Text(
                            b.unlocked
                                ? 'открыто ✓'
                                : '${b.current}/${b.threshold} · ${b.condition}',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: T.body(9.5,
                                color: b.unlocked ? T.online : T.faint,
                                w: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: T.s20),
              sectionLabel('Титулы города', color: T.salmon),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: T.s16, vertical: T.s8),
                child: Column(
                  children: [
                    for (var i = 0; i < titles.length; i++) ...[
                      if (i > 0) hairline(opacity: 0.6),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: T.s8),
                        child: Row(
                          children: [
                            Text(
                              titles[i].unlocked ? '👑' : '🔒',
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(width: T.s12),
                            Expanded(
                              child: Text(
                                '${titles[i].name} · ${widget.cityName}',
                                style: T.body(13.5,
                                    w: FontWeight.w600,
                                    color: titles[i].unlocked
                                        ? T.text
                                        : T.muted),
                              ),
                            ),
                            if (myTitle != null &&
                                myTitle.startsWith(titles[i].name))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: T.fireGrad,
                                  borderRadius: BorderRadius.circular(T.rPill),
                                ),
                                child: const Text(
                                  'твой титул',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              )
                            else
                              Text(
                                titles[i].unlocked ? 'открыт' : titles[i].hint,
                                style: T.body(11.5,
                                    color: titles[i].unlocked
                                        ? T.online
                                        : T.faint),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: T.s20),
              sectionLabel('Лестница уровней', color: T.salmon),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: T.s16, vertical: T.s8),
                child: Column(
                  children: [
                    for (var i = 0; i < kLevels.length; i++) ...[
                      if (i > 0) hairline(opacity: 0.6),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: T.s8),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient:
                                    lvNum == i + 1 ? T.fireGradV : null,
                                color: lvNum == i + 1 ? null : T.surfaceHi,
                                border: lvNum == i + 1
                                    ? null
                                    : Border.all(
                                        color: T.faint.withOpacity(0.4)),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: T.num(14,
                                    color: lvNum == i + 1
                                        ? Colors.white
                                        : T.muted),
                              ),
                            ),
                            const SizedBox(width: T.s12),
                            Expanded(
                              child: Text(
                                kLevels[i].$2,
                                style: T.body(13.5,
                                    w: FontWeight.w600,
                                    color: lvNum == i + 1
                                        ? T.text
                                        : (xp >= kLevels[i].$1
                                            ? T.text
                                            : T.muted)),
                              ),
                            ),
                            Text(
                              lvNum == i + 1 && nextXp != null
                                  ? 'осталось ${nextXp - xp} XP'
                                  : 'от ${kLevels[i].$1} XP',
                              style: T.body(11.5,
                                  color: lvNum == i + 1 ? T.ember : T.faint,
                                  w: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: T.s20),
              sectionLabel('👑 Топ призраков', color: T.salmon),
              if (!_signedIn)
                GlassCard(
                  gradientBorder: true,
                  child: Column(
                    children: [
                      const Text('👑', style: TextStyle(fontSize: 34)),
                      const SizedBox(height: T.s8),
                      Text(
                        'Войди, чтобы видеть топ города',
                        textAlign: TextAlign.center,
                        style: T.head(15),
                      ),
                      const SizedBox(height: T.s4),
                      Text(
                        'Кто самый легендарный призрак района — видно только своим.',
                        textAlign: TextAlign.center,
                        style: T.body(12.5, color: T.muted),
                      ),
                      const SizedBox(height: T.s12),
                      FireButton(
                        text: '🚀 Войти',
                        small: true,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const LoginPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_board == null && !_boardFailed)
                const Column(
                  children: [
                    ShimmerBox(height: 62),
                    SizedBox(height: T.s8),
                    ShimmerBox(height: 62),
                    SizedBox(height: T.s8),
                    ShimmerBox(height: 62),
                  ],
                )
              else if (_boardFailed || (_board?.isEmpty ?? true))
                const EmptyState(
                  emoji: '👻',
                  title: 'Топ пока пуст',
                  hint: 'Не удалось загрузить призраков города.',
                )
              else
                for (var i = 0; i < _board!.length; i++)
                  _boardRow(i, _board![i]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _boardRow(int i, Map<String, dynamic> row) {
    final rank = i + 1;
    final xp = row['xp'] as int;
    final (_, lvName, _) = levelOf(xp);
    final mine = row['id'] == myUidOrNull;
    return Container(
      margin: const EdgeInsets.only(bottom: T.s8),
      padding: const EdgeInsets.symmetric(horizontal: T.s12, vertical: T.s8),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: mine ? T.gold : T.stroke),
        boxShadow: mine ? T.glowEmber : null,
      ),
      child: Row(
        children: [
          if (rank <= 3)
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: rank == 1
                    ? T.goldGrad
                    : (rank == 2 ? T.emberGrad : T.fireGradV),
              ),
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            )
          else
            SizedBox(
              width: 32,
              child: Center(child: Text('$rank', style: T.num(14, color: T.muted))),
            ),
          const SizedBox(width: T.s12),
          CircleAvatar(
            radius: 20,
            backgroundColor: T.surfaceHi,
            backgroundImage: row['avatar_url'] != null
                ? NetworkImage(row['avatar_url'].toString())
                : null,
            child: row['avatar_url'] == null
                ? Text((row['avatar'] ?? '👻').toString(),
                    style: const TextStyle(fontSize: 18))
                : null,
          ),
          const SizedBox(width: T.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${row['name'] ?? 'Призрак'}${mine ? ' · ты' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.body(14, w: FontWeight.w700),
                ),
                Text(lvName, style: T.body(11.5, color: T.muted)),
              ],
            ),
          ),
          AnimatedNumber(value: xp, suffix: ' XP', style: T.num(14, color: T.ember)),
        ],
      ),
    );
  }
}

/* ---------------- profile tab: «Мой призрак» + about ---------------- */

class ProfileTab extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final Map<String, dynamic> stats;
  final Set<String> favs;
  final List<Place> places;
  final City? city;
  final void Function(Map<String, dynamic>) onProfileChanged;
  final VoidCallback onOpenTasks;
  final bool hapticsValue;
  final void Function(bool) onToggleHaptics;
  const ProfileTab({
    super.key,
    required this.profile,
    required this.stats,
    required this.favs,
    required this.places,
    required this.city,
    required this.onProfileChanged,
    required this.onOpenTasks,
    required this.hapticsValue,
    required this.onToggleHaptics,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  int? _guestNumber;
  String? _guestAvatarPath;
  String? _guestEmoji;
  final Map<String, bool> _notif = {};
  final GlobalKey _aboutKey = GlobalKey();

  static const _notifKinds = <(String, String)>[
    ('quest', '🏙️ Квесты и задания дня'),
    ('friends', '👻 Друзья в деле и онлайн'),
    ('votes', '🗳️ Голосования'),
    ('photos', '📸 Фото и турнир дня'),
    ('streak', '🔥 Серия под угрозой'),
    ('rain', '🌧️ Дождь в городе'),
    ('steps', '👟 Цели шагов'),
  ];

  @override
  void initState() {
    super.initState();
    _loadGuestNumber();
  }

  Future<void> _loadGuestNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var n = prefs.getInt('ghost_number');
      if (n == null) {
        n = 1000 + math.Random().nextInt(9000);
        await prefs.setInt('ghost_number', n);
      }
      if (!mounted) return;
      setState(() {
        _guestNumber = n;
        // Guest avatar lives ONLY on this phone: a local file whose path
        // is kept in prefs (guest_avatar_path) — nothing is uploaded.
        _guestAvatarPath = prefs.getString('guest_avatar_path');
        _guestEmoji = prefs.getString('guest_avatar_emoji');
        for (final (key, _) in _notifKinds) {
          _notif[key] = prefs.getBool('notif_$key') ?? true;
        }
      });
    } catch (_) {}
  }

  Future<void> _setNotif(String key, bool on) async {
    setState(() => _notif[key] = on);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notif_$key', on);
    } catch (_) {}
  }

  /* Avatar editor: emoji grid + «Фото из галереи». Signed-in users
     upload to the avatars bucket (<uid>/avatar.jpg) and set
     profiles.avatar_url; guests keep the picked photo on-device. */
  void _showAvatarSheet() {
    final signedIn = supa.auth.currentUser != null;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SheetShell(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(T.s20, T.s4, T.s20, T.s16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Аватар призрака', style: T.head(16)),
              const SizedBox(height: T.s12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final e in [
                    '👻', '😎', '🦊', '🐺', '🦉', '🐱',
                    '🔥', '🌙', '⭐', '💀', '🎭', '🦄',
                  ])
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        _setEmojiAvatar(e);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: T.surfaceHi,
                          border: Border.all(color: T.stroke),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: T.s16),
              FireButton(
                text: '📷 Фото из галереи',
                small: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  _pickGalleryAvatar();
                },
              ),
              if (!signedIn) ...[
                const SizedBox(height: T.s8),
                Text(
                  'Гостю фото сохранится только на этом телефоне. Войди — и аватар будет жить в облаке.',
                  textAlign: TextAlign.center,
                  style: T.body(11.5, color: T.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setEmojiAvatar(String e) async {
    final uid = myUidOrNull;
    if (uid == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('guest_avatar_emoji', e);
      } catch (_) {}
      if (mounted) setState(() => _guestEmoji = e);
      return;
    }
    widget.onProfileChanged({...?widget.profile, 'avatar': e, 'avatar_url': null});
    try {
      await supa
          .from('profiles')
          .update({'avatar': e, 'avatar_url': null}).eq('id', uid);
    } catch (_) {}
  }

  Future<void> _pickGalleryAvatar() async {
    final bytes = await pickAndProcessImage(ImageSource.gallery);
    if (bytes == null) return;
    final uid = myUidOrNull;
    if (uid == null) {
      // Guest: write the photo to a local file and remember its path.
      try {
        final f = File(
            '${Directory.systemTemp.path}/tirada_guest_avatar.jpg');
        await f.writeAsBytes(bytes);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('guest_avatar_path', f.path);
        if (mounted) setState(() => _guestAvatarPath = f.path);
      } catch (_) {}
      return;
    }
    try {
      final path = '$uid/avatar.jpg';
      await supa.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      final url =
          '${supa.storage.from('avatars').getPublicUrl(path)}?t=${DateTime.now().millisecondsSinceEpoch}';
      widget.onProfileChanged({...?widget.profile, 'avatar_url': url});
      await supa.from('profiles').update({'avatar_url': url}).eq('id', uid);
      if (mounted) snack(context, 'Аватар обновлён 📷');
    } catch (_) {
      if (mounted) snack(context, 'Аватар не загрузился — попробуй ещё раз');
    }
  }

  Future<void> _setMode(String mode) async {
    final p = {...?widget.profile, 'mode': mode};
    widget.onProfileChanged(p);
    final uid = myUidOrNull;
    if (uid == null) return;
    try {
      await supa.from('profiles').update({'mode': mode}).eq('id', uid);
    } catch (_) {}
  }

  Widget _statCard(String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: kRed.withOpacity(0.28)),
            boxShadow: [
              BoxShadow(color: kRed.withOpacity(0.10), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              Text(value, style: T.num(19, color: T.ember)),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: T.body(9.5, color: T.muted, w: FontWeight.w600)
                    .copyWith(height: 1.15),
              ),
            ],
          ),
        ),
      );

  Widget _socialButton(String glyph, String url) => GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          openLink(url);
        },
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kSurface,
            border: Border.all(color: kBorder, width: 1.3),
            boxShadow: [
              BoxShadow(color: kRed.withOpacity(0.25), blurRadius: 14),
            ],
          ),
          child: Text(glyph, style: const TextStyle(fontSize: 23)),
        ),
      );

  Widget _creatorRow(String emoji, String name, String handle,
      {bool main = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kSurface2,
              border: Border.all(color: kBorder),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          if (main) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kRed, kOrange]),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'главный создатель',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const Spacer(),
          Text(
            handle,
            style: const TextStyle(
              color: Color(0xFFFF6B4A),
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = supa.auth.currentUser != null;
    final p = widget.profile;
    final nick = signedIn ? ((p?['name'] as String?) ?? 'Призрак') : 'Гость';
    final uid = myUidOrNull;
    final number = signedIn && uid != null
        ? 1000 + stableHash(uid) % 9000
        : (_guestNumber ?? 1000);
    final avatarEmoji =
        signedIn ? ((p?['avatar'] as String?) ?? '👻') : (_guestEmoji ?? '👻');
    final avatarUrl = signedIn ? (p?['avatar_url'] as String?) : null;
    final mode = (p?['mode'] as String?) ?? 'visible';
    final s = widget.stats;
    final xp = xpOfStats(s);
    final (lvNum, lvName, nextXp) = levelOf(xp);
    final curThreshold = kLevels[lvNum - 1].$1;
    final progress = nextXp == null
        ? 1.0
        : ((xp - curThreshold) / (nextXp - curThreshold)).clamp(0.0, 1.0);
    final nextName = nextXp == null ? null : kLevels[lvNum].$2;
    final best = math.max(statInt(s, 'bestStreak'), statInt(s, 'streak'));
    final b = math.min(math.max(0, best), 30);
    final contrib = <String, int>{
      'задания': statInt(s, 'tasks') * 20,
      'квест': statInt(s, 'quests') * 100 + statInt(s, 'questSteps') * 15,
      'маршруты': statInt(s, 'routes') * 40,
      'ночи': statInt(s, 'nights') * 30,
      'фото': statInt(s, 'photos') * 25,
      'голоса': statInt(s, 'votes') * 5,
      'серия': b * b * 2,
    };
    final favPlaces = widget.favs
        .map((id) => widget.places.where((pl) => pl.id == id).firstOrNull)
        .whereType<Place>()
        .toList();
    final visited = (s['places'] as List?)?.length ?? 0;

    return GlowBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
        children: [
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Мой '),
              TextSpan(text: 'призрак', style: T.display(21, color: T.ember)),
            ]),
            style: T.display(21),
          ),
          const SizedBox(height: 18),
          Center(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _showAvatarSheet();
              },
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kRed, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: kRed.withOpacity(0.55),
                      blurRadius: 30,
                      spreadRadius: 3,
                    ),
                  ],
                  image: avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : (!signedIn && _guestAvatarPath != null
                          ? DecorationImage(
                              image: FileImage(File(_guestAvatarPath!)),
                              fit: BoxFit.cover,
                            )
                          : null),
                  color: kSurface2,
                ),
                alignment: Alignment.center,
                child: avatarUrl == null &&
                        (signedIn || _guestAvatarPath == null)
                    ? Text(avatarEmoji, style: const TextStyle(fontSize: 52))
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'тап по призраку — выбрать аватарку',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            '$nick #$number',
            textAlign: TextAlign.center,
            style: T.head(21),
          ),
          const SizedBox(height: T.s8),
          Builder(builder: (_) {
            final title = ghostTitle(s, widget.city?.name ?? 'города');
            if (title == null) {
              return Text(
                'Без титула — пока',
                textAlign: TextAlign.center,
                style: T.body(12, color: T.faint),
              );
            }
            return Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: T.s12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: T.goldGrad,
                  borderRadius: BorderRadius.circular(T.rPill),
                  boxShadow: T.glowEmber,
                ),
                child: Text(
                  '👑 $title',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 5),
          const Text(
            'Без настоящего имени. Без лишнего. Только вайб.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, fontSize: 13.5),
          ),
          const SizedBox(height: 20),
          if (signedIn) ...[
            sectionLabel('Ник призрака'),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kRed.withOpacity(0.25)),
              ),
              child: Text(
                nick,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 18),
            sectionLabel('Режим на карте'),
            Wrap(
              spacing: 8,
              children: [
                for (final (v, label) in [
                  ('visible', '👁 Видимый'),
                  ('ghost', '👻 Призрак'),
                  ('offline', '🚫 Невидимка'),
                ])
                  GestureDetector(
                    onTap: () => _setMode(v),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: mode == v
                            ? const LinearGradient(colors: [kRed, kOrange])
                            : null,
                        color: mode == v ? null : kSurface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: mode == v
                              ? Colors.transparent
                              : kRed.withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ] else ...[
            PressButton(
              text: '🚀 Войти / Создать аккаунт',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LoginPage()),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Аккаунт нужен для друзей на карте, своего ника и синхронизации. '
              'Всё остальное работает и так.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              _statCard('${statInt(s, 'nights')}', 'ночи в деле'),
              const SizedBox(width: 8),
              _statCard('$visited', 'мест открыто'),
              const SizedBox(width: 8),
              _statCard('${statInt(s, 'routes')}', 'маршрута построено'),
              const SizedBox(width: 8),
              _statCard('${statInt(s, 'photos')}', 'фото в городе'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LevelRing(level: lvNum, progress: progress, size: 74),
                    const SizedBox(width: T.s16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lvName, style: T.head(17)),
                        const SizedBox(height: 2),
                        AnimatedNumber(
                          value: xp,
                          suffix: ' XP',
                          style: T.num(15, color: T.ember),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: T.s16),
                GradientProgress(value: progress),
                const SizedBox(height: 9),
                Text(
                  nextXp == null
                      ? 'Максимальный уровень 👑'
                      : 'До уровня ${lvNum + 1} «$nextName» осталось ${nextXp - xp} XP',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  contrib.entries.map((e) => '${e.key} ${e.value}').join(' · '),
                  style: const TextStyle(color: kMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: T.s16),
          Builder(builder: (_) {
            final streak = statInt(s, 'streak');
            final bestStreak =
                math.max(streak, statInt(s, 'bestStreak'));
            final weekday = DateTime.now().weekday; // 1 = Пн
            bool filled(int i) {
              if (streak >= 7) return true;
              final daysAgo = weekday - (i + 1);
              return daysAgo >= 0 && daysAgo < streak;
            }

            return Container(
              padding: const EdgeInsets.all(T.s16),
              decoration: cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('🔥 серия: $streak дн.',
                          style: T.head(15)),
                      const Spacer(),
                      Text(
                        'рекорд: $bestStreak',
                        style: T.body(12, color: T.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: T.s12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < 7; i++)
                        Column(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: filled(i) ? T.fireGradV : null,
                                color: filled(i) ? null : T.surfaceHi,
                                border: filled(i)
                                    ? null
                                    : Border.all(
                                        color: T.faint.withOpacity(0.4)),
                                boxShadow: filled(i)
                                    ? [
                                        BoxShadow(
                                          color: T.fire.withOpacity(0.4),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                filled(i) ? '🔥' : '·',
                                style: TextStyle(
                                  fontSize: filled(i) ? 14 : 16,
                                  color: T.faint,
                                ),
                              ),
                            ),
                            const SizedBox(height: T.s4),
                            Text(
                              ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'][i],
                              style: T.body(10,
                                  color: i + 1 == weekday
                                      ? T.ember
                                      : T.faint,
                                  w: FontWeight.w700),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: T.s16),
          const StepsCard(),
          const SizedBox(height: T.s16),
          Row(
            children: [
              Expanded(
                child: FireButton(
                  text: '🎯 Задачник',
                  onPressed: widget.onOpenTasks,
                ),
              ),
              const SizedBox(width: T.s12),
              Expanded(
                child: GhostButton(
                  text: '🏆 Награды',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BadgesPage(
                        stats: s,
                        cityName: widget.city?.name ?? 'города',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          sectionLabel('❤️ Избранное', color: const Color(0xFFFF8A7A)),
          if (favPlaces.isEmpty)
            const Text(
              'Пока пусто — жми сердечко у мест',
              style: TextStyle(color: kMuted),
            ),
          for (final fp in favPlaces)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kRed.withOpacity(0.22)),
              ),
              child: Row(
                children: [
                  Text(kTypeEmoji[fp.type] ?? '📍',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      fp.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${vibeOf(fp)}%',
                    style: const TextStyle(
                      color: kOrange,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          if (signedIn) ...[
            const SizedBox(height: 10),
            PressButton(
              text: 'Выйти',
              primary: false,
              onPressed: () => supa.auth.signOut(),
            ),
          ],
          const SizedBox(height: T.s24),
          sectionLabel('Карточка призрака', color: T.salmon),
          GlassCard(
            gradientBorder: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    glowIcon(54),
                    const SizedBox(width: T.s16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$nick #$number', style: T.head(16)),
                          const SizedBox(height: 2),
                          Text(
                            'Уровень $lvNum · $lvName · $xp XP',
                            style: T.body(12.5, color: T.muted),
                          ),
                          Text(
                            widget.city?.name ?? '',
                            style: T.body(12.5, color: T.muted),
                          ),
                        ],
                      ),
                    ),
                    const Text('👻', style: TextStyle(fontSize: 26)),
                  ],
                ),
                const SizedBox(height: T.s12),
                GhostButton(
                  text: '🔗 Поделиться карточкой',
                  small: true,
                  onPressed: () => shareWithXp(
                    context,
                    '👻 $nick #$number — TiradA anon\n'
                    'Уровень $lvNum · $lvName · $xp XP\n'
                    'Город: ${widget.city?.name ?? ''} · живой радар движа 🔥',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: T.s24),
          sectionLabel('Настройки', color: T.salmon),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: T.s16, vertical: T.s4),
            decoration: cardDecoration(),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('📳', style: TextStyle(fontSize: 17)),
                    const SizedBox(width: T.s12),
                    Expanded(
                      child: Text(
                        'Вибрация кнопок',
                        style: T.body(14, w: FontWeight.w600),
                      ),
                    ),
                    Switch(
                      value: widget.hapticsValue,
                      onChanged: widget.onToggleHaptics,
                      activeColor: T.ember,
                      activeTrackColor: T.fire.withOpacity(0.45),
                    ),
                  ],
                ),
                hairline(opacity: 0.6),
                Pressable(
                  onTap: () {
                    final ctx = _aboutKey.currentContext;
                    if (ctx != null) {
                      Scrollable.ensureVisible(
                        ctx,
                        duration: T.dSlow,
                        curve: T.cPage,
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: T.s12),
                    child: Row(
                      children: [
                        const Text('📱', style: TextStyle(fontSize: 17)),
                        const SizedBox(width: T.s12),
                        Expanded(
                          child: Text(
                            'О приложении',
                            style: T.body(14, w: FontWeight.w600),
                          ),
                        ),
                        const Icon(Icons.expand_more, color: T.muted, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: T.s24),
          sectionLabel('🔔 Уведомления', color: T.salmon),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: T.s16, vertical: T.s4),
            decoration: cardDecoration(),
            child: Column(
              children: [
                for (var i = 0; i < _notifKinds.length; i++) ...[
                  if (i > 0) hairline(opacity: 0.6),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: T.s8),
                          child: Text(
                            _notifKinds[i].$2,
                            style: T.body(14, w: FontWeight.w600),
                          ),
                        ),
                      ),
                      Switch(
                        value: _notif[_notifKinds[i].$1] ?? true,
                        onChanged: (v) => _setNotif(_notifKinds[i].$1, v),
                        activeColor: T.ember,
                        activeTrackColor: T.fire.withOpacity(0.45),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: T.s16),
          Text(
            'TiradA anon · 2.0.8',
            textAlign: TextAlign.center,
            style: T.body(11.5, color: T.faint),
          ),
          const SizedBox(height: 28),
          /* ---------------- About ---------------- */
          Center(child: Container(key: _aboutKey, child: glowIcon(118))),
          const SizedBox(height: 16),
          const Text(
            'Живой радар движа твоего города.\nАнонимно, честно, прямо сейчас.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 22),
          Center(child: sectionLabel('Мы на связи')),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialButton('✈️', 'https://t.me/anoncarmiel'),
              const SizedBox(width: 16),
              _socialButton('📸', 'https://www.instagram.com/black_prince_1.8'),
              const SizedBox(width: 16),
              _socialButton('🎵', 'https://www.tiktok.com/@black_prince_1.8'),
            ],
          ),
          const SizedBox(height: 24),
          sectionLabel('Сделали призраки'),
          _creatorRow('👑', 'Яша', '@black_prince_18', main: true),
          const Divider(color: Color(0xFF26262E), height: 1),
          _creatorRow('🛠️', 'Вард', '@WardDeveloper'),
          const Divider(color: Color(0xFF26262E), height: 1),
          _creatorRow('🎨', 'Сева', '@Severarin'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PressButton(
                  text: '👻 Создатели',
                  small: true,
                  primary: false,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Сделали призраки: Яша 👑, Вард 🛠️ и Сева 🎨',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PressButton(
                  text: '📱 О приложении',
                  small: true,
                  primary: false,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'TiradA anon — живой радар движа твоего города. Анонимно, честно, прямо сейчас.',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          PressButton(
            text: '🔒 Политика конфиденциальности',
            small: true,
            primary: false,
            onPressed: () => openLink('https://tirada-anon.vercel.app'),
          ),
        ],
      ),
    );
  }
}

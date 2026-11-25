// TiradA anon — native app (Flutter), v2.0.16.
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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  /* v2.0.12 icon set (owner's spec): monoline glyphs in soft gray. */
  static const iconGray = Color(0xFF9A9AA0);

  /* Active-badge gradient (owner's spec): #E8301E → #FF6A1A. */
  static const specGrad = LinearGradient(
    colors: [Color(0xFFE8301E), Color(0xFFFF6A1A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
              content: Text(tr('svc_loc_denied')),
              action: SnackBarAction(
                label: tr('settings'),
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
            tr('svc_gps_off'),
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

/* One shared map overlay for BOTH line features (v2.0.9): the evening /
   ready route polyline and the single-place «Маршрут сюда» directions.
   Whoever sets a new line replaces the previous one — the two can
   never fight on the map. MapTab listens and (re)draws; HomePage
   listens to showTick and switches to the Map tab. */
class MapRouteLine {
  final String kind; // 'route' · 'directions'
  final String title;
  final List<LatLng> points; // start first, then the stops in order
  final List<Place> stops;
  final Place? target; // directions only
  final bool fromCityCenter; // start fell back to the city center
  final double totalKm; // straight-line estimate (the fallback)
  /* Real road route from OSRM (v2.0.10), filled in asynchronously by
     RoutingService.enrich after the line is shown. While these are
     null the overlay is exactly the v2.0.9 straight line. */
  final String profile; // OSRM profile: 'foot' · 'driving'
  final List<LatLng>? roadGeometry;
  final double? roadKm;
  final double? roadMins; // duration for [profile]
  final List<double>? legKm;
  final List<double>? legMins;
  const MapRouteLine({
    required this.kind,
    required this.title,
    required this.points,
    required this.stops,
    this.target,
    this.fromCityCenter = false,
    required this.totalKm,
    this.profile = 'foot',
    this.roadGeometry,
    this.roadKm,
    this.roadMins,
    this.legKm,
    this.legMins,
  });

  MapRouteLine copyWithRoad(RoadRoute r) => MapRouteLine(
        kind: kind,
        title: title,
        points: points,
        stops: stops,
        target: target,
        fromCityCenter: fromCityCenter,
        totalKm: totalKm,
        profile: profile,
        roadGeometry: r.geometry,
        roadKm: r.totalKm,
        roadMins: r.totalMins,
        legKm: r.legKm,
        legMins: r.legMins,
      );

  /* What the UI shows: road values when OSRM answered, straight-line
     estimates until then (and forever when it can't). */
  double get displayKm => roadKm ?? totalKm;
  int get walkMins => profile == 'foot' && roadMins != null
      ? roadMins!.round()
      : (displayKm / 5.0 * 60).round();
  int get driveMins => profile == 'driving' && roadMins != null
      ? roadMins!.round()
      : (displayKm / 30.0 * 60).round();
}

class MapRouteBus {
  static final ValueNotifier<MapRouteLine?> line =
      ValueNotifier<MapRouteLine?>(null);
  static final ValueNotifier<int> showTick = ValueNotifier<int>(0);

  /* v2.0.12: «delete route» requests coming from the MAP (the chip's
     delete button). The RouteTab owns the active-route state, so it
     listens to this tick and performs the actual stop-tracking wipe
     (with the confirm sheet when progress exists). The map itself
     only clears plain directions lines directly. */
  static final ValueNotifier<int> deleteRequestTick = ValueNotifier<int>(0);

  static void show(MapRouteLine l) {
    line.value = l;
    showTick.value++;
    // Straight line appears instantly; the road geometry swaps in
    // when OSRM answers (silently never, when it can't).
    RoutingService.enrich(l);
  }

  static void clear() {
    line.value = null;
  }

  static void requestDeleteRoute() {
    deleteRequestTick.value++;
  }
}

/* One real road route from OSRM: full geometry plus per-leg values. */
class RoadRoute {
  final List<LatLng> geometry;
  final double totalKm;
  final double totalMins;
  final List<double> legKm;
  final List<double> legMins;
  const RoadRoute({
    required this.geometry,
    required this.totalKm,
    required this.totalMins,
    required this.legKm,
    required this.legMins,
  });
}

/* Real road routing via free OSRM servers — no key, no signup, no
   paid tier (owner's free-services rule). Every failure (offline,
   timeout, OSRM error) returns null and the caller keeps the
   straight-line behaviour of v2.0.9. Results are cached in memory
   per (profile + rounded waypoints), so re-opening the same route
   — or switching car ↔ bus, which share the driving route — never
   re-hits the server. */
class RoutingService {
  static final Map<String, RoadRoute> _cache = {};

  /* Route-tab transport → OSRM profile. 'bus' uses driving geometry:
     there is no transit routing here, and we don't pretend
     otherwise — the bus TIME is the driving duration adjusted at
     display time in the RouteTab (×1.35 + 8 min, v2.0.15). */
  static String profileFor(String transport) =>
      transport == 'walk' ? 'foot' : 'driving';

  /* OSRM hosts per profile (v2.0.15). ROOT CAUSE of «время не
     меняется от транспорта»: the public demo server
     (router.project-osrm.org) IGNORES the profile in the path —
     verified live 2026-11-25: /route/v1/foot/… and
     /route/v1/driving/… returned byte-identical car-speed results
     (340.1 s over the same 3.86 km), so once the road route landed,
     walk, bus and car all displayed one and the same duration and
     the same polyline. The FOSSGIS server (routing.openstreetmap.de,
     free, no key) runs a separate instance per profile and honours
     it: for the same waypoints routed-foot answered 2395 s over a
     shorter pedestrian geometry, routed-car 340 s. The demo server
     remains only as a DRIVING fallback (for driving its numbers
     are the correct car numbers). */
  static List<String> _basesFor(String profile) => profile == 'foot'
      ? const [
          'https://routing.openstreetmap.de/routed-foot/route/v1/driving'
        ]
      : const [
          'https://routing.openstreetmap.de/routed-car/route/v1/driving',
          'https://router.project-osrm.org/route/v1/driving',
        ];

  static String cacheKey(String profile, List<LatLng> pts) =>
      '$profile|${pts.map((p) => '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}').join(';')}';

  static Future<RoadRoute?> route(
      String profile, List<LatLng> waypoints) async {
    if (waypoints.length < 2) return null;
    final key = cacheKey(profile, waypoints);
    final hit = _cache[key];
    if (hit != null) return hit;
    for (final base in _basesFor(profile)) {
      final result = await _fetchFrom(base, waypoints);
      if (result != null) {
        _cache[key] = result;
        return result;
      }
    }
    return null;
  }

  static Future<RoadRoute?> _fetchFrom(
      String base, List<LatLng> waypoints) async {
    final client = HttpClient();
    try {
      client.connectionTimeout = const Duration(seconds: 6);
      final coords =
          waypoints.map((p) => '${p.longitude},${p.latitude}').join(';');
      final uri = Uri.parse('$base/$coords'
          '?overview=full&geometries=geojson&annotations=false');
      final req = await client.getUrl(uri).timeout(const Duration(seconds: 6));
      final resp = await req.close().timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return null;
      final body =
          await resp.transform(utf8.decoder).join().timeout(const Duration(seconds: 6));
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (json['code'] != 'Ok') return null;
      final routes = json['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final r = (routes.first as Map).cast<String, dynamic>();
      final coordsList =
          ((r['geometry'] as Map)['coordinates'] as List? ?? []);
      if (coordsList.length < 2) return null;
      final geometry = <LatLng>[
        for (final c in coordsList)
          LatLng(((c as List)[1] as num).toDouble(),
              (c[0] as num).toDouble()),
      ];
      final legs = (r['legs'] as List?) ?? const [];
      final result = RoadRoute(
        geometry: geometry,
        totalKm: ((r['distance'] as num?)?.toDouble() ?? 0) / 1000,
        totalMins: ((r['duration'] as num?)?.toDouble() ?? 0) / 60,
        legKm: [
          for (final l in legs)
            (((l as Map)['distance'] as num?)?.toDouble() ?? 0) / 1000
        ],
        legMins: [
          for (final l in legs)
            (((l as Map)['duration'] as num?)?.toDouble() ?? 0) / 60
        ],
      );
      if (result.totalKm <= 0) return null;
      return result; // caching lives in route(), keyed by profile
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  /* Fetch the road version of a shown overlay line and swap it in —
     but only if that exact line is still the one on the map. */
  static void enrich(MapRouteLine l) {
    if (l.roadGeometry != null) return;
    route(l.profile, l.points).then((r) {
      if (r == null) return;
      if (identical(MapRouteBus.line.value, l)) {
        MapRouteBus.line.value = l.copyWithRoad(r);
      }
    });
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

/* v2.0.12: the type→emoji map is gone — type icons are TI vector
   glyphs now (see typeGlyph in the TI library). */

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
    if (est == 0) return tr('free');
    return '≈${'₪' * est.clamp(1, 4)}';
  }
  if (pl == 0) return tr('free');
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
      return tr('free_lc');
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
  if (lvl == 0) return tr('free');
  final est = p.priceLevel == null ? '≈' : '';
  return '$est${'₪' * lvl.clamp(1, 4)} · ${priceRangeText(lvl)} ${tr('per_person')}';
}

/* Ghost label with the same numbering the profile uses:
   1000 + stableHash(uid) % 9000. */
String ghostLabelFor(String uid) =>
    trf('ghost_label', {'n': 1000 + stableHash(uid) % 9000});

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

String vibeWord(int v) =>
    v >= 70 ? tr('vibe_hot') : (v >= 45 ? tr('vibe_mid') : tr('vibe_calm'));

/* Open-Meteo weathercode → TI condition glyph (night-aware for clear
   sky). v2.0.12: vector glyphs replace the weather emoji. */
TIGlyph wxGlyphFor(int? code, int hour) {
  if (code == null) return TIGlyph.sun;
  final night = hour >= 20 || hour < 6;
  if (code == 0) return night ? TIGlyph.moon : TIGlyph.sun;
  if (code == 1) return TIGlyph.sun;
  if (code == 2 || code == 3) return TIGlyph.cloud;
  if (code == 45 || code == 48) return TIGlyph.fog;
  if (code >= 95) return TIGlyph.storm;
  if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
    return TIGlyph.snow;
  }
  if (code >= 51) return TIGlyph.cloudRain;
  return TIGlyph.sun;
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

/* A guest's avatar lives only on this phone: a photo file + an emoji,
   both kept in prefs and owned by ProfileTab's state. ProfileTab mirrors
   every change here so the header's profile button (which sits above the
   tab stack, outside ProfileTab) shows the same face the moment it
   changes — no restart, no tab hop. Signed-in users don't need this:
   their avatar rides HomePage's live _profile map. */
class GuestAvatarBus {
  static final ValueNotifier<String?> photoPath =
      ValueNotifier<String?>(null);
  static final ValueNotifier<String?> emoji = ValueNotifier<String?>(null);
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
    snack(context, tr('share_xp_snack'));
  } else {
    snack(context, tr('share_limit_snack'));
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

  /* Persist a mutated steps list; returns true exactly once — when
     this call completes the whole quest and the bonus is due. */
  static Future<bool> _applyDone(
      Map<String, dynamic> quest, List<Map<String, dynamic>> steps) async {
    quest['steps'] = steps;
    final prefs = await SharedPreferences.getInstance();
    final allDone = steps.isNotEmpty && steps.every((st) => st['done'] == true);
    var bonusDue = false;
    if (allDone && quest['bonus'] != true) {
      quest['bonus'] = true;
      bonusDue = true;
      await prefs.setBool('cityquest_done', true);
    }
    await prefs.setString('cityquest_steps', jsonEncode(quest));
    revision.value++;
    return bonusDue;
  }

  /* Mark the step matching (kind, place) from a real action.
     Returns (newly completed steps, bonus due) — v2.0.14: callers
     feed stats.questSteps / stats.quests from these, exactly once
     per step (the done flag is the guard). */
  static Future<(int, bool)> mark(
      String kind, Place place, List<Place> places, City city) async {
    try {
      final quest = await ensure(places, city);
      final steps = (quest['steps'] as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      var newly = 0;
      for (final st in steps) {
        if (st['kind'] == kind && st['place'] == place.id && st['done'] != true) {
          st['done'] = true;
          newly++;
        }
      }
      if (newly == 0) return (0, false);
      final bonusDue = await _applyDone(quest, steps);
      return (newly, bonusDue);
    } catch (_) {
      return (0, false);
    }
  }

  /* Manual tick (v2.0.14, Item 7): the owner asked for a checkbox —
     «нету где поставить галочку». Ticking step [index] by hand goes
     through the same done-flag guard and bonus gate as a real
     action, so a step can never be credited twice however it was
     completed. One-way: there is no un-tick. */
  static Future<(bool, bool)> markStep(
      int index, List<Place> places, City city) async {
    try {
      final quest = await ensure(places, city);
      final steps = (quest['steps'] as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      if (index < 0 || index >= steps.length) return (false, false);
      if (steps[index]['done'] == true) return (false, false);
      steps[index]['done'] = true;
      final bonusDue = await _applyDone(quest, steps);
      return (true, bonusDue);
    } catch (_) {
      return (false, false);
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

/* Local notification display (v2.0.14). FCM does NOT display
   notification messages while the app is in the foreground — before
   2.0.14 a foreground push only became an in-app snackbar, which is
   half of why «уведомления не приходят». This helper shows real
   system notifications (foreground pushes + the Settings self-test)
   through flutter_local_notifications on a single app channel. */
class LocalNotify {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _channel = AndroidNotificationChannel(
    'tirada_general',
    'TiradA anon',
    description: 'Городские уведомления TiradA anon',
    importance: Importance.high,
  );

  static Future<bool> ensureInit() async {
    if (_ready) return true;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(
        const InitializationSettings(android: android),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      _ready = true;
    } catch (e) {
      debugPrint('TiradA LocalNotify init failed: $e');
    }
    return _ready;
  }

  /* Show a system notification now. Returns false when the display
     path is unavailable so callers can fall back to a snackbar. */
  static Future<bool> show(String title, String body) async {
    if (!await ensureInit()) return false;
    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'tirada_general',
            'TiradA anon',
            channelDescription: 'Городские уведомления TiradA anon',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('TiradA LocalNotify show failed: $e');
      return false;
    }
  }

  /* Android 13+ runtime permission for notifications, via the plugin
     (the same system dialog FCM's requestPermission drives). */
  static Future<bool> requestPermission() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return true; // non-Android: nothing to ask
      return await android.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }
}

/* FCM pushes: permission, device token registration into device_tokens,
   foreground messages surfaced to HomePage through [foreground].
   v2.0.14 hardening (owner: «уведомления скорее всего не приходят»):
   the token is (re)registered at init, after every sign-in (auth
   listener below — the common case was: app first launched as a
   guest, token fetched then had no user to attach to and was dropped
   forever), on every app start with a session, and on token refresh;
   the Android 13+ permission is re-asked after sign-in and from the
   «Ты в деле» sheet, not only once at first launch. Server-side
   triggers are a separate wiring (send-fcm) — this is the client. */
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
      // A sign-in after a guest first launch is exactly when the
      // token must land in device_tokens — and when the permission
      // deserves a second ask if the first one was dismissed.
      supa.auth.onAuthStateChange.listen((state) {
        if (state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.tokenRefreshed) {
          ensurePermission();
          registerCurrent();
        }
      });
      await registerCurrent();
    } catch (_) {}
  }

  /* Ask for the notification permission if it is not granted yet.
     Safe to call repeatedly (post-login, first «Ты в деле», Settings
     self-test): Android shows the dialog only while it still can. */
  static Future<void> ensurePermission() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        return;
      }
      await FirebaseMessaging.instance.requestPermission();
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
    } catch (e) {
      // Was a silent catch — a failed registration must at least be
      // visible in the log; the Settings self-test surfaces it in UI.
      debugPrint('TiradA device_tokens upsert failed: $e');
    }
  }

  /* Settings self-test data: is a token row registered for the
     current user, and when was it last refreshed? Null uid = guest. */
  static Future<({int count, DateTime? last})> tokenStatus() async {
    final uid = myUidOrNull;
    if (uid == null) return (count: 0, last: null);
    final rows = await supa
        .from('device_tokens')
        .select('token, updated_at')
        .eq('user_id', uid)
        .order('updated_at', ascending: false);
    DateTime? last;
    for (final r in rows as List) {
      final t = DateTime.tryParse((r['updated_at'] ?? '').toString());
      if (t != null && (last == null || t.isAfter(last))) last = t;
    }
    return (count: (rows as List).length, last: last);
  }
}

/* A pick/processing failure, as opposed to a user cancel. Before
   2.0.14 pickAndProcessImage swallowed EVERY error into the same
   null as a cancel, so a denied camera permission or a picker
   failure made «Добавить фото» silently do nothing (owner: «отправка
   фото не работает»). Callers now catch this and say what happened. */
class ImagePickException implements Exception {
  final Object cause;
  ImagePickException(this.cause);
  @override
  String toString() => 'ImagePickException: $cause';
}

/* Pick an image and re-encode it as JPEG. Decoding + re-encoding strips
   EXIF (GPS coordinates included) — the same privacy trick as the web
   app's canvas re-encode. Returns null ONLY when the user cancels;
   failures throw ImagePickException. */
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
  } catch (e) {
    throw ImagePickException(e);
  }
}

/* XP — the exact formula of the web app (xpOfStats + LEVELS). */
/* Level thresholds; the name is a kStr key, resolved via tr() so the
   ladder reads in the current language everywhere it appears. */
const kLevels = <(int, String)>[
  (0, 'lv_newbie'),
  (100, 'lv_wanderer'),
  (250, 'lv_partier'),
  (500, 'lv_district_ghost'),
  (900, 'lv_city_ghost'),
  (1500, 'lv_night_legend'),
  (2500, 'lv_keeper'),
  (4000, 'lv_myth'),
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
  return (i + 1, tr(kLevels[i].$2), i + 1 < kLevels.length ? kLevels[i + 1].$1 : null);
}

int dayIndex() => DateTime.now().millisecondsSinceEpoch ~/ 86400000;

String dayKeyOf(DateTime d) {
  String p(int n) => n < 10 ? '0$n' : '$n';
  return '${d.year}-${p(d.month)}-${p(d.day)}';
}

String dayKey() => dayKeyOf(DateTime.now());

/* ============================ STREAK (v2.0.14) ============================
   ROOT CAUSE of «серия дней не работает»: before 2.0.14 NOTHING in the
   app ever wrote stats['streak'] / stats['bestStreak'] — the counters
   existed in normStats, were read by the profile display, the badges
   and the XP formula, but no code path incremented them (the check-in
   comment even said "streak is left to its own logic" — that logic did
   not exist). The streak therefore sat at 0 forever.

   This service owns the truth in prefs (streak_count, streak_best,
   streak_last_day — LOCAL calendar dates via dayKeyOf, never UTC):
   a day counts as active when HomePage funnels a meaningful action
   through markActive() (any Item-7 completion toggle, a photo
   check-in/upload, a place or route check-in). First activity of a
   new day: last active yesterday → streak+1; older/none → streak=1;
   same day → unchanged. best = max(best, streak), never decreases.
   HomePage mirrors the returned values into stats (the single source
   the profile, badges and xpOfStats read) and persists them with the
   rest of stats, so the streak survives restarts for guests (prefs +
   local_stats) and signed-in users (cloud profile) alike. */
class StreakService {
  static const _kCount = 'streak_count';
  static const _kBest = 'streak_best';
  static const _kLast = 'streak_last_day';

  /* Record activity for today; returns the (streak, best) to display. */
  static Future<(int, int)> markActive() async {
    final prefs = await SharedPreferences.getInstance();
    final today = dayKey();
    final last = prefs.getString(_kLast) ?? '';
    var streak = prefs.getInt(_kCount) ?? 0;
    var best = prefs.getInt(_kBest) ?? 0;
    if (last != today) {
      final yesterday = dayKeyOf(DateTime.now().subtract(
          const Duration(days: 1)));
      streak = (last == yesterday && streak > 0) ? streak + 1 : 1;
      await prefs.setString(_kLast, today);
      await prefs.setInt(_kCount, streak);
    }
    if (streak > best) {
      best = streak;
      await prefs.setInt(_kBest, best);
    }
    return (streak, best);
  }

  /* Read-only view for display: a streak whose last active day is
     older than yesterday is broken and reads 0 (best is kept). */
  static Future<(int, int)> current() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString(_kLast) ?? '';
    final best = prefs.getInt(_kBest) ?? 0;
    if (last == dayKey() ||
        last == dayKeyOf(DateTime.now().subtract(const Duration(days: 1)))) {
      return (prefs.getInt(_kCount) ?? 0, best);
    }
    return (0, best);
  }

  /* One-time reconciliation at load: seed prefs from the stats copy
     (cloud profile / local_stats) when prefs have never seen a streak
     (fresh install, reinstall), then persist a broken streak as 0 so
     every reader agrees. Returns the values stats should show. */
  static Future<(int, int)> reconcile(Map<String, dynamic> stats) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_kLast) == null) {
      final sStreak = statInt(stats, 'streak');
      final sBest = math.max(sStreak, statInt(stats, 'bestStreak'));
      if (sBest > 0) {
        // Adopt the stored record; treat it as "active yesterday" so
        // it displays today and continues if today becomes active.
        await prefs.setInt(_kCount, sStreak);
        await prefs.setInt(_kBest, sBest);
        await prefs.setString(
            _kLast,
            dayKeyOf(DateTime.now().subtract(const Duration(days: 1))));
      }
    }
    final cur = await current();
    if (cur.$1 == 0 && (prefs.getInt(_kCount) ?? 0) != 0) {
      await prefs.setInt(_kCount, 0); // broken — persist the reset
    }
    return cur;
  }
}

/* ============================ I18N ============================
   App language: 'ru' (default) · 'he' · 'en', persisted in prefs as
   app_lang and held in a notifier so a switch applies app-wide at
   once — HomePage rebuilds the shell, pushed pages listen on their
   own, and MaterialApp's builder flips Directionality for Hebrew.
   EVERY user-visible UI string goes through tr()/trf() and kStr;
   proper names (places, nicks, cities) are data and never pass here.
   Content pools that already carry {ru, he, en} maps (AI daily drop,
   ready-route names) resolve through aiText() below. */
final ValueNotifier<String> appLang = ValueNotifier<String>('ru');

Future<void> setAppLang(String lang) async {
  appLang.value = lang;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', lang);
  } catch (_) {}
}

String tr(String key) {
  final v = kStr[key];
  if (v == null) return key;
  return switch (appLang.value) {
    'he' => v.$2,
    'en' => v.$3,
    _ => v.$1,
  };
}

/* tr with {placeholder} substitution: trf('x', {'n': 3}). */
String trf(String key, [Map<String, Object?> args = const {}]) {
  var s = tr(key);
  args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

const Map<String, (String, String, String)> kStr = {
  'settings': ('Настройки', 'הגדרות', 'Settings'),
  'svc_loc_denied': (
    'Геолокация выключена для приложения — без неё карта тебя не видит',
    'המיקום כבוי לאפליקציה — בלעדיו המפה לא רואה אותך',
    "Location is off for the app — the map can't see you without it"
  ),
  'svc_gps_off': (
    'Включи геолокацию на телефоне — тогда карта покажет, где ты',
    'הפעל את שירותי המיקום בטלפון — ואז המפה תראה איפה אתה',
    'Turn on location services on your phone — then the map will show where you are'
  ),
  'free': ('Бесплатно', 'חינם', 'Free'),
  'free_lc': ('бесплатно', 'חינם', 'free'),
  'per_person': ('на человека', 'לאדם', 'per person'),
  'ghost_label': ('Призрак #{n}', 'רוח #{n}', 'Ghost #{n}'),
  'ghost': ('Призрак', 'רוח', 'Ghost'),
  'vibe_hot': ('жарко', 'חם', 'hot'),
  'vibe_mid': ('средне', 'בינוני', 'moderate'),
  'vibe_calm': ('спокойно', 'רגוע', 'calm'),
  'vibe_label': ('движ', 'וייב', 'vibe'),
  'vibe_of_place': ('движ места', 'הוייב של המקום', 'place vibe'),
  'share_xp_snack': ('🔗 +5 XP за шаринг', '🔗 +5 XP על שיתוף', '🔗 +5 XP for sharing'),
  'share_limit_snack': (
    'Лимит шаринга на сегодня исчерпан',
    'מגבלת השיתופים להיום נגמרה',
    "Today's sharing limit is used up"
  ),
  'splash_tagline': (
    'живой радар движа твоего города',
    'רדאר חי של הבילוי בעיר שלך',
    "a live radar of your city's scene"
  ),
  'lv_newbie': ('Новичок', 'מתחיל', 'Newbie'),
  'lv_wanderer': ('Бродяга', 'נווד', 'Wanderer'),
  'lv_partier': ('Тусовщик', 'בליין', 'Partygoer'),
  'lv_district_ghost': ('Призрак района', 'רוח השכונה', 'District Ghost'),
  'lv_city_ghost': ('Призрак города', 'רוח העיר', 'City Ghost'),
  'lv_night_legend': ('Легенда ночей', 'אגדת הלילות', 'Legend of the Nights'),
  'lv_keeper': ('Хранитель движа', 'שומר הוייב', 'Keeper of the Vibe'),
  'lv_myth': ('Миф', 'מיתוס', 'Myth'),
  'err_generic': (
    'Что-то пошло не так. Проверь интернет.',
    'משהו השתבש. בדוק את החיבור לאינטרנט.',
    'Something went wrong. Check your internet connection.'
  ),
  'login_tagline': ('твой город · твои правила', 'העיר שלך · החוקים שלך', 'your city · your rules'),
  'hint_nick': (
    'Ник (только для нового аккаунта)',
    'כינוי (רק לחשבון חדש)',
    'Nickname (only for a new account)'
  ),
  'hint_password': ('Пароль', 'סיסמה', 'Password'),
  'wait': ('Секунду…', 'רגע…', 'One second…'),
  'sign_in': ('Войти', 'כניסה', 'Sign in'),
  'sign_up': ('Создать аккаунт', 'יצירת חשבון', 'Create account'),
  'login_web_note': (
    'Тот же аккаунт, что и на сайте tirada-anon.vercel.app',
    'אותו חשבון כמו באתר tirada-anon.vercel.app',
    'The same account as on tirada-anon.vercel.app'
  ),
  'browse_guest': ('Смотреть без аккаунта', 'להמשיך בלי חשבון', 'Browse without an account'),
  'nav_map': ('Карта', 'מפה', 'Map'),
  'nav_places': ('Места', 'מקומות', 'Places'),
  'nav_route': ('Маршрут', 'מסלול', 'Route'),
  'nav_profile': ('Профиль', 'פרופיל', 'Profile'),
  'pick_city': ('Выбери город', 'בחר עיר', 'Choose a city'),
  'live_in_city': ('в городе: ', 'בעיר: ', 'in the city: '),
  'live_hot': ('{n} мест жарких', '{n} מקומות חמים', '{n} hot places'),
  'live_total': (
    ' сейчас • всего {n} мест на радаре',
    ' עכשיו • סך הכול {n} מקומות על הרדאר',
    ' now • {n} places on the radar in total'
  ),
  'tick_radar_on': ('👻 Радар включён…', '👻 הרדאר פועל…', '👻 Radar is on…'),
  'tick_top': (
    '🔥 {name} — самый живой движ по радару сейчас…',
    '🔥 {name} — הוייב הכי חי על הרדאר עכשיו…',
    '🔥 {name} — the liveliest vibe on the radar right now…'
  ),
  'tick_city': (
    '📍 {city}: {n} мест на радаре, {hot} жарких прямо сейчас',
    '📍 {city}: {n} מקומות על הרדאר, {hot} חמים ממש עכשיו',
    '📍 {city}: {n} places on the radar, {hot} hot right now'
  ),
  'tick_tap': (
    '👻 Жми 🔥 внизу — город сам соберёт твою ночь',
    '👻 לחץ על 🔥 למטה — והעיר תבנה לך את הלילה',
    '👻 Tap 🔥 below — the city will build your night'
  ),
  'quest_done_snack': (
    '🏙️ Квест города выполнен · +50 XP',
    '🏙️ קווסט העיר הושלם · +50 XP',
    '🏙️ City quest complete · +50 XP'
  ),
  'you_in_city': ('📍 Ты сейчас в: {city}', '📍 אתה עכשיו בעיר: {city}', '📍 You are now in: {city}'),
  'fab_in_deal': ('Ты в деле', 'אתה בפנים', "You're in"),
  'deal_title_a': ('Я в ', 'אני ', "I'm "),
  'deal_title_b': ('деле', 'בפנים', 'in'),
  'deal_sub': (
    'Один тап — и город сам собирает твою ночь.',
    'טאפ אחד — והעיר בונה לך את הלילה.',
    'One tap — and the city builds your night.'
  ),
  'deal_online_now': ('Сейчас в сети: ', 'מחוברים עכשיו: ', 'Online now: '),
  'deal_friends_label': (
    'Друзья сейчас в деле · {n}',
    'חברים שבפנים עכשיו · {n}',
    'Friends in right now · {n}'
  ),
  'deal_guest_note': (
    'Ты пока гость 👻 Войди в аккаунт — и здесь будут друзья, которые сейчас в деле.',
    'אתה אורח בינתיים 👻 היכנס לחשבון — וכאן יופיעו חברים שנמצאים עכשיו בפנים.',
    "You're a guest for now 👻 Sign in — and friends who are in will show up here."
  ),
  'deal_none': (
    'Пока никто из друзей не в деле. Будь первым 🔥',
    'אף חבר עוד לא בפנים. תהיה הראשון 🔥',
    'No friends are in yet. Be the first 🔥'
  ),
  'deal_in_city': ('в сети · {city}', 'מחובר · {city}', 'online · {city}'),
  'deal_in': ('в деле', 'בפנים', 'in'),
  'deal_top_pick': ('Топ выбор радара', 'הבחירה המובילה של הרדאר', "Radar's top pick"),
  'deal_already': (
    '📍 А движ уже есть: {name}',
    '📍 וכבר יש וייב: {name}',
    '📍 And the vibe is already on: {name}'
  ),
  'deal_rec_text': (
    'Город {city} · сейчас там {word} (движ {v}%), от тебя · по прямой: {d} км. Можно стартовать отсюда — друзья подтянутся по ссылке.',
    'העיר {city} · עכשיו {word} שם (וייב {v}%), ממך · בקו ישר: {d} ק״מ. אפשר להתחיל מכאן — חברים יצטרפו דרך הקישור.',
    '{city} · it is {word} there right now (vibe {v}%), from you · straight line: {d} km. You can start here — friends will join via the link.'
  ),
  'deal_route_btn': ('Маршрут', 'מסלול', 'Route'),
  'deal_other': ('Другое место', 'מקום אחר', 'Another place'),
  'deal_poll_title': ('Куда идём?', 'לאן הולכים?', 'Where are we going?'),
  'deal_poll_hint': (
    'Тапни место — это будет твой голос',
    'הקש על מקום — וזה הקול שלך',
    'Tap a place — that will be your vote'
  ),
  'deal_invite': ('Позвать голосовать 👻', 'להזמין להצביע 👻', 'Invite to vote 👻'),
  'deal_share_text': (
    'Голосование за движ в TiradA anon 👻 Присоединяйся: https://tirada-anon.vercel.app',
    'הצבעה על הוייב ב-TiradA anon 👻 הצטרפו: https://tirada-anon.vercel.app',
    'Voting for the vibe in TiradA anon 👻 Join in: https://tirada-anon.vercel.app'
  ),
  'place_word': ('Место', 'מקום', 'Place'),
  'signin_to_fire': ('Войди, чтобы ставить 🔥', 'היכנס כדי לתת 🔥', 'Sign in to give 🔥'),
  'nav_open_fail': (
    'Не удалось открыть навигатор 😕',
    'לא הצלחנו לפתוח את הנווט 😕',
    "Couldn't open the navigator 😕"
  ),
  'review_posted': ('Отзыв опубликован 👻', 'הביקורת פורסמה 👻', 'Review posted 👻'),
  'review_fail': (
    'Отзыв не отправился — попробуй ещё раз',
    'הביקורת לא נשלחה — נסה שוב',
    "The review didn't send — try again"
  ),
  'signin_to_photo': ('Войди, чтобы добавлять фото', 'היכנס כדי להוסיף תמונות', 'Sign in to add photos'),
  'camera': ('Камера', 'מצלמה', 'Camera'),
  'gallery': ('Галерея', 'גלריה', 'Gallery'),
  'who_sees_photo': ('Кто увидит фото?', 'מי יראה את התמונה?', 'Who will see the photo?'),
  'vis_all': ('Всем', 'לכולם', 'Everyone'),
  'vis_friends': ('Только друзьям', 'רק לחברים', 'Friends only'),
  'vis_none': ('Не показывать', 'לא להציג', "Don't show"),
  'photo_posted': (
    'Фото опубликовано 📸 · +25 XP за фото',
    'התמונה פורסמה 📸 · +25 XP על תמונה',
    'Photo posted 📸 · +25 XP for the photo'
  ),
  'photo_fail': (
    'Фото не загрузилось — попробуй ещё раз',
    'התמונה לא עלתה — נסה שוב',
    "The photo didn't upload — try again"
  ),
  'reviews_suffix': (' · {n} отзывов', ' · {n} ביקורות', ' · {n} reviews'),
  'new_place': ('новое место', 'מקום חדש', 'new place'),
  'km_from_you': ('· {d} км от тебя', '· {d} ק״מ ממך', '· {d} km from you'),
  'crowd_now': ('Сейчас отдыхают: ~{n}', 'נחים עכשיו: ~{n}', 'Hanging out now: ~{n}'),
  'crowd_friends': (' · друзья рядом: {n}', ' · חברים בקרבת מקום: {n}', ' · friends nearby: {n}'),
  'you_here': ('✓ Ты здесь', '✓ אתה כאן', "✓ You're here"),
  'i_here': ('✓ Я здесь', '✓ אני כאן', "✓ I'm here"),
  'checkin_snack': (
    'Чек-ин засчитан · место в твоей статистике 👻',
    'הצ׳ק-אין נקלט · המקום בסטטיסטיקה שלך 👻',
    'Check-in counted · the place is in your stats 👻'
  ),
  'share': ('Поделиться', 'שיתוף', 'Share'),
  'share_place_text': (
    '{name} — движ {v}% в TiradA anon 🔥',
    '{name} — וייב {v}% ב-TiradA anon 🔥',
    '{name} — vibe {v}% in TiradA anon 🔥'
  ),
  'uploading': ('Загрузка…', 'מעלה…', 'Uploading…'),
  'add_photo': ('Добавить фото', 'הוסף תמונה', 'Add a photo'),
  'route_here': ('Маршрут сюда', 'מסלול לכאן', 'Route here'),
  'to_navigator': ('В навигатор', 'לנווט', 'Open navigator'),
  'ghost_photos_here': ('Фото призраков здесь', 'תמונות רוחות כאן', 'Ghost photos here'),
  'tap_photo_fire': (
    'тап по фото — поставить 🔥',
    'הקש על תמונה — כדי לתת 🔥',
    'tap a photo — to give 🔥'
  ),
  'ghost_reviews': ('Отзывы призраков', 'ביקורות רוחות', 'Ghost reviews'),
  'reviews_empty': (
    'Пока тихо — стань первым призраком с отзывом.',
    'שקט בינתיים — תהיה הרוח הראשונה עם ביקורת.',
    'Quiet for now — be the first ghost to leave a review.'
  ),
  'ghost_reviews_count': (
    '{avg} · {n} отзывов призраков',
    '{avg} · {n} ביקורות רוחות',
    '{avg} · {n} ghost reviews'
  ),
  'hint_review': ('Оставить отзыв…', 'כתוב ביקורת…', 'Write a review…'),
  'leave_review': ('Оставить отзыв', 'כתוב ביקורת', 'Write a review'),
  'signin_to_review': (
    'Войди, чтобы оставить отзыв',
    'היכנס כדי לכתוב ביקורת',
    'Sign in to write a review'
  ),
  'similar_places': ('Похожие места', 'מקומות דומים', 'Similar places'),
  'online_now': ('Сейчас в сети', 'מחובר עכשיו', 'Online now'),
  'seen_recently': ('Был(а) недавно', 'נראה לאחרונה', 'Seen recently'),
  'pulse_chip': (
    '{city} · {n} мест · {hot} жарких',
    '{city} · {n} מקומות · {hot} חמים',
    '{city} · {n} places · {hot} hot'
  ),
  'chip_dir': ('{name} · {d} · ', '{name} · {d} · ', '{name} · {d} · '),
  'chip_walk': ('≈ {n} мин пешком', '≈ {n} דקות הליכה', '≈ {n} min on foot'),
  'chip_drive': (' · ≈ {n} мин', ' · ≈ {n} דקות', ' · ≈ {n} min'),
  'chip_from_center': (' · от центра города', ' · ממרכז העיר', ' · from the city center'),
  'chip_route': ('{title} · {n} точки · {d}', '{title} · {n} נקודות · {d}', '{title} · {n} stops · {d}'),
  'unit_m': ('м', 'מ׳', 'm'),
  'unit_km': ('км', 'ק״מ', 'km'),
  'type_park': ('Парки', 'פארקים', 'Parks'),
  'type_cafe': ('Кафе', 'בתי קפה', 'Cafes'),
  'type_bar': ('Бары', 'ברים', 'Bars'),
  'type_restaurant': ('Рестораны', 'מסעדות', 'Restaurants'),
  'type_club': ('Клубы', 'מועדונים', 'Clubs'),
  'type_beach': ('Пляжи', 'חופים', 'Beaches'),
  'type_view': ('Смотровые', 'נקודות תצפית', 'Viewpoints'),
  'type_sport': ('Спорт', 'ספורט', 'Sports'),
  'type_culture': ('Культура', 'תרבות', 'Culture'),
  'type_market': ('Магазины', 'חנויות', 'Shops'),
  'type_other': ('Разное', 'שונות', 'Misc'),
  'sort_vibe': ('По движу', 'לפי הוייב', 'By vibe'),
  'sort_dist': ('Рядом со мной', 'קרוב אליי', 'Near me'),
  'sort_rating': ('По рейтингу', 'לפי דירוג', 'By rating'),
  'sort_price': ('По цене', 'לפי מחיר', 'By price'),
  'sort_name': ('А–Я', 'א–ת', 'A–Z'),
  'places_count': ('{n} мест', '{n} מקומות', '{n} places'),
  'tasks_book': ('Задачник', 'משימות', 'Tasks'),
  'ai_day': ('ИИ дня', 'ה-AI של היום', 'AI of the day'),
  'first_task': ('Первое задание: {t}', 'המשימה הראשונה: {t}', 'First task: {t}'),
  'open_tasks': ('Открыть задачник →', 'לפתוח את המשימות ←', 'Open the tasks →'),
  'city_now': ('Город сейчас', 'העיר עכשיו', 'The city now'),
  'stat_places_radar': ('мест на радаре', 'מקומות על הרדאר', 'places on the radar'),
  'stat_hot_now': ('жарких сейчас', 'חמים עכשיו', 'hot now'),
  'stat_avg_vibe': ('средний движ', 'וייב ממוצע', 'average vibe'),
  'search_hint': ('Поиск места…', 'חיפוש מקום…', 'Search a place…'),
  'all': ('Все', 'הכול', 'All'),
  'only_hot': ('Только жаркие', 'רק חמים', 'Only hot'),
  'found_n': ('Найдено: {n}', 'נמצאו: {n}', 'Found: {n}'),
  'empty_title': ('Здесь пока тихо', 'שקט כאן בינתיים', 'Quiet here for now'),
  'empty_hint': (
    'Попробуй другой фильтр, поиск или город.',
    'נסה מסנן אחר, חיפוש אחר או עיר אחרת.',
    'Try another filter, search or city.'
  ),
  'new_short': ('✨ новое', '✨ חדש', '✨ new'),
  'dist_badge': ('{d} км', '{d} ק״מ', '{d} km'),
  'route_evening_title': ('Маршрут на вечер', 'מסלול לערב', 'Evening route'),
  'route_saved_title': ('Сохранённый маршрут', 'מסלול שמור', 'Saved route'),
  'route_title_a': ('Маршрут на ', 'מסלול ל', 'Route for the '),
  'route_title_b': ('вечер', 'ערב', 'evening'),
  'route_saved_snack': ('Маршрут сохранён 💾', 'המסלול נשמר 💾', 'Route saved 💾'),
  'route_desc_0': (
    'Старт — спокойно зайти в вечер.',
    'מתחילים — נכנסים לערב ברוגע.',
    'Start — ease into the evening.'
  ),
  'route_desc_1': (
    'Пик ночи — туда, где жарче всего.',
    'שיא הלילה — איפה שהכי חם.',
    'Peak of the night — where it is hottest.'
  ),
  'route_desc_2': (
    'Финал — закрепить ночь красиво.',
    'סיום — לחתום את הלילה יפה.',
    'Finale — close the night in style.'
  ),
  'route_task_fallback': (
    'Сделай фото, которое расскажет про это место без слов.',
    'צלם תמונה שמספרת על המקום הזה בלי מילים.',
    'Take a photo that tells the story of this place without words.'
  ),
  'route_too_far': (
    'Подойди ближе к месту · до него {d} — чек-ин откроется рядом',
    'התקרב למקום · נותרו {d} — הצ׳ק-אין ייפתח כשתהיה קרוב',
    'Get closer to the place · {d} to go — check-in opens when you are near'
  ),
  'route_done_snack': (
    'Маршрут пройден целиком · +40 XP 🎉',
    'המסלול הושלם במלואו · +40 XP 🎉',
    'Route fully completed · +40 XP 🎉'
  ),
  'route_empty_snack': (
    'Сначала собери маршрут — пока показывать нечего',
    'קודם בנה מסלול — אין מה להציג בינתיים',
    'Build a route first — nothing to show yet'
  ),
  'mins_short': ('≈ {n} мин', '≈ {n} דקות', '≈ {n} min'),
  'stop_near': (
    '📍 Ты рядом — можно чекиниться',
    '📍 אתה קרוב — אפשר לעשות צ׳ק-אין',
    "📍 You're nearby — you can check in"
  ),
  'stop_far': (
    '📍 {d} от тебя · чек-ин откроется у места',
    '📍 {d} ממך · הצ׳ק-אין ייפתח ליד המקום',
    '📍 {d} from you · check-in opens at the place'
  ),
  'done_label': ('Выполнено ✓', 'בוצע ✓', 'Done ✓'),
  'checkin_task': ('Я здесь · задание выполнено', 'אני כאן · המשימה בוצעה', "I'm here · task done"),
  'route_counted_suffix': (' · ✓ пройден', ' · ✓ הושלם', ' · ✓ completed'),
  'ready_card_line': (
    '{n} точки · ≈ {d} от центра',
    '{n} נקודות · ≈ {d} מהמרכז',
    '{n} stops · ≈ {d} from the center'
  ),
  'route_intro_evening': (
    'Три точки, три задания — маршрут строится от тебя по городу {city}. Не нравится расклад — пересобери.',
    'שלוש נקודות, שלוש משימות — המסלול נבנה ממך ברחבי {city}. לא מתאים? בנה מחדש.',
    "Three stops, three tasks — the route is built from you across {city}. Don't like the layout? Reshuffle it."
  ),
  'route_intro_ready': (
    'Готовый маршрут по городу {city}: лучшие места, собранные в пешую цепочку. Иди по точкам и чекинься у каждой.',
    'מסלול מוכן ב{city}: המקומות הטובים ביותר בשרשרת הליכה. עבור בין הנקודות ועשה צ׳ק-אין בכל אחת.',
    'A ready route across {city}: the best places chained into a walk. Follow the stops and check in at each one.'
  ),
  'route_intro_saved': (
    'Твой сохранённый маршрут по городу {city}.',
    'המסלול השמור שלך ב{city}.',
    'Your saved route across {city}.'
  ),
  'route_start_center': ('Геолокация выключена — старт от центра города', 'המיקום כבוי — מתחילים ממרכז העיר', 'Location is off — starting from the city center'),
  'route_start_you': ('Старт — от тебя', 'מתחילים — ממך', 'Start — from you'),
  'route_summary': (
    '🗺️ {n} точки · всего ≈ {d}',
    '🗺️ {n} נקודות · סך הכול ≈ {d}',
    '🗺️ {n} stops · total ≈ {d}'
  ),
  'route_summary_done': (' · ✓ маршрут пройден', ' · ✓ המסלול הושלם', ' · ✓ route completed'),
  'tp_walk': ('Пешком', 'ברגל', 'Walking'),
  'tp_bus': ('Автобус', 'אוטובוס', 'Bus'),
  'tp_car': ('Машина', 'ברכב', 'Car'),
  'route_reshuffle': ('Пересобрать маршрут', 'בנה מסלול מחדש', 'Reshuffle route'),
  'route_show_map': ('Показать на карте', 'הצג במפה', 'Show on map'),
  'route_save': ('Сохранить маршрут', 'שמור מסלול', 'Save route'),
  'delete_route': ('Удалить маршрут', 'מחיקת מסלול', 'Delete route'),
  'delete_route_title': ('Удалить маршрут?', 'למחוק את המסלול?', 'Delete route?'),
  'delete_route_progress': (
    'Прогресс по точкам будет сброшен',
    'ההתקדמות בתחנות תאופס',
    'Progress at the stops will be reset'
  ),
  'btn_cancel': ('Отмена', 'ביטול', 'Cancel'),
  'btn_delete': ('Удалить', 'מחיקה', 'Delete'),
  'route_deleted': ('Маршрут удалён', 'המסלול נמחק', 'Route deleted'),
  'route_back_evening': ('К маршруту на вечер', 'למסלול הערב', 'Back to the evening route'),
  'my_routes': ('Мои маршруты', 'המסלולים שלי', 'My routes'),
  'ready_routes': ('Готовые маршруты', 'מסלולים מוכנים', 'Ready routes'),
  'route_no_places': (
    'В этом городе пока нет мест для маршрута.',
    'בעיר הזו אין עדיין מקומות למסלול.',
    'This city has no places for a route yet.'
  ),
  'from_center': ('от центра', 'מהמרכז', 'from the center'),
  'from_you': ('от тебя', 'ממך', 'from you'),
  'steps_title': ('Шаги сегодня', 'צעדים היום', "Today's steps"),
  'steps_no_access': (
    'Нет доступа к шагам — разреши физическую активность, и шаги начнут давать XP',
    'אין גישה לצעדים — אשר פעילות גופנית, והצעדים יתחילו לתת XP',
    'No access to steps — allow physical activity and steps will start earning XP'
  ),
  'steps_info': (
    'Каждые 1000 шагов = +5 XP (до +50 в день) · до следующего +5 XP: {n} шагов · сегодня +{xp} XP',
    'כל 1000 צעדים = +5 XP (עד +50 ביום) · עד ה-+5 XP הבא: {n} צעדים · היום +{xp} XP',
    'Every 1000 steps = +5 XP (up to +50 a day) · {n} steps to the next +5 XP · today +{xp} XP'
  ),
  'cq_title': ('Квест города — {city}', 'קווסט העיר — {city}', 'City quest — {city}'),
  'cq_checkin': ('Зачекинься: {name}', 'עשה צ׳ק-אין: {name}', 'Check in: {name}'),
  'cq_photo': ('Сфотографируй: {name}', 'צלם: {name}', 'Photograph: {name}'),
  'cq_fav': ('Добавь в избранное: {name}', 'הוסף למועדפים: {name}', 'Add to favorites: {name}'),
  'cq_done': (
    'Квест выполнен · +50 XP уже твои 🎉',
    'הקווסט הושלם · +50 XP כבר שלך 🎉',
    'Quest complete · +50 XP is yours 🎉'
  ),
  'cq_hint': (
    'Все три шага за день — бонус +50 XP. Шаги засчитываются сами: чек-ин, фото и сердечко у нужных мест.',
    'שלושת הצעדים ביום — בונוס +50 XP. הצעדים נספרים מעצמם: צ׳ק-אין, תמונה ולב במקומות הנכונים.',
    'All three steps in a day — a +50 XP bonus. Steps count automatically: a check-in, a photo and a heart at the right places.'
  ),
  'tour_title': ('Фото дня — турнир', 'תמונת היום — טורניר', 'Photo of the day — tournament'),
  'tour_sub': (
    'Фото призраков города за сегодня. Больше 🔥 — выше место; лидер дня завтра получит +25 XP.',
    'תמונות הרוחות של העיר מהיום. יותר 🔥 — מקום גבוה יותר; מוביל היום יקבל מחר +25 XP.',
    "Today's ghost photos of the city. More 🔥 — higher rank; today's leader gets +25 XP tomorrow."
  ),
  'tour_empty': (
    'Сегодня пока нет фото — открой место и стань первым 📸',
    'אין תמונות היום עדיין — פתח מקום ותהיה הראשון 📸',
    'No photos today yet — open a place and be the first 📸'
  ),
  'tour_winner_snack': (
    '🏆 Твоё фото выиграло вчерашний турнир · +25 XP',
    '🏆 התמונה שלך ניצחה בטורניר של אתמול · +25 XP',
    "🏆 Your photo won yesterday's tournament · +25 XP"
  ),
  'tour_leader': ('🏆 Фото дня · {ghost}', '🏆 תמונת היום · {ghost}', '🏆 Photo of the day · {ghost}'),
  'ai_task_done': ('Задание ИИ выполнено · +{xp} XP', 'משימת ה-AI הושלמה · +{xp} XP', 'AI task complete · +{xp} XP'),
  'daily_task_done': ('Задание дня выполнено · +20 XP', 'משימת היום הושלמה · +20 XP', 'Daily task complete · +20 XP'),
  'ai_quest_label': ('Квест дня: {t}', 'קווסט היום: {t}', 'Quest of the day: {t}'),
  'ai_route_theme_label': ('Тема маршрута: {t}', 'נושא המסלול: {t}', 'Route theme: {t}'),
  'done_btn': ('Готово ✓', 'בוצע ✓', 'Done ✓'),
  'loading': ('Загрузка…', 'טוען…', 'Loading…'),
  'week_quest_label': ('Квест недели: {t}', 'קווסט השבוע: {t}', 'Quest of the week: {t}'),
  'daily_task_label': ('Задание дня', 'משימת היום', 'Daily task'),
  /* v2.0.14: staged failure messages (photo/review), progress lines,
     route-task section and the notification self-test. */
  'progress_of': ('{a} из {b}', '{a} מתוך {b}', '{a} of {b}'),
  'photo_pick_fail': (
    'Не удалось открыть фото — попробуй ещё раз',
    'לא ניתן לפתוח את התמונה — נסה שוב',
    "Couldn't open the photo — try again"
  ),
  'photo_upload_fail': (
    'Фото не загрузилось — проверь интернет и попробуй ещё раз',
    'התמונה לא עלתה — בדוק את החיבור ונסה שוב',
    "The photo didn't upload — check your connection and try again"
  ),
  'photo_save_fail': (
    'Фото загрузилось, но не сохранилось в галерее места',
    'התמונה עלתה אך לא נשמרה בגלריית המקום',
    'The photo uploaded but was not saved to the place gallery'
  ),
  'review_save_fail': (
    'Отзыв не отправился — проверь интернет и попробуй ещё раз',
    'הביקורת לא נשלחה — בדוק את החיבור ונסה שוב',
    "The review didn't send — check your connection and try again"
  ),
  'route_tasks_title': ('Задания маршрута', 'משימות המסלול', 'Route tasks'),
  'route_stops_title': ('Точки маршрута', 'נקודות המסלול', 'Route stops'),
  'route_task_done': (
    'Задание маршрута выполнено · +20 XP',
    'משימת המסלול הושלמה · +20 XP',
    'Route task complete · +20 XP'
  ),
  'week_quest_done': (
    'Квест недели выполнен! · +100 XP',
    'קווסט השבוע הושלם! · +100 XP',
    'Weekly quest complete! · +100 XP'
  ),
  'notif_check_title': (
    'Проверка уведомлений',
    'בדיקת התראות',
    'Notification check'
  ),
  'notif_check_btn': (
    'Проверить уведомления',
    'בדיקת התראות',
    'Test notifications'
  ),
  'notif_checking': ('Проверяю…', 'בודק…', 'Checking…'),
  'notif_test_title': (
    'Тестовое уведомление',
    'התראת בדיקה',
    'Test notification'
  ),
  'notif_test_body': (
    'Уведомления работают — так будут приходить новости города',
    'ההתראות עובדות — כך יגיעו חדשות העיר',
    'Notifications work — this is how city news will arrive'
  ),
  'notif_token_ok': (
    'Токен зарегистрирован · обновлён {t}',
    'הטוקן רשום · עודכן {t}',
    'Token registered · updated {t}'
  ),
  'notif_token_none': (
    'Токен не зарегистрирован на сервере — нажми проверку',
    'הטוקן לא רשום בשרת — לחץ על בדיקה',
    'No token registered on the server — run the check'
  ),
  'notif_guest_push': (
    'Гостю пуши не приходят: серверу некуда их слать. Войди в аккаунт — и нажми проверку',
    'לאורח לא מגיעות התראות: לשרת אין לאן לשלוח. היכנס לחשבון — ולחץ על בדיקה',
    'Guests get no pushes: the server has nowhere to send them. Sign in — then run the check'
  ),
  'b_first_night': ('Первая ночь', 'הלילה הראשון', 'First Night'),
  'c_1_night': ('1 ночь в деле', 'לילה אחד בפנים', '1 night in'),
  'c_5_nights': ('5 ночей в деле', '5 לילות בפנים', '5 nights in'),
  'b_explorer': ('Исследователь', 'חוקר', 'Explorer'),
  'c_10_places': ('10 мест открыто', '10 מקומות נפתחו', '10 places opened'),
  'b_photographer': ('Фотограф города', 'צלם העיר', 'City Photographer'),
  'c_1_photo': ('1 фото в городе', 'תמונה אחת בעיר', '1 photo in the city'),
  'b_eye': ('Глаз города', 'עין העיר', 'Eye of the City'),
  'c_5_photos': ('5 фото в городе', '5 תמונות בעיר', '5 photos in the city'),
  'b_router': ('Маршрутник', 'בונה מסלולים', 'Route Builder'),
  'c_3_routes': ('3 маршрута построено', '3 מסלולים נבנו', '3 routes built'),
  'b_architect': ('Архитектор ночей', 'אדריכל הלילות', 'Architect of Nights'),
  'c_10_routes': ('10 маршрутов', '10 מסלולים', '10 routes'),
  'b_streak3': ('Серия 3', 'רצף 3', 'Streak 3'),
  'c_streak3': ('серия 3 дня подряд', 'רצף של 3 ימים', '3-day streak'),
  'b_streak7': ('Серия 7', 'רצף 7', 'Streak 7'),
  'c_streak7': ('серия 7 дней подряд', 'רצף של 7 ימים', '7-day streak'),
  'b_voice': ('Голос города', 'קול העיר', 'Voice of the City'),
  'c_10_votes': ('10 голосов', '10 קולות', '10 votes'),
  'b_quester': ('Квестер', 'קווסטר', 'Quester'),
  'c_1_quest': ('1 квест пройден', 'קווסט אחד הושלם', '1 quest completed'),
  'b_legend': ('Легенда', 'אגדה', 'Legend'),
  't_explorer_city': ('Исследователь города', 'חוקר העיר', 'City Explorer'),
  'c_25_places': ('25 мест открыто', '25 מקומות נפתחו', '25 places opened'),
  'c_5_routes': ('5 маршрутов', '5 מסלולים', '5 routes'),
  't_king': ('Король ночей', 'מלך הלילות', 'King of Nights'),
  'c_10_nights': ('10 ночей в деле', '10 לילות בפנים', '10 nights in'),
  'badges_title': ('Награды', 'פרסים', 'Rewards'),
  'badges_open_count': (
    'Награды · открыто {n} из {total}',
    'פרסים · נפתחו {n} מתוך {total}',
    'Rewards · {n} of {total} unlocked'
  ),
  'badge_open': ('открыто ✓', 'נפתח ✓', 'unlocked ✓'),
  'city_titles': ('Титулы города', 'תוארי העיר', 'City titles'),
  'your_title': ('твой титул', 'התואר שלך', 'your title'),
  'title_open': ('открыт', 'פתוח', 'unlocked'),
  'level_ladder': ('Лестница уровней', 'סולם הרמות', 'Level ladder'),
  'xp_left': ('осталось {n} XP', 'נותרו {n} XP', '{n} XP to go'),
  'xp_from': ('от {n} XP', 'מ-{n} XP', 'from {n} XP'),
  'top_ghosts': ('Топ призраков', 'טופ הרוחות', 'Top ghosts'),
  'top_signin_title': (
    'Войди, чтобы видеть топ города',
    'היכנס כדי לראות את טופ העיר',
    'Sign in to see the city top'
  ),
  'top_signin_sub': (
    'Кто самый легендарный призрак района — видно только своим.',
    'מי הרוח הכי אגדי בשכונה — רואים רק מבפנים.',
    'Who the most legendary ghost of the district is — visible only to insiders.'
  ),
  'top_empty_title': ('Топ пока пуст', 'הטופ ריק בינתיים', 'The top is empty for now'),
  'top_empty_hint': (
    'Не удалось загрузить призраков города.',
    'לא הצלחנו לטעון את רוחות העיר.',
    "Couldn't load the city's ghosts."
  ),
  'you_suffix': (' · ты', ' · אתה', ' · you'),
  'language': ('Язык', 'שפה', 'Language'),
  'settings_btn': ('Настройки', 'הגדרות', 'Settings'),
  'creators_btn': ('Создатели', 'היוצרים', 'Creators'),
  'creators_title': ('Создатели', 'היוצרים', 'Creators'),
  'main_creator': ('главный создатель', 'היוצר הראשי', 'main creator'),
  'app_tagline': (
    'Живой радар движа твоего города.\nАнонимно, честно, прямо сейчас.',
    'רדאר חי של הבילוי בעיר שלך.\nאנונימי, כן, ממש עכשיו.',
    "A live radar of your city's scene.\nAnonymous, honest, right now."
  ),
  'we_on_air': ('Мы на связи', 'דברו איתנו', 'Get in touch'),
  'made_by_ghosts': ('Сделали призраки', 'נוצר על ידי רוחות', 'Made by ghosts'),
  'avatar_sheet_title': ('Аватар призрака', 'האווטאר של הרוח', "The ghost's avatar"),
  'photo_from_gallery': ('Фото из галереи', 'תמונה מהגלריה', 'Photo from gallery'),
  'guest_photo_note': (
    'Гостю фото сохранится только на этом телефоне. Войди — и аватар будет жить в облаке.',
    'לאורח התמונה תישמר רק בטלפון הזה. היכנס — והאווטאר יחיה בענן.',
    'For a guest the photo stays only on this phone. Sign in — and the avatar will live in the cloud.'
  ),
  'avatar_updated': ('Аватар обновлён 📷', 'האווטאר עודכן 📷', 'Avatar updated 📷'),
  'avatar_fail': (
    'Аватар не загрузился — попробуй ещё раз',
    'האווטאר לא עלה — נסה שוב',
    "The avatar didn't upload — try again"
  ),
  'guest': ('Гость', 'אורח', 'Guest'),
  'contrib_tasks': ('задания', 'משימות', 'tasks'),
  'contrib_quest': ('квест', 'קווסט', 'quest'),
  'contrib_routes': ('маршруты', 'מסלולים', 'routes'),
  'contrib_nights': ('ночи', 'לילות', 'nights'),
  'contrib_photos': ('фото', 'תמונות', 'photos'),
  'contrib_votes': ('голоса', 'קולות', 'votes'),
  'contrib_streak': ('серия', 'רצף', 'streak'),
  'prof_title_a': ('Мой ', 'הרוח ', 'My '),
  'prof_title_b': ('призрак', 'שלי', 'ghost'),
  'tap_ghost_hint': (
    'тап по призраку — выбрать аватарку',
    'הקש על הרוח — כדי לבחור אווטאר',
    'tap the ghost — to pick an avatar'
  ),
  'no_title_yet': ('Без титула — пока', 'בלי תואר — בינתיים', 'No title — yet'),
  'city_fallback': ('города', 'העיר', 'the city'),
  'prof_motto': (
    'Без настоящего имени. Без лишнего. Только вайб.',
    'בלי שם אמיתי. בלי מיותר. רק וייב.',
    'No real name. No extras. Just the vibe.'
  ),
  'ghost_nick_label': ('Ник призрака', 'הכינוי של הרוח', "The ghost's nickname"),
  'map_mode_label': ('Режим на карте', 'מצב במפה', 'Map mode'),
  'mode_visible': ('Видимый', 'גלוי', 'Visible'),
  'mode_ghost': ('Призрак', 'רוח', 'Ghost'),
  'mode_offline': ('Невидимка', 'בלתי נראה', 'Invisible'),
  'signin_create': ('Войти / Создать аккаунт', 'כניסה / יצירת חשבון', 'Sign in / Create account'),
  'account_why': (
    'Аккаунт нужен для друзей на карте, своего ника и синхронизации. Всё остальное работает и так.',
    'החשבון נדרש לחברים במפה, לכינוי שלך ולסנכרון. כל השאר עובד גם ככה.',
    'An account is needed for friends on the map, your own nickname and sync. Everything else works anyway.'
  ),
  'stat_nights': ('ночи в деле', 'לילות בפנים', 'nights in'),
  'stat_places_opened': ('мест открыто', 'מקומות נפתחו', 'places opened'),
  'stat_routes_built': ('маршрута построено', 'מסלולים נבנו', 'routes built'),
  'stat_photos_city': ('фото в городе', 'תמונות בעיר', 'photos in the city'),
  'max_level': ('Максимальный уровень', 'הרמה המקסימלית', 'Maximum level'),
  'to_level': (
    'До уровня {n} «{name}» осталось {xp} XP',
    'עד רמה {n} «{name}» נותרו {xp} XP',
    '{xp} XP left to level {n} “{name}”'
  ),
  'streak_line': ('серия: {n} дн.', 'רצף: {n} ימים', 'streak: {n} days'),
  'record': ('рекорд: {n}', 'שיא: {n}', 'record: {n}'),
  'wd_1': ('Пн', 'ב׳', 'Mon'),
  'wd_2': ('Вт', 'ג׳', 'Tue'),
  'wd_3': ('Ср', 'ד׳', 'Wed'),
  'wd_4': ('Чт', 'ה׳', 'Thu'),
  'wd_5': ('Пт', 'ו׳', 'Fri'),
  'wd_6': ('Сб', 'ש׳', 'Sat'),
  'wd_7': ('Вс', 'א׳', 'Sun'),
  'favorites_label': ('Избранное', 'מועדפים', 'Favorites'),
  'favorites_empty': (
    'Пока пусто — жми сердечко у мест',
    'ריק בינתיים — לחץ על הלב ליד מקומות',
    'Empty for now — tap the heart on places'
  ),
  'sign_out': ('Выйти', 'התנתק', 'Sign out'),
  'ghost_card_label': ('Карточка призрака', 'כרטיס הרוח', 'Ghost card'),
  'level_line': ('Уровень {n} · {name} · {xp} XP', 'רמה {n} · {name} · {xp} XP', 'Level {n} · {name} · {xp} XP'),
  'share_card': ('Поделиться карточкой', 'שיתוף הכרטיס', 'Share the card'),
  'share_card_text': (
    '👻 {nick} #{num} — TiradA anon\nУровень {n} · {name} · {xp} XP\nГород: {city} · живой радар движа 🔥',
    '👻 {nick} #{num} — TiradA anon\nרמה {n} · {name} · {xp} XP\nעיר: {city} · רדאר חי של הבילוי 🔥',
    '👻 {nick} #{num} — TiradA anon\nLevel {n} · {name} · {xp} XP\nCity: {city} · a live vibe radar 🔥'
  ),
  'haptics_label': ('Вибрация кнопок', 'רטט בכפתורים', 'Button vibration'),
  'notif_section': ('Уведомления', 'התראות', 'Notifications'),
  'notif_quest': ('Квесты и задания дня', 'קווסטים ומשימות היום', 'Quests and daily tasks'),
  'notif_friends': ('Друзья в деле и онлайн', 'חברים בפנים ומחוברים', 'Friends in and online'),
  'notif_votes': ('Голосования', 'הצבעות', 'Votes'),
  'notif_photos': ('Фото и турнир дня', 'תמונות וטורניר היום', 'Photos and the daily tournament'),
  'notif_streak': ('Серия под угрозой', 'רצף בסכנה', 'Streak at risk'),
  'notif_rain': ('Дождь в городе', 'גשם בעיר', 'Rain in the city'),
  'notif_steps': ('Цели шагов', 'יעדי צעדים', 'Step goals'),
  'in_deal_btn': ('Ты в деле', 'אתה בפנים', "You're in"),
  // __MORE_KEYS__
};

String aiText(dynamic o) {
  if (o is Map) {
    final lang = appLang.value;
    return (o[lang] ?? o['ru'] ?? o['en'] ?? o['he'] ?? '').toString();
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

Widget sectionLabel(String text, {Color color = T.muted, TIGlyph? glyph}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[
            TiradIcon(glyph, size: 13, color: color),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(text.toUpperCase(), style: T.micro(color: color)),
          ),
        ],
      ),
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
  /* v2.0.12: optional TI glyph before the label (icon roles are
     vector now, never emoji). */
  final TIGlyph? icon;
  const FireButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.small = false,
    this.icon,
  });

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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            TiradIcon(
                              widget.icon!,
                              size: widget.small ? 16 : 19,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
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
                        ],
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
  /* v2.0.12: optional TI glyph before the label. */
  final TIGlyph? icon;
  const GhostButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.small = false,
    this.icon,
  });

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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  TiradIcon(
                    icon!,
                    size: small ? 16 : 19,
                    color: T.iconGray,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
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
              ],
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
  final TIGlyph? icon;
  const PressButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.primary = true,
    this.small = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => primary
      ? FireButton(text: text, onPressed: onPressed, small: small, icon: icon)
      : GhostButton(text: text, onPressed: onPressed, small: small, icon: icon);
}

/* Danger action in the app's own button language (v2.0.12): the
   GhostButton shell — dark glass, red border, soft red shadow — with
   a salmon TI glyph + salmon label, so a destructive action reads
   instantly without leaving the design system. */
class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool small;
  final TIGlyph icon;
  const DangerButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.small = false,
    this.icon = TIGlyph.trash,
  });

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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TiradIcon(icon, size: small ? 16 : 19, color: T.salmon),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: T.salmon,
                      fontSize: small ? 13.5 : 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
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

/* Small pill action (chips that behave like buttons). */
class PillButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;
  /* v2.0.12: optional TI glyph before the label (type filter chips). */
  final TIGlyph? icon;
  const PillButton({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
    this.icon,
  });

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              TiradIcon(
                icon!,
                size: 15,
                color: selected ? Colors.white : T.iconGray,
                filled: selected,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? Colors.white : T.text,
              ),
            ),
          ],
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
            TiradIcon(TIGlyph.flame, size: 12, color: c, filled: vibe >= 70),
            const SizedBox(width: 2),
            AnimatedNumber(
              value: vibe,
              suffix: '%',
              style: T.num(16, color: c),
            ),
          ],
        ),
        Text(tr('vibe_label'), style: T.body(9.5, color: T.faint, w: FontWeight.w600)),
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

  /* v2.0.14 (Item 8) — knob geometry, measured before/after.
     BEFORE: the knob (height+3 = 13 dp at the default height 10)
     lived in an Align inside a ClipRRect stack only `height` tall —
     so the clip sliced 1.5 dp off its top and bottom (it rendered
     as a squashed pill, never a circle), and Align's (W−k)·v + k/2
     centring put the knob centre at v·W + k·(0.5−v): exact only at
     v=0.5, drifting up to ±6.5 dp away from the fill boundary
     toward the ends.
     AFTER: the box is knobD = height+6 tall; the track (height) is
     vertically centred in it and inset by knobR on both sides —
     the Material-slider layout — the fill boundary sits at
     knobR + v·(W−2·knobR) and the knob (diameter knobD) is
     Positioned with its centre EXACTLY on that boundary and on the
     track's vertical centre. Nothing clips the knob. This one
     widget backs the level/XP scale and the steps scale (and the
     badge rows), so both are fixed consistently. */
  @override
  Widget build(BuildContext context) {
    final knobD = height + 6;
    final knobR = knobD / 2;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0, 1)),
      duration: T.dEpic,
      curve: T.cOut,
      builder: (_, v, __) => LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final trackW = math.max(0.0, w - knobD);
          final fillW = trackW * v;
          return SizedBox(
            height: knobD,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Track, vertically centred, inset by the knob radius.
                Positioned(
                  left: knobR,
                  right: knobR,
                  top: (knobD - height) / 2,
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: T.surfaceHi,
                      borderRadius: BorderRadius.circular(height),
                    ),
                  ),
                ),
                // Fill, ending exactly where the knob centre sits.
                if (v > 0)
                  Positioned(
                    left: knobR,
                    top: (knobD - height) / 2,
                    child: Container(
                      width: fillW,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: T.fireGrad,
                        borderRadius: BorderRadius.circular(height),
                      ),
                    ),
                  ),
                // Knob: centre = (knobR + fillW, knobD/2) — exactly the
                // fill boundary, exactly the track's mid-height.
                if (v > 0.02)
                  Positioned(
                    left: fillW,
                    top: 0,
                    child: Container(
                      width: knobD,
                      height: knobD,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: T.gold,
                        border: Border.all(color: T.bg, width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: T.ember.withOpacity(0.9), blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
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
                Text(tr('vibe_of_place'), style: T.body(11, color: T.faint, w: FontWeight.w600)),
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


/* ================== TI ICON SET (v2.0.12) ==================
   The owner's design spec, verbatim core: "Set of minimalist
   emoji-style icons, monoline outline style, thick rounded stroke,
   rounded line caps and joins, soft gray color (#9a9aa0), no fill,
   simple geometric shapes. One active icon in filled solid white
   glyph on a glowing orange-to-red gradient circle (#e8301e to
   #ff6a1a) with soft neon glow and subtle radar rings."

   Every glyph is a vector drawn on a 24-unit grid with ONE stroke
   width (2.1 units), round caps/joins, stroke-only in T.iconGray.
   [TIPaint.paint] draws onto any canvas (widgets AND map-marker
   bitmaps); [TiradIcon] is the widget form; [ActiveIconBadge] is
   the active-state form (white filled glyph on the spec gradient).
   This set REPLACES emoji in every icon role in the app; emoji
   inside text content (tasks, snackbars, share text) is untouched. */

enum TIGlyph {
  flame, ghost, mapPin, routePath, heart, star, bolt, skull,
  wineGlass, coffeeCup, tree, utensils, umbrella, musicNote, ball,
  eye, bag, landmark, camera, photo, paperPlane, gear, bell, check,
  x, chevronBack, plus, minus, navArrow, compass, cloud, sun, moon,
  cloudRain, snow, fog, storm, phone, globe, trash, users, voteBox,
  target, calendar, link, share, lock, trophy, dice, walk, car, bus,
  pencil, chat, clock,
}

/* Place type → TI glyph (map pins, chips, cards — replaces the old
   kTypeEmoji/kPinEmoji emoji maps in every icon role). */
TIGlyph typeGlyph(String type) {
  switch (type) {
    case 'restaurant':
      return TIGlyph.utensils;
    case 'cafe':
      return TIGlyph.coffeeCup;
    case 'bar':
      return TIGlyph.wineGlass;
    case 'park':
      return TIGlyph.tree;
    case 'beach':
      return TIGlyph.umbrella;
    case 'culture':
      return TIGlyph.landmark;
    case 'sport':
      return TIGlyph.ball;
    case 'club':
      return TIGlyph.musicNote;
    case 'view':
      return TIGlyph.eye;
    case 'market':
      return TIGlyph.bag;
    default:
      return TIGlyph.mapPin;
  }
}

class TIPaint {
  TIPaint._();

  /* Draws [g] inside [rect] on any canvas. [filled] renders the
     solid variant (active states, badge glyphs, rating stars). */
  static void paint(
    Canvas canvas,
    TIGlyph g,
    Rect rect,
    Color color, {
    bool filled = false,
    double strokeScale = 1,
  }) {
    final s = rect.width / 24;
    canvas.save();
    canvas.translate(rect.left, rect.top);
    canvas.scale(s);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1 * strokeScale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    final main = filled ? fill : stroke;
    Offset o(double x, double y) => Offset(x, y);

    void line(double x1, double y1, double x2, double y2, [Paint? p]) =>
        canvas.drawLine(o(x1, y1), o(x2, y2), p ?? stroke);
    void circle(double x, double y, double r, [Paint? p]) =>
        canvas.drawCircle(o(x, y), r, p ?? stroke);
    void dot(double x, double y, [double r = 1.35]) =>
        canvas.drawCircle(o(x, y), r, fill);

    switch (g) {
      case TIGlyph.flame:
        final p = Path()
          ..moveTo(12, 2.8)
          ..cubicTo(13.4, 6, 17.8, 8.6, 17.8, 13.4)
          ..cubicTo(17.8, 17.6, 15.2, 20.6, 12, 20.6)
          ..cubicTo(8.8, 20.6, 6.2, 17.6, 6.2, 13.4)
          ..cubicTo(6.2, 10.4, 7.6, 8.4, 9, 6.6)
          ..cubicTo(9.4, 8.4, 10.2, 9.4, 11.2, 10)
          ..cubicTo(10.6, 7.2, 11, 4.8, 12, 2.8);
        canvas.drawPath(p, main);
      case TIGlyph.ghost:
        final p = Path()
          ..moveTo(5.5, 20.5)
          ..lineTo(5.5, 11)
          ..cubicTo(5.5, 6.6, 8.4, 3.5, 12, 3.5)
          ..cubicTo(15.6, 3.5, 18.5, 6.6, 18.5, 11)
          ..lineTo(18.5, 20.5)
          ..lineTo(15.3, 17.8)
          ..lineTo(12, 20.5)
          ..lineTo(8.7, 17.8)
          ..close();
        canvas.drawPath(p, main);
        if (!filled) {
          dot(9.6, 10.5, 1.3);
          dot(14.4, 10.5, 1.3);
        }
      case TIGlyph.mapPin:
        final p = Path()
          ..moveTo(12, 21.5)
          ..cubicTo(12, 21.5, 5, 14.8, 5, 10.2)
          ..cubicTo(5, 6.2, 8.1, 3, 12, 3)
          ..cubicTo(15.9, 3, 19, 6.2, 19, 10.2)
          ..cubicTo(19, 14.8, 12, 21.5, 12, 21.5);
        canvas.drawPath(p, main);
        // Filled (badge) form: the hole is knocked out in bg colour,
        // like the old nav pin — reads as the pin's centre dot.
        circle(12, 10.2, 3, filled ? (Paint()..color = T.bg) : stroke);
      case TIGlyph.routePath:
        circle(6, 18.5, 3);
        circle(18, 5.5, 3);
        final p = Path()
          ..moveTo(6, 15.5)
          ..lineTo(6, 11)
          ..cubicTo(6, 7.5, 18, 10.5, 18, 8.5);
        canvas.drawPath(p, stroke);
        dot(6, 18.5, 1.1);
        dot(18, 5.5, 1.1);
      case TIGlyph.heart:
        final p = Path()
          ..moveTo(12, 20.3)
          ..cubicTo(7.2, 16.6, 3.6, 13.3, 3.6, 9.4)
          ..cubicTo(3.6, 6.5, 5.8, 4.6, 8.3, 4.6)
          ..cubicTo(10, 4.6, 11.4, 5.5, 12, 6.7)
          ..cubicTo(12.6, 5.5, 14, 4.6, 15.7, 4.6)
          ..cubicTo(18.2, 4.6, 20.4, 6.5, 20.4, 9.4)
          ..cubicTo(20.4, 13.3, 16.8, 16.6, 12, 20.3)
          ..close();
        canvas.drawPath(p, main);
      case TIGlyph.star:
        final p = Path();
        for (var i = 0; i < 10; i++) {
          final ang = -math.pi / 2 + i * math.pi / 5;
          final r = i.isEven ? 9.2 : 3.9;
          final x = 12 + r * math.cos(ang);
          final y = 12 + r * math.sin(ang);
          if (i == 0) {
            p.moveTo(x, y);
          } else {
            p.lineTo(x, y);
          }
        }
        p.close();
        canvas.drawPath(p, main);
      case TIGlyph.bolt:
        final p = Path()
          ..moveTo(13.2, 2.6)
          ..lineTo(5.6, 13.4)
          ..lineTo(10.9, 13.4)
          ..lineTo(9.7, 21.4)
          ..lineTo(18.4, 10.2)
          ..lineTo(12.9, 10.2)
          ..close();
        canvas.drawPath(p, main);
      case TIGlyph.skull:
        final p = Path()
          ..moveTo(12, 3.2)
          ..cubicTo(7.6, 3.2, 4.8, 6.7, 4.8, 11)
          ..cubicTo(4.8, 13.7, 5.9, 15.3, 7.2, 16.2)
          ..lineTo(7.2, 19.8)
          ..lineTo(16.8, 19.8)
          ..lineTo(16.8, 16.2)
          ..cubicTo(18.1, 15.3, 19.2, 13.7, 19.2, 11)
          ..cubicTo(19.2, 6.7, 16.4, 3.2, 12, 3.2)
          ..close();
        canvas.drawPath(p, main);
        if (!filled) {
          dot(9.1, 11.2, 1.5);
          dot(14.9, 11.2, 1.5);
          line(10.4, 16.6, 10.4, 19.8);
          line(13.6, 16.6, 13.6, 19.8);
        }
      case TIGlyph.wineGlass:
        final p = Path()
          ..moveTo(6.2, 3.2)
          ..lineTo(17.8, 3.2)
          ..cubicTo(17.8, 8.2, 15.4, 11.2, 12, 11.2)
          ..cubicTo(8.6, 11.2, 6.2, 8.2, 6.2, 3.2)
          ..close();
        canvas.drawPath(p, main);
        line(12, 11.2, 12, 18.6);
        line(8.4, 20.6, 15.6, 20.6);
      case TIGlyph.coffeeCup:
        final p = Path()
          ..moveTo(5.4, 9.6)
          ..lineTo(16.6, 9.6)
          ..lineTo(15.9, 15.8)
          ..cubicTo(15.7, 17.7, 14.5, 18.9, 12.7, 18.9)
          ..lineTo(9.3, 18.9)
          ..cubicTo(7.5, 18.9, 6.3, 17.7, 6.1, 15.8)
          ..close();
        canvas.drawPath(p, main);
        final h = Path()
          ..moveTo(16.6, 10.8)
          ..cubicTo(19.4, 10.8, 19.4, 14.8, 16.2, 14.9);
        canvas.drawPath(h, stroke);
        line(4.4, 21.2, 19.6, 21.2);
        line(9.2, 3.4, 9.2, 5.6);
        line(13.4, 3.4, 13.4, 5.6);
      case TIGlyph.tree:
        circle(12, 8.6, 4.8);
        line(12, 13.4, 12, 20.4);
        line(12, 16.6, 9.4, 14.6);
        line(8.2, 20.6, 15.8, 20.6);
      case TIGlyph.utensils:
        final f = Path()
          ..moveTo(5.2, 3.6)
          ..lineTo(5.2, 7.6)
          ..cubicTo(5.2, 9.4, 6, 10.2, 7, 10.2)
          ..cubicTo(8, 10.2, 8.8, 9.4, 8.8, 7.6)
          ..lineTo(8.8, 3.6);
        canvas.drawPath(f, stroke);
        line(7, 10.2, 7, 20.4);
        final k = Path()
          ..moveTo(16.8, 20.4)
          ..lineTo(16.8, 3.8)
          ..cubicTo(18.6, 5.8, 19.2, 8.2, 19.2, 10.6)
          ..cubicTo(19.2, 12.8, 18.3, 14, 16.8, 14.2);
        canvas.drawPath(k, main);
      case TIGlyph.umbrella:
        final p = Path()
          ..moveTo(3.8, 11.2)
          ..cubicTo(3.8, 6.4, 7.4, 3.8, 12, 3.8)
          ..cubicTo(16.6, 3.8, 20.2, 6.4, 20.2, 11.2);
        canvas.drawPath(p, main);
        final sc = Path()
          ..moveTo(3.8, 11.2)
          ..cubicTo(5.2, 9.8, 6.8, 9.8, 8.2, 11.2)
          ..cubicTo(9.6, 9.8, 10.6, 9.8, 12, 11.2)
          ..cubicTo(13.4, 9.8, 14.4, 9.8, 15.8, 11.2)
          ..cubicTo(17.2, 9.8, 18.8, 9.8, 20.2, 11.2);
        canvas.drawPath(sc, stroke);
        line(12, 11.2, 12, 18.2);
        final hk = Path()
          ..moveTo(12, 18.2)
          ..cubicTo(12, 20.4, 15.4, 20.4, 15.4, 18);
        canvas.drawPath(hk, stroke);
      case TIGlyph.musicNote:
        circle(8.1, 17.2, 2.5);
        circle(17.1, 15.2, 2.5);
        line(10.6, 17.2, 10.6, 5.4);
        line(19.6, 15.2, 19.6, 3.6);
        line(10.6, 5.4, 19.6, 3.6);
      case TIGlyph.ball:
        circle(12, 12, 8.6);
        final pent = Path();
        for (var i = 0; i < 5; i++) {
          final ang = -math.pi / 2 + i * 2 * math.pi / 5;
          final x = 12 + 3.4 * math.cos(ang);
          final y = 12 + 3.4 * math.sin(ang);
          if (i == 0) {
            pent.moveTo(x, y);
          } else {
            pent.lineTo(x, y);
          }
        }
        pent.close();
        canvas.drawPath(pent, stroke);
        for (var i = 0; i < 5; i++) {
          final ang = -math.pi / 2 + i * 2 * math.pi / 5;
          line(12 + 3.4 * math.cos(ang), 12 + 3.4 * math.sin(ang),
              12 + 8.2 * math.cos(ang), 12 + 8.2 * math.sin(ang));
        }
      case TIGlyph.eye:
        final p = Path()
          ..moveTo(2.6, 12)
          ..cubicTo(5.6, 6.6, 8.9, 4.6, 12, 4.6)
          ..cubicTo(15.1, 4.6, 18.4, 6.6, 21.4, 12)
          ..cubicTo(18.4, 17.4, 15.1, 19.4, 12, 19.4)
          ..cubicTo(8.9, 19.4, 5.6, 17.4, 2.6, 12)
          ..close();
        canvas.drawPath(p, main);
        circle(12, 12, 3.1);
      case TIGlyph.bag:
        final p = Path()
          ..moveTo(5.9, 8.2)
          ..lineTo(18.1, 8.2)
          ..lineTo(17.3, 19.6)
          ..cubicTo(17.2, 20.5, 16.6, 21, 15.8, 21)
          ..lineTo(8.2, 21)
          ..cubicTo(7.4, 21, 6.8, 20.5, 6.7, 19.6)
          ..close();
        canvas.drawPath(p, main);
        final h = Path()
          ..moveTo(9.2, 10.4)
          ..lineTo(9.2, 6.8)
          ..cubicTo(9.2, 5, 10.4, 3.8, 12, 3.8)
          ..cubicTo(13.6, 3.8, 14.8, 5, 14.8, 6.8)
          ..lineTo(14.8, 10.4);
        canvas.drawPath(h, stroke);
      case TIGlyph.landmark:
        final p = Path()
          ..moveTo(4, 9.4)
          ..lineTo(12, 4.2)
          ..lineTo(20, 9.4);
        canvas.drawPath(p, main);
        line(6.4, 11.6, 6.4, 17.4);
        line(10, 11.6, 10, 17.4);
        line(14, 11.6, 14, 17.4);
        line(17.6, 11.6, 17.6, 17.4);
        line(4, 19.8, 20, 19.8);
      case TIGlyph.camera:
        final r = RRect.fromRectAndRadius(
            const Rect.fromLTWH(3.6, 7.2, 16.8, 12.6), const Radius.circular(2.6));
        canvas.drawRRect(r, main);
        circle(12, 13.5, 3.3);
        final vf = Path()
          ..moveTo(9, 7.2)
          ..lineTo(10.4, 4.6)
          ..lineTo(13.6, 4.6)
          ..lineTo(15, 7.2);
        canvas.drawPath(vf, stroke);
      case TIGlyph.photo:
        final r = RRect.fromRectAndRadius(
            const Rect.fromLTWH(4, 5, 16, 14.4), const Radius.circular(2.2));
        canvas.drawRRect(r, main);
        circle(9, 9.8, 1.6);
        final m = Path()
          ..moveTo(4.6, 17.6)
          ..lineTo(10, 12.8)
          ..lineTo(13.4, 15.6)
          ..lineTo(15.8, 13.6)
          ..lineTo(19.4, 17.2);
        canvas.drawPath(m, stroke);
      case TIGlyph.paperPlane:
        final p = Path()
          ..moveTo(21.3, 2.9)
          ..lineTo(3.9, 10.7)
          ..lineTo(10.4, 13.4)
          ..lineTo(13.1, 20.1)
          ..close();
        canvas.drawPath(p, main);
        line(10.4, 13.4, 21.3, 2.9);
      case TIGlyph.gear:
        for (var i = 0; i < 8; i++) {
          canvas.save();
          canvas.translate(12, 12);
          canvas.rotate(i * math.pi / 4);
          canvas.drawLine(
            const Offset(0, -5.4),
            const Offset(0, -8.4),
            Paint()
              ..color = color
              ..strokeWidth = 3.1 * strokeScale
              ..strokeCap = StrokeCap.round,
          );
          canvas.restore();
        }
        circle(12, 12, 5.2);
        circle(12, 12, 1.9);
      case TIGlyph.bell:
        final p = Path()
          ..moveTo(12, 4.2)
          ..cubicTo(8.9, 4.2, 6.6, 6.7, 6.6, 10.4)
          ..cubicTo(6.6, 13.9, 5.9, 15.7, 4.9, 16.9)
          ..lineTo(19.1, 16.9)
          ..cubicTo(18.1, 15.7, 17.4, 13.9, 17.4, 10.4)
          ..cubicTo(17.4, 6.7, 15.1, 4.2, 12, 4.2)
          ..close();
        canvas.drawPath(p, main);
        final cl = Path()
          ..moveTo(10.1, 19.6)
          ..cubicTo(10.7, 20.8, 13.3, 20.8, 13.9, 19.6);
        canvas.drawPath(cl, stroke);
      case TIGlyph.check:
        final p = Path()
          ..moveTo(4.6, 12.6)
          ..lineTo(9.9, 17.9)
          ..lineTo(19.4, 6.4);
        canvas.drawPath(p, filled
            ? (Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3 * strokeScale
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round)
            : stroke);
      case TIGlyph.clock:
        // v2.0.14: added for the route hero's time chip — same
        // 24-grid monoline language as the rest of the set.
        circle(12, 12, 8.4);
        line(12, 7.6, 12, 12);
        line(12, 12, 15.4, 14.2);
      case TIGlyph.x:
        line(6, 6, 18, 18);
        line(18, 6, 6, 18);
      case TIGlyph.chevronBack:
        final p = Path()
          ..moveTo(14.6, 5.4)
          ..lineTo(7.9, 12)
          ..lineTo(14.6, 18.6);
        canvas.drawPath(p, stroke);
      case TIGlyph.plus:
        line(12, 5, 12, 19);
        line(5, 12, 19, 12);
      case TIGlyph.minus:
        line(5, 12, 19, 12);
      case TIGlyph.navArrow:
        final p = Path()
          ..moveTo(12, 2.8)
          ..lineTo(19.2, 20.4)
          ..lineTo(12, 16.7)
          ..lineTo(4.8, 20.4)
          ..close();
        canvas.drawPath(p, main);
      case TIGlyph.compass:
        circle(12, 12, 8.6);
        final n = Path()
          ..moveTo(15.6, 8.4)
          ..lineTo(13.1, 13.1)
          ..lineTo(8.4, 15.6)
          ..lineTo(10.9, 10.9)
          ..close();
        canvas.drawPath(n, main);
      case TIGlyph.cloud:
        final p = Path()
          ..moveTo(7, 18.6)
          ..lineTo(17, 18.6)
          ..cubicTo(19.8, 18.6, 21.2, 16.7, 21.2, 14.4)
          ..cubicTo(21.2, 12.3, 19.6, 10.6, 17.5, 10.3)
          ..cubicTo(16.9, 7.1, 14.5, 4.9, 11.4, 4.9)
          ..cubicTo(8.4, 4.9, 5.9, 7.4, 5.9, 10.4)
          ..cubicTo(4.3, 11, 2.8, 12.7, 2.8, 14.6)
          ..cubicTo(2.8, 16.8, 4.7, 18.6, 7, 18.6)
          ..close();
        canvas.drawPath(p, main);
      case TIGlyph.sun:
        circle(12, 12, 4.1);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          line(12 + 6.3 * math.cos(a), 12 + 6.3 * math.sin(a),
              12 + 8.6 * math.cos(a), 12 + 8.6 * math.sin(a));
        }
      case TIGlyph.moon:
        final p = Path()
          ..moveTo(20.4, 14.6)
          ..cubicTo(19.1, 17.9, 16, 20.1, 12.4, 20.1)
          ..cubicTo(7.8, 20.1, 4, 16.3, 4, 11.7)
          ..cubicTo(4, 8.1, 6.1, 5.2, 9.2, 4)
          ..cubicTo(8.4, 5.9, 7.9, 8, 7.9, 10.4)
          ..cubicTo(7.9, 15, 11.7, 18.8, 16.3, 18.8)
          ..cubicTo(17.9, 18.8, 19.4, 18.1, 20.4, 14.6)
          ..close();
        canvas.drawPath(p, main);
      case TIGlyph.cloudRain:
        final p = Path()
          ..moveTo(7, 15.4)
          ..lineTo(17, 15.4)
          ..cubicTo(19.4, 15.4, 20.6, 13.9, 20.6, 12)
          ..cubicTo(20.6, 10.2, 19.3, 8.8, 17.5, 8.5)
          ..cubicTo(17, 5.9, 14.9, 4.2, 12.2, 4.2)
          ..cubicTo(9.4, 4.2, 7.2, 6.3, 7.2, 9)
          ..cubicTo(5.8, 9.5, 4.6, 10.9, 4.6, 12.4)
          ..cubicTo(4.6, 14.1, 5.6, 15.4, 7, 15.4)
          ..close();
        canvas.drawPath(p, main);
        line(8.6, 18, 7.8, 20.4);
        line(12.4, 18, 11.6, 20.4);
        line(16.2, 18, 15.4, 20.4);
      case TIGlyph.snow:
        final p = Path()
          ..moveTo(7, 15.4)
          ..lineTo(17, 15.4)
          ..cubicTo(19.4, 15.4, 20.6, 13.9, 20.6, 12)
          ..cubicTo(20.6, 10.2, 19.3, 8.8, 17.5, 8.5)
          ..cubicTo(17, 5.9, 14.9, 4.2, 12.2, 4.2)
          ..cubicTo(9.4, 4.2, 7.2, 6.3, 7.2, 9)
          ..cubicTo(5.8, 9.5, 4.6, 10.9, 4.6, 12.4)
          ..cubicTo(4.6, 14.1, 5.6, 15.4, 7, 15.4)
          ..close();
        canvas.drawPath(p, main);
        dot(8.6, 18.6, 1.15);
        dot(12.4, 20, 1.15);
        dot(16.2, 18.6, 1.15);
      case TIGlyph.fog:
        final p = Path()
          ..moveTo(6.4, 10.4)
          ..cubicTo(6.8, 7.4, 9, 5.4, 11.8, 5.4)
          ..cubicTo(14.3, 5.4, 16.3, 7.2, 16.8, 9.6)
          ..cubicTo(18.6, 9.9, 19.8, 11.4, 19.8, 13.2);
        canvas.drawPath(p, main);
        line(5.4, 13.4, 14.6, 13.4);
        line(4.2, 17, 19.8, 17);
        line(6.4, 20.4, 17.6, 20.4);
      case TIGlyph.storm:
        final p = Path()
          ..moveTo(7, 14.6)
          ..lineTo(16.4, 14.6)
          ..cubicTo(18.8, 14.6, 20, 13.1, 20, 11.2)
          ..cubicTo(20, 9.4, 18.7, 8, 16.9, 7.7)
          ..cubicTo(16.4, 5.1, 14.3, 3.4, 11.6, 3.4)
          ..cubicTo(8.8, 3.4, 6.6, 5.5, 6.6, 8.2)
          ..cubicTo(5.2, 8.5, 4, 9.9, 4, 11.6)
          ..cubicTo(4, 13.3, 5.2, 14.6, 7, 14.6)
          ..close();
        canvas.drawPath(p, main);
        final b = Path()
          ..moveTo(12.6, 15.6)
          ..lineTo(9.8, 19.4)
          ..lineTo(11.8, 19.4)
          ..lineTo(11.2, 21.8)
          ..lineTo(14.4, 17.8)
          ..lineTo(12.4, 17.8)
          ..close();
        canvas.drawPath(b, fill);
      case TIGlyph.phone:
        final r = RRect.fromRectAndRadius(
            const Rect.fromLTWH(8.4, 3.4, 7.2, 17.2), const Radius.circular(2.2));
        canvas.drawRRect(r, main);
        line(11, 17.4, 13, 17.4);
        line(4.9, 9.6, 4.9, 14.4);
        line(19.1, 9.6, 19.1, 14.4);
      case TIGlyph.globe:
        circle(12, 12, 8.6);
        final e = Path()
          ..addOval(const Rect.fromLTWH(8.6, 3.4, 6.8, 17.2));
        canvas.drawPath(e, stroke);
        line(3.4, 12, 20.6, 12);
      case TIGlyph.trash:
        line(4.4, 6.4, 19.6, 6.4);
        final hd = Path()
          ..moveTo(9.4, 6.4)
          ..lineTo(9.4, 4.9)
          ..cubicTo(9.4, 4.1, 10, 3.6, 10.8, 3.6)
          ..lineTo(13.2, 3.6)
          ..cubicTo(14, 3.6, 14.6, 4.1, 14.6, 4.9)
          ..lineTo(14.6, 6.4);
        canvas.drawPath(hd, stroke);
        final b = Path()
          ..moveTo(6.4, 6.4)
          ..lineTo(7.5, 19.2)
          ..cubicTo(7.6, 20.2, 8.3, 20.7, 9.3, 20.7)
          ..lineTo(14.7, 20.7)
          ..cubicTo(15.7, 20.7, 16.4, 20.2, 16.5, 19.2)
          ..lineTo(17.6, 6.4);
        canvas.drawPath(b, main);
        line(10.2, 10.4, 10.5, 16.8);
        line(13.8, 10.4, 13.5, 16.8);
      case TIGlyph.users:
        circle(9.2, 9, 3.4);
        final s1 = Path()
          ..moveTo(3.4, 19.6)
          ..cubicTo(3.4, 15.9, 5.9, 14.1, 9.2, 14.1)
          ..cubicTo(12.5, 14.1, 15, 15.9, 15, 19.6);
        canvas.drawPath(s1, main);
        circle(17.2, 10, 2.6);
        final s2 = Path()
          ..moveTo(16.2, 14.4)
          ..cubicTo(18.9, 14.8, 20.6, 16.6, 20.6, 19.6);
        canvas.drawPath(s2, stroke);
      case TIGlyph.voteBox:
        final paper = Path()
          ..moveTo(8.4, 10.6)
          ..lineTo(8.4, 4.4)
          ..lineTo(15.6, 4.4)
          ..lineTo(15.6, 10.6);
        canvas.drawPath(paper, main);
        final ck = Path()
          ..moveTo(10.2, 7.4)
          ..lineTo(11.7, 8.9)
          ..lineTo(14, 6.2);
        canvas.drawPath(ck, stroke);
        final bx = RRect.fromRectAndRadius(
            const Rect.fromLTWH(3.8, 10.6, 16.4, 9.6), const Radius.circular(1.8));
        canvas.drawRRect(bx, main);
      case TIGlyph.target:
        circle(12, 12, 8.4);
        circle(12, 12, 4.9);
        dot(12, 12, 1.5);
      case TIGlyph.calendar:
        final r = RRect.fromRectAndRadius(
            const Rect.fromLTWH(4, 5.6, 16, 14.8), const Radius.circular(2.2));
        canvas.drawRRect(r, main);
        line(4, 10.2, 20, 10.2);
        line(8.4, 3.4, 8.4, 7.6);
        line(15.6, 3.4, 15.6, 7.6);
        dot(8.6, 14, 1.05);
        dot(12, 14, 1.05);
        dot(15.4, 14, 1.05);
      case TIGlyph.link:
        canvas.save();
        canvas.translate(12, 12);
        canvas.rotate(math.pi / 4);
        final r1 = RRect.fromRectAndRadius(
            const Rect.fromLTWH(-8.6, -3.4, 10, 6.8), const Radius.circular(3.4));
        canvas.drawRRect(r1, stroke);
        final r2 = RRect.fromRectAndRadius(
            const Rect.fromLTWH(-1.4, -3.4, 10, 6.8), const Radius.circular(3.4));
        canvas.drawRRect(r2, stroke);
        canvas.restore();
      case TIGlyph.share:
        circle(6, 12, 2.7);
        circle(17.6, 5.4, 2.7);
        circle(17.6, 18.6, 2.7);
        line(8.4, 10.7, 15.2, 6.7);
        line(8.4, 13.3, 15.2, 17.3);
      case TIGlyph.lock:
        final r = RRect.fromRectAndRadius(
            const Rect.fromLTWH(5.4, 10.6, 13.2, 9.8), const Radius.circular(2.2));
        canvas.drawRRect(r, main);
        final sh = Path()
          ..moveTo(8.4, 10.6)
          ..lineTo(8.4, 7.9)
          ..cubicTo(8.4, 5.9, 10, 4.4, 12, 4.4)
          ..cubicTo(14, 4.4, 15.6, 5.9, 15.6, 7.9)
          ..lineTo(15.6, 10.6);
        canvas.drawPath(sh, stroke);
        dot(12, 15.4, 1.4);
      case TIGlyph.trophy:
        final cup = Path()
          ..moveTo(7, 4.4)
          ..lineTo(17, 4.4)
          ..lineTo(17, 9.4)
          ..cubicTo(17, 12.9, 14.8, 14.9, 12, 14.9)
          ..cubicTo(9.2, 14.9, 7, 12.9, 7, 9.4)
          ..close();
        canvas.drawPath(cup, main);
        final h1 = Path()
          ..moveTo(7, 6.4)
          ..cubicTo(4.7, 6.4, 3.8, 7.9, 3.8, 9.2)
          ..cubicTo(3.8, 11, 5.2, 12.1, 7.1, 12.1);
        canvas.drawPath(h1, stroke);
        final h2 = Path()
          ..moveTo(17, 6.4)
          ..cubicTo(19.3, 6.4, 20.2, 7.9, 20.2, 9.2)
          ..cubicTo(20.2, 11, 18.8, 12.1, 16.9, 12.1);
        canvas.drawPath(h2, stroke);
        line(12, 14.9, 12, 17.6);
        line(8.4, 20.2, 15.6, 20.2);
      case TIGlyph.dice:
        final r = RRect.fromRectAndRadius(
            const Rect.fromLTWH(4.4, 4.4, 15.2, 15.2), const Radius.circular(3.2));
        canvas.drawRRect(r, main);
        dot(8.9, 8.9, 1.4);
        dot(15.1, 8.9, 1.4);
        dot(12, 12, 1.4);
        dot(8.9, 15.1, 1.4);
        dot(15.1, 15.1, 1.4);
      case TIGlyph.walk:
        circle(13.8, 4.4, 1.95);
        line(12.9, 7.4, 11.2, 12.2);
        line(12.5, 9, 9.4, 11.8);
        line(12.5, 9, 15.4, 11);
        line(11.2, 12.2, 8.4, 16.4);
        line(8.4, 16.4, 7.9, 20.4);
        line(11.2, 12.2, 14.4, 15.6);
        line(14.4, 15.6, 17.2, 17.2);
      case TIGlyph.car:
        final b = Path()
          ..moveTo(3.4, 15.8)
          ..lineTo(4.7, 10.7)
          ..cubicTo(4.9, 9.8, 5.6, 9.3, 6.5, 9.1)
          ..lineTo(8.5, 8.7)
          ..lineTo(10.3, 6.2)
          ..cubicTo(10.7, 5.6, 11.4, 5.2, 12.2, 5.2)
          ..lineTo(12.9, 5.2)
          ..cubicTo(13.7, 5.2, 14.4, 5.6, 14.8, 6.2)
          ..lineTo(16.6, 8.7)
          ..lineTo(18.6, 9.1)
          ..cubicTo(19.5, 9.3, 20.2, 9.8, 20.4, 10.7)
          ..lineTo(21.7, 15.8);
        canvas.drawPath(b, main);
        line(3.4, 15.8, 21.7, 15.8);
        circle(7.5, 16.1, 2);
        circle(16.6, 16.1, 2);
      case TIGlyph.bus:
        final r = RRect.fromRectAndRadius(
            const Rect.fromLTWH(5, 4.2, 14, 13.4), const Radius.circular(2.6));
        canvas.drawRRect(r, main);
        line(5, 10.4, 19, 10.4);
        dot(8.4, 14, 1.2);
        dot(15.6, 14, 1.2);
        line(7.6, 17.6, 7.6, 20.2);
        line(16.4, 17.6, 16.4, 20.2);
      case TIGlyph.pencil:
        final p = Path()
          ..moveTo(4.6, 19.4)
          ..lineTo(5.6, 15.7)
          ..lineTo(16.9, 4.4)
          ..cubicTo(17.7, 3.6, 19, 3.6, 19.8, 4.4)
          ..cubicTo(20.6, 5.2, 20.6, 6.5, 19.8, 7.3)
          ..lineTo(8.5, 18.6)
          ..close();
        canvas.drawPath(p, main);
        line(14.9, 6.4, 17.6, 9.1);
      case TIGlyph.chat:
        final r = RRect.fromRectAndRadius(
            const Rect.fromLTWH(3.6, 4.8, 16.8, 11.8), const Radius.circular(3.4));
        canvas.drawRRect(r, main);
        final t = Path()
          ..moveTo(8, 16.6)
          ..lineTo(8, 20.4)
          ..lineTo(13.2, 16.6);
        canvas.drawPath(t, stroke);
        dot(8.2, 10.7, 1.1);
        dot(12, 10.7, 1.1);
        dot(15.8, 10.7, 1.1);
    }
    canvas.restore();
  }
}

class _TIPainter extends CustomPainter {
  final TIGlyph glyph;
  final Color color;
  final bool filled;
  const _TIPainter(this.glyph, this.color, this.filled);

  @override
  void paint(Canvas canvas, Size size) =>
      TIPaint.paint(canvas, glyph, Offset.zero & size, color, filled: filled);

  @override
  bool shouldRepaint(_TIPainter old) =>
      old.glyph != glyph || old.color != color || old.filled != filled;
}

/* The monoline icon as a widget: soft gray #9A9AA0 by default,
   stroke-only, no fill (the owner's spec). */
class TiradIcon extends StatelessWidget {
  final TIGlyph glyph;
  final double size;
  final Color color;
  final bool filled;
  const TiradIcon(
    this.glyph, {
    super.key,
    this.size = 20,
    this.color = T.iconGray,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _TIPainter(glyph, color, filled),
      );
}

/* The ACTIVE state from the spec: filled solid white glyph on a
   glowing orange-to-red gradient circle (#E8301E → #FF6A1A) with a
   soft neon glow and subtle radar rings around it. */
class ActiveIconBadge extends StatelessWidget {
  final TIGlyph glyph;
  final double size;
  final bool rings;
  const ActiveIconBadge({
    super.key,
    required this.glyph,
    this.size = 40,
    this.rings = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (rings) ...[
            Positioned(
              left: -size * 0.13,
              top: -size * 0.13,
              right: -size * 0.13,
              bottom: -size * 0.13,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withOpacity(0.13)),
                ),
              ),
            ),
            Positioned(
              left: -size * 0.27,
              top: -size * 0.27,
              right: -size * 0.27,
              bottom: -size * 0.27,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withOpacity(0.06)),
                ),
              ),
            ),
          ],
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: T.specGrad,
              boxShadow: [
                BoxShadow(
                  color: Color(0x73E8301E),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Color(0x40FF6A1A),
                  blurRadius: 26,
                ),
              ],
            ),
            child: TiradIcon(
              glyph,
              color: Colors.white,
              filled: true,
              size: size * 0.56,
            ),
          ),
        ],
      ),
    );
  }
}

/* ---- Ghost-avatar values (v2.0.16) ----
   profiles.avatar (and the guest prefs / GuestAvatarBus mirror)
   historically stored an EMOJI string (default '👻'). The owner
   rejected the stock-emoji picker: avatar choices are now TI
   glyphs from his icon spec, stored as a token 'ti:<glyphName>'
   (e.g. 'ti:ghost'). Rendering is backward compatible everywhere:
   a token renders the vector glyph, any legacy emoji string
   renders as text exactly as before — existing users' avatars do
   not break. */
TIGlyph? tiAvatarGlyph(String? value) {
  if (value == null || !value.startsWith('ti:')) return null;
  final name = value.substring(3);
  for (final g in TIGlyph.values) {
    if (g.name == name) return g;
  }
  return null;
}

String tiAvatarToken(TIGlyph g) => 'ti:${g.name}';

/* The 12 choices in the «Аватар призрака» picker: the spec's own
   list first (ghost, flame, star, skull, heart, bolt, mapPin,
   routePath), then moon, eye, compass, musicNote. */
const kAvatarGlyphs = <TIGlyph>[
  TIGlyph.ghost, TIGlyph.flame, TIGlyph.star, TIGlyph.skull,
  TIGlyph.heart, TIGlyph.bolt, TIGlyph.mapPin, TIGlyph.routePath,
  TIGlyph.moon, TIGlyph.eye, TIGlyph.compass, TIGlyph.musicNote,
];

/* Renders a stored avatar value in a widget tree: 'ti:<name>' →
   the TI glyph; anything else → the legacy emoji text. With
   [ghostForDefault], the unset / '👻' / '👤' values render the TI
   ghost glyph instead of emoji text (the treatment the friends
   lists already used). */
class AvatarFace extends StatelessWidget {
  final String? value;
  final double glyphSize;
  final double emojiSize;
  final Color glyphColor;
  final bool glyphFilled;
  final bool ghostForDefault;
  const AvatarFace(
    this.value, {
    super.key,
    this.glyphSize = 20,
    this.emojiSize = 20,
    this.glyphColor = T.iconGray,
    this.glyphFilled = false,
    this.ghostForDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    final g = tiAvatarGlyph(value);
    if (g != null) {
      return TiradIcon(g,
          size: glyphSize, color: glyphColor, filled: glyphFilled);
    }
    final v = value;
    if (ghostForDefault &&
        (v == null || v.isEmpty || v == '👻' || v == '👤')) {
      return TiradIcon(TIGlyph.ghost, size: glyphSize, color: glyphColor);
    }
    return Text(
      (v == null || v.isEmpty) ? '👻' : v,
      style: TextStyle(fontSize: emojiSize),
    );
  }
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
  /* v2.0.12: the empty-state mark is a TI glyph, not an emoji. */
  final TIGlyph glyph;
  final String title;
  final String hint;
  const EmptyState({super.key, required this.glyph, required this.title, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: T.s24, vertical: T.s32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TiradIcon(glyph, size: 46, color: T.iconGray),
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
      // Hebrew is RTL: the whole app (shell + pushed routes + sheets)
      // flips direction the moment the language changes.
      builder: (context, child) => AnimatedBuilder(
        animation: appLang,
        builder: (context, _) => Directionality(
          textDirection:
              appLang.value == 'he' ? TextDirection.rtl : TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
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
              // SizedBox.expand is load-bearing (v2.0.10 fix): without
              // it this Stack shrink-wraps to the Column/RadarSweep,
              // and GlowBackground — whose Stack aligns non-positioned
              // children top-start — parks the whole intro in the
              // top-left corner. Expanded, the Stack IS the full
              // screen, so its center alignment truly centers the
              // composition and the loader hugs the real bottom.
              return SizedBox.expand(
                child: Stack(
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
                          tr('splash_tagline'),
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
                ),
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
      setState(() => _error = tr('err_generic'));
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
                  tr('login_tagline'),
                  textAlign: TextAlign.center,
                  style: T.body(14, color: T.muted),
                ),
                const SizedBox(height: 36),
                TextField(
                  controller: _nick,
                  decoration: InputDecoration(hintText: tr('hint_nick')),
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
                  decoration: InputDecoration(hintText: tr('hint_password')),
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
                  text: _busy ? tr('wait') : tr('sign_in'),
                  icon: TIGlyph.bolt,
                  onPressed: _busy ? null : () => _go(false),
                ),
                const SizedBox(height: 12),
                PressButton(
                  text: tr('sign_up'),
                  primary: false,
                  icon: TIGlyph.star,
                  onPressed: _busy ? null : () => _go(true),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('login_web_note'),
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
                  child: Text(
                    tr('browse_guest'),
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
  TIGlyph _wxGlyph = TIGlyph.sun;
  List<Friend> _friends = [];
  LatLng? _lastCitySyncPos; // last position the city auto-sync judged

  @override
  void initState() {
    super.initState();
    _load();
    SharedPreferences.getInstance().then((p) {
      hapticsOn = p.getBool('haptics_on') ?? true;
      final lang = p.getString('app_lang');
      if (lang != null && (lang == 'he' || lang == 'en' || lang == 'ru')) {
        appLang.value = lang;
      }
    });
    appLang.addListener(_onLangChanged);
    // v2.0.6 services: bonus-XP bus, steps→XP, FCM pushes.
    AiXpBus.pending.addListener(_drainAiXp);
    StepsTracker.onCredit = (xp) => AiXpBus.credit(xp);
    StepsTracker.start();
    PushService.init();
    PushService.foreground.addListener(_onForegroundPush);
    // v2.0.9: «Показать на карте» / «Маршрут сюда» ask for the Map tab.
    MapRouteBus.showTick.addListener(_onShowMapRequest);
    // v2.0.10: the selected city auto-syncs to the live position.
    myLocationNotifier.addListener(_syncCityToLocation);
    // v2.0.8: ask for location up front and start the live GPS feed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) LocationService.ensureLocation(context);
    });
    // v2.0.16: the 4 s ticker timer is gone with the ticker strip
    // it fed (see build()) — nothing rotates any more.
  }

  /* A language switch rebuilds the whole shell (header, nav, tabs) —
     every build reads its strings through tr() at build time. */
  void _onLangChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    appLang.removeListener(_onLangChanged);
    AiXpBus.pending.removeListener(_drainAiXp);
    PushService.foreground.removeListener(_onForegroundPush);
    MapRouteBus.showTick.removeListener(_onShowMapRequest);
    myLocationNotifier.removeListener(_syncCityToLocation);
    super.dispose();
  }

  /* Bonus XP posted by deep widgets (sharing, steps, city quest) lands
     in stats here, where stats actually live. */
  /* A route line was just published (Route tab or a place sheet):
     bring the Map tab forward; MapTab itself draws the line. */
  void _onShowMapRequest() {
    if (mounted && _tab != 0) setState(() => _tab = 0);
  }

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
    // v2.0.14: a foreground push becomes a REAL system notification —
    // FCM never displays foreground messages itself, and the old
    // snackbar-only path is half of why pushes «не приходили». The
    // snackbar remains as a fallback when the display path is down.
    final shown = await LocalNotify.show(title, body);
    if (!shown && mounted) {
      snack(context, body.isEmpty ? title : '$title — $body');
    }
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
      // v2.0.14: reconcile the streak with its prefs-owned truth
      // (seed from stats on first run, zero a broken streak) and
      // mirror the result into stats so profile/badges/XP agree.
      final sv = await StreakService.reconcile(_stats);
      if (mounted &&
          (statInt(_stats, 'streak') != sv.$1 ||
              statInt(_stats, 'bestStreak') != sv.$2)) {
        setState(() {
          _stats['streak'] = sv.$1;
          _stats['bestStreak'] = sv.$2;
        });
        _saveStats();
      }
      if (_city != null) _fetchTemp(_city!);
      _loadFriends();
      // A fix may already exist by the time the data lands — judge
      // it once now; later fixes arrive through the listener.
      _syncCityToLocation();
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
    // Every stat bump in this app is a meaningful action (task /
    // quest step / quest / route / photo completion) — it feeds the
    // daily streak (v2.0.14; before, nothing ever incremented it).
    _touchStreak();
  }

  /* Mirror StreakService's verdict into stats (profile display,
     badges and the xpOfStats streak bonus all read stats). */
  Future<void> _touchStreak() async {
    final r = await StreakService.markActive();
    if (!mounted) return;
    if (statInt(_stats, 'streak') != r.$1 ||
        statInt(_stats, 'bestStreak') != r.$2) {
      setState(() {
        _stats['streak'] = r.$1;
        _stats['bestStreak'] = r.$2;
      });
      _saveStats();
    }
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
              name: (p['name'] as String?) ?? tr('ghost'),
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
          _wxGlyph = wxGlyphFor(code, DateTime.now().hour);
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
    final (steps, bonusDue) = await CityQuest.mark(kind, p, _cityPlaces, city);
    if (!mounted) return;
    // v2.0.14: quest steps and finished quests finally feed the
    // stats counters xpOfStats has always priced (questSteps ×15,
    // quests ×100) — before, only the flat +50 aiXp bonus existed
    // and the counters stayed 0 forever.
    if (steps > 0) _bumpStat('questSteps', steps);
    if (bonusDue) {
      _bumpStat('quests', 1);
      _addAiXp(50);
      fireConfetti(context);
      snack(context, tr('quest_done_snack'));
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
      _touchStreak(); // a place check-in is a meaningful day action
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

  /* City auto-sync (v2.0.10): the selected city follows the live
     position. Evaluated on the first fix and again only after a
     >1 km move, so a jittery GPS can't thrash the selection. A
     switch happens only when the nearest city is clearly his —
     its center is < 70% as far as the selected city's center, or
     the selected city is > 40 km away — and it goes through
     _onCity, the exact manual-pick path (map recenters, places
     and routes rescope), plus one subtle snackbar per switch.
     Manual picks stay possible at any time; with no position,
     nothing changes at all. */
  void _syncCityToLocation() {
    final pos = myLocationNotifier.value;
    if (pos == null || !mounted || _cities.isEmpty) return;
    final last = _lastCitySyncPos;
    if (last != null &&
        haversineKm(last.latitude, last.longitude, pos.latitude,
                pos.longitude) <
            1.0) {
      return;
    }
    _lastCitySyncPos = pos;
    City? nearest;
    var nd = double.infinity;
    for (final c in _cities) {
      final d = haversineKm(pos.latitude, pos.longitude, c.lat, c.lng);
      if (d < nd) {
        nd = d;
        nearest = c;
      }
    }
    final cur = _city;
    if (nearest == null || (cur != null && nearest.id == cur.id)) return;
    final curD = cur == null
        ? double.infinity
        : haversineKm(pos.latitude, pos.longitude, cur.lat, cur.lng);
    if (nd < curD * 0.7 || curD > 40) {
      _onCity(nearest);
      snack(context, trf('you_in_city', {'city': nearest.name}));
    }
  }

  void _openTasks() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TasksPage(
          stats: _stats,
          onTaskDone: () => _bumpStat('tasks', 1),
          onAiXp: _addAiXp,
          onQuestStep: () => _bumpStat('questSteps', 1),
          onQuestDone: () => _bumpStat('quests', 1),
          cityPlaces: _cityPlaces,
          city: _city,
        ),
      ),
    );
  }

  Future<void> _openDeal() async {
    HapticFeedback.mediumImpact();
    // v2.0.14: first «Ты в деле» is a sensible moment to (re)ask the
    // notification permission — «друг в деле» pushes are its point.
    PushService.ensurePermission();
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
                child: Text(tr('pick_city'), style: T.head(18)),
              ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _cities.length,
                itemBuilder: (_, i) {
                  final c = _cities[i];
                  final sel = c.id == _city?.id;
                  return ListTile(
                    leading: TiradIcon(TIGlyph.mapPin,
                        size: 19, color: sel ? T.ember : T.iconGray),
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

  /* ---------- shell pieces: header / nav (LIVE bar + ticker removed in v2.0.16) ---------- */

  /* The header's round profile button: the user's own face, kept in sync
     with the Profile tab. Signed-in → read straight from HomePage's live
     _profile (the avatar_url photo, else the profile's emoji) — the same
     map ProfileTab edits through onProfileChanged, so a fresh upload
     lands here on the same setState (the upload URL carries a ?t=
     timestamp, which also busts the NetworkImage cache). Guest → the
     on-phone avatar mirrored through GuestAvatarBus (photo file, else
     the guest emoji). No avatar anywhere → the branded ghost look.
     Tap = the Profile tab, identical to the bottom-nav Profile slot. */
  Widget _profileButton() {
    Widget face(String? photoUrl, String? photoPath, String emoji) {
      return Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [kRed, kOrange]),
          boxShadow: [
            BoxShadow(color: kRed.withOpacity(0.55), blurRadius: 14),
          ],
          image: photoUrl != null
              ? DecorationImage(
                  image: NetworkImage(photoUrl), fit: BoxFit.cover)
              : (photoPath != null
                  ? DecorationImage(
                      image: FileImage(File(photoPath)), fit: BoxFit.cover)
                  : null),
        ),
        child: (photoUrl == null && photoPath == null)
            // v2.0.16: a 'ti:' avatar renders as the white filled
            // glyph on this gradient circle; a legacy emoji renders
            // as text, as before.
            ? AvatarFace(emoji,
                glyphSize: 20,
                emojiSize: 18,
                glyphColor: Colors.white,
                glyphFilled: true)
            : null,
      );
    }

    final Widget inner;
    if (supa.auth.currentUser != null) {
      final url = _profile?['avatar_url'] as String?;
      inner = face(
        (url != null && url.isNotEmpty) ? url : null,
        null,
        (_profile?['avatar'] as String?) ?? '👻',
      );
    } else {
      inner = AnimatedBuilder(
        animation:
            Listenable.merge([GuestAvatarBus.photoPath, GuestAvatarBus.emoji]),
        builder: (_, __) {
          final gp = GuestAvatarBus.photoPath.value;
          // The guest photo sits in the temp dir; if the OS cleared it,
          // fall back to the emoji instead of an empty circle.
          final guestPhoto = (gp != null &&
                  gp.isNotEmpty &&
                  File(gp).existsSync())
              ? gp
              : null;
          return face(null, guestPhoto, GuestAvatarBus.emoji.value ?? '👻');
        },
      );
    }
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _tab = 3);
      },
      child: inner,
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(
        children: [
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TiradIcon(TIGlyph.mapPin, size: 14, color: T.fire),
                    const SizedBox(width: 5),
                    Text(
                      '${_city!.name} ▾',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TiradIcon(_wxGlyph, size: 15, color: T.ember),
                  const SizedBox(width: 5),
                  Text(
                    '$_temp°',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(width: 8),
          _profileButton(),
        ],
      ),
    );
  }

  /* v2.0.16: _liveBar() (the LIVE strip) and _ticker() /
     _tickerMessages() (the red city-summary strip) are DELETED —
     the owner removed both panels so the map gets the space. The
     hot-count data behind them (vibeOf / _cityPlaces) is untouched:
     the «только жаркие» filters and the on-map pulse chip still use
     it. The now-unused kStr keys (live_*, tick_*) stay in the table
     harmlessly. */

  /* v2.0.12: nav items are TI glyphs — inactive: monoline gray;
     active: the spec's ActiveIconBadge (white filled glyph on the
     glowing gradient circle). Every slot has the SAME structure
     (36 px icon zone + label under it), so switching tabs changes
     nothing but colours — zero layout shift, the FAB stays centred. */
  Widget _navSlot(int idx, TIGlyph glyph, String label) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: Center(
              child: active
                  ? ActiveIconBadge(glyph: glyph, size: 36)
                  : TiradIcon(glyph, size: 23, color: T.iconGray),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: T.body(
              10.5,
              color: active ? T.text : T.faint,
              w: FontWeight.w700,
            ),
          ),
        ],
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
        // v2.0.12: five EQUAL-width slots. The old spaceBetween Row of
        // variable-width children let the active slot's expanded pill
        // (label + wider padding) change the left/right group widths,
        // so the FAB drifted off-centre — worst with a left tab active.
        // Now every child sits centred inside its own fixed slot: the
        // pill may grow/shrink inside slot bounds without moving any
        // sibling, and the middle slot's centre IS the panel centre,
        // so the FAB is exactly centred in every tab state.
        //
        // v2.0.13 ROOT-CAUSE FIX (panel filled the whole screen): the
        // slots must NOT be wrapped in Center/Align. A Center sizes
        // itself to constraints.maxHeight whenever that is finite and
        // no heightFactor is set — and the Scaffold bottomNavigationBar
        // slot hands this bar loose constraints with maxHeight = the
        // FULL screen height. In v2.0.12 each slot was
        // Expanded(child: Center(...)), so every Center stretched to
        // full height, the Row and the Container followed, and the
        // panel's background/border covered the entire screen with the
        // nav row floating in the vertical middle (centred by those
        // very Centers). The slot widgets themselves are
        // Column(mainAxisSize.min) and shrink-wrap their height; the
        // Expanded gives each a tight WIDTH, and the Column's default
        // crossAxisAlignment.center centres icon+label horizontally
        // inside the slot — no Center needed. Never re-add one here.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _navSlot(0, TIGlyph.mapPin, tr('nav_map')),
            ),
            Expanded(
              child: _navSlot(1, TIGlyph.flame, tr('nav_places')),
            ),
            Expanded(
              child: _DealFab(onTap: _openDeal),
            ),
            Expanded(
              child: _navSlot(2, TIGlyph.routePath, tr('nav_route')),
            ),
            Expanded(
              child: _navSlot(3, TIGlyph.ghost, tr('nav_profile')),
            ),
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
            // v2.0.16: the LIVE bar and the ticker strip under the
            // header are REMOVED (owner: «убери вот эти две панели,
            // карта станет больше») — the map gets the freed space.
            Expanded(
              // IndexedStack: tabs are built once and kept alive — the
              // MapLibre widget is never recreated on tab switches.
              child: IndexedStack(
                index: _tab,
                children: [
                  MapTab(
                    places: _cityPlaces,
                    allPlaces: _places,
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
                    allPlaces: _places,
                    cities: _cities,
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
              clipBehavior: Clip.none,
              children: [
                // v2.0.13: the radar sweep is a Positioned OVERLAY
                // centred on the badge ((86-58)/2 = 14 px overhang).
                // As a plain Stack child it was the largest child and
                // set the stack's layout size to 86 px, making the FAB
                // column — and with it the whole nav panel — ~104 px
                // tall. As a Positioned child it paints around the
                // badge without taking any layout space, so the FAB
                // column is just badge 58 + label ≈ 75 px and the
                // panel stays compact. IgnorePointer: pure decoration,
                // taps belong to the badge/column.
                const Positioned(
                  left: -14,
                  top: -14,
                  child: IgnorePointer(
                    child: RadarSweep(size: 86, opacity: 0.13),
                  ),
                ),
                // v2.0.12: the FAB IS the spec's active badge — white
                // filled flame on the glowing gradient circle (its own
                // radar rings off; RadarSweep above provides them).
                const ActiveIconBadge(
                  glyph: TIGlyph.flame,
                  size: 58,
                  rings: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            tr('in_deal_btn'),
            style: const TextStyle(
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
                // v2.0.12: the deal hero is the spec's active badge.
                ActiveIconBadge(glyph: TIGlyph.flame, size: 64),
              ],
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: tr('deal_title_a')),
                TextSpan(text: tr('deal_title_b'), style: T.display(23, color: T.ember)),
              ]),
              textAlign: TextAlign.center,
              style: T.display(23),
            ),
            const SizedBox(height: 6),
            Text(
              tr('deal_sub'),
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const OnlineDot(),
                const SizedBox(width: 7),
                Text(tr('deal_online_now'), style: T.body(14, w: FontWeight.w600)),
                AnimatedNumber(value: onlineCount, style: T.num(15)),
              ],
            ),
            const SizedBox(height: 18),
            sectionLabel(trf('deal_friends_label', {'n': inDeal.length}),
                color: const Color(0xFFFF8A7A)),
            if (!widget.signedIn)
              Text(
                tr('deal_guest_note'),
                style: TextStyle(color: kMuted, fontSize: 13),
              ),
            if (widget.signedIn && inDeal.isEmpty)
              Text(
                tr('deal_none'),
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
                          ? AvatarFace(f.avatar,
                              glyphSize: 21,
                              emojiSize: 19,
                              ghostForDefault: true)
                          : null,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.mode == 'ghost' ? tr('ghost') : f.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            trf('deal_in_city', {'city': _cityName(f.cityId)}),
                            style: const TextStyle(color: kGreen, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const TiradIcon(TIGlyph.flame,
                            size: 13, color: T.ember, filled: true),
                        const SizedBox(width: 4),
                        Text(
                          tr('deal_in'),
                          style: TextStyle(
                            color: kOrange,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const TiradIcon(TIGlyph.trophy,
                          size: 13, color: Colors.white, filled: true),
                      const SizedBox(width: 5),
                      Text(
                        tr('deal_top_pick'),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                trf('deal_already', {'name': recPlace.name}),
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
                  trf('deal_rec_text', {
                    'city': widget.city.name,
                    'word': vibeWord(v),
                    'v': v,
                    'd': fmtKm(d),
                  }),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kMuted, fontSize: 13),
                );
              }),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: PressButton(
                      text: tr('deal_route_btn'),
                      icon: TIGlyph.car,
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onRoute();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PressButton(
                      text: tr('deal_other'),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const TiradIcon(TIGlyph.voteBox,
                          size: 18, color: T.ember),
                      const SizedBox(width: 7),
                      Text(
                        tr('deal_poll_title'),
                        textAlign: TextAlign.center,
                        style: T.head(17),
                      ),
                    ],
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
                  Text(
                    tr('deal_poll_hint'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  PressButton(
                    text: tr('deal_invite'),
                    primary: false,
                    onPressed: () => shareWithXp(
                      context,
                      tr('deal_share_text'),
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

  /* 🧭 «Маршрут сюда»: publish a directions line to the Map tab via
     MapRouteBus (HomePage switches tabs, MapTab draws). Start is the
     live position; while location is off it falls back to the city
     center and re-runs the location flow, which shows the usual hint. */
  void _directionsHere() {
    final p = _place;
    final origin = myLocationNotifier.value;
    if (origin == null) LocationService.ensureLocation(context);
    final city = widget.city;
    final start = origin ??
        (city != null
            ? LatLng(city.lat, city.lng)
            : LatLng(p.lat, p.lng));
    final dist =
        haversineKm(start.latitude, start.longitude, p.lat, p.lng);
    MapRouteBus.show(MapRouteLine(
      kind: 'directions',
      title: p.name,
      points: [start, LatLng(p.lat, p.lng)],
      stops: [p],
      target: p,
      fromCityCenter: origin == null,
      totalKm: dist,
    ));
    Navigator.of(context).pop();
  }

  /* External navigator: Waze deep link first, Google Maps directions
     as the fallback; a snackbar when neither can open. */
  Future<void> _openNavigator() async {
    final p = _place;
    var ok = false;
    try {
      ok = await launchUrl(
        Uri.parse('waze://?ll=${p.lat},${p.lng}&navigate=yes'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (!ok) {
      try {
        ok = await launchUrl(
          Uri.parse(
              'https://www.google.com/maps/dir/?api=1&destination=${p.lat},${p.lng}'),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {}
    }
    if (!ok && mounted) snack(context, tr('nav_open_fail'));
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
      snack(context, tr('signin_to_fire'));
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

  bool _reviewSending = false;

  Future<void> _submitReview() async {
    final uid = myUidOrNull;
    if (uid == null) {
      // v2.0.14 (Item 3): this was a SILENT `return` — the form is
      // rendered from a build-time auth check, so with an expired
      // session the visible «Оставить отзыв» button did literally
      // nothing. Now it explains and routes to sign-in, exactly
      // like the photo flow.
      snack(context, tr('signin_to_review'));
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      );
      return;
    }
    if (_reviewSending) return;
    setState(() => _reviewSending = true);
    final text = _reviewCtl.text.trim();
    final rating = _myRating;
    final ghost = ghostLabelFor(uid);
    try {
      await supa.from('place_reviews').insert({
        'place_id': _place.id,
        'user_id': uid,
        'ghost': ghost,
        'rating': rating,
        'text': text,
      });
    } catch (e) {
      // Was: catch(_) → one generic snackbar, real error swallowed.
      debugPrint('TiradA place_reviews insert failed: $e');
      if (mounted) {
        snack(context, tr('review_save_fail'));
        setState(() => _reviewSending = false);
      }
      return;
    }
    _reviewCtl.clear();
    if (!mounted) return;
    // Optimistic prepend: the new review and the average rating move
    // immediately; the authoritative reload follows right behind.
    setState(() {
      _reviews = [
        {
          'place_id': _place.id,
          'user_id': uid,
          'ghost': ghost,
          'rating': rating,
          'text': text,
          'created_at': DateTime.now().toIso8601String(),
        },
        ..._reviews,
      ];
      _reviewSending = false;
    });
    snack(context, tr('review_posted'));
    _loadReviews();
  }

  /* Publish a photo to this place: pick → EXIF-stripped re-encode →
     consent sheet (Всем / Только друзьям / Не показывать) → upload to
     the place-photos bucket → place_photos row → stats via HomePage. */
  Future<void> _addPhoto() async {
    final uid = myUidOrNull;
    if (uid == null) {
      snack(context, tr('signin_to_photo'));
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
              leading: const TiradIcon(TIGlyph.camera,
                  size: 22, color: T.iconGray),
              title: Text(tr('camera'), style: T.body(15, w: FontWeight.w600)),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading:
                  const TiradIcon(TIGlyph.photo, size: 22, color: T.iconGray),
              title: Text(tr('gallery'), style: T.body(15, w: FontWeight.w600)),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final Uint8List? bytes;
    try {
      bytes = await pickAndProcessImage(source);
    } on ImagePickException catch (e) {
      // Was: every picker failure collapsed into the same null as a
      // cancel and the flow died silently (v2.0.14, Item 2).
      debugPrint('TiradA photo pick failed: $e');
      if (mounted) snack(context, tr('photo_pick_fail'));
      return;
    }
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
              Text(tr('who_sees_photo'), style: T.head(16)),
              const SizedBox(height: T.s12),
              FireButton(
                text: tr('vis_all'),
                small: true,
                icon: TIGlyph.globe,
                onPressed: () => Navigator.of(context).pop('public'),
              ),
              const SizedBox(height: T.s8),
              GhostButton(
                text: tr('vis_friends'),
                small: true,
                icon: TIGlyph.ghost,
                onPressed: () => Navigator.of(context).pop('friends'),
              ),
              const SizedBox(height: T.s8),
              GhostButton(
                text: tr('vis_none'),
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
    // v2.0.14 (Item 2): uid-FIRST storage path — the bucket layout
    // proven by the working avatars bucket ('<uid>/avatar.jpg'). The
    // old '<place_id>/<uid>-…' path put the place id in the owner
    // segment of the path, which a folder-ownership storage policy
    // rejects for every single upload. Failures are now staged: the
    // snackbar names the stage that broke instead of one generic
    // «не получилось», and the real error goes to the log.
    final path =
        '$uid/${_place.id}-${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await supa.storage.from('place-photos').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
    } catch (e) {
      debugPrint('TiradA place-photo upload failed: $e');
      if (mounted) {
        snack(context, tr('photo_upload_fail'));
        setState(() => _uploading = false);
      }
      return;
    }
    final url = supa.storage.from('place-photos').getPublicUrl(path);
    try {
      await supa.from('place_photos').insert({
        'place_id': _place.id,
        'user_id': uid,
        'url': url,
        'visibility': vis,
      });
    } catch (e) {
      debugPrint('TiradA place_photos insert failed: $e');
      if (mounted) {
        snack(context, tr('photo_save_fail'));
        setState(() => _uploading = false);
      }
      return;
    }
    widget.onPhotoUploaded?.call(_place);
    if (!mounted) return;
    fireConfetti(context);
    snack(context, tr('photo_posted'));
    _loadPhotos();
    if (mounted) setState(() => _uploading = false);
  }

  Widget _stars(double rating) {
    final full = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.only(right: 1.5),
            child: TiradIcon(
              TIGlyph.star,
              size: 15,
              color: i < full ? T.gold : T.faint.withOpacity(0.5),
              filled: i < full,
            ),
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
                  child: TiradIcon(
                    typeGlyph(p.type),
                    size: 26,
                    color: typeColor(p.type),
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
                    '${p.rating!.toStringAsFixed(1)}${p.reviews != null ? trf('reviews_suffix', {'n': p.reviews}) : ''}',
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
                      tr('new_place'),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (p.address.isNotEmpty) ...[
                        const TiradIcon(TIGlyph.mapPin,
                            size: 13, color: T.iconGray),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          [
                            if (p.address.isNotEmpty) p.address,
                            if (dist != null)
                              trf('km_from_you', {'d': fmtKm(dist)}),
                          ].join(' · '),
                          textAlign: TextAlign.center,
                          style: T.body(12.5, color: T.muted),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              trf('crowd_now', {'n': crowdOf(p)}) +
                  (_crowdFriends > 0
                      ? trf('crowd_friends', {'n': _crowdFriends})
                      : ''),
              textAlign: TextAlign.center,
              style: T.body(12.5, color: T.salmon, w: FontWeight.w600),
            ),
            const SizedBox(height: T.s16),
            Row(
              children: [
                Expanded(
                  child: _here
                      ? GhostButton(
                          text: tr('you_here'),
                          small: true,
                          onPressed: () {},
                        )
                      : FireButton(
                          text: tr('i_here'),
                          small: true,
                          onPressed: () {
                            widget.onCheckIn?.call(p);
                            setState(() => _here = true);
                            fireConfetti(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tr('checkin_snack')),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(width: T.s12),
                Expanded(
                  child: GhostButton(
                    text: tr('share'),
                    small: true,
                    onPressed: () => shareWithXp(
                      context,
                      trf('share_place_text', {'name': p.name, 'v': vibeOf(p)}),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: T.s12),
            GhostButton(
              text: _uploading ? tr('uploading') : tr('add_photo'),
              small: true,
              icon: TIGlyph.camera,
              onPressed: _uploading ? () {} : _addPhoto,
            ),
            const SizedBox(height: T.s12),
            Row(
              children: [
                Expanded(
                  child: FireButton(
                    text: tr('route_here'),
                    small: true,
                    icon: TIGlyph.navArrow,
                    onPressed: _directionsHere,
                  ),
                ),
                const SizedBox(width: T.s12),
                Expanded(
                  child: GhostButton(
                    text: tr('to_navigator'),
                    small: true,
                    onPressed: _openNavigator,
                  ),
                ),
              ],
            ),
            if (_photos.isNotEmpty) ...[
              const SizedBox(height: T.s20),
              sectionLabel(tr('ghost_photos_here'),
                  color: T.salmon, glyph: TIGlyph.camera),
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
                                child: const Center(
                                  child: TiradIcon(TIGlyph.ghost,
                                      size: 26, color: T.iconGray),
                                ),
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const TiradIcon(TIGlyph.flame,
                                        size: 11,
                                        color: Colors.white,
                                        filled: true),
                                    const SizedBox(width: 3),
                                    Text(
                                      '$fires',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
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
                tr('tap_photo_fire'),
                style: T.body(11, color: T.faint),
              ),
            ],
            // ---- ghost reviews ----
            const SizedBox(height: T.s20),
            sectionLabel(tr('ghost_reviews'),
                color: T.salmon, glyph: TIGlyph.chat),
            if (_reviews.isEmpty)
              Text(
                tr('reviews_empty'),
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
                      trf('ghost_reviews_count', {'avg': avg.toStringAsFixed(1), 'n': _reviews.length}),
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
                      const TiradIcon(TIGlyph.ghost,
                          size: 17, color: T.iconGray),
                      const SizedBox(width: T.s8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  (r['ghost'] as String?) ?? tr('ghost'),
                                  style: T.body(12.5, w: FontWeight.w700),
                                ),
                                const SizedBox(width: T.s8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    for (var s = 0;
                                        s <
                                            (((r['rating'] as num?)?.toInt() ??
                                                0));
                                        s++)
                                      const TiradIcon(TIGlyph.star,
                                          size: 11,
                                          color: T.gold,
                                          filled: true),
                                  ],
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
                        child: TiradIcon(
                          TIGlyph.star,
                          size: 24,
                          color: i <= _myRating
                              ? T.gold
                              : T.faint.withOpacity(0.5),
                          filled: i <= _myRating,
                        ),
                      ),
                    ),
                  const SizedBox(width: T.s8),
                  Expanded(
                    child: TextField(
                      controller: _reviewCtl,
                      decoration: InputDecoration(hintText: tr('hint_review')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: T.s8),
              GhostButton(
                text: tr('leave_review'),
                small: true,
                onPressed: _submitReview,
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: T.s8),
                child: GhostButton(
                  text: tr('signin_to_review'),
                  small: true,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const LoginPage()),
                  ),
                ),
              ),
            if (similar.isNotEmpty) ...[
              const SizedBox(height: T.s20),
              sectionLabel(tr('similar_places'),
                  color: T.salmon, glyph: TIGlyph.mapPin),
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
                              TiradIcon(
                                typeGlyph(sp.type),
                                size: 14,
                                color: T.iconGray,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                sp.name,
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
  final List<Place> places; // selected city's places (pulse chip)
  final List<Place> allPlaces; // the whole country — the pin layer
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
    required this.allPlaces,
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
  // Route / directions overlay (v2.0.9): one line + its markers, owned
  // separately from place pins and friend avatars so redraws of those
  // never wipe it.
  Line? _routeLineObj;
  final List<Symbol> _routeSymbols = [];
  final Map<String, Uint8List> _routePinCache = {};
  final Set<String> _routeImagesOnMap = {};
  // «Me» marker (v2.0.10): a big custom symbol for the user himself —
  // the native puck alone was too small to spot. Tracked separately,
  // exactly like the place/friend/route symbols, so no redraw of
  // those ever wipes it (or vice versa).
  Symbol? _meSymbol;
  bool _meImgReady = false;
  bool _meSyncing = false;
  bool _meAgain = false;
  // Side-zoom swipe session (v2.0.16): pointer id that owns the
  // active edge drag, the finger Y and the camera zoom/target
  // captured when the drag started.
  int? _zoomDragPointer;
  double _zoomDragStartY = 0;
  double _zoomDragStartZoom = 0;
  LatLng? _zoomDragTarget;

  @override
  void initState() {
    super.initState();
    MapRouteBus.line.addListener(_onRouteLineChanged);
    myLocationNotifier.addListener(_onMyLocation);
    rootBundle.loadString('assets/map-style.json').then((s) {
      if (mounted) setState(() => _style = s);
    });
  }

  @override
  void dispose() {
    MapRouteBus.line.removeListener(_onRouteLineChanged);
    myLocationNotifier.removeListener(_onMyLocation);
    _timer?.cancel();
    _zoomDragPointer = null;
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
     symbols. Since v2.0.10 _drawPlaces pins ALL places in the country
     (widget.allPlaces), not just the selected city. */
  Future<Uint8List> _placePin(String type, {required bool hot}) async {
    final cacheKey = hot ? '$type|hot' : type;
    final cached = _pinCache[cacheKey];
    if (cached != null) return cached;
    // v2.0.10: pins were too small to read (owner) — the bitmap is
    // re-painted at 192 px (was 120) with every radius/glyph scaled
    // ×1.6, and _drawPlaces shows it at iconSize 0.5 (was 0.45):
    // ≈1.78× on screen, still crisp because the source is bigger.
    const double size = 192;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
    final center = const Offset(size / 2, size / 2);
    if (hot) {
      canvas.drawCircle(
        center,
        91,
        Paint()..color = T.fire.withOpacity(0.16),
      );
      canvas.drawCircle(
        center,
        82,
        Paint()
          ..color = T.fire
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10,
      );
    }
    canvas.drawCircle(
      center,
      67,
      Paint()..color = const Color(0xFF9AA1A9),
    );
    canvas.drawCircle(
      center,
      67,
      Paint()
        ..color = const Color(0xFF3A3F45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
    // v2.0.12: the emblem is a TI vector glyph (monoline, thick
    // rounded stroke) painted straight onto the disc — no emoji.
    // Dark slate on the light-gray disc keeps it readable; the glyph
    // box is ~96 px of the 192 px bitmap.
    TIPaint.paint(
      canvas,
      typeGlyph(type),
      Rect.fromCenter(center: center, width: 98, height: 98),
      const Color(0xFF2E3238),
      strokeScale: 1.25,
    );
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
    for (final type in kPinTypes) {
      await ctl.addImage('pin-$type', await _placePin(type, hot: false));
      await ctl.addImage('pin-$type-hot', await _placePin(type, hot: true));
    }
  }

  bool _drawingPlaces = false;

  /* v2.0.12: how many place pins the last _drawPlaces pass actually
     put on the map — the verifiable completion count (target:
     widget.allPlaces.length, 5,212). */
  int _placesDrawnCount = 0;

  /* v2.0.12 root-cause fix for «не все места видны»: the plugin's
     SymbolManager creates its symbol layer with icon-allow-overlap /
     icon-ignore-placement = false, so MapLibre COLLISION-CULLED any
     annotation symbol overlapping an already-drawn one. With 5,212
     chunky pins, a large share of places in dense areas was silently
     hidden at city zoom even though every symbol had been added.
     The flags are manager-level: one call covers place pins, friend
     avatars and the «me» marker alike. Set once per style load,
     before the first draw. */
  Future<void> _prepareSymbolLayer() async {
    try {
      final sm = _ctl?.symbolManager;
      if (sm != null) {
        await sm.setIconAllowOverlap(true);
        await sm.setIconIgnorePlacement(true);
      }
    } catch (_) {}
    _drawPlaces();
  }

  /* v2.0.10: the pin layer is COUNTRY-WIDE by the owner's word — every
     place in the database (allPlaces, 5,212 pins), not just the
     selected city. The selected city still scopes lists, routes and
     the pulse chip; only the map stopped filtering. 5k symbols are
     added/removed in batches (addSymbols/removeSymbols) using the
     same registered per-type pin images — no new bitmaps. Only our
     own tracked symbols are removed: friend avatars, the «me» marker
     and the route overlay live in their own lists and are untouched. */
  Future<void> _drawPlaces() async {
    final ctl = _ctl;
    if (ctl == null || !_styleReady || _drawingPlaces) return;
    _drawingPlaces = true;
    try {
      await _ensurePinImages();
      if (_placeSymbols.isNotEmpty) {
        try {
          await ctl.removeSymbols(List.of(_placeSymbols));
        } catch (_) {}
        _placeSymbols.clear();
        _symbolPlace.clear();
      }
      final all = widget.allPlaces;
      const chunk = 400;
      var failedChunks = 0;
      for (var i = 0; i < all.length; i += chunk) {
        if (!mounted || _ctl != ctl) return;
        final part = all.sublist(i, math.min(i + chunk, all.length));
        final opts = <SymbolOptions>[];
        for (final p in part) {
          final hot = vibeOf(p) >= 70;
          final type = kPinTypes.contains(p.type) ? p.type : 'other';
          opts.add(SymbolOptions(
            geometry: LatLng(p.lat, p.lng),
            iconImage: hot ? 'pin-$type-hot' : 'pin-$type',
            iconSize: 0.5, // 192 px bitmap → ≈96 px on screen (was ≈54)
          ));
        }
        // v2.0.12: a failed chunk must NOT abort the rest of the draw
        // (previously one try wrapped the WHOLE loop, so a single
        // platform hiccup silently dropped every later chunk). Each
        // chunk gets one retry, then is skipped — never fatal.
        List<Symbol>? syms;
        for (var attempt = 0; attempt < 2 && syms == null; attempt++) {
          try {
            syms = await ctl.addSymbols(opts);
          } catch (_) {
            if (attempt == 0) {
              await Future<void>.delayed(const Duration(milliseconds: 250));
            }
          }
        }
        if (syms == null) {
          failedChunks++;
          continue;
        }
        for (var j = 0; j < syms.length && j < part.length; j++) {
          _symbolPlace[syms[j].id] = part[j];
          _placeSymbols.add(syms[j]);
        }
      }
      // Verifiable completion: the draw ends only when every chunk has
      // been attempted; the count proves how many pins are on the map.
      _placesDrawnCount = _placeSymbols.length;
      debugPrint('TiradA pins: $_placesDrawnCount/${all.length} drawn'
          '${failedChunks > 0 ? ' · $failedChunks chunk(s) failed' : ''}');
    } catch (_) {
      // Pins are best-effort: a platform hiccup must not kill the map.
    } finally {
      _drawingPlaces = false;
    }
  }

  /* ---------------- route / directions overlay (v2.0.9) ----------- */

  void _onRouteLineChanged() {
    _drawRouteLine();
  }

  String _distText(double km) =>
      km < 1 ? '${(km * 1000).round()} ${tr('unit_m')}' : '${fmtKm(km)} ${tr('unit_km')}';

  Future<Uint8List> _routePinBitmap(String key, void Function(Canvas, Offset) paint) async {
    final cached = _routePinCache[key];
    if (cached != null) return cached;
    const double size = 140;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
    paint(canvas, const Offset(size / 2, size / 2));
    final pic = recorder.endRecording();
    final img = await pic.toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List();
    _routePinCache[key] = bytes;
    return bytes;
  }

  Future<Uint8List> _routeNumPin(int n) => _routePinBitmap('num$n', (canvas, center) {
        canvas.drawCircle(
          center,
          46,
          Paint()
            ..shader = ui.Gradient.linear(
              const Offset(0, 0),
              const Offset(140, 140),
              [T.fire, T.ember],
            ),
        );
        canvas.drawCircle(
          center,
          46,
          Paint()
            ..color = Colors.white.withOpacity(0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
        final tp = TextPainter(
          text: TextSpan(
            text: '$n',
            style: const TextStyle(
              fontSize: 58,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
      });

  Future<Uint8List> _routeStartPin() => _routePinBitmap('start', (canvas, center) {
        canvas.drawCircle(center, 58, Paint()..color = Colors.white.withOpacity(0.16));
        canvas.drawCircle(center, 30, Paint()..color = Colors.white);
        canvas.drawCircle(
          center,
          30,
          Paint()
            ..color = T.fire
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7,
        );
        canvas.drawCircle(center, 10, Paint()..color = T.fire);
      });

  Future<Uint8List> _routeTargetPin() => _routePinBitmap('target', (canvas, center) {
        canvas.drawCircle(center, 66, Paint()..color = T.fire.withOpacity(0.15));
        canvas.drawCircle(
          center,
          50,
          Paint()
            ..color = T.fire
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10,
        );
        canvas.drawCircle(center, 15, Paint()..color = T.fire);
      });

  Future<void> _ensureRouteImages(int stopCount) async {
    final ctl = _ctl;
    if (ctl == null) return;
    Future<void> reg(String name, Future<Uint8List> bytes) async {
      if (_routeImagesOnMap.contains(name)) return;
      _routeImagesOnMap.add(name);
      try {
        await ctl.addImage(name, await bytes);
      } catch (_) {}
    }

    await reg('route-start', _routeStartPin());
    await reg('route-target', _routeTargetPin());
    for (var i = 1; i <= stopCount; i++) {
      await reg('route-num-$i', _routeNumPin(i));
    }
  }

  /* Draws (or clears) the single shared overlay line from
     MapRouteBus: evening/ready route polyline with numbered stops,
     or a directions line to one place with a target ring. Setting a
     new line replaces the old one — they never coexist. */
  Future<void> _drawRouteLine() async {
    final ctl = _ctl;
    if (ctl == null || !_styleReady) return;
    if (_routeLineObj != null) {
      try {
        await ctl.removeLine(_routeLineObj!);
      } catch (_) {}
      _routeLineObj = null;
    }
    for (final s in _routeSymbols) {
      try {
        await ctl.removeSymbol(s);
      } catch (_) {}
    }
    _routeSymbols.clear();
    final data = MapRouteBus.line.value;
    if (data == null || data.points.length < 2) return;
    await _ensureRouteImages(data.stops.length);
    // Road geometry from OSRM when it has arrived; the straight
    // waypoint line until then (and on any routing failure).
    final linePts = data.roadGeometry ?? data.points;
    try {
      _routeLineObj = await ctl.addLine(
        LineOptions(
          geometry: linePts,
          lineColor: '#E11D1D',
          lineWidth: 4.5,
          lineOpacity: 0.92,
        ),
      );
    } catch (_) {}
    try {
      final s = await ctl.addSymbol(
        SymbolOptions(
          geometry: data.points.first,
          iconImage: 'route-start',
          iconSize: 0.4,
        ),
      );
      _routeSymbols.add(s);
    } catch (_) {}
    if (data.kind == 'directions' && data.target != null) {
      try {
        final s = await ctl.addSymbol(
          SymbolOptions(
            geometry: LatLng(data.target!.lat, data.target!.lng),
            iconImage: 'route-target',
            iconSize: 0.55,
          ),
        );
        _routeSymbols.add(s);
      } catch (_) {}
    } else {
      for (var i = 0; i < data.stops.length; i++) {
        final p = data.stops[i];
        try {
          final s = await ctl.addSymbol(
            SymbolOptions(
              geometry: LatLng(p.lat, p.lng),
              iconImage: 'route-num-${i + 1}',
              iconSize: 0.42,
            ),
          );
          _routeSymbols.add(s);
        } catch (_) {}
      }
    }
    // Fit the whole line on screen (the drawn geometry, so a road
    // route that swings wide still fits).
    try {
      var minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
      for (final pt in linePts) {
        minLat = math.min(minLat, pt.latitude);
        maxLat = math.max(maxLat, pt.latitude);
        minLng = math.min(minLng, pt.longitude);
        maxLng = math.max(maxLng, pt.longitude);
      }
      await ctl.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          left: 70,
          top: 90,
          right: 70,
          bottom: 140,
        ),
      );
    } catch (_) {}
  }

  /* Info chip for the overlay line: route summary, or — for
     directions — distance + walking time (driving too, when it
     differs enough to matter). ✕ clears the line. */
  Widget _routeChip() {
    return ValueListenableBuilder<MapRouteLine?>(
      valueListenable: MapRouteBus.line,
      builder: (_, data, __) {
        if (data == null) return const SizedBox.shrink();
        final String text;
        if (data.kind == 'directions' && data.target != null) {
          // displayKm / walkMins / driveMins turn into the real OSRM
          // road values as soon as the enrichment lands.
          text = trf('chip_dir', {
                'name': data.target!.name,
                'd': _distText(data.displayKm),
              }) +
              trf('chip_walk', {'n': data.walkMins}) +
              (data.walkMins - data.driveMins >= 10
                  ? trf('chip_drive', {'n': data.driveMins})
                  : '') +
              (data.fromCityCenter ? tr('chip_from_center') : '');
        } else {
          text = trf('chip_route', {
            'title': data.title,
            'n': data.stops.length,
            'd': _distText(data.displayKm),
          });
        }
        return Positioned(
          top: T.s12,
          left: T.s12,
          right: T.s12,
          child: Center(
            child: Container(
              padding: const EdgeInsets.fromLTRB(T.s16, T.s8, T.s8, T.s8),
              decoration: BoxDecoration(
                color: T.surface.withOpacity(0.92),
                borderRadius: BorderRadius.circular(T.rPill),
                border: Border.all(color: T.fire.withOpacity(0.55)),
                boxShadow: T.cardDepth,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: T.body(12.5, w: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: T.s8),
                  // v2.0.12: a real «Delete route» button replaces the
                  // tiny ✕. Directions lines clear right here; a ROUTE
                  // line goes through the RouteTab, which owns the
                  // tracking state (confirm sheet if progress exists,
                  // then stops/done/counted are wiped there).
                  GestureDetector(
                    onTap: () {
                      if (data.kind == 'route') {
                        MapRouteBus.requestDeleteRoute();
                      } else {
                        MapRouteBus.clear();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: T.fire.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(T.rPill),
                        border:
                            Border.all(color: T.fire.withOpacity(0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const TiradIcon(
                            TIGlyph.trash,
                            size: 13,
                            color: T.salmon,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            tr('delete_route'),
                            style: T.body(11.5,
                                color: T.salmon, w: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Uint8List> _friendMarker(Friend f) async {
    // The online state is part of the cache key (v2.0.10): the ring
    // colour depends on it, so a friend flipping online/offline must
    // repaint the bitmap on the next 30 s refresh, not reuse the old.
    final cacheKey = '${f.id}|${f.avatarUrl ?? f.avatar ?? ''}|${f.online}';
    final cached = _markerCache[cacheKey];
    if (cached != null) return cached;
    // v2.0.10: markers were too small (owner) — bitmap re-painted at
    // 168 px (was 112) with all radii scaled ×1.5; iconSize stays
    // 0.55, so on screen ≈92 px (was ≈62). The status ring also gets
    // a thicker stroke so the online green actually reads at a glance.
    const double size = 168;
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
        Path()..addOval(Rect.fromCircle(center: center, radius: 72)),
      );
      canvas.drawImageRect(
        photo,
        crop.isEmpty ? src : crop,
        Rect.fromCircle(center: center, radius: 72),
        Paint(),
      );
      canvas.restore();
    } else {
      canvas.drawCircle(center, 72, Paint()..color = kSurface2);
      // v2.0.12: the ghost-mode and default fallbacks are the TI ghost
      // glyph (vector). A friend's CHOSEN avatar emoji stays text —
      // that is their identity data, not app iconography.
      // v2.0.16: a chosen 'ti:<name>' avatar (the glyph picker)
      // paints that glyph's vector centred in the disc instead.
      final chosen = f.avatar;
      final isDefault = chosen == null ||
          chosen.isEmpty ||
          chosen == '👤' ||
          chosen == '👻';
      final chosenGlyph = tiAvatarGlyph(chosen);
      if (f.mode != 'ghost' && chosenGlyph != null) {
        TIPaint.paint(
          canvas,
          chosenGlyph,
          Rect.fromCenter(center: center, width: 96, height: 96),
          T.iconGray,
          strokeScale: 1.1,
        );
      } else if (f.mode == 'ghost' || isDefault) {
        TIPaint.paint(
          canvas,
          TIGlyph.ghost,
          Rect.fromCenter(center: center, width: 96, height: 96),
          T.iconGray,
          strokeScale: 1.1,
        );
      } else {
        final tp = TextPainter(
          text: TextSpan(
            text: chosen,
            style: const TextStyle(fontSize: 75),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
      }
    }
    // Status ring: bright green (#22C55E) while the friend is online —
    // the same profiles.online / presence signal the friends list
    // uses — muted gray otherwise. Ring only; the avatar is untouched.
    canvas.drawCircle(
      center,
      75,
      Paint()
        ..color = f.online ? kGreen : kMuted
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
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
          name: (p['name'] as String?) ?? tr('ghost'),
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

  /* ---------------- «me» marker (v2.0.10) ---------------- */

  void _onMyLocation() {
    _updateMeMarker();
  }

  /* Keeps the big «you are here» symbol glued to myLocationNotifier —
     the same position feed presence and distances already use. Since
     v2.0.12 the native puck is DISABLED: its LocationComponent disc
     rendered above annotation symbols and sat on top of this marker's
     avatar photo. This symbol is now the only «you are here» on the
     map. Serialised via _meSyncing so rapid stream updates can never
     stack duplicate symbols. */
  Future<void> _updateMeMarker() async {
    if (_meSyncing) {
      _meAgain = true;
      return;
    }
    final ctl = _ctl;
    if (ctl == null || !_styleReady) return;
    if (myLocationNotifier.value == null) return;
    _meSyncing = true;
    try {
      if (!_meImgReady) {
        try {
          await ctl.addImage('me-marker', await _meMarkerBitmap());
          _meImgReady = true;
        } catch (_) {
          return;
        }
      }
      final pos = myLocationNotifier.value; // may have moved meanwhile
      if (pos == null) return;
      if (_meSymbol == null) {
        _meSymbol = await ctl.addSymbol(
          SymbolOptions(
            geometry: pos,
            iconImage: 'me-marker',
            iconSize: 0.75, // 176 px bitmap → ≈132 px on screen
          ),
        );
      } else {
        await ctl.updateSymbol(_meSymbol!, SymbolOptions(geometry: pos));
      }
    } catch (_) {
      _meSymbol = null; // stale handle — recreate on the next update
    } finally {
      _meSyncing = false;
      if (_meAgain) {
        _meAgain = false;
        _updateMeMarker();
      }
    }
  }

  Future<ui.Image?> _downloadImage(String url) async {
    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(url));
      final resp = await req.close();
      final bytes = await resp.fold<BytesBuilder>(
        BytesBuilder(),
        (b, d) => b..add(d),
      );
      client.close();
      final codec = await ui.instantiateImageCodec(bytes.takeBytes());
      return (await codec.getNextFrame()).image;
    } catch (_) {
      return null;
    }
  }

  /* The user's own face for the marker: signed-in → profiles.avatar_url;
     guest → the local avatar file the profile tab keeps in prefs.
     Null → the bitmap falls back to the branded ghost. */
  Future<ui.Image?> _loadMePhoto() async {
    try {
      final uid = myUidOrNull;
      if (uid != null) {
        final rows = await supa
            .from('profiles')
            .select('avatar_url')
            .eq('id', uid)
            .limit(1);
        for (final r in rows as List) {
          final url = r['avatar_url'] as String?;
          if (url != null && url.isNotEmpty) {
            final img = await _downloadImage(url);
            if (img != null) return img;
          }
        }
      }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('guest_avatar_path');
      if (path != null && path.isNotEmpty) {
        final bytes = await File(path).readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        return (await codec.getNextFrame()).image;
      }
    } catch (_) {}
    return null;
  }

  /* 176 px round marker: brand-red outer ring + white ring, then the
     avatar photo (or the TI ghost on the dark surface) — «you are
     here» reads instantly, and it can't be confused with a friend
     (green/gray ring) or a place pin (gray disc).
     v2.0.12 (Part A): this bitmap is verified clean — rings at r86
     (fire) and r77 (white), the photo clipped to r68, NOTHING painted
     after or over the photo. The «кружок поверх аватарки» the owner
     saw was the native MapLibre location puck drawn above annotation
     symbols; the puck's rendering is now off (myLocationEnabled:
     false on the map), so this symbol is the only me-marker. */
  /* The stored avatar VALUE behind the me-marker fallback
     (v2.0.16): signed-in → profiles.avatar; guest → the
     GuestAvatarBus mirror, else the guest prefs value. Null when
     nothing is stored. */
  Future<String?> _meAvatarValue() async {
    try {
      final uid = myUidOrNull;
      if (uid != null) {
        final rows = await supa
            .from('profiles')
            .select('avatar')
            .eq('id', uid)
            .limit(1);
        for (final r in rows as List) {
          final v = r['avatar'] as String?;
          if (v != null && v.isNotEmpty) return v;
        }
        return null;
      }
    } catch (_) {}
    final bus = GuestAvatarBus.emoji.value;
    if (bus != null && bus.isNotEmpty) return bus;
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString('guest_avatar_emoji');
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {}
    return null;
  }

  Future<Uint8List> _meMarkerBitmap() async {
    const cacheKey = 'me-marker-bitmap';
    final cached = _markerCache[cacheKey];
    if (cached != null) return cached;
    const double size = 176;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
    final center = const Offset(size / 2, size / 2);
    canvas.drawCircle(center, 86, Paint()..color = T.fire);
    canvas.drawCircle(center, 77, Paint()..color = Colors.white);
    final photo = await _loadMePhoto();
    if (photo != null) {
      final side = math.min(photo.width, photo.height).toDouble();
      final crop = Rect.fromLTWH(
        (photo.width - side) / 2,
        (photo.height - side) / 2,
        side,
        side,
      );
      canvas.save();
      canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: center, radius: 68)),
      );
      canvas.drawImageRect(
        photo,
        crop,
        Rect.fromCircle(center: center, radius: 68),
        Paint(),
      );
      canvas.restore();
    } else {
      canvas.drawCircle(center, 68, Paint()..color = kSurface2);
      // v2.0.12: TI ghost glyph fallback (vector, no emoji).
      // v2.0.16: if the user picked a glyph avatar ('ti:<name>'),
      // paint THAT glyph; a legacy emoji keeps the previous
      // behaviour (the branded ghost).
      final myGlyph = tiAvatarGlyph(await _meAvatarValue());
      TIPaint.paint(
        canvas,
        myGlyph ?? TIGlyph.ghost,
        Rect.fromCenter(center: center, width: 92, height: 92),
        T.iconGray,
        strokeScale: 1.1,
      );
    }
    final pic = recorder.endRecording();
    final img = await pic.toImage(size.toInt(), size.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = data!.buffer.asUint8List();
    _markerCache[cacheKey] = bytes;
    return bytes;
  }

  /* ---------------- side zoom: invisible swipe (v2.0.16) ----
     History: v2.0.10 shipped tap strips (upper half zoom-in, lower
     half zoom-out) as GestureDetectors; they starved in the gesture
     arena over the MapLibre platform view and never fired.
     v2.0.14 rebuilt them on a Listener (HitTestBehavior.opaque) —
     pointer events arrive in the hit-test phase, before any arena,
     so the strip claims its 48 dp first and the map never sees the
     touch — with tap/long-press STEP zoom, a 4% white tint and
     faint + / − glyphs. The owner rejected that («боковой зум
     хуевый»): he wants a GESTURE, fully invisible.
     v2.0.16: each edge strip is one invisible hit area. A vertical
     drag on it drives the zoom CONTINUOUSLY: finger up → zoom in,
     finger down → zoom out. On pointer-down the session captures
     the finger Y and the camera's current zoom + target; on move,
     targetZoom = startZoom + (startY − currentY) / _zoomSwipeK,
     clamped to [3, 19], applied with moveCamera(newCameraPosition)
     around the CAPTURED target — the map never recentres and there
     is no animation lag or stepping, the zoom tracks the finger.
     NOTHING is drawn: no glyphs, no tint, no painted box. The hit
     region does not depend on painting: a Listener with
     HitTestBehavior.opaque hit-tests by its own bounds (the child
     is a bare SizedBox.expand with the same 48 dp × full-height
     bounds the painted Container had), so the strips stay fully
     functional while invisible. A drag that starts outside the
     strips never reaches this Listener and pans the map normally;
     a drag that starts inside is consumed here and never pans. */

  // dp of vertical drag per 1.0 zoom level.
  static const double _zoomSwipeK = 120;
  static const double _zoomSwipeMin = 3;
  static const double _zoomSwipeMax = 19;

  void _zoomSwipeStart(PointerDownEvent e) {
    if (_zoomDragPointer != null) return; // one session at a time
    final ctl = _ctl;
    if (ctl == null) return;
    final cam = ctl.cameraPosition;
    if (cam == null) return;
    _zoomDragPointer = e.pointer;
    _zoomDragStartY = e.position.dy;
    _zoomDragStartZoom = cam.zoom;
    _zoomDragTarget = cam.target;
  }

  void _zoomSwipeMove(PointerMoveEvent e) {
    if (e.pointer != _zoomDragPointer) return;
    final ctl = _ctl;
    final target = _zoomDragTarget;
    if (ctl == null || target == null) return;
    final z = (_zoomDragStartZoom + (_zoomDragStartY - e.position.dy) / _zoomSwipeK)
        .clamp(_zoomSwipeMin, _zoomSwipeMax)
        .toDouble();
    try {
      ctl.moveCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: z),
      ));
    } catch (_) {}
  }

  void _zoomSwipeEnd(PointerEvent e) {
    if (e.pointer != _zoomDragPointer) return;
    _zoomDragPointer = null;
    _zoomDragTarget = null;
  }

  Widget _zoomPanel({required bool leftSide}) {
    return Positioned(
      top: 84, // below the route chip
      bottom: 64, // above the pulse chip / bottom controls
      left: leftSide ? 0 : null,
      right: leftSide ? null : 0,
      width: 48,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _zoomSwipeStart,
        onPointerMove: _zoomSwipeMove,
        onPointerUp: _zoomSwipeEnd,
        onPointerCancel: _zoomSwipeEnd,
        child: const SizedBox.expand(),
      ),
    );
  }

  Future<void> _presence() async {
    try {
      // v2.0.12: the position comes from the geolocator-fed
      // myLocationNotifier (LocationService), NOT from MapLibre's
      // requestMyLocationLatLng() — that API only works while the
      // native location puck is enabled, and the puck's own disc was
      // drawn by the native LocationComponent ON TOP of the custom
      // «me» avatar symbol (owner: «кружок поверх моей аватарки»).
      // The puck is now disabled (myLocationEnabled: false); nothing
      // else read position from MapLibre — centring, distances and
      // presence all already flow through the notifier.
      final pos = myLocationNotifier.value;
      if (pos == null) return;
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
    _routeImagesOnMap.clear(); // …and so must the route-marker images
    _routeLineObj = null;
    _routeSymbols.clear();
    _meSymbol = null; // …and the «me» marker belongs to the old style
    _meImgReady = false;
    ctl.onSymbolTapped.add((s) {
      final p = _symbolPlace[s.id];
      if (p != null && mounted) {
        // Pins are country-wide now: the sheet gets the place's OWN
        // city as context (vibe text, «similar», directions fallback),
        // not whichever city happens to be selected.
        City? pCity;
        for (final c in widget.cities) {
          if (c.id == p.city) {
            pCity = c;
            break;
          }
        }
        showPlaceSheet(
          context,
          p,
          favs: widget.favs,
          onToggleFav: widget.onToggleFav,
          cityPlaces: pCity != null
              ? widget.allPlaces.where((x) => x.city == p.city).toList()
              : widget.places,
          city: pCity ?? widget.city,
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
                  ? AvatarFace(f.avatar,
                      glyphSize: 28, emojiSize: 26, ghostForDefault: true)
                  : null,
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  f.mode == 'ghost' ? tr('ghost') : f.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  f.online ? tr('online_now') : tr('seen_recently'),
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
        _routeChip(),
        MapLibreMap(
          styleString: _style!,
          initialCameraPosition: CameraPosition(
            target: LatLng(city.lat, city.lng),
            zoom: 13,
          ),
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: () {
        _styleReady = true;
        _prepareSymbolLayer(); // overlap flags first, then draws places
        _drawRouteLine();
        _refreshFriends();
        _updateMeMarker();
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
          // v2.0.12: native puck OFF — its disc rendered above the
          // annotation symbols and covered the «me» avatar marker.
          // Position still flows via LocationService → myLocationNotifier.
          myLocationEnabled: false,
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
                      trf('pulse_chip', {'city': city.name, 'n': widget.places.length, 'hot': hot}),
                      style: T.body(12, w: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Side zoom panels — topmost, but only their 48 dp strips
        // catch touches; the map centre stays fully pan/pinch-able.
        _zoomPanel(leftSide: true),
        _zoomPanel(leftSide: false),
      ],
    );
  }
}

/* ---------------- places tab ---------------- */

/* Map pin types (v2.0.12): the gray pin discs carry a TI vector
   glyph per type (see typeGlyph) — the v2.0.8 owner's picks (бокал,
   чашка кофе, дерево…) redrawn in the monoline icon set; the emoji
   map is gone. */
const kPinTypes = <String>[
  'restaurant', 'cafe', 'bar', 'park', 'beach', 'culture', 'sport',
  'club', 'view', 'market', 'other',
];

/* Type id → kStr key (display names resolve through tr()). */
const kTypeNames = <String, String>{
  'park': 'type_park', 'cafe': 'type_cafe', 'bar': 'type_bar',
  'restaurant': 'type_restaurant', 'club': 'type_club', 'beach': 'type_beach',
  'view': 'type_view', 'sport': 'type_sport', 'culture': 'type_culture',
  'market': 'type_market', 'other': 'type_other',
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
  dynamic _dailyEntry;

  static const _sortLabels = {
    'vibe': 'sort_vibe',
    'dist': 'sort_dist',
    'rating': 'sort_rating',
    'price': 'sort_price',
    'name': 'sort_name',
  };

  @override
  void initState() {
    super.initState();
    _loadDaily();
  }

  /* «Задание дня» banner data (v2.0.14, Item 6 — replaces the
     «ИИ дня» banner): today's entry of the daily pool in tasks.json —
     the same deterministic pick the Tasks page card shows. The
     daily_drops pipeline stays untouched server-side; the client
     no longer presents it. */
  Future<void> _loadDaily() async {
    try {
      final raw = await rootBundle.loadString('assets/tasks.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final daily = (data['daily'] as List?) ?? [];
      if (daily.isNotEmpty && mounted) {
        setState(() => _dailyEntry = daily[dayIndex() % daily.length]);
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
        icon: type == null ? null : typeGlyph(type),
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
    final typesPresent = kPinTypes.where(
      (t) => all.any((p) => p.type == t),
    );

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
                  trf('places_count', {'n': all.length}),
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
                    child: const TiradIcon(TIGlyph.dice,
                        size: 19, color: T.iconGray),
                  ),
                ),
                const SizedBox(width: T.s8),
                SizedBox(
                  width: 132,
                  child: PressButton(
                    text: tr('tasks_book'),
                    small: true,
                    icon: TIGlyph.target,
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
                      if (_dailyEntry != null)
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
                                  sectionLabel(tr('daily_task_label'),
                                      color: T.salmon, glyph: TIGlyph.target),
                                  Text(
                                    aiText(_dailyEntry),
                                    style: T.body(14.5, w: FontWeight.w600),
                                  ),
                                  const SizedBox(height: T.s4),
                                  Text(
                                    tr('open_tasks'),
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
                              sectionLabel(tr('city_now'), color: T.salmon),
                              Row(
                                children: [
                                  _cityStat('${all.length}', tr('stat_places_radar')),
                                  _cityStat('$hotCount', tr('stat_hot_now')),
                                  _cityStat('$avgVibe%', tr('stat_avg_vibe')),
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
                                        TiradIcon(
                                          typeGlyph(p.type),
                                          size: 17,
                                          color: T.iconGray,
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
                              InputDecoration(hintText: tr('search_hint')),
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
                            _filterChip(null, tr('all')),
                            for (final t in typesPresent)
                              _filterChip(
                                t,
                                tr(kTypeNames[t] ?? t),
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
                                    child: Text(tr(e.value), style: T.body(13.5)),
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
                                  '↕ ${tr(_sortLabels[_sort] ?? 'sort_vibe')} ▾',
                                  style: T.body(12.5, w: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: T.s8),
                            PillButton(
                              text: tr('only_hot'),
                              selected: _hotOnly,
                              icon: TIGlyph.flame,
                              onTap: () =>
                                  setState(() => _hotOnly = !_hotOnly),
                            ),
                            const Spacer(),
                            Text(
                              trf('found_n', {'n': list.length}),
                              style: T.body(12, color: T.faint),
                            ),
                          ],
                        ),
                      ),
                      if (list.isEmpty)
                        EmptyState(
                          glyph: TIGlyph.ghost,
                          title: tr('empty_title'),
                          hint: tr('empty_hint'),
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
                            child: TiradIcon(
                              typeGlyph(p.type),
                              size: 24,
                              color: typeColor(p.type),
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
                                    return Row(
                                      children: [
                                        if (p.rating != null) ...[
                                          const TiradIcon(TIGlyph.star,
                                              size: 12,
                                              color: T.gold,
                                              filled: true),
                                          const SizedBox(width: 3),
                                        ],
                                        Expanded(
                                          child: Text(
                                            [
                                              if (p.rating != null)
                                                p.rating!.toStringAsFixed(1)
                                              else
                                                tr('new_short'),
                                              if (priceText(p).isNotEmpty)
                                                priceText(p),
                                              if (d != null)
                                                trf('dist_badge',
                                                    {'d': fmtKm(d)}),
                                              if (p.address.isNotEmpty)
                                                p.address,
                                            ].join(' · '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: T.body(12.5,
                                                color: T.muted),
                                          ),
                                        ),
                                      ],
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

/* A ready-made route, generated deterministically at runtime from the
   real places DB (no data files): an anchor place plus a walkable
   chain of complementary types. Name is a {ru, he, en} map, picked by
   aiText() — the same pattern the AI daily drop uses. */
class ReadyRoute {
  final String id;
  final City city;
  final Map<String, dynamic> name;
  final List<Place> stops;
  const ReadyRoute({
    required this.id,
    required this.city,
    required this.name,
    required this.stops,
  });
}

/* City names for generated route titles (he/en); anything missing
   falls back to the Russian name from cities.json. */
const kCityI18n = <String, (String, String)>{
  'telaviv': ('תל אביב', 'Tel Aviv'),
  'jerusalem': ('ירושלים', 'Jerusalem'),
  'haifa': ('חיפה', 'Haifa'),
  'karmiel': ('כרמיאל', 'Karmiel'),
  'beersheva': ('באר שבע', 'Beersheba'),
  'eilat': ('אילת', 'Eilat'),
  'netanya': ('נתניה', 'Netanya'),
  'ashdod': ('אשדוד', 'Ashdod'),
  'ashkelon': ('אשקלון', 'Ashkelon'),
  'rishon': ('ראשון לציון', 'Rishon LeZion'),
  'petahtikva': ('פתח תקווה', 'Petah Tikva'),
  'holon': ('חולון', 'Holon'),
};

class RouteTab extends StatefulWidget {
  final List<Place> places;
  final List<Place> allPlaces;
  final List<City> cities;
  final City? city;
  final VoidCallback onTaskDone;
  final VoidCallback onRouteBuilt;
  const RouteTab({
    super.key,
    required this.places,
    required this.allPlaces,
    required this.cities,
    required this.city,
    required this.onTaskDone,
    required this.onRouteBuilt,
  });

  @override
  State<RouteTab> createState() => _RouteTabState();
}

class _RouteTabState extends State<RouteTab> {
  String _transport = 'car';
  /* Real road route (OSRM, v2.0.10) for the active route — per-leg
     and total values replace the straight-line estimates in place
     when it lands. Null while loading and on any routing failure:
     the estimates just stay, exactly as in v2.0.9. */
  RoadRoute? _road;
  String _roadSig = '';
  int _seed = 0;
  List<dynamic> _routeTasks = [];

  /* The active route — built evening route, an opened ready route or
     an opened saved one. Persisted whole in prefs (active_route_v1),
     so a half-walked route survives an app restart. */
  List<Place> _stops = [];
  LatLng? _start;
  bool _startIsCenter = false;
  String _kind = 'evening'; // evening · ready · saved
  String _routeKey = '';
  String _routeTitle = 'route_evening_title';

  /* The active ready route's name as its raw {ru, he, en} map, when
     the active route is a ready one. _titleText resolves it through
     aiText() so a language switch re-reads it, and _persistActive
     stores the map (not a one-language snapshot) so a restart also
     restores it in whatever language is current. Null for the
     built-in kinds, whose titles are kStr keys. */
  Map<String, dynamic>? _routeTitleMap;

  /* _routeTitle holds either a localized ready-route name (aiText) or a
     kStr key for the built-in kinds; resolve it at display time so a
     language switch re-reads it. Legacy persisted titles (the Russian
     literals older builds stored) map onto the same keys. */
  String get _titleText {
    if (_routeTitleMap != null) return aiText(_routeTitleMap);
    if (_routeTitle == 'route_evening_title' ||
        _routeTitle == 'Маршрут на вечер') {
      return tr('route_evening_title');
    }
    if (_routeTitle == 'route_saved_title' ||
        _routeTitle == 'Сохранённый маршрут') {
      return tr('route_saved_title');
    }
    return _routeTitle;
  }
  String _routeCityId = '';
  String _routeCityName = '';
  final Set<int> _done = {};
  bool _counted = false;

  /* Route theme tasks ticked for the ACTIVE route (v2.0.14, Item 7):
     prefs 'route_tasks_done_<routeKey>' — a JSON list of stop
     indices whose _taskFor(i) task is ticked. Deliberately separate
     from the ≤150 m check-ins (_done): a task is ticked when done,
     a check-in still requires actually being there. One-way —
     a ticked task cannot be un-ticked (anti-farm). */
  final Set<int> _routeTasksDone = {};

  List<Map<String, dynamic>> _savedRoutes = [];
  final Map<String, List<ReadyRoute>> _readyCache = {};
  Set<String> _readyCounted = {};

  static const _speeds = {'walk': 5.0, 'bus': 18.0, 'car': 30.0};

  /* Bus time (v2.0.15): OSRM has no transit routing, so the bus
     rides the DRIVING road route — but its displayed time must not
     be the car's number (before 2.0.15 bus and car showed the exact
     same OSRM duration). Bus estimate = driving duration × 1.35
     (stops, lights, boarding) + a flat 8 min access/wait buffer.
     The buffer rides on the FIRST leg, so the leg rows still sum
     to the header total. Walk and car show the raw OSRM durations
     of their own profiles. While no road route has landed, the
     straight-line fallback stays speed-based per mode via _speeds
     (walk 5, bus 18, car 30 km/h), so it is mode-aware too. */
  static const _busFactor = 1.35;
  static const _busBufferMins = 8.0;

  double _modeTotalMins(double roadMins) => _transport == 'bus'
      ? roadMins * _busFactor + _busBufferMins
      : roadMins;

  double _modeLegMins(double legRoadMins, int leg) => _transport == 'bus'
      ? legRoadMins * _busFactor + (leg == 0 ? _busBufferMins : 0)
      : legRoadMins;
  /* v2.0.12: transport marks are TI glyphs (walk/bus/car), resolved
     inline at the render sites — the emoji map is gone. */
  static const _checkInRadiusKm = 0.15; // «Я здесь» opens within ~150 m

  @override
  void initState() {
    super.initState();
    _seed = dayIndex();
    _load();
    // The map chip's delete button asks HERE to wipe route tracking —
    // this tab owns the active-route state (stops/done/counted).
    MapRouteBus.deleteRequestTick.addListener(_onDeleteRequested);
  }

  @override
  void dispose() {
    MapRouteBus.deleteRequestTick.removeListener(_onDeleteRequested);
    super.dispose();
  }

  void _onDeleteRequested() {
    if (!mounted) return;
    _requestDeleteRoute();
  }

  /* «Удалить маршрут» (v2.0.12): stops tracking the active route.
     Nothing completed yet → wipe immediately, no dialog. Some stops
     already done → one confirm sheet in the app's style first. XP
     already credited (tasks/routes stats) is NEVER revoked — only
     the tracking state (stops/done/counted + persisted copy) goes. */
  Future<void> _requestDeleteRoute() async {
    if (_stops.isEmpty) {
      if (MapRouteBus.line.value?.kind == 'route') MapRouteBus.clear();
      return;
    }
    if (_done.isNotEmpty) {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => SheetShell(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(T.s20, T.s4, T.s20, T.s20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr('delete_route_title'), style: T.head(17)),
                const SizedBox(height: T.s8),
                Text(
                  tr('delete_route_progress'),
                  style: T.body(13.5, color: T.muted),
                ),
                const SizedBox(height: T.s16),
                FireButton(
                  text: tr('btn_delete'),
                  icon: TIGlyph.trash,
                  small: true,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: T.s8),
                GhostButton(
                  text: tr('btn_cancel'),
                  small: true,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ),
      );
      if (ok != true || !mounted) return;
    }
    _deleteActiveRoute();
  }

  void _deleteActiveRoute() {
    if (MapRouteBus.line.value?.kind == 'route') MapRouteBus.clear();
    _done.clear();
    _counted = false;
    _stops = [];
    _road = null;
    _roadSig = '';
    // The tab's resting state is a fresh, untouched evening route for
    // the selected city (exactly what first open builds): it replaces
    // the persisted active_route_v1, so the deleted route's stops,
    // done set and counted flag are gone everywhere. The builder and
    // the ready routes below are visible again.
    _buildEvening();
    if (mounted) {
      setState(() {});
      snack(context, tr('route_deleted'));
    }
  }

  @override
  void didUpdateWidget(RouteTab old) {
    super.didUpdateWidget(old);
    // The evening route belongs to the selected city; ready/saved
    // routes the user opened on purpose stay untouched.
    if (old.city?.id != widget.city?.id && _kind == 'evening') {
      _buildEvening();
      if (mounted) setState(() {});
    }
  }

  Map<String, dynamic> _placeMap(Place p) => {
        'id': p.id,
        'city': p.city,
        'name': p.name,
        'type': p.type,
        'lat': p.lat,
        'lng': p.lng,
        'rating': p.rating,
        'reviews': p.reviews,
        'priceLevel': p.priceLevel,
        'address': p.address,
      };

  Place _placeFromMap(Map<String, dynamic> m) => Place(
        id: (m['id'] ?? '').toString(),
        city: (m['city'] ?? '').toString(),
        name: (m['name'] ?? '').toString(),
        type: (m['type'] ?? 'other').toString(),
        lat: (m['lat'] as num?)?.toDouble() ?? 0,
        lng: (m['lng'] as num?)?.toDouble() ?? 0,
        rating: (m['rating'] as num?)?.toDouble(),
        reviews: (m['reviews'] as num?)?.toInt(),
        priceLevel: (m['priceLevel'] as num?)?.toInt(),
        address: (m['address'] ?? '').toString(),
      );

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/tasks.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _routeTasks = (data['route'] as List?) ?? [];
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final tr = prefs.getString('route_transport_${dayKey()}');
      if (tr != null && _speeds.containsKey(tr)) _transport = tr;
      final sr = prefs.getString('saved_routes');
      if (sr != null) {
        _savedRoutes = (jsonDecode(sr) as List)
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();
      }
      _readyCounted =
          (prefs.getStringList('ready_routes_counted') ?? []).toSet();
      final ar = prefs.getString('active_route_v1');
      if (ar != null) _restoreActive(jsonDecode(ar));
    } catch (_) {}
    if (_stops.isEmpty) _buildEvening();
    _loadRouteTasksDone();
    _refreshRoad();
    if (mounted) setState(() {});
  }

  Future<void> _loadRouteTasksDone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('route_tasks_done_$_routeKey');
      final loaded = <int>{};
      if (raw != null) {
        loaded.addAll(
            (jsonDecode(raw) as List).map((e) => (e as num).toInt()));
      }
      _routeTasksDone
        ..clear()
        ..addAll(loaded);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _toggleRouteTask(int i) async {
    if (_routeTasksDone.contains(i)) return; // one-way, anti-farm
    setState(() => _routeTasksDone.add(i));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'route_tasks_done_$_routeKey',
        jsonEncode(_routeTasksDone.toList()),
      );
    } catch (_) {}
    widget.onTaskDone(); // stats.tasks +1, exactly once per task
    if (!mounted) return;
    snack(context, tr('route_task_done'));
    if (_stops.isNotEmpty && _routeTasksDone.length >= _stops.length) {
      fireConfetti(context);
    }
  }

  void _restoreActive(dynamic raw) {
    if (raw is! Map) return;
    final m = raw.cast<String, dynamic>();
    final stops = <Place>[];
    for (final e in (m['stops'] as List? ?? [])) {
      if (e is Map) stops.add(_placeFromMap(e.cast<String, dynamic>()));
    }
    if (stops.isEmpty) return;
    final kind = (m['kind'] ?? 'evening').toString();
    // An evening route from another selected city is stale — rebuild.
    if (kind == 'evening' && m['cityId']?.toString() != widget.city?.id) {
      return;
    }
    _kind = kind;
    _routeKey = (m['key'] ?? '').toString();
    _routeTitle = (m['title'] ?? 'route_evening_title').toString();
    final tm = m['titleMap'];
    _routeTitleMap = tm is Map ? tm.cast<String, dynamic>() : null;
    _routeCityId = (m['cityId'] ?? '').toString();
    _routeCityName = (m['cityName'] ?? '').toString();
    _seed = (m['seed'] as num?)?.toInt() ?? _seed;
    final slat = (m['startLat'] as num?)?.toDouble();
    final slng = (m['startLng'] as num?)?.toDouble();
    _start = (slat != null && slng != null) ? LatLng(slat, slng) : null;
    _startIsCenter = m['startIsCenter'] == true;
    _stops = stops;
    _done
      ..clear()
      ..addAll((m['done'] as List? ?? [])
          .map((e) => (e as num).toInt())
          .where((i) => i >= 0 && i < stops.length));
    _counted = m['counted'] == true;
  }

  Future<void> _persistActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'active_route_v1',
        jsonEncode({
          'kind': _kind,
          'key': _routeKey,
          'title': _routeTitle,
          'titleMap': _routeTitleMap,
          'cityId': _routeCityId,
          'cityName': _routeCityName,
          'seed': _seed,
          'startLat': _start?.latitude,
          'startLng': _start?.longitude,
          'startIsCenter': _startIsCenter,
          'stops': [for (final p in _stops) _placeMap(p)],
          'done': _done.toList(),
          'counted': _counted,
        }),
      );
    } catch (_) {}
  }

  /* ---------------- evening builder (from real geolocation) -------- */

  /* Stop quality, priced in «kilometres of walking we trade for
     it» (v2.0.14, Item 4a). The old chain scored d − vibe/100 only:
     no rating weight at all, and a greedy nearest-per-slot walk
     that happily zig-zagged back across the start. Now vibe still
     dominates, a real rating adds (a poor one subtracts), and a
     place with an actual review footprint beats an unrated one.
     Bounded, so quality bends the choice — never teleports it. */
  double _qualityOf(Place p) {
    var q = vibeOf(p) / 100.0 * 1.6; // 0 .. 1.6
    final r = p.rating;
    if (r != null) {
      q += (r - 3.5).clamp(-1.0, 1.5) * 0.5; // −0.5 .. +0.75
      if ((p.reviews ?? 0) >= 20) q += 0.25; // people actually go here
    }
    return q;
  }

  /* Per slot, take the unused place of the slot types with the best
     (distance − quality) score from the current point. When a
     walking cap is given, candidates that keep the running total
     under the cap win over a marginally better-scoring one that
     would blow it. */
  List<Place> _chain(LatLng from, List<Place> candidates,
      List<Set<String>> slots,
      {double capKm = double.infinity}) {
    final picks = <Place>[];
    var cur = from;
    var total = 0.0;
    for (final types in slots) {
      Place? best;
      var bestScore = double.infinity;
      Place? bestCapped;
      var bestCappedScore = double.infinity;
      for (final p in candidates) {
        if (picks.contains(p) || !types.contains(p.type)) continue;
        final d = haversineKm(cur.latitude, cur.longitude, p.lat, p.lng);
        final score = d - _qualityOf(p);
        if (score < bestScore) {
          bestScore = score;
          best = p;
        }
        if (total + d <= capKm && score < bestCappedScore) {
          bestCappedScore = score;
          bestCapped = p;
        }
      }
      final pick = bestCapped ?? best;
      if (pick == null) break;
      picks.add(pick);
      total += haversineKm(cur.latitude, cur.longitude, pick.lat, pick.lng);
      cur = LatLng(pick.lat, pick.lng);
    }
    return picks;
  }

  /* Order improvement (v2.0.14): with 3 stops there are only 6
     orders — score them all by true walking length from the start
     and keep the shortest; ties keep the slot order (the evening
     arc). Kills the greedy chain's backtracking without changing
     WHICH places the slots picked. */
  List<Place> _improveOrder(LatLng start, List<Place> stops) {
    if (stops.length < 2) return stops;
    var best = stops;
    var bestKm = _chainKm(start, stops);
    final a = List.generate(stops.length, (i) => i);
    void permute(int l) {
      if (l == a.length) {
        final cand = [for (final i in a) stops[i]];
        final km = _chainKm(start, cand);
        if (km < bestKm - 0.001) {
          bestKm = km;
          best = cand;
        }
        return;
      }
      for (var i = l; i < a.length; i++) {
        final t = a[l];
        a[l] = a[i];
        a[i] = t;
        permute(l + 1);
        final u = a[l];
        a[l] = a[i];
        a[i] = u;
      }
    }

    permute(0);
    return best;
  }

  List<Place> _buildStops(LatLng start, {Set<String> exclude = const {}}) {
    final pool = widget.places;
    if (pool.isEmpty) return [];
    // Evening arc: easy start → something green/open → the night peak.
    const slots = [
      {'cafe', 'restaurant', 'bar'},
      {'view', 'park', 'culture', 'beach'},
      {'bar', 'club', 'restaurant'},
    ];
    const allTypes = {
      'cafe', 'restaurant', 'bar', 'view', 'park', 'culture',
      'beach', 'club', 'market', 'sport', 'other',
    };
    // A sane evening walk, start → last stop (v2.0.14): radius tiers
    // are tried as before, but a tier only «wins» outright when its
    // improved order stays within the cap; otherwise the shortest
    // complete chain found is kept.
    const capKm = 6.0;
    List<Place>? best;
    var bestKm = double.infinity;
    for (final radius in [2.5, 5.0, double.infinity]) {
      final inR = pool
          .where((p) =>
              !exclude.contains(p.id) &&
              haversineKm(start.latitude, start.longitude, p.lat, p.lng) <=
                  radius)
          .toList();
      final picks = _chain(start, inR, slots, capKm: capKm);
      if (picks.length == 3) {
        final ordered = _improveOrder(start, picks);
        final km = _chainKm(start, ordered);
        if (km <= capKm) return ordered;
        if (km < bestKm) {
          bestKm = km;
          best = ordered;
        }
      }
    }
    if (best != null) return best;
    if (exclude.isNotEmpty) {
      final picks = _chain(start, pool, slots, capKm: capKm);
      if (picks.length == 3) return _improveOrder(start, picks);
    }
    // Exotic city where the type slots can't be filled at all:
    // a plain chain over everything there is, order-improved.
    final anyPool = pool.where((p) => !exclude.contains(p.id)).toList();
    return _improveOrder(
        start,
        _chain(start, anyPool.isEmpty ? pool : anyPool,
            [allTypes, allTypes, allTypes]));
  }

  void _buildEvening({Set<String> exclude = const {}}) {
    final city = widget.city;
    if (city == null) {
      _stops = [];
      return;
    }
    final origin = myLocationNotifier.value;
    final start = origin ?? LatLng(city.lat, city.lng);
    var stops = _buildStops(start, exclude: exclude);
    if (stops.isEmpty && exclude.isNotEmpty) stops = _buildStops(start);
    _kind = 'evening';
    _stops = stops;
    _start = start;
    _startIsCenter = origin == null;
    _routeCityId = city.id;
    _routeCityName = city.name;
    _routeTitle = 'route_evening_title';
    _routeTitleMap = null;
    _routeKey =
        'evening-${city.id}-${dayKey()}-$_seed-${stops.map((p) => p.id).join('.')}';
    _done.clear();
    _counted = false;
    if (MapRouteBus.line.value?.kind == 'route') MapRouteBus.clear();
    _persistActive();
    _loadRouteTasksDone();
    _refreshRoad();
  }

  Future<void> _reshuffle() async {
    HapticFeedback.mediumImpact();
    _seed++;
    _buildEvening(exclude: _stops.map((p) => p.id).toSet());
    if (mounted) setState(() {});
  }

  /* ---------------- ready-made routes ---------------- */

  double _rateOf(Place p) => p.rating ?? 3.8;

  List<Place> _byRating(List<Place> pool) {
    final list = [...pool];
    list.sort((a, b) {
      final r = _rateOf(b).compareTo(_rateOf(a));
      if (r != 0) return r;
      final rv = (b.reviews ?? 0).compareTo(a.reviews ?? 0);
      if (rv != 0) return rv;
      return stableHash(a.id).compareTo(stableHash(b.id));
    });
    return list;
  }

  /* Anchor + chain: each next stop is the top-rated unused place of
     the slot types within 1.5 km of the previous stop (nearest of the
     type when nothing is that close), so the route stays walkable. */
  List<Place> _readyStops(
      Place anchor, List<Place> pool, List<Set<String>> slots) {
    final stops = [anchor];
    var cur = anchor;
    Place? stepPick(Set<String> types) {
      final unused = pool
          .where((p) => !stops.contains(p) && types.contains(p.type))
          .toList();
      if (unused.isEmpty) return null;
      final near = unused
          .where((p) => haversineKm(cur.lat, cur.lng, p.lat, p.lng) <= 1.5)
          .toList();
      if (near.isNotEmpty) return _byRating(near).first;
      unused.sort((a, b) => haversineKm(cur.lat, cur.lng, a.lat, a.lng)
          .compareTo(haversineKm(cur.lat, cur.lng, b.lat, b.lng)));
      return unused.first;
    }

    for (final s in slots) {
      final p = stepPick(s);
      if (p != null) {
        stops.add(p);
        cur = p;
      }
    }
    // Optional 4th stop: something open/green to land the route.
    final p4 = stepPick(const {'view', 'park', 'culture', 'beach'});
    if (p4 != null) stops.add(p4);
    return stops;
  }

  List<ReadyRoute> _readyFor(City city) {
    final cached = _readyCache[city.id];
    if (cached != null) return cached;
    final pool = widget.allPlaces.where((p) => p.city == city.id).toList();
    final routes = <ReadyRoute>[];
    if (pool.length >= 10) {
      final he = kCityI18n[city.id]?.$1 ?? city.name;
      final en = kCityI18n[city.id]?.$2 ?? city.name;
      final anchorsA = _byRating(pool
          .where((p) => p.type == 'restaurant' || p.type == 'bar')
          .toList());
      if (anchorsA.isNotEmpty) {
        final stops = _readyStops(anchorsA.first, pool, const [
          {'view', 'park', 'culture'},
          {'club', 'bar', 'restaurant'},
        ]);
        if (stops.length >= 3) {
          routes.add(ReadyRoute(
            id: 'ready-${city.id}-evening',
            city: city,
            name: {
              'ru': 'Вечер в ${city.name}',
              'he': 'ערב ב$he',
              'en': 'Evening in $en',
            },
            stops: stops,
          ));
        }
      }
      final anchorsB =
          _byRating(pool.where((p) => p.type == 'cafe').toList());
      if (anchorsB.isNotEmpty) {
        final stops = _readyStops(anchorsB.first, pool, const [
          {'park', 'view'},
          {'restaurant', 'cafe'},
        ]);
        if (stops.length >= 3) {
          routes.add(ReadyRoute(
            id: 'ready-${city.id}-day',
            city: city,
            name: {
              'ru': 'День в ${city.name}',
              'he': 'יום ב$he',
              'en': 'A day in $en',
            },
            stops: stops,
          ));
        }
      }
    }
    _readyCache[city.id] = routes;
    return routes;
  }

  /* Selected city first, then the anchor cities — every other city
     gets its routes when it becomes the selected one. */
  List<(City, List<ReadyRoute>)> _readyGroups() {
    final groups = <(City, List<ReadyRoute>)>[];
    final seen = <String>{};
    void add(City? c) {
      if (c == null || !seen.add(c.id)) return;
      final r = _readyFor(c);
      if (r.isNotEmpty) groups.add((c, r));
    }

    add(widget.city);
    for (final id in ['karmiel', 'telaviv', 'jerusalem', 'haifa']) {
      for (final c in widget.cities) {
        if (c.id == id) add(c);
      }
    }
    return groups;
  }

  void _activateReady(ReadyRoute r) {
    HapticFeedback.mediumImpact();
    final origin = myLocationNotifier.value;
    _kind = 'ready';
    _routeKey = r.id;
    _routeTitle = aiText(r.name);
    _routeTitleMap = r.name;
    _routeCityId = r.city.id;
    _routeCityName = r.city.name;
    _stops = List.of(r.stops);
    _start = origin ?? LatLng(r.city.lat, r.city.lng);
    _startIsCenter = origin == null;
    _done.clear();
    _counted = _readyCounted.contains(r.id);
    _loadRouteTasksDone();
    if (MapRouteBus.line.value?.kind == 'route') MapRouteBus.clear();
    _persistActive();
    _refreshRoad();
    setState(() {});
  }

  /* ---------------- saved routes ---------------- */

  String _savedKey(Map<String, dynamic> e) =>
      'saved-${e['day']}-${(e['places'] as List? ?? []).map((x) => (x as Map)['id']).join('.')}';

  void _activateSaved(Map<String, dynamic> e) {
    final stops = <Place>[];
    for (final x in (e['places'] as List? ?? [])) {
      if (x is Map) stops.add(_placeFromMap(x.cast<String, dynamic>()));
    }
    if (stops.isEmpty) return;
    HapticFeedback.selectionClick();
    final origin = myLocationNotifier.value;
    City? rc;
    for (final c in widget.cities) {
      if (c.id == stops.first.city) rc = c;
    }
    _kind = 'saved';
    _routeKey = _savedKey(e);
    _routeTitle = 'route_saved_title';
    _routeTitleMap = null;
    _routeCityId = stops.first.city;
    _routeCityName = (e['cityName'] ?? '').toString();
    _stops = stops;
    _start = origin ??
        (rc != null
            ? LatLng(rc.lat, rc.lng)
            : LatLng(stops.first.lat, stops.first.lng));
    _startIsCenter = origin == null;
    final tr = e['transport']?.toString();
    if (tr != null && _speeds.containsKey(tr)) _transport = tr;
    _done.clear();
    _counted = e['counted'] == true;
    _loadRouteTasksDone();
    if (MapRouteBus.line.value?.kind == 'route') MapRouteBus.clear();
    _persistActive();
    _refreshRoad();
    setState(() {});
  }

  Future<void> _markSavedCounted() async {
    for (final e in _savedRoutes) {
      if (_savedKey(e) == _routeKey) e['counted'] = true;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_routes', jsonEncode(_savedRoutes));
    } catch (_) {}
  }

  Future<void> _saveRoute() async {
    if (_stops.isEmpty) return;
    final entry = <String, dynamic>{
      'day': dayKey(),
      'cityName': _routeCityName,
      'transport': _transport,
      'counted': _counted,
      'places': [for (final p in _stops) _placeMap(p)],
    };
    setState(() => _savedRoutes = [entry, ..._savedRoutes].take(12).toList());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_routes', jsonEncode(_savedRoutes));
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('route_saved_snack'))),
      );
    }
  }

  /* ---------------- walking the route ---------------- */

  String _descFor(int i) {
    switch (i) {
      case 0:
        return tr('route_desc_0');
      case 1:
        return tr('route_desc_1');
      default:
        return tr('route_desc_2');
    }
  }

  String _timeFor(int i) {
    final mins = 19 * 60 + 30 + i * 90;
    final h = (mins ~/ 60) % 24;
    final m = mins % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String _taskFor(int i) {
    if (_routeTasks.isEmpty) {
      return tr('route_task_fallback');
    }
    return aiText(
        _routeTasks[stableHash('$_routeKey|$i') % _routeTasks.length]);
  }

  String _fmtDist(double km) =>
      km < 1 ? '${(km * 1000).round()} ${tr('unit_m')}' : '${fmtKm(km)} ${tr('unit_km')}';

  double get _totalKm {
    var t = 0.0;
    LatLng? prev = _start;
    for (final p in _stops) {
      if (prev != null) {
        t += haversineKm(prev.latitude, prev.longitude, p.lat, p.lng);
      }
      prev = LatLng(p.lat, p.lng);
    }
    return t;
  }

  double _chainKm(LatLng from, List<Place> stops) {
    var t = 0.0;
    var prev = from;
    for (final p in stops) {
      t += haversineKm(prev.latitude, prev.longitude, p.lat, p.lng);
      prev = LatLng(p.lat, p.lng);
    }
    return t;
  }

  /* Check-in is proximity-gated when we can see the user: the stop
     completes only within ~150 m of it. With no live position at all
     there is nothing to verify against, so the tap still counts —
     location-off users are nudged, not bricked. */
  void _toggleDone(int i) {
    if (_done.contains(i)) {
      HapticFeedback.selectionClick();
      setState(() => _done.remove(i));
      _persistActive();
      return;
    }
    final p = _stops[i];
    final origin = myLocationNotifier.value;
    if (origin != null) {
      final d = haversineKm(origin.latitude, origin.longitude, p.lat, p.lng);
      if (d > _checkInRadiusKm) {
        snack(context, trf('route_too_far', {'d': _fmtDist(d)}));
        return;
      }
    }
    HapticFeedback.selectionClick();
    setState(() => _done.add(i));
    widget.onTaskDone();
    if (_done.length >= _stops.length && _stops.isNotEmpty && !_counted) {
      _counted = true;
      if (_kind == 'ready') {
        _readyCounted.add(_routeKey);
        SharedPreferences.getInstance().then((prefs) => prefs.setStringList(
            'ready_routes_counted', _readyCounted.toList()));
      }
      if (_kind == 'saved') _markSavedCounted();
      widget.onRouteBuilt();
      fireConfetti(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('route_done_snack'))),
      );
    }
    _persistActive();
  }

  /* Loads the real road route (OSRM) for the active route at the
     current transport. Straight-line estimates stay on screen until
     it lands; on failure they simply stay forever. The signature
     guards against a slow answer for a previous route/transport
     overwriting the current one. */
  Future<void> _refreshRoad() async {
    final start = _start;
    if (start == null || _stops.isEmpty) {
      _road = null;
      _roadSig = '';
      return;
    }
    final pts = [start, for (final p in _stops) LatLng(p.lat, p.lng)];
    final profile = RoutingService.profileFor(_transport);
    final sig = RoutingService.cacheKey(profile, pts);
    // Bus and car share the driving signature ON PURPOSE (v2.0.15):
    // switching between them reuses the loaded driving route with
    // no refetch — only the displayed times change, via
    // _modeTotalMins/_modeLegMins reading _transport at build time.
    if (sig == _roadSig) return;
    _roadSig = sig;
    _road = null;
    final r = await RoutingService.route(profile, pts);
    if (r != null && mounted && _roadSig == sig) {
      setState(() => _road = r);
    }
  }

  /* Total shown in the header: road distance once OSRM answered. */
  double get _displayTotalKm => _road?.totalKm ?? _totalKm;

  void _showOnMap() {
    if (_stops.isEmpty) {
      snack(context, tr('route_empty_snack'));
      return;
    }
    final start = _start ??
        myLocationNotifier.value ??
        (widget.city != null
            ? LatLng(widget.city!.lat, widget.city!.lng)
            : LatLng(_stops.first.lat, _stops.first.lng));
    final pts = [start, for (final p in _stops) LatLng(p.lat, p.lng)];
    final profile = RoutingService.profileFor(_transport);
    // If the road route for exactly these waypoints is already in
    // hand, the map gets the road geometry instantly; otherwise the
    // bus enrichment fetches it (same shared cache) and swaps it in.
    final preloaded =
        (_road != null && _roadSig == RoutingService.cacheKey(profile, pts))
            ? _road
            : null;
    final line = MapRouteLine(
      kind: 'route',
      title: _titleText,
      points: pts,
      stops: List.of(_stops),
      fromCityCenter: _startIsCenter,
      totalKm: _totalKm,
      profile: profile,
    );
    MapRouteBus.show(preloaded != null ? line.copyWithRoad(preloaded) : line);
  }

  /* ---------------- UI ---------------- */

  /* Summary chip for the route hero card (v2.0.14). */
  Widget _summaryChip(TIGlyph glyph, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: T.s12, vertical: T.s8),
      decoration: BoxDecoration(
        color: T.surfaceHi,
        borderRadius: BorderRadius.circular(T.rPill),
        border: Border.all(color: T.stroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TiradIcon(glyph, size: 13, color: T.iconGray),
          const SizedBox(width: 6),
          Text(text, style: T.body(12, w: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _transportPill(String id, String label) {
    final sel = _transport == id;
    return GestureDetector(
      onTap: () async {
        tickSelect();
        setState(() => _transport = id);
        _refreshRoad(); // legs/total re-fetch for the new profile
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TiradIcon(
              id == 'walk'
                  ? TIGlyph.walk
                  : (id == 'bus' ? TIGlyph.bus : TIGlyph.car),
              size: 15,
              color: sel ? Colors.white : T.iconGray,
              filled: sel,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legRow(LatLng a, Place b, {String? fromLabel, int leg = -1}) {
    // OSRM leg values once the road route has landed, adjusted for
    // the selected transport (v2.0.15: bus legs are the driving
    // legs ×1.35, +8 min wait on the first leg); the straight-line
    // estimate for this leg until then (and on any failure).
    final r = _road;
    final double km;
    final int mins;
    if (r != null && leg >= 0 && leg < r.legKm.length) {
      km = r.legKm[leg];
      mins = _modeLegMins(r.legMins[leg], leg).round();
    } else {
      km = haversineKm(a.latitude, a.longitude, b.lat, b.lng);
      mins = (km / (_speeds[_transport] ?? 30) * 60).round();
    }
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Center(
            child: Container(width: 3, height: 30, color: kRed.withOpacity(0.55)),
          ),
        ),
        const SizedBox(width: 10),
        TiradIcon(
          _transport == 'walk'
              ? TIGlyph.walk
              : (_transport == 'bus' ? TIGlyph.bus : TIGlyph.car),
          size: 14,
          color: T.iconGray,
        ),
        const SizedBox(width: 5),
        Text(
          '${fromLabel != null ? '$fromLabel · ' : ''}${_fmtDist(km)} · ${trf('mins_short', {'n': mins})}',
          style: const TextStyle(color: kMuted, fontSize: 12.5),
        ),
      ],
    );
  }

  Widget _stopCard(int i, Place p) {
    final task = _taskFor(i);
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
            if (i < _stops.length - 1)
              Container(width: 3, height: 14, color: kRed.withOpacity(0.55)),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(15),
            // v2.0.14 (Item 4b): token typography throughout and a
            // green edge once the stop is checked in, so the card
            // reads as part of the same system as the hero above it.
            decoration: cardDecoration().copyWith(
              border: Border.all(
                color: done ? T.online.withOpacity(0.55) : T.stroke,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_timeFor(i)} · $_routeCityName',
                  style: T.micro(color: T.salmon),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    TiradIcon(
                      typeGlyph(p.type),
                      size: 18,
                      color: T.iconGray,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: T.head(16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  _descFor(i),
                  style: T.body(13, color: T.muted),
                ),
                const SizedBox(height: 7),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child:
                          TiradIcon(TIGlyph.target, size: 15, color: T.ember),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        task,
                        style: T.body(13.5),
                      ),
                    ),
                  ],
                ),
                // Live distance to this stop + whether check-in is open.
                ValueListenableBuilder<LatLng?>(
                  valueListenable: myLocationNotifier,
                  builder: (_, origin, __) {
                    if (done || origin == null) {
                      return const SizedBox.shrink();
                    }
                    final d = haversineKm(
                        origin.latitude, origin.longitude, p.lat, p.lng);
                    final near = d <= _checkInRadiusKm;
                    return Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Text(
                        near
                            ? tr('stop_near')
                            : trf('stop_far', {'d': _fmtDist(d)}),
                        style: TextStyle(
                          color: near ? kGreen : kMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _toggleDone(i),
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
                          done ? tr('done_label') : tr('checkin_task'),
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

  Widget _readyCard(ReadyRoute r) {
    final active = _kind == 'ready' && _routeKey == r.id;
    final counted = _readyCounted.contains(r.id);
    final km = _chainKm(LatLng(r.city.lat, r.city.lng), r.stops);
    return Pressable(
      onTap: () => _activateReady(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: T.s8),
        padding:
            const EdgeInsets.symmetric(horizontal: T.s16, vertical: T.s12),
        decoration: BoxDecoration(
          color: T.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: active ? T.fire : T.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const TiradIcon(TIGlyph.moon, size: 15, color: T.ember),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${aiText(r.name)}${counted ? tr('route_counted_suffix') : ''}',
                    style: T.body(13.5, w: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              r.stops.map((p) => p.name).join(' → '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: T.body(12, color: T.muted),
            ),
            const SizedBox(height: 3),
            Text(
              trf('ready_card_line', {'n': r.stops.length, 'd': _fmtDist(km)}),
              style: T.body(11.5, color: T.salmon, w: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = _readyGroups();
    return GlowBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          /* v2.0.14 (Item 4b): the tab head is a proper hero card
             in the design system — gradient border, brand glyph,
             summary chips, controls grouped inside — instead of the
             flat stack of raw texts the owner called «без стиля». */
          GlassCard(
            gradientBorder: true,
            padding: const EdgeInsets.all(T.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: T.specGrad,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66E8301E),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const TiradIcon(TIGlyph.routePath,
                          size: 22, color: Colors.white, filled: true),
                    ),
                    const SizedBox(width: T.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_kind == 'evening')
                            Text.rich(
                              TextSpan(children: [
                                TextSpan(text: tr('route_title_a')),
                                TextSpan(
                                    text: tr('route_title_b'),
                                    style:
                                        T.display(19, color: T.ember)),
                              ]),
                              style: T.display(19),
                            )
                          else
                            Text(_titleText, style: T.display(19)),
                          const SizedBox(height: T.s4),
                          Text(
                            _kind == 'evening'
                                ? trf('route_intro_evening',
                                    {'city': _routeCityName})
                                : _kind == 'ready'
                                    ? trf('route_intro_ready',
                                        {'city': _routeCityName})
                                    : trf('route_intro_saved',
                                        {'city': _routeCityName}),
                            style: T.body(13, color: T.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_stops.isNotEmpty) ...[
                  const SizedBox(height: T.s12),
                  Wrap(
                    spacing: T.s8,
                    runSpacing: T.s8,
                    children: [
                      _summaryChip(
                        TIGlyph.mapPin,
                        _startIsCenter
                            ? tr('route_start_center')
                            : tr('route_start_you'),
                      ),
                      _summaryChip(
                        TIGlyph.routePath,
                        trf('route_summary', {
                              'n': _stops.length,
                              'd': _fmtDist(_displayTotalKm),
                            }) +
                            (_counted ? tr('route_summary_done') : ''),
                      ),
                      _summaryChip(
                        TIGlyph.clock,
                        trf('mins_short', {
                          // v2.0.15: the OSRM total goes through
                          // the transport adjustment (bus = driving
                          // ×1.35 + 8 min) — before, this chip showed
                          // the raw duration, identical for bus/car
                          // and, via the profile-blind demo server,
                          // for walking too.
                          'n': _road != null
                              ? _modeTotalMins(_road!.totalMins).round()
                              : (_displayTotalKm /
                                      (_speeds[_transport] ?? 5) *
                                      60)
                                  .round(),
                        }),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: T.s16),
                hairline(),
                const SizedBox(height: T.s16),
                Row(
                  children: [
                    _transportPill('walk', tr('tp_walk')),
                    const SizedBox(width: 8),
                    _transportPill('bus', tr('tp_bus')),
                    const SizedBox(width: 8),
                    _transportPill('car', tr('tp_car')),
                  ],
                ),
                const SizedBox(height: T.s12),
                PressButton(
                  text: tr('route_reshuffle'),
                  primary: false,
                  icon: TIGlyph.dice,
                  onPressed: _reshuffle,
                ),
                const SizedBox(height: T.s12),
                Row(
                  children: [
                    Expanded(
                      child: GhostButton(
                        text: tr('route_show_map'),
                        small: true,
                        icon: TIGlyph.routePath,
                        onPressed: _showOnMap,
                      ),
                    ),
                    const SizedBox(width: T.s8),
                    Expanded(
                      child: GhostButton(
                        text: tr('route_save'),
                        small: true,
                        icon: TIGlyph.check,
                        onPressed: _saveRoute,
                      ),
                    ),
                  ],
                ),
                if (_kind != 'evening') ...[
                  const SizedBox(height: T.s12),
                  GhostButton(
                    text: tr('route_back_evening'),
                    small: true,
                    icon: TIGlyph.moon,
                    onPressed: () {
                      _seed++;
                      _buildEvening();
                      setState(() {});
                    },
                  ),
                ],
              ],
            ),
          ),
          if (_savedRoutes.isNotEmpty) ...[
            const SizedBox(height: T.s20),
            sectionLabel(tr('my_routes'),
                color: T.salmon, glyph: TIGlyph.routePath),
            for (final e in _savedRoutes)
              Pressable(
                onTap: () => _activateSaved(e),
                child: Container(
                  margin: const EdgeInsets.only(bottom: T.s8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: T.s16, vertical: T.s12),
                  decoration: BoxDecoration(
                    color: T.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _kind == 'saved' && _routeKey == _savedKey(e)
                          ? T.fire
                          : T.stroke,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TiradIcon(
                            e['transport'] == 'walk'
                                ? TIGlyph.walk
                                : (e['transport'] == 'bus'
                                    ? TIGlyph.bus
                                    : TIGlyph.car),
                            size: 15,
                            color: T.iconGray,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${e['cityName']} · ${e['day']}${e['counted'] == true ? tr('route_counted_suffix') : ''}',
                              style: T.body(13, w: FontWeight.w700),
                            ),
                          ),
                        ],
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
          if (groups.isNotEmpty) ...[
            const SizedBox(height: T.s20),
            sectionLabel(tr('ready_routes'),
                color: T.salmon, glyph: TIGlyph.routePath),
            for (final g in groups) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: T.s8, top: T.s4),
                child: Text(
                  g.$1.name,
                  style: T.body(12.5, color: T.muted, w: FontWeight.w700),
                ),
              ),
              for (final r in g.$2) _readyCard(r),
            ],
          ],
          const SizedBox(height: 20),
          if (_stops.isEmpty)
            Text(
              tr('route_no_places'),
              style: TextStyle(color: kMuted),
            ),
          if (_stops.isNotEmpty) ...[
            const SizedBox(height: T.s20),
            sectionLabel(tr('route_stops_title'),
                color: T.salmon, glyph: TIGlyph.routePath),
          ],
          if (_stops.isNotEmpty && _start != null)
            _legRow(_start!, _stops.first,
                fromLabel: _startIsCenter ? tr('from_center') : tr('from_you'),
                leg: 0),
          for (var i = 0; i < _stops.length; i++) ...[
            _stopCard(i, _stops[i]),
            if (i < _stops.length - 1)
              _legRow(LatLng(_stops[i].lat, _stops[i].lng), _stops[i + 1],
                  leg: i + 1),
          ],
          /* v2.0.14 (Item 7): the route's theme tasks as a real
             checklist — before, they were only printed inside the
             stop cards with nowhere to tick them. Persisted per
             route key, one-way, each tick = stats.tasks +1. */
          if (_stops.isNotEmpty) ...[
            const SizedBox(height: T.s20),
            Row(
              children: [
                Expanded(
                  child: sectionLabel(tr('route_tasks_title'),
                      color: T.salmon, glyph: TIGlyph.target),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    trf('progress_of',
                        {'a': _routeTasksDone.length, 'b': _stops.length}),
                    style: T.num(12.5, color: T.salmon),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(T.s16),
              decoration: cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _stops.length; i++) ...[
                    if (i > 0) const SizedBox(height: T.s12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DoneToggle(
                          done: _routeTasksDone.contains(i),
                          onComplete: () => _toggleRouteTask(i),
                        ),
                        const SizedBox(width: T.s12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _taskFor(i),
                              style: T.body(14,
                                  w: FontWeight.w600,
                                  color: _routeTasksDone.contains(i)
                                      ? T.muted
                                      : T.text),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          // v2.0.12: stop tracking this route — danger action under
          // the route card, in the app's button language.
          if (_stops.isNotEmpty) ...[
            const SizedBox(height: T.s24),
            DangerButton(
              text: tr('delete_route'),
              small: true,
              onPressed: _requestDeleteRoute,
            ),
          ],
        ],
      ),
    );
  }
}

/* One-way completion control (v2.0.14, Item 7) — THE checkbox the
   owner asked for («нету где поставить галочку»): daily task, city
   quest steps, weekly quest steps and route tasks all use this one
   control. One-way by design (anti-farm): once done it renders the
   filled state and takes no taps, so a completion can never be
   un-ticked and re-ticked for double XP; every parent persists the
   done state (day / ISO-bucket week / route key) and credits stats
   exactly once behind the same flag. */
class DoneToggle extends StatelessWidget {
  final bool done;
  final VoidCallback? onComplete;
  const DoneToggle({super.key, required this.done, this.onComplete});

  @override
  Widget build(BuildContext context) {
    final box = AnimatedContainer(
      duration: T.dMed,
      curve: T.cOut,
      width: 27,
      height: 27,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        gradient: done
            ? const LinearGradient(
                colors: [Color(0xFF2BD465), Color(0xFF16A34A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: done ? null : T.surfaceHi,
        border: Border.all(
          color: done ? Colors.transparent : T.faint,
          width: 1.6,
        ),
        boxShadow: done
            ? [
                BoxShadow(
                  color: T.online.withOpacity(0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: done
          ? const TiradIcon(TIGlyph.check,
              size: 15, color: Colors.white, filled: true)
          : null,
    );
    if (done || onComplete == null) return box;
    return Pressable(
      onTap: () {
        tickSelect();
        onComplete!();
      },
      child: box,
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
        tr('done_label'),
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
                    const TiradIcon(TIGlyph.bolt, size: 17, color: T.ember),
                    const SizedBox(width: 8),
                    Text(tr('steps_title'), style: T.head(15)),
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
                      ? tr('steps_no_access')
                      : trf('steps_info', {'n': 1000 - (steps % 1000), 'xp': xp}),
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
  /* v2.0.14: manual step ticks report into stats (questSteps per
     step, quests + the +50 bonus on completion) through these. */
  final VoidCallback? onStepDone;
  final VoidCallback? onQuestComplete;
  const CityQuestCard({
    super.key,
    required this.places,
    required this.city,
    this.onStepDone,
    this.onQuestComplete,
  });

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

  /* Manual tick of a step (the checkbox the owner asked for). The
     done-flag guard inside CityQuest.markStep makes double credit
     impossible; real actions (check-in/photo/fav) complete the same
     steps through CityQuest.mark. */
  Future<void> _tick(int i) async {
    final city = widget.city;
    if (city == null) return;
    final (changed, bonusDue) =
        await CityQuest.markStep(i, widget.places, city);
    if (!changed || !mounted) return;
    widget.onStepDone?.call();
    if (bonusDue) {
      widget.onQuestComplete?.call();
      fireConfetti(context);
      snack(context, tr('quest_done_snack'));
    }
    _reload();
  }

  String _stepLabel(Map<String, dynamic> st) {
    switch (st['kind']) {
      case 'checkin':
        return trf('cq_checkin', {'name': st['name']});
      case 'photo':
        return trf('cq_photo', {'name': st['name']});
      case 'fav':
        return trf('cq_fav', {'name': st['name']});
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
    final doneCount = steps.where((st) => st['done'] == true).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TiradIcon(TIGlyph.mapPin, size: 17, color: T.ember),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trf('cq_title', {'city': widget.city!.name}),
                  style: T.head(15),
                ),
              ),
              Text(
                trf('progress_of', {'a': doneCount, 'b': steps.length}),
                style: T.num(12.5, color: T.salmon),
              ),
              if (allDone) ...[
                const SizedBox(width: T.s8),
                const DonePill(),
              ],
            ],
          ),
          const SizedBox(height: T.s8),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1, right: 9),
                    child: DoneToggle(
                      done: steps[i]['done'] == true,
                      onComplete: () => _tick(i),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        _stepLabel(steps[i]),
                        style: T.body(
                          14,
                          color: steps[i]['done'] == true ? T.muted : T.text,
                          w: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            allDone ? tr('cq_done') : tr('cq_hint'),
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
      .firstOrNull ?? tr('place_word');

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
          snack(context, tr('tour_winner_snack'));
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleFire(Map<String, dynamic> ph) async {
    final uid = myUidOrNull;
    if (uid == null) {
      snack(context, tr('signin_to_fire'));
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
          Row(
            children: [
              const TiradIcon(TIGlyph.trophy, size: 17, color: T.ember),
              const SizedBox(width: 8),
              Text(tr('tour_title'), style: T.head(15)),
            ],
          ),
          const SizedBox(height: T.s4),
          Text(
            tr('tour_sub'),
            style: T.body(12, color: T.muted),
          ),
          const SizedBox(height: T.s12),
          if (!_loaded)
            const ShimmerBox(height: 64)
          else if (_photos.isEmpty)
            Text(
              tr('tour_empty'),
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
                            child: const Center(
                              child: TiradIcon(TIGlyph.ghost,
                                  size: 24, color: T.iconGray),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: T.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (leader) ...[
                                  const TiradIcon(TIGlyph.trophy,
                                      size: 14, color: T.gold, filled: true),
                                  const SizedBox(width: 5),
                                ],
                                Flexible(
                                  child: Text(
                                    _placeName(ph['place_id'].toString()),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        T.body(13.5, w: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              leader
                                  ? trf('tour_leader', {'ghost': ghostLabelFor(ph['user_id'].toString())})
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TiradIcon(TIGlyph.flame,
                                  size: 13,
                                  color: mine ? T.ember : T.iconGray,
                                  filled: mine),
                              const SizedBox(width: 4),
                              Text(
                                '$fires',
                                style: T.num(12.5,
                                    color: mine ? T.ember : T.text),
                              ),
                            ],
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
  /* v2.0.14: quest completions feed stats.questSteps / stats.quests
     (city quest steps + ticks, weekly quest steps + finish). */
  final VoidCallback? onQuestStep;
  final VoidCallback? onQuestDone;
  final List<Place> cityPlaces;
  final City? city;
  const TasksPage({
    super.key,
    required this.stats,
    required this.onTaskDone,
    required this.onAiXp,
    this.onQuestStep,
    this.onQuestDone,
    required this.cityPlaces,
    required this.city,
  });

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  List<dynamic> _daily = [];
  List<dynamic> _week = [];
  bool _dailyDone = false;
  /* Weekly quest ticks (v2.0.14, Item 7): persisted per rotation
     bucket — the same dayIndex()~/7 bucket that selects this week's
     quest — as 'week_done_<bucket>' (JSON step indices) plus a
     'week_counted_<bucket>' flag so the finish credits stats.quests
     exactly once. One-way ticks: no un-tick, no XP farming. */
  final Set<int> _weekDone = {};
  bool _weekCounted = false;
  SharedPreferences? _prefs;

  int get _weekBucket => dayIndex() ~/ 7;

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
    _dailyDone = _prefs!.getString('daily_done_day') == dayKey();
    try {
      final savedWeek = _prefs!.getString('week_done_$_weekBucket');
      if (savedWeek != null) {
        _weekDone.addAll(
            (jsonDecode(savedWeek) as List).map((e) => (e as num).toInt()));
      }
      _weekCounted = _prefs!.getBool('week_counted_$_weekBucket') ?? false;
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _daily = (data['daily'] as List?) ?? [];
      _week = (data['week'] as List?) ?? [];
    });
  }

  Future<void> _completeWeekStep(int i, int total) async {
    if (_weekDone.contains(i)) return;
    setState(() => _weekDone.add(i));
    await _prefs?.setString(
      'week_done_$_weekBucket',
      jsonEncode(_weekDone.toList()),
    );
    widget.onQuestStep?.call();
    if (total > 0 && _weekDone.length >= total && !_weekCounted) {
      _weekCounted = true;
      await _prefs?.setBool('week_counted_$_weekBucket', true);
      widget.onQuestDone?.call();
      if (mounted) {
        fireConfetti(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('week_quest_done'))),
        );
      }
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
        SnackBar(content: Text(tr('daily_task_done'))),
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
        : aiText(_daily[dayIndex() % _daily.length]);
    final weekQuest = _week.isEmpty
        ? null
        : (_week[(dayIndex() ~/ 7) % _week.length] as Map).cast<String, dynamic>();
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
                  Text(tr('tasks_book'), style: T.display(20)),
                ],
              ),
              /* v2.0.14 (Item 6): the «ИИ дня» block is GONE from the
                 presentation — in its place, the first-class
                 «Задание дня» card: today's task from the daily pool
                 in tasks.json, deterministic by date (same task all
                 day, rotating), completed with the shared DoneToggle.
                 The daily_drops pipeline itself (table + morning
                 cron) is untouched server-side; the client simply
                 presents «Задание дня» now. */
              sectionLabel(tr('daily_task_label'),
                  color: const Color(0xFFFF8A7A), glyph: TIGlyph.target),
              _taskCard(
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DoneToggle(done: _dailyDone, onComplete: _completeDaily),
                    const SizedBox(width: T.s12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          dailyTask ?? tr('loading'),
                          style: T.body(15,
                              w: FontWeight.w600,
                              color: _dailyDone ? T.muted : T.text),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CityQuestCard(
                places: widget.cityPlaces,
                city: widget.city,
                onStepDone: widget.onQuestStep,
                onQuestComplete: () {
                  widget.onQuestDone?.call();
                  widget.onAiXp(50); // same bonus as the action path
                },
              ),
              PhotoTournamentCard(
                places: widget.cityPlaces,
                onAiXp: widget.onAiXp,
              ),
              const StepsCard(),
              if (weekQuest != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: sectionLabel(
                          trf('week_quest_label',
                              {'t': aiText(weekQuest['theme'])}),
                          color: const Color(0xFFFF8A7A),
                          glyph: TIGlyph.calendar),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        trf('progress_of', {
                          'a': _weekDone.length,
                          'b': (weekQuest['steps'] as List? ?? []).length,
                        }),
                        style: T.num(12.5, color: T.salmon),
                      ),
                    ),
                  ],
                ),
                /* v2.0.14 (Item 7): weekly steps were plain text with
                   a red dot — nowhere to tick them. Now each step has
                   the shared DoneToggle, persisted for this rotation
                   bucket; the last tick credits the quest. */
                _taskCard(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0;
                          i < (weekQuest['steps'] as List? ?? []).length;
                          i++) ...[
                        if (i > 0) const SizedBox(height: T.s12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DoneToggle(
                              done: _weekDone.contains(i),
                              onComplete: () => _completeWeekStep(
                                  i,
                                  (weekQuest['steps'] as List? ?? [])
                                      .length),
                            ),
                            const SizedBox(width: T.s12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  aiText((weekQuest['steps'] as List)[i]),
                                  style: T.body(14,
                                      w: FontWeight.w600,
                                      color: _weekDone.contains(i)
                                          ? T.muted
                                          : T.text),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
  /* v2.0.12: the badge mark is a TI glyph, not an emoji. */
  final TIGlyph glyph;
  final String name, condition;
  final int current, threshold;
  const BadgeDef(this.glyph, this.name, this.condition, this.current, this.threshold);
  bool get unlocked => current >= threshold;
  double get progress =>
      threshold <= 0 ? 1 : (current / threshold).clamp(0.0, 1.0);
}

List<BadgeDef> badgesOf(Map<String, dynamic> stats) {
  final places = (stats['places'] as List?)?.length ?? 0;
  final streak = math.max(statInt(stats, 'streak'), statInt(stats, 'bestStreak'));
  return [
    BadgeDef(TIGlyph.moon, tr('b_first_night'), tr('c_1_night'), statInt(stats, 'nights'), 1),
    BadgeDef(TIGlyph.star, tr('lv_partier'), tr('c_5_nights'), statInt(stats, 'nights'), 5),
    BadgeDef(TIGlyph.compass, tr('b_explorer'), tr('c_10_places'), places, 10),
    BadgeDef(TIGlyph.camera, tr('b_photographer'), tr('c_1_photo'), statInt(stats, 'photos'), 1),
    BadgeDef(TIGlyph.eye, tr('b_eye'), tr('c_5_photos'), statInt(stats, 'photos'), 5),
    BadgeDef(TIGlyph.routePath, tr('b_router'), tr('c_3_routes'), statInt(stats, 'routes'), 3),
    BadgeDef(TIGlyph.landmark, tr('b_architect'), tr('c_10_routes'), statInt(stats, 'routes'), 10),
    BadgeDef(TIGlyph.flame, tr('b_streak3'), tr('c_streak3'), streak, 3),
    BadgeDef(TIGlyph.bolt, tr('b_streak7'), tr('c_streak7'), streak, 7),
    BadgeDef(TIGlyph.voteBox, tr('b_voice'), tr('c_10_votes'), statInt(stats, 'votes'), 10),
    BadgeDef(TIGlyph.target, tr('b_quester'), tr('c_1_quest'), statInt(stats, 'quests'), 1),
    BadgeDef(TIGlyph.trophy, tr('b_legend'), '1500 XP', xpOfStats(stats), 1500),
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
    TitleDef(tr('lv_wanderer'), '100 XP', xp >= 100),
    TitleDef(tr('lv_district_ghost'), '500 XP', xp >= 500),
    TitleDef(tr('t_explorer_city'), tr('c_25_places'), places >= 25),
    TitleDef(tr('b_architect'), tr('c_5_routes'), statInt(stats, 'routes') >= 5),
    TitleDef(tr('t_king'), tr('c_10_nights'), statInt(stats, 'nights') >= 10),
    TitleDef(tr('lv_night_legend'), '1500 XP', xp >= 1500),
    TitleDef(tr('lv_keeper'), '2500 XP', xp >= 2500),
  ];
}

/* The one title shown under the nick — highest earned wins. */
String? ghostTitle(Map<String, dynamic> stats, String cityName) {
  final xp = xpOfStats(stats);
  final places = (stats['places'] as List?)?.length ?? 0;
  if (xp >= 2500) return '${tr('lv_keeper')} · $cityName';
  if (xp >= 1500) return '${tr('lv_night_legend')} · $cityName';
  if (statInt(stats, 'nights') >= 10) return '${tr('t_king')} · $cityName';
  if (places >= 25) return '${tr('b_explorer')} · $cityName';
  if (statInt(stats, 'routes') >= 5) return '${tr('b_architect')} · $cityName';
  if (xp >= 500) return '${tr('ghost')} · $cityName';
  if (xp >= 100) return '${tr('lv_wanderer')} · $cityName';
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
                  Text(tr('badges_title'), style: T.display(19)),
                ],
              ),
              const SizedBox(height: T.s8),
              sectionLabel(
                trf('badges_open_count', {'n': badges.where((b) => b.unlocked).length, 'total': badges.length}),
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
                              child: TiradIcon(
                                b.glyph,
                                size: 26,
                                color: b.unlocked ? Colors.white : T.iconGray,
                                filled: b.unlocked,
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
                                ? tr('badge_open')
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
              sectionLabel(tr('city_titles'),
                  color: T.salmon, glyph: TIGlyph.landmark),
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
                            TiradIcon(
                              titles[i].unlocked
                                  ? TIGlyph.trophy
                                  : TIGlyph.lock,
                              size: 17,
                              color: titles[i].unlocked
                                  ? T.gold
                                  : T.faint,
                              filled: titles[i].unlocked,
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
                                child: Text(
                                  tr('your_title'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              )
                            else
                              Text(
                                titles[i].unlocked ? tr('title_open') : titles[i].hint,
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
              sectionLabel(tr('level_ladder'),
                  color: T.salmon, glyph: TIGlyph.bolt),
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
                                tr(kLevels[i].$2),
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
                                  ? trf('xp_left', {'n': nextXp - xp})
                                  : trf('xp_from', {'n': kLevels[i].$1}),
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
              sectionLabel(tr('top_ghosts'),
                  color: T.salmon, glyph: TIGlyph.trophy),
              if (!_signedIn)
                GlassCard(
                  gradientBorder: true,
                  child: Column(
                    children: [
                      const TiradIcon(TIGlyph.trophy,
                          size: 36, color: T.gold),
                      const SizedBox(height: T.s8),
                      Text(
                        tr('top_signin_title'),
                        textAlign: TextAlign.center,
                        style: T.head(15),
                      ),
                      const SizedBox(height: T.s4),
                      Text(
                        tr('top_signin_sub'),
                        textAlign: TextAlign.center,
                        style: T.body(12.5, color: T.muted),
                      ),
                      const SizedBox(height: T.s12),
                      FireButton(
                        text: tr('sign_in'),
                        small: true,
                        icon: TIGlyph.bolt,
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
                EmptyState(
                  glyph: TIGlyph.ghost,
                  title: tr('top_empty_title'),
                  hint: tr('top_empty_hint'),
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
                ? AvatarFace((row['avatar'] ?? '👻').toString(),
                    glyphSize: 20, emojiSize: 18)
                : null,
          ),
          const SizedBox(width: T.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${row['name'] ?? tr('ghost')}${mine ? tr('you_suffix') : ''}',
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

  /* (prefs key, kStr label key) — labels resolve through tr(). */
  static const _notifKinds = <(String, String)>[
    ('quest', 'notif_quest'),
    ('friends', 'notif_friends'),
    ('votes', 'notif_votes'),
    ('photos', 'notif_photos'),
    ('streak', 'notif_streak'),
    ('rain', 'notif_rain'),
    ('steps', 'notif_steps'),
  ];

  /* v2.0.12: one TI glyph per notification kind (settings rows). */
  static TIGlyph _notifGlyph(String kind) {
    switch (kind) {
      case 'quest':
        return TIGlyph.mapPin;
      case 'friends':
        return TIGlyph.ghost;
      case 'votes':
        return TIGlyph.voteBox;
      case 'photos':
        return TIGlyph.camera;
      case 'streak':
        return TIGlyph.flame;
      case 'rain':
        return TIGlyph.cloudRain;
      case 'steps':
        return TIGlyph.bolt;
      default:
        return TIGlyph.bell;
    }
  }

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
        // Mirror into the bus so the header's profile button (outside
        // this tab) starts out showing the same guest face.
        GuestAvatarBus.photoPath.value = _guestAvatarPath;
        GuestAvatarBus.emoji.value = _guestEmoji;
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

  /* Notification self-test state (v2.0.14, Item 5). */
  String? _pushCheckResult;
  bool _pushChecking = false;

  /* Settings → «Проверить уведомления»: (1) re-ask the Android 13+
     permission, (2) re-register the FCM token for the signed-in
     user, (3) read back what the server actually holds in
     device_tokens, (4) fire a real local test notification so the
     display path is proven on screen, not just believed. */
  Future<void> _runPushCheck(void Function(VoidCallback) setPageState) async {
    if (_pushChecking) return;
    setPageState(() {
      _pushChecking = true;
      _pushCheckResult = null;
    });
    await PushService.ensurePermission();
    await LocalNotify.requestPermission();
    await PushService.registerCurrent();
    String status;
    if (myUidOrNull == null) {
      status = tr('notif_guest_push');
    } else {
      try {
        final s = await PushService.tokenStatus();
        if (s.count > 0) {
          final t = s.last?.toLocal();
          final when = t == null
              ? ''
              : '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')} '
                  '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
          status = trf('notif_token_ok', {'t': when});
        } else {
          status = tr('notif_token_none');
        }
      } catch (e) {
        debugPrint('TiradA device_tokens status failed: $e');
        status = tr('notif_token_none');
      }
    }
    final shown =
        await LocalNotify.show(tr('notif_test_title'), tr('notif_test_body'));
    if (!mounted) return;
    setPageState(() {
      _pushChecking = false;
      _pushCheckResult = shown ? status : tr('notif_token_none');
    });
  }

  /* Avatar editor: TI-glyph grid + «Фото из галереи». Signed-in users
     upload to the avatars bucket (<uid>/avatar.jpg) and set
     profiles.avatar_url; guests keep the picked photo on-device.
     v2.0.16: the grid offers the 12 TI glyphs of the owner's icon
     spec (stored as 'ti:<name>' tokens via _setEmojiAvatar, which
     just persists the string) instead of stock emoji. The current
     value is highlighted: a stored token selects its glyph
     (ActiveIconBadge); a legacy emoji value selects nothing in the
     grid — it stays the user's avatar until they pick a glyph or a
     photo. */
  void _showAvatarSheet() {
    final signedIn = supa.auth.currentUser != null;
    final current =
        signedIn ? (widget.profile?['avatar'] as String?) : _guestEmoji;
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
              Text(tr('avatar_sheet_title'), style: T.head(16)),
              const SizedBox(height: T.s12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final g in kAvatarGlyphs)
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        _setEmojiAvatar(tiAvatarToken(g));
                      },
                      child: tiAvatarToken(g) == current
                          ? ActiveIconBadge(glyph: g, size: 48)
                          : Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: T.surfaceHi,
                                border: Border.all(color: T.stroke),
                              ),
                              child: TiradIcon(g, size: 26),
                            ),
                    ),
                ],
              ),
              const SizedBox(height: T.s16),
              FireButton(
                text: tr('photo_from_gallery'),
                small: true,
                icon: TIGlyph.photo,
                onPressed: () {
                  Navigator.of(context).pop();
                  _pickGalleryAvatar();
                },
              ),
              if (!signedIn) ...[
                const SizedBox(height: T.s8),
                Text(
                  tr('guest_photo_note'),
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
      GuestAvatarBus.emoji.value = e;
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
    final Uint8List? bytes;
    try {
      bytes = await pickAndProcessImage(ImageSource.gallery);
    } on ImagePickException catch (e) {
      debugPrint('TiradA avatar pick failed: $e');
      if (mounted) snack(context, tr('photo_pick_fail'));
      return;
    }
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
        GuestAvatarBus.photoPath.value = f.path;
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
      if (mounted) snack(context, tr('avatar_updated'));
    } catch (_) {
      if (mounted) snack(context, tr('avatar_fail'));
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

  Widget _socialButton(TIGlyph glyph, String url) => GestureDetector(
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
          child: TiradIcon(glyph, size: 24, color: T.iconGray),
        ),
      );

  Widget _creatorRow(TIGlyph glyph, String name, String handle,
      {bool main = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          // v2.0.12: the main creator's medallion is the spec's active
          // badge (white filled star on the glowing gradient circle);
          // the others keep the quiet gray medallion with a TI glyph.
          if (main)
            ActiveIconBadge(glyph: glyph, size: 44)
          else
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kSurface2,
                border: Border.all(color: kBorder),
              ),
              child: TiradIcon(glyph, size: 21, color: T.iconGray),
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
              child: Text(
                tr('main_creator'),
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

  /* Dedicated Creators page (v2.0.10): everything that used to sit
     inline at the bottom of the profile — neon logo, version caption,
     tagline, «Мы на связи» socials and the «Сделали призраки» list —
     moved behind the profile's one remaining button, «👻 Создатели».
     Content and order are unchanged from the old About block. */
  void _openCreators() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _creatorsPage()),
    );
  }

  Widget _creatorsPage() {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Builder(
            builder: (pageCtx) => ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: T.text),
                      onPressed: () => Navigator.of(pageCtx).pop(),
                    ),
                    Text(tr('creators_title'), style: T.head(19)),
                  ],
                ),
                const SizedBox(height: 10),
                Center(child: glowIcon(118)),
                const SizedBox(height: 12),
                Text(
                  'TiradA anon · 2.0.16',
                  textAlign: TextAlign.center,
                  style: T.body(11.5, color: T.faint),
                ),
                const SizedBox(height: 10),
                Text(
                  tr('app_tagline'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kMuted, fontSize: 14, height: 1.45),
                ),
                const SizedBox(height: 22),
                Center(child: sectionLabel(tr('we_on_air'))),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialButton(
                        TIGlyph.paperPlane, 'https://t.me/anoncarmiel'),
                    const SizedBox(width: 16),
                    _socialButton(TIGlyph.camera,
                        'https://www.instagram.com/black_prince_1.8'),
                    const SizedBox(width: 16),
                    _socialButton(TIGlyph.musicNote,
                        'https://www.tiktok.com/@black_prince_1.8'),
                  ],
                ),
                const SizedBox(height: 24),
                sectionLabel(tr('made_by_ghosts')),
                _creatorRow(TIGlyph.star, 'Яша', '@black_prince_18',
                    main: true),
                const Divider(color: Color(0xFF26262E), height: 1),
                _creatorRow(TIGlyph.bolt, 'Вард', '@WardDeveloper'),
                const Divider(color: Color(0xFF26262E), height: 1),
                _creatorRow(TIGlyph.heart, 'Сева', '@Severarin'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* ── Dedicated Settings page (v2.0.10, owner's word) ─────────────────
     The profile's inline «Настройки» (Вибрация кнопок) and
     «🔔 Уведомления» sections MOVED here, behind the «⚙️ Настройки»
     button, and a «Язык» switcher (ru/he/en) sits on top. Toggles bind
     the very same state/prefs as before — haptics via HomePage
     (haptics_on), notifications via notif_<key> prefs — so nothing
     about PushService behaviour changes. The page re-renders on
     language change (AnimatedBuilder on appLang) and on its own
     toggle taps (StatefulBuilder). */
  void _openSettings() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _settingsPage()),
    );
  }

  Widget _settingsPage() {
    const langOptions = <(String, String)>[
      ('ru', 'Русский'),
      ('he', 'עברית'),
      ('en', 'English'),
    ];
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: appLang,
            builder: (pageCtx, _) => StatefulBuilder(
              builder: (ctx, setPageState) => ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: T.text),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      Text(tr('settings'), style: T.head(19)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  sectionLabel(tr('language'), glyph: TIGlyph.globe),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: T.s16, vertical: T.s4),
                    decoration: cardDecoration(),
                    child: Column(
                      children: [
                        for (var i = 0; i < langOptions.length; i++) ...[
                          if (i > 0) hairline(opacity: 0.6),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setAppLang(langOptions[i].$1),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: T.s12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      langOptions[i].$2,
                                      style:
                                          T.body(14, w: FontWeight.w600),
                                    ),
                                  ),
                                  if (appLang.value == langOptions[i].$1)
                                    const Icon(Icons.check,
                                        color: T.ember, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: T.s24),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: T.s16, vertical: T.s4),
                    decoration: cardDecoration(),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const TiradIcon(TIGlyph.phone,
                                size: 19, color: T.iconGray),
                            const SizedBox(width: T.s12),
                            Expanded(
                              child: Text(
                                tr('haptics_label'),
                                style: T.body(14, w: FontWeight.w600),
                              ),
                            ),
                            Switch(
                              value: widget.hapticsValue,
                              onChanged: (v) {
                                widget.onToggleHaptics(v);
                                setPageState(() {});
                              },
                              activeColor: T.ember,
                              activeTrackColor: T.fire.withOpacity(0.45),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: T.s24),
                  sectionLabel(tr('notif_section'),
                      color: T.salmon, glyph: TIGlyph.bell),
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
                              TiradIcon(
                                _notifGlyph(_notifKinds[i].$1),
                                size: 18,
                                color: T.iconGray,
                              ),
                              const SizedBox(width: T.s12),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: T.s8),
                                  child: Text(
                                    tr(_notifKinds[i].$2),
                                    style: T.body(14, w: FontWeight.w600),
                                  ),
                                ),
                              ),
                              Switch(
                                value: _notif[_notifKinds[i].$1] ?? true,
                                onChanged: (v) {
                                  _setNotif(_notifKinds[i].$1, v);
                                  setPageState(() {});
                                },
                                activeColor: T.ember,
                                activeTrackColor: T.fire.withOpacity(0.45),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  /* v2.0.14 (Item 5): notification self-test — is a
                     device token registered for this user on the
                     server, and does the display path work? Fires a
                     real local notification so the owner SEES it. */
                  const SizedBox(height: T.s24),
                  sectionLabel(tr('notif_check_title'),
                      color: T.salmon, glyph: TIGlyph.bell),
                  Container(
                    padding: const EdgeInsets.all(T.s16),
                    decoration: cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (myUidOrNull == null)
                          Text(
                            tr('notif_guest_push'),
                            style: T.body(13, color: T.muted),
                          )
                        else if (_pushCheckResult != null)
                          Text(
                            _pushCheckResult!,
                            style: T.body(13, color: T.muted),
                          ),
                        if (myUidOrNull == null || _pushCheckResult != null)
                          const SizedBox(height: T.s12),
                        GhostButton(
                          text: _pushChecking
                              ? tr('notif_checking')
                              : tr('notif_check_btn'),
                          small: true,
                          icon: TIGlyph.bell,
                          onPressed: _pushChecking
                              ? () {}
                              : () => _runPushCheck(setPageState),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final signedIn = supa.auth.currentUser != null;
    final p = widget.profile;
    final nick = signedIn ? ((p?['name'] as String?) ?? tr('ghost')) : tr('guest');
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
      tr('contrib_tasks'): statInt(s, 'tasks') * 20,
      tr('contrib_quest'): statInt(s, 'quests') * 100 + statInt(s, 'questSteps') * 15,
      tr('contrib_routes'): statInt(s, 'routes') * 40,
      tr('contrib_nights'): statInt(s, 'nights') * 30,
      tr('contrib_photos'): statInt(s, 'photos') * 25,
      tr('contrib_votes'): statInt(s, 'votes') * 5,
      tr('contrib_streak'): b * b * 2,
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
              TextSpan(text: tr('prof_title_a')),
              TextSpan(text: tr('prof_title_b'), style: T.display(21, color: T.ember)),
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
                    ? AvatarFace(avatarEmoji, glyphSize: 54, emojiSize: 52)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr('tap_ghost_hint'),
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
            final title = ghostTitle(s, widget.city?.name ?? tr('city_fallback'));
            if (title == null) {
              return Text(
                tr('no_title_yet'),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TiradIcon(TIGlyph.trophy,
                        size: 12, color: Colors.white, filled: true),
                    const SizedBox(width: 5),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 5),
          Text(
            tr('prof_motto'),
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, fontSize: 13.5),
          ),
          const SizedBox(height: 20),
          if (signedIn) ...[
            sectionLabel(tr('ghost_nick_label')),
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
            sectionLabel(tr('map_mode_label')),
            Wrap(
              spacing: 8,
              children: [
                for (final (v, label) in [
                  ('visible', tr('mode_visible')),
                  ('ghost', tr('mode_ghost')),
                  ('offline', tr('mode_offline')),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TiradIcon(
                            v == 'visible'
                                ? TIGlyph.eye
                                : (v == 'ghost'
                                    ? TIGlyph.ghost
                                    : TIGlyph.lock),
                            size: 14,
                            color: mode == v ? Colors.white : T.iconGray,
                            filled: mode == v,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ] else ...[
            PressButton(
              text: tr('signin_create'),
              icon: TIGlyph.bolt,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LoginPage()),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('account_why'),
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
          Row(
            children: [
              _statCard('${statInt(s, 'nights')}', tr('stat_nights')),
              const SizedBox(width: 8),
              _statCard('$visited', tr('stat_places_opened')),
              const SizedBox(width: 8),
              _statCard('${statInt(s, 'routes')}', tr('stat_routes_built')),
              const SizedBox(width: 8),
              _statCard('${statInt(s, 'photos')}', tr('stat_photos_city')),
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
                      ? tr('max_level')
                      : trf('to_level', {'n': lvNum + 1, 'name': nextName, 'xp': nextXp - xp}),
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
                      const TiradIcon(TIGlyph.flame,
                          size: 17, color: T.ember, filled: true),
                      const SizedBox(width: 7),
                      Text(trf('streak_line', {'n': streak}),
                          style: T.head(15)),
                      const Spacer(),
                      Text(
                        trf('record', {'n': bestStreak}),
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
                              child: filled(i)
                                  ? const TiradIcon(TIGlyph.flame,
                                      size: 15,
                                      color: Colors.white,
                                      filled: true)
                                  : const Text(
                                      '·',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: T.faint,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: T.s4),
                            Text(
                              [tr('wd_1'), tr('wd_2'), tr('wd_3'), tr('wd_4'), tr('wd_5'), tr('wd_6'), tr('wd_7')][i],
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
                  text: tr('tasks_book'),
                  icon: TIGlyph.target,
                  onPressed: widget.onOpenTasks,
                ),
              ),
              const SizedBox(width: T.s12),
              Expanded(
                child: GhostButton(
                  text: tr('badges_title'),
                  icon: TIGlyph.trophy,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BadgesPage(
                        stats: s,
                        cityName: widget.city?.name ?? tr('city_fallback'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          sectionLabel(tr('favorites_label'),
              color: const Color(0xFFFF8A7A), glyph: TIGlyph.heart),
          if (favPlaces.isEmpty)
            Text(
              tr('favorites_empty'),
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
                  TiradIcon(typeGlyph(fp.type), size: 19, color: T.iconGray),
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
              text: tr('sign_out'),
              primary: false,
              onPressed: () => supa.auth.signOut(),
            ),
          ],
          const SizedBox(height: T.s24),
          sectionLabel(tr('ghost_card_label'), color: T.salmon),
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
                            trf('level_line', {'n': lvNum, 'name': lvName, 'xp': xp}),
                            style: T.body(12.5, color: T.muted),
                          ),
                          Text(
                            widget.city?.name ?? '',
                            style: T.body(12.5, color: T.muted),
                          ),
                        ],
                      ),
                    ),
                    const TiradIcon(TIGlyph.ghost,
                        size: 28, color: T.iconGray),
                  ],
                ),
                const SizedBox(height: T.s12),
                GhostButton(
                  text: tr('share_card'),
                  icon: TIGlyph.share,
                  small: true,
                  onPressed: () => shareWithXp(
                    context,
                    trf('share_card_text', {
                      'nick': nick,
                      'num': number,
                      'n': lvNum,
                      'name': lvName,
                      'xp': xp,
                      'city': widget.city?.name ?? '',
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: T.s16),
          Text(
            'TiradA anon · 2.0.16',
            textAlign: TextAlign.center,
            style: T.body(11.5, color: T.faint),
          ),
          const SizedBox(height: 20),
          /* Two dedicated pages (v2.0.10, owner's word): Settings —
             language, vibration and all notification toggles moved
             there out of this scroll; Creators — the about page. The
             «О приложении» and «Политика конфиденциальности» buttons
             are gone. */
          PressButton(
            text: tr('settings_btn'),
            small: true,
            primary: false,
            icon: TIGlyph.gear,
            onPressed: _openSettings,
          ),
          const SizedBox(height: 10),
          PressButton(
            text: tr('creators_btn'),
            small: true,
            primary: false,
            icon: TIGlyph.ghost,
            onPressed: _openCreators,
          ),
        ],
      ),
    );
  }
}

// TiradA anon — native app (Flutter), v2.0.29.
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

/* v2.0.25: my own visibility mode ('visible' · 'ghost' · 'offline'),
   mirrored app-wide. HomePage owns the profile and keeps this in
   sync (load + every onProfileChanged); MapTab's presence writer and
   me-marker and LocationService's background gate read it here. */
final ValueNotifier<String> myModeNotifier = ValueNotifier<String>('visible');

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
  /* v2.0.25: whether the live stream runs as an Android foreground
     service (background location), and whether the second-step
     "always" permission has been asked this session. */
  static bool _fgsStream = false;
  static bool _bgAsked = false;

  /* Signed-in + «Невидимка»: no stream at all — the owner must not
     broadcast (or even track) a position he chose to hide. */
  static bool get _iAmHidden =>
      myUidOrNull != null && myModeNotifier.value == 'offline';

  static void _startStream({required bool fgs}) {
    _fgsStream = fgs;
    final LocationSettings settings = fgs
        ? AndroidSettings(
            accuracy: LocationAccuracy.medium,
            distanceFilter: 25,
            intervalDuration: const Duration(seconds: 30),
            foregroundNotificationConfig: ForegroundNotificationConfig(
              notificationTitle: 'TiradA anon',
              notificationText: tr('bg_loc_note'),
              enableWakeLock: false,
              /* v2.0.27: as quiet as Android allows (owner's decision:
                 the «Ты на радаре» entry STAYS but minimal). The
                 plugin itself creates its channel at IMPORTANCE_NONE
                 — no sound, no vibration, no heads-up, no status-bar
                 icon; that is the floor for a foreground service, and
                 geolocator exposes no importance/priority knob to
                 Dart at all. setOngoing stays FALSE so the entry is
                 dismissible (the service keeps running after a
                 swipe-away). What still shows in the shade is
                 Android's system-enforced minimum for any FGS. */
              setOngoing: false,
            ),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.medium,
            distanceFilter: 25,
          );
    try {
      _sub = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        (pos) {
          myLocationNotifier.value = LatLng(pos.latitude, pos.longitude);
        },
        onError: (_) {},
      );
    } catch (_) {
      _sub = null;
      _fgsStream = false;
    }
    /* v2.0.27: the heartbeat lives and dies with the foreground-
       service stream — see _heartbeatTick. */
    if (_fgsStream) {
      _startHeartbeat();
    } else {
      _stopHeartbeat();
    }
  }

  static Future<void> _stopStream() async {
    _stopHeartbeat();
    try {
      await _sub?.cancel();
    } catch (_) {}
    _sub = null;
    _fgsStream = false;
  }

  /* v2.0.27: the ONE presence write, shared by MapTab's 30 s cycle
     (its _presence() delegates here) and the background heartbeat
     below — one path, one semantics. Stamps _lastPresenceWriteAt on
     a successful position upsert so the heartbeat can avoid
     double-writes. */
  static DateTime? _lastPresenceWriteAt;

  /* v2.0.28: WHY friends can't see me, as a live state for the Map
     tab's honesty banner: null = sharing works (or doesn't apply —
     guest / «Невидимка»), otherwise 'denied' (app permission off,
     still askable), 'permanent' (permission off for good — only the
     system settings can undo it) or 'gps_off' (location services off
     on the phone). A signed-in visible/ghost user with NO location
     row was invisible to everyone while profiles.online said true
     (owner, live: «все друг друга видят») — the failure was silent
     on every surface. Now refreshShareIssue() computes the state,
     kickPresence() feeds it when a one-shot write can't run, and a
     successful syncPresence() write clears it. */
  static final ValueNotifier<String?> shareIssue =
      ValueNotifier<String?>(null);

  static Future<void> refreshShareIssue() async {
    try {
      if (myUidOrNull == null || _iAmHidden) {
        shareIssue.value = null;
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        shareIssue.value = 'gps_off';
        return;
      }
      final status = await Permission.location.status;
      if (status.isPermanentlyDenied) {
        shareIssue.value = 'permanent';
      } else if (!status.isGranted && !status.isLimited) {
        shareIssue.value = 'denied';
      } else {
        shareIssue.value = null;
      }
    } catch (_) {}
  }

  static Future<void> syncPresence() async {
    try {
      final uid = myUidOrNull;
      if (uid == null) return; // guest: nowhere to write presence
      /* v2.0.25: presence RESPECTS the mode. Before, this writer
         upserted a fresh location and online=true unconditionally —
         a «Невидимка» user kept broadcasting a live position (and
         showed as online) forever; only the map's render filter
         hid him. Now «Невидимка» deletes the location row and goes
         offline in the DB, so NO surface can place or count him. */
      if (myModeNotifier.value == 'offline') {
        await supa.from('profile_locations').delete().eq('user_id', uid);
        await supa.from('profiles').update({
          'online': false,
          'last_seen': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', uid);
        return;
      }
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
      _lastPresenceWriteAt = DateTime.now();
      // v2.0.28: a location write just landed — friends CAN see me,
      // so any sharing-issue banner state is stale by definition.
      shareIssue.value = null;
    } catch (_) {}
  }

  /* v2.0.28: guaranteed first location (owner: «все друг друга
     видят»). A brand-new signed-in user could stay invisible
     forever: presence writes rode on stream events and the map's
     30 s cycle, so with no fix in myLocationNotifier syncPresence()
     returned in silence and no profile_locations row ever landed.
     This one-shot runs right after sign-in/profile load and on the
     Map tab's first open, in addition to the stream/heartbeat:
     fresh fix → notifier → syncPresence(), within seconds, even
     standing still. Every failure path is silent in code (no crash,
     no throw to callers) but feeds shareIssue via
     refreshShareIssue(), so the Map banner can say WHY. */
  static Future<void> kickPresence() async {
    try {
      if (myUidOrNull == null || _iAmHidden) return;
      var status = await Permission.location.status;
      if (status.isDenied) {
        // Same first ask ensureLocation makes — kickPresence can be
        // the first location code to run after a fast profile load.
        status = await Permission.location.request();
      }
      if (!status.isGranted && !status.isLimited) {
        await refreshShareIssue();
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        await refreshShareIssue();
        return;
      }
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
        myLocationNotifier.value = LatLng(pos.latitude, pos.longitude);
      } catch (_) {
        await refreshShareIssue();
        return;
      }
      await syncPresence();
    } catch (_) {}
  }

  /* v2.0.27: background heartbeat (owner: «нужно чтоб оно всегда
     обновлялось»). The movement stream only fires after a 25 m move,
     so a user standing still went stale on friends' maps — the point
     just stopped refreshing. While background sharing is active
     (foreground-service stream running), a timer takes a FRESH fix
     every 5 minutes and writes it through syncPresence() — the same
     path the stream-fed MapTab cycle uses. Rules:
     · a presence write younger than ~2 min (movement stream via
       MapTab's cycle, or a previous heartbeat) → skip, no double-write;
     · the fix FAILS (timeout / GPS off) → write NOTHING. No cached
       fallback: a stale point must never get a fresh timestamp;
     · never for guests, never in «Невидимка» (the timer is cancelled
       with the stream anyway; the tick re-checks as a second lock).
     Started/stopped with the FGS stream in _startStream/_stopStream,
     so offline mode and sign-out (stopAll) kill it too. */
  static Timer? _heartbeat;

  static void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _heartbeatTick(),
    );
  }

  static void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  static Future<void> _heartbeatTick() async {
    try {
      if (myUidOrNull == null || _iAmHidden) return;
      final last = _lastPresenceWriteAt;
      if (last != null &&
          DateTime.now().difference(last) < const Duration(minutes: 2)) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      myLocationNotifier.value = LatLng(pos.latitude, pos.longitude);
      await syncPresence();
    } catch (_) {
      // Failed fix: no write — see the rules above.
    }
  }

  /* v2.0.25: stop everything (sign-out, «Невидимка»). Cancelling the
     subscription also tears down the foreground service and its
     persistent notification. */
  static Future<void> stopAll() => _stopStream();

  /* v2.0.25: reconcile the stream with the sharing state.
     Signed-in + visible/ghost → the stream must be the foreground-
     service one so the position keeps updating while the app is
     backgrounded; the "always" (background) permission is requested
     here, as the second step after the foreground one (Android
     rules), at most once per session. Signed-out or «Невидимка» →
     no stream. Guests keep the plain foreground-only stream that
     ensureLocation started. */
  static Future<void> applySharing() async {
    try {
      final uid = myUidOrNull;
      if (uid == null) return; // guest: nothing to reconcile
      if (myModeNotifier.value == 'offline') {
        await _stopStream();
        return;
      }
      final status = await Permission.location.status;
      if (!status.isGranted && !status.isLimited) {
        return; // ensureLocation owns the first (foreground) ask
      }
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final always = await Permission.locationAlways.status;
      if (!always.isGranted && !_bgAsked) {
        _bgAsked = true;
        try {
          await Permission.locationAlways.request();
        } catch (_) {}
      }
      if (_sub != null && _fgsStream) return; // already background-live
      await _stopStream();
      _startStream(fgs: true);
    } catch (_) {}
  }

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
      if (_iAmHidden) return; // «Невидимка»: no stream, no fix
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
      /* Signed-in users share from the background too (foreground
         service); guests get the plain foreground-only stream. */
      _startStream(fgs: myUidOrNull != null);
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

/* =====================================================================
   v2.0.24 — realistic busyness («движ» % and «people here now»).

   The old model was 30 + rating/hash noise with a flat evening boost:
   every place sat at 30–60% around the clock, a cemetery-grade quiet
   park could read 55% at 3 AM, and the headcount re-rolled its seed
   every hour. The owner: «процент жарко вообще не выглядит
   реалистичным».

   The new model is ONE deterministic function of (place, time):
   - each category owns an hour-by-hour occupancy curve (fraction of
     a typical place's busy level) in three Israel-aware day tables:
     workday (Sun–Thu), Friday, Saturday (Shabbat);
   - a stable per-place popularity factor (seeded from the place id,
     tilted by real rating/reviews when the data has them) scales the
     curve inside the category's plausible band, and a hard per-
     category cap clamps it — only nightlife may pass ~90%, and only
     at its peak hours;
   - the curve is interpolated between hourly anchors and carries a
     slow, small deterministic wobble, so the number DRIFTS with time
     (a few points over 10–15 min on a slope) but never jumps or
     flickers between two views a minute apart;
   - the headcount is the same % of a per-place capacity seeded
     inside a per-category range, so % and people always agree.

   Friday nightlife (owner's correction): bars are packed on Friday
   EVENING — the Friday table stays quiet by day, climbs from ~19:00
   to the week's peak at 21:00–24:00 and eases after midnight
   (Saturday table, hours 0–2). Thursday night is the other big
   going-out night: a boost on Thu ≥19:00 plus a strong authored
   tail in the Friday table's hours 0–2. Saturday-night sessions run
   past midnight into Sunday 00:00–02:00 via satTail.
   ===================================================================== */

/* One category's day: three 24-anchor tables + plausibility limits. */
class _BusyProfile {
  final List<double> work, fri, sat;
  /* Sunday 00:00–02:00 anchors for nightlife: the Saturday-night
     session still running past midnight. */
  final List<double> satTail;
  final int capPct; // hard ceiling for the % of this category
  final int peopleLo, peopleHi; // plausible capacity range per place
  final bool nightlife, h24;
  const _BusyProfile(
    this.work,
    this.fri,
    this.sat, {
    this.satTail = const [0.02, 0.01, 0.01],
    required this.capPct,
    required this.peopleLo,
    required this.peopleHi,
    this.nightlife = false,
    this.h24 = false,
  });
}

/* Copy of [base] with per-hour overrides — builds Friday/Saturday
   tables out of the workday one where the shape mostly matches. */
List<double> _ov(List<double> base, Map<int, double> o) {
  final l = List<double>.of(base);
  o.forEach((h, v) => l[h] = v);
  return l;
}

final _cafeWork = <double>[
  .01, .01, .01, .01, .01, .02, .08, .38, .68, .82, .72, .58, //
  .62, .56, .46, .42, .48, .58, .66, .60, .48, .34, .18, .07
];
final _bpCafe = _BusyProfile(
  _cafeWork,
  _ov(_cafeWork, const {
    7: .45, 8: .78, 9: .88, 10: .85, 11: .78, 12: .62, 13: .40, 14: .22,
    15: .12, 16: .08, 17: .06, 18: .06, 19: .07, 20: .10, 21: .14, 22: .17,
    23: .12
  }),
  const [
    .01, .01, .01, .01, .01, .01, .01, .01, .02, .02, .03, .04, //
    .04, .04, .03, .03, .04, .08, .22, .45, .62, .58, .42, .25
  ],
  capPct: 88,
  peopleLo: 12,
  peopleHi: 55,
);

final _restWork = <double>[
  .06, .03, .01, .01, .01, .01, .02, .05, .10, .16, .24, .45, //
  .78, .88, .62, .36, .22, .28, .52, .82, .95, .90, .62, .32
];
final _bpRestaurant = _BusyProfile(
  _restWork,
  _ov(_restWork, const {
    11: .50, 12: .85, 13: .90, 14: .60, 15: .30, 16: .15, 17: .10, 18: .10,
    19: .14, 20: .20, 21: .24, 22: .20, 23: .12
  }),
  const [
    .08, .03, .01, .01, .01, .01, .01, .01, .01, .02, .02, .02, //
    .02, .02, .02, .02, .02, .05, .15, .45, .82, .95, .85, .55
  ],
  capPct: 92,
  peopleLo: 25,
  peopleHi: 120,
);

final _barWork = <double>[
  .55, .35, .15, .05, .02, .01, .01, .01, .02, .02, .03, .04, //
  .06, .06, .05, .05, .07, .12, .22, .38, .55, .68, .78, .82
];
final _bpBar = _BusyProfile(
  _barWork,
  // Friday: dead by day, the week's peak in the EVENING (owner).
  const [
    .82, .62, .38, .08, .03, .01, .01, .01, .02, .02, .03, .04, //
    .05, .05, .04, .03, .04, .08, .18, .38, .62, .85, .95, .97
  ],
  // Saturday: hours 0–2 are the Friday evening easing after midnight;
  // the day is shut, the night surges again.
  const [
    .55, .30, .12, .04, .02, .01, .01, .01, .01, .02, .02, .02, //
    .02, .02, .02, .02, .03, .05, .12, .30, .52, .74, .88, .95
  ],
  satTail: const [.88, .62, .32],
  capPct: 95,
  peopleLo: 30,
  peopleHi: 150,
  nightlife: true,
);

final _clubWork = <double>[
  .60, .40, .18, .05, .01, .01, .01, .01, .01, .01, .01, .02, //
  .02, .02, .02, .02, .02, .03, .04, .05, .08, .14, .30, .58
];
final _bpClub = _BusyProfile(
  _clubWork,
  const [
    .85, .65, .40, .10, .03, .01, .01, .01, .01, .01, .01, .01, //
    .02, .02, .02, .02, .02, .03, .05, .10, .22, .48, .78, .93
  ],
  const [
    .60, .35, .15, .05, .01, .01, .01, .01, .01, .01, .01, .01, //
    .01, .01, .01, .01, .02, .03, .05, .10, .22, .42, .70, .92
  ],
  satTail: const [.95, .78, .48],
  capPct: 97,
  peopleLo: 80,
  peopleHi: 400,
  nightlife: true,
);

final _hookahWork = <double>[
  .45, .25, .10, .03, .01, .01, .01, .02, .03, .04, .05, .06, //
  .07, .07, .09, .10, .13, .18, .28, .48, .66, .78, .83, .80
];
final _bpHookah = _BusyProfile(
  _hookahWork,
  _ov(_hookahWork, const {
    0: .70, 1: .50, 2: .25, 3: .08, 14: .06, 15: .06, 16: .08, 17: .12,
    18: .20, 19: .35, 20: .58, 21: .82, 22: .90, 23: .92
  }),
  const [
    .50, .28, .10, .03, .01, .01, .01, .01, .02, .02, .03, .03, //
    .03, .03, .04, .04, .06, .10, .18, .32, .55, .76, .86, .88
  ],
  satTail: const [.70, .50, .28],
  capPct: 85,
  peopleLo: 20,
  peopleHi: 80,
  nightlife: true,
);

final _parkWork = <double>[
  .01, .01, .01, .01, .01, .01, .06, .16, .30, .42, .48, .52, //
  .48, .44, .42, .46, .52, .55, .44, .30, .18, .10, .05, .02
];
final _bpPark = _BusyProfile(
  _parkWork,
  _ov(_parkWork, const {
    8: .40, 9: .55, 10: .62, 11: .65, 12: .60, 13: .50, 14: .40, 15: .32,
    16: .26, 17: .20, 18: .14, 19: .10, 20: .07, 21: .05, 22: .03, 23: .01
  }),
  _ov(_parkWork, const {
    7: .25, 8: .45, 9: .62, 10: .72, 11: .75, 12: .72, 13: .65, 14: .55,
    15: .50, 16: .50, 17: .48, 18: .38, 19: .26, 20: .16, 21: .09, 22: .04,
    23: .02
  }),
  capPct: 75,
  peopleLo: 80,
  peopleHi: 500,
);

final _beachWork = <double>[
  .01, .01, .01, .01, .01, .01, .04, .10, .22, .38, .55, .68, //
  .75, .78, .75, .70, .62, .50, .38, .24, .12, .06, .03, .01
];
final _bpBeach = _BusyProfile(
  _beachWork,
  _ov(_beachWork, const {
    9: .45, 10: .65, 11: .80, 12: .88, 13: .88, 14: .80, 15: .62, 16: .45,
    17: .30, 18: .18, 19: .10, 20: .05, 21: .03
  }),
  _ov(_beachWork, const {
    8: .30, 9: .50, 10: .70, 11: .85, 12: .92, 13: .92, 14: .88, 15: .80,
    16: .68, 17: .52, 18: .36, 19: .20, 20: .10, 21: .05, 22: .02
  }),
  capPct: 88,
  peopleLo: 150,
  peopleHi: 700,
);

final _viewWork = <double>[
  .01, .01, .01, .01, .01, .01, .03, .08, .15, .22, .28, .32, //
  .30, .28, .26, .28, .34, .48, .52, .35, .18, .10, .05, .02
];
final _bpView = _BusyProfile(
  _viewWork,
  _ov(_viewWork, const {
    9: .28, 10: .36, 11: .40, 12: .38, 13: .35, 14: .30, 17: .55, 18: .58,
    19: .40
  }),
  _ov(_viewWork, const {
    9: .28, 10: .36, 11: .40, 12: .38, 13: .35, 14: .30, 17: .55, 18: .58,
    19: .40
  }),
  capPct: 60,
  peopleLo: 15,
  peopleHi: 100,
);

final _cultureWork = <double>[
  .01, .01, .01, .01, .01, .01, .01, .02, .05, .18, .38, .45, //
  .42, .40, .38, .36, .38, .42, .45, .55, .58, .50, .30, .10
];
final _bpCulture = _BusyProfile(
  _cultureWork,
  _ov(_cultureWork, const {
    10: .42, 11: .48, 12: .45, 13: .38, 14: .25, 15: .12, 16: .08, 17: .08,
    18: .10, 19: .18, 20: .25, 21: .20, 22: .10, 23: .04
  }),
  _ov(_cultureWork, const {
    9: .15, 10: .40, 11: .48, 12: .46, 13: .42, 14: .38, 15: .36, 16: .38,
    17: .40, 18: .42, 19: .50, 20: .55, 21: .45, 22: .25, 23: .08
  }),
  capPct: 70,
  peopleLo: 40,
  peopleHi: 300,
);

final _sportWork = <double>[
  .01, .01, .01, .01, .01, .15, .45, .62, .55, .35, .28, .26, //
  .32, .30, .26, .30, .45, .68, .82, .85, .75, .55, .30, .10
];
final _bpSport = _BusyProfile(
  _sportWork,
  _ov(_sportWork, const {
    9: .32, 10: .30, 11: .28, 12: .25, 13: .18, 14: .10, 15: .05, 16: .03,
    17: .03, 18: .04, 19: .06, 20: .08, 21: .06, 22: .03, 23: .01
  }),
  const [
    .03, .01, .01, .01, .01, .01, .01, .02, .02, .02, .02, .02, //
    .02, .02, .02, .02, .03, .08, .20, .45, .62, .60, .40, .15
  ],
  capPct: 85,
  peopleLo: 30,
  peopleHi: 180,
);

final _marketWork = <double>[
  .01, .01, .01, .01, .01, .02, .15, .45, .68, .75, .72, .65, //
  .58, .50, .40, .30, .22, .15, .10, .06, .03, .02, .01, .01
];
final _bpMarket = _BusyProfile(
  _marketWork,
  _ov(_marketWork, const {
    6: .20, 7: .60, 8: .85, 9: .90, 10: .85, 11: .75, 12: .60, 13: .40,
    14: .20, 15: .08, 16: .03, 17: .03, 18: .02, 19: .02, 20: .01
  }),
  const [
    .01, .01, .01, .01, .01, .01, .01, .01, .01, .01, .01, .01, //
    .01, .01, .01, .01, .02, .02, .04, .10, .20, .22, .15, .06
  ],
  capPct: 80,
  peopleLo: 100,
  peopleHi: 450,
);

final _retailWork = <double>[
  .01, .01, .01, .01, .01, .01, .01, .02, .04, .20, .45, .58, //
  .62, .60, .55, .52, .55, .62, .68, .70, .62, .40, .15, .04
];
final _bpRetail = _BusyProfile(
  _retailWork,
  _ov(_retailWork, const {
    9: .30, 10: .60, 11: .72, 12: .75, 13: .60, 14: .30, 15: .10, 16: .04,
    17: .03, 18: .03, 19: .05, 20: .08, 21: .10, 22: .06, 23: .02
  }),
  const [
    .01, .01, .01, .01, .01, .01, .01, .01, .01, .01, .01, .01, //
    .01, .01, .01, .01, .01, .03, .10, .35, .60, .70, .55, .30
  ],
  capPct: 85,
  peopleLo: 200,
  peopleHi: 1200,
);

final _h24Table = <double>[
  .20, .18, .16, .15, .15, .17, .20, .24, .28, .30, .30, .30, //
  .30, .30, .29, .28, .28, .29, .30, .30, .29, .27, .24, .22
];
final _bpH24 = _BusyProfile(
  _h24Table,
  _h24Table,
  _h24Table,
  capPct: 40,
  peopleLo: 60,
  peopleHi: 300,
  h24: true,
);

final _eduWork = <double>[
  .01, .01, .01, .01, .01, .01, .02, .30, .65, .70, .68, .66, //
  .60, .58, .50, .40, .30, .20, .12, .08, .05, .03, .01, .01
];
final _bpEducation = _BusyProfile(
  _eduWork,
  _ov(_eduWork, const {
    8: .62, 9: .65, 10: .60, 11: .55, 12: .45, 13: .25, 14: .08, 15: .02,
    16: .02, 17: .02, 18: .01, 19: .01, 20: .01, 21: .01
  }),
  const [
    .01, .01, .01, .01, .01, .01, .01, .01, .01, .01, .01, .01, //
    .01, .01, .01, .01, .01, .01, .02, .02, .02, .02, .01, .01
  ],
  capPct: 80,
  peopleLo: 200,
  peopleHi: 800,
);

final _relWork = <double>[
  .01, .01, .01, .01, .01, .02, .05, .10, .12, .08, .05, .04, //
  .04, .04, .04, .04, .05, .08, .12, .10, .06, .03, .02, .01
];
final _bpReligious = _BusyProfile(
  _relWork,
  _ov(_relWork, const {
    16: .08, 17: .20, 18: .35, 19: .40, 20: .25, 21: .10, 22: .04
  }),
  _ov(_relWork, const {
    7: .15, 8: .30, 9: .50, 10: .55, 11: .45, 12: .25, 13: .10, 14: .06,
    15: .05, 16: .08, 17: .15, 18: .12, 19: .06, 20: .04
  }),
  capPct: 55,
  peopleLo: 30,
  peopleHi: 200,
);

final _memorialTable = <double>[
  .005, .005, .005, .005, .005, .005, .010, .015, .020, .025, .025, .025, //
  .020, .020, .020, .020, .020, .015, .010, .008, .005, .005, .005, .005
];
final _bpMemorial = _BusyProfile(
  _memorialTable,
  _memorialTable,
  _memorialTable,
  capPct: 8,
  peopleLo: 20,
  peopleHi: 120,
);

final _genericWork = <double>[
  .01, .01, .01, .01, .01, .01, .02, .05, .10, .20, .30, .35, //
  .36, .34, .30, .28, .30, .34, .36, .34, .28, .18, .09, .04
];
final _bpGeneric = _BusyProfile(
  _genericWork,
  _ov(_genericWork, const {
    14: .22, 15: .15, 16: .10, 17: .07, 18: .06, 19: .07, 20: .09, 21: .08,
    22: .05, 23: .02
  }),
  const [
    .01, .01, .01, .01, .01, .01, .01, .02, .03, .05, .08, .10, //
    .10, .09, .08, .07, .07, .08, .12, .22, .30, .30, .22, .10
  ],
  capPct: 65,
  peopleLo: 15,
  peopleHi: 90,
);

/* Every place type in the data (plus plausible future ones) maps onto
   a profile; anything unknown lands on the generic daytime shape. */
_BusyProfile _busyProfileOf(String type) {
  switch (type) {
    case 'cafe':
      return _bpCafe;
    case 'restaurant':
      return _bpRestaurant;
    case 'bar':
      return _bpBar;
    case 'club':
      return _bpClub;
    case 'hookah':
      return _bpHookah;
    case 'park':
      return _bpPark;
    case 'beach':
      return _bpBeach;
    case 'view':
      return _bpView;
    case 'culture':
      return _bpCulture;
    case 'sport':
    case 'gym':
    case 'fitness':
      return _bpSport;
    case 'market':
      return _bpMarket;
    case 'shop':
    case 'mall':
    case 'store':
      return _bpRetail;
    case 'hospital':
    case 'pharmacy':
    case 'clinic':
    case 'gas':
    case 'fuel':
      return _bpH24;
    case 'school':
    case 'university':
    case 'college':
      return _bpEducation;
    case 'synagogue':
    case 'church':
    case 'mosque':
    case 'religious':
      return _bpReligious;
    case 'cemetery':
    case 'memorial':
      return _bpMemorial;
    default:
      return _bpGeneric;
  }
}

/* One hourly anchor, with the Sunday-past-midnight nightlife tail. */
double _busyAnchorAt(_BusyProfile prof, int weekday, int hour) {
  if (prof.nightlife && weekday == DateTime.sunday && hour < 3) {
    return prof.satTail[hour];
  }
  final t = weekday == DateTime.friday
      ? prof.fri
      : (weekday == DateTime.saturday ? prof.sat : prof.work);
  return t[hour];
}

/* The category curve at [now], interpolated between hourly anchors
   (wrapping into the next day's table at 23:xx) — no steps, ever. */
double _busyAnchor(_BusyProfile prof, DateTime now) {
  final t = now.hour + now.minute / 60.0 + now.second / 3600.0;
  final h0 = t.floor();
  final frac = t - h0;
  final wd = now.weekday;
  final a0 = _busyAnchorAt(prof, wd, h0);
  final nextWd = h0 == 23 ? (wd == DateTime.sunday ? 1 : wd + 1) : wd;
  final a1 = _busyAnchorAt(prof, nextWd, (h0 + 1) % 24);
  return a0 + (a1 - a0) * frac;
}

/* Stable per-place popularity, 0.35–1.30: seeded from the place id
   (identical on every launch). Where the data carries a real review
   footprint, the seed is BLENDED with a review-derived popularity
   (a place thousands of people reviewed is famous, full stop — it
   must not land at the bottom of the band on a hash coin flip); the
   rating adds a small tilt. A famous spot can near its category cap
   at peak; an obscure one never reads absurd. */
double _popOf(Place p) {
  var pop = 0.45 + (stableHash('${p.id}|pop') % 1000) / 1000.0 * 0.75;
  final rev = p.reviews;
  if (rev != null && rev > 0) {
    final revPop = 0.55 + 0.75 * (math.log(rev + 1) / math.log(2234));
    pop = (pop + revPop) / 2;
  }
  final r = p.rating;
  if (r != null) pop *= 0.92 + (r - 3.5) * 0.07;
  return pop.clamp(0.35, 1.30);
}

/* This place's plausible capacity, seeded inside its category range. */
int _capacityOf(Place p) {
  final prof = _busyProfileOf(p.type);
  return prof.peopleLo +
      stableHash('${p.id}|cap') % (prof.peopleHi - prof.peopleLo + 1);
}

/* «Сколько людей отдыхает сейчас» — the same % as vibeOf, applied to
   this place's capacity, so the two numbers can never disagree. */
int crowdOf(Place p) => (vibeOf(p) * _capacityOf(p) / 100).round();

/* Deterministic small hash (FNV-1a) — stable across runs. */
int stableHash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0x7fffffff;
  }
  return h;
}

/* «Движ» of a place right now, 0–100% — v2.0.24: the category day
   curve at the current minute × this place's stable popularity,
   plus a slow ±2-point deterministic wobble (4-hour period, seeded
   per place) so the number breathes instead of sitting frozen.
   Everything derives from (place id, current time) only — reopen
   the app at any moment and you get the current value, with no jump
   from the one a minute ago. See the model comment above crowdOf. */
int vibeOf(Place p) {
  final now = DateTime.now();
  final prof = _busyProfileOf(p.type);
  var anchor = _busyAnchor(prof, now);
  // Thursday night is a going-out night too: lift the nightlife
  // curve from 19:00 (its past-midnight tail is authored into the
  // Friday table's hours 0–2).
  if (prof.nightlife && now.weekday == DateTime.thursday && now.hour >= 19) {
    anchor *= 1.22;
  }
  var v = anchor * _popOf(p) * 100.0;
  final phase = (stableHash('${p.id}|wob') % 6283) / 1000.0;
  final mins = now.hour * 60.0 + now.minute + now.second / 60.0;
  v += math.sin(2 * math.pi * (mins / 240.0) + phase) * 2.2 * (0.25 + anchor);
  // Deep night: by 03:00 everything but genuine 24h places is shut.
  if (!prof.h24 && now.hour >= 3 && now.hour < 6) {
    v = math.min(v, 6);
  }
  return v.round().clamp(0, prof.capPct);
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
   triggers are a separate wiring (send-fcm) — this is the client.
   v2.0.26 ROOT-CAUSE FIX (owner: «тестовое уведомление работает, но
   обычные не приходят» — and the server held NO device_tokens row
   for him, ever): every stage of this chain used to fail into a
   bare `catch (_) {}` — registerCurrent() didn't even keep the
   error — and init() awaited requestPermission() FIRST, inside the
   same single try as the listener wiring and the first
   registration, so one throw/hang in the permission stage aborted
   the whole init. The write path itself is proven good (the exact
   upsert payload succeeds over REST; the shipped APK carries the
   full Firebase wiring and google_app_id), so the failure lived
   inside the Firebase calls on the handset and was invisible by
   construction. Now: each stage is isolated, registration never
   waits on the permission call, every failure is kept in
   [lastError] + the log, and the Settings check (probe()) reports
   each stage separately instead of one ambiguous line. */
class PushService {
  static final ValueNotifier<RemoteMessage?> foreground =
      ValueNotifier<RemoteMessage?>(null);
  static bool _inited = false;

  /* The last registration failure, verbatim — surfaced by the
     Settings notification check so a broken stage names itself
     instead of vanishing into a silent catch. */
  static String? lastError;

  static Future<void> init() async {
    if (_inited) return;
    _inited = true;
    // 1) Listeners first, each in its own try: no single failure
    //    may take the rest of the wiring down with it.
    try {
      FirebaseMessaging.onMessage.listen((msg) => foreground.value = msg);
      FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);
    } catch (e) {
      lastError = '$e';
      debugPrint('TiradA FCM listener wiring failed: $e');
    }
    // 2) A sign-in after a guest first launch is exactly when the
    //    token must land in device_tokens — and when the permission
    //    deserves a second ask if the first one was dismissed.
    try {
      supa.auth.onAuthStateChange.listen((state) {
        if (state.event == AuthChangeEvent.signedIn ||
            state.event == AuthChangeEvent.tokenRefreshed) {
          ensurePermission();
          registerCurrent();
        }
      });
    } catch (e) {
      debugPrint('TiradA FCM auth listener failed: $e');
    }
    // 3) Registration — deliberately NOT gated on the permission
    //    call (v2.0.26: it used to run after an awaited
    //    requestPermission() inside the same try, so a permission
    //    failure aborted registration for the whole session).
    await registerCurrent();
    // 4) The permission ask, last and separate.
    await ensurePermission();
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
    } catch (e) {
      debugPrint('TiradA FCM permission ask failed: $e');
    }
  }

  static Future<void> registerCurrent() async {
    try {
      final t = await FirebaseMessaging.instance.getToken();
      if (t == null) {
        // Was a bare catch (_) {} — a null/failed token died here
        // without a trace, at every call site, forever.
        lastError = 'getToken() returned null';
        debugPrint('TiradA FCM: getToken() returned null');
        return;
      }
      await _saveToken(t);
    } catch (e) {
      lastError = '$e';
      debugPrint('TiradA FCM getToken failed: $e');
    }
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
      lastError = null; // the full chain just succeeded end to end
    } catch (e) {
      lastError = 'device_tokens: $e';
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

  /* v2.0.26: staged probe for the Settings notification check —
     each stage of the registration chain reported on its own
     (Firebase initialised? permission? token fetched on THIS
     phone? the exact error when one stage fails), so the check
     stops being one ambiguous «token: yes/no» line. Fetching the
     token here doubles as another registration attempt. */
  static Future<
      ({
        bool firebase,
        bool permGranted,
        bool tokenOk,
        String? error,
      })> probe() async {
    var firebase = false;
    var permGranted = false;
    var tokenOk = false;
    String? error;
    try {
      firebase = Firebase.apps.isNotEmpty;
    } catch (e) {
      error = '$e';
    }
    try {
      final s = await FirebaseMessaging.instance.getNotificationSettings();
      permGranted =
          s.authorizationStatus == AuthorizationStatus.authorized ||
              s.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      error ??= '$e';
    }
    try {
      final t = await FirebaseMessaging.instance.getToken();
      tokenOk = t != null;
      if (t != null) {
        await _saveToken(t);
      } else {
        error ??= 'getToken() returned null';
      }
    } catch (e) {
      error = '$e';
    }
    error ??= lastError;
    return (
      firebase: firebase,
      permGranted: permGranted,
      tokenOk: tokenOk,
      error: error,
    );
  }
}

/* v2.0.26: real event pushes, client-triggered. The app never
   composes push text and never names recipients for these — it
   only tells send-fcm WHAT happened (an event + the id of the DB
   row that proves it), authenticated with the signed-in user's own
   Supabase JWT (functions.invoke attaches it automatically). The
   function validates the row server-side (sender == caller,
   fresh), derives the sender's display name/mode and the
   recipients from the database, and composes the text itself —
   so a client can never push in someone else's name or to an
   arbitrary audience. The webhook-secret path stays for server
   callers. Every call is fire-and-forget: a failed push must never
   fail or block the user action that caused it. */
class EventPush {
  static Future<void> _send(Map<String, dynamic> body, String what) async {
    try {
      await supa.functions.invoke('send-fcm', body: body);
    } catch (e) {
      debugPrint('TiradA event push ($what) failed: $e');
    }
  }

  /* A ping (hi / sticker) was just inserted — [pingId] is its row. */
  static void ping(String pingId) {
    _send({'event': 'ping', 'ping_id': pingId}, 'ping');
  }

  /* A place photo was just published — [photoId] is its
     place_photos row (the server-side check-in record carrying the
     Всем/Только друзьям consent; «Не показывать» creates no row,
     so it can never reach this call). */
  static void checkinPhoto(String photoId, String placeName) {
    _send(
      {'event': 'checkin_photo', 'photo_id': photoId, 'place_name': placeName},
      'checkin_photo',
    );
  }

  /* The plain «Я здесь» check-in (no server row of its own): the
     JWT is the signature — the function takes the sender's name
     and mode from the caller's own profile, requires a live
     presence row, and refuses outright for «Невидимка». */
  static void checkinPlace(Place place) {
    _send(
      {'event': 'checkin', 'place_id': place.id, 'place_name': place.name},
      'checkin',
    );
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

/* v2.0.24: the weekly quest follows the real calendar week,
   Sunday→Saturday (owner: «с воскресенье до субботы»). The old
   dayIndex()~/7 bucket counted 7-day blocks from the epoch, so it
   flipped every Thursday and the quest changed mid-week. weekId()
   is a stable integer per local calendar week: the epoch-day of
   this week's Sunday (weekday % 7 is the offset back to Sunday,
   Mon=1..Sun=7). Constant Sun..Sat, changes on Sunday. */
int weekId() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final sunday = today.subtract(Duration(days: now.weekday % 7));
  return sunday.millisecondsSinceEpoch ~/ 86400000;
}

String dayKeyOf(DateTime d) {
  String p(int n) => n < 10 ? '0$n' : '$n';
  return '${d.year}-${p(d.month)}-${p(d.day)}';
}

String dayKey() => dayKeyOf(DateTime.now());

/* ============================ STREAK ============================
   v2.0.25 REWORK. The v2.0.14 service stored only (count, best,
   last active day) — no per-day history existed, so the profile
   week strip INVENTED the past: it painted the last N days ending
   TODAY from the bare counter, in a Monday-first row. Yesterday's
   real completion landed on today's cell, a not-yet-done today
   already looked done, and missed days could never show as missed
   (owner: «я вчера выполнял задания, а огонь у меня стоит только
   на сегодня»).

   Now the truth is a per-day history in prefs ('streak_days' —
   JSON {yyyy-mm-dd: true} for days with at least one completed
   TASK, 'streak_since' — the first tracked day; pruned to ~60
   days, LOCAL dates via dayKeyOf). A day counts ONLY through
   markActive(), which HomePage calls from the same _bumpStat
   funnel that credits tasks/XP (daily task, AI-drop task, quest
   steps, quests; a place check-in also passes through it). A bare
   app open records nothing.

   The count, per the owner's rules: a missed day inside the
   tracked history is ICE — it shows as ice and does NOT break the
   run by itself, but the THIRD ice inside one calendar month
   zeroes the run from that day (done days after it start a new
   streak from 1); the ice counter resets each calendar month.
   Days before the history starts are unknown, never ice. Today
   pending changes nothing. best = the historical maximum run,
   never erased by a reset. HomePage mirrors (count, best) into
   stats — the single source the profile, badges and the
   xpOfStats streak bonus read — so everything stays consistent.

   Migration: the legacy (count, last) pair claimed «count
   consecutive active days ending at last» — exactly those days
   are marked done on first run. If prefs hold nothing but stats
   carry a streak, the old adopt-convention applies (that many
   days ending yesterday). Anything older is unrecoverable — the
   old storage never kept it — and is NOT invented. */
class StreakService {
  static const _kCount = 'streak_count';
  static const _kBest = 'streak_best';
  static const _kLast = 'streak_last_day';
  /* v2.0.25: the per-day history (see the section header). */
  static const _kDays = 'streak_days';
  static const _kSince = 'streak_since';

  /* Load the done-day set, running the legacy migration on first
     use (see header). [stats] is only a fallback seed source for
     reconcile() — prefs data always wins. */
  static Future<Set<String>> _loadDays(SharedPreferences prefs,
      [Map<String, dynamic>? stats]) async {
    final raw = prefs.getString(_kDays);
    if (raw != null) {
      try {
        return (jsonDecode(raw) as Map<String, dynamic>).keys.toSet();
      } catch (_) {}
    }
    final days = <String>{};
    var count = prefs.getInt(_kCount) ?? 0;
    var last = prefs.getString(_kLast) ?? '';
    if (count <= 0 && stats != null) {
      count = statInt(stats, 'streak');
      if (count > 0) {
        last = dayKeyOf(DateTime.now().subtract(const Duration(days: 1)));
      }
    }
    if (count > 0 && last.isNotEmpty) {
      final end = DateTime.tryParse(last);
      if (end != null) {
        for (var i = 0; i < count && i < 60; i++) {
          days.add(dayKeyOf(end.subtract(Duration(days: i))));
        }
      }
    }
    if (days.isNotEmpty) {
      await prefs.setString(
          _kDays, jsonEncode({for (final d in days) d: true}));
      await prefs.setString(
          _kSince, days.reduce((a, b) => a.compareTo(b) < 0 ? a : b));
    }
    return days;
  }

  static Future<void> _saveDays(
      SharedPreferences prefs, Set<String> days) async {
    final cutoff =
        dayKeyOf(DateTime.now().subtract(const Duration(days: 60)));
    days.removeWhere((d) => d.compareTo(cutoff) < 0);
    await prefs.setString(
        _kDays, jsonEncode({for (final d in days) d: true}));
  }

  /* (current, best) derived from the day history alone — see the
     section header for the exact rules (ice, 3rd-ice reset). */
  static (int, int) _compute(Set<String> days, String since, int bestFloor) {
    if (days.isEmpty || since.isEmpty) return (0, bestFloor);
    final start = DateTime.tryParse(since);
    if (start == null) return (0, bestFloor);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var run = 0;
    var best = bestFloor;
    var monthIce = 0;
    var curMonth = -1;
    var d = DateTime(start.year, start.month, start.day);
    while (!d.isAfter(today)) {
      final mk = d.year * 12 + d.month;
      if (mk != curMonth) {
        curMonth = mk;
        monthIce = 0;
      }
      if (days.contains(dayKeyOf(d))) {
        run++;
        if (run > best) best = run;
      } else if (d.isBefore(today)) {
        monthIce++;
        if (monthIce >= 3) run = 0; // third ice of the month: reset
      }
      d = d.add(const Duration(days: 1));
    }
    return (run, best);
  }

  /* Record a completed-task day (today) and return the (streak,
     best) to mirror into stats. Called ONLY from HomePage's
     completion funnel — never from app open. */
  static Future<(int, int)> markActive() async {
    final prefs = await SharedPreferences.getInstance();
    final days = await _loadDays(prefs);
    final today = dayKey();
    if (prefs.getString(_kSince) == null) {
      await prefs.setString(_kSince, today);
    }
    days.add(today);
    await _saveDays(prefs, days);
    final r = _compute(
        days, prefs.getString(_kSince) ?? today, prefs.getInt(_kBest) ?? 0);
    await prefs.setInt(_kCount, r.$1);
    await prefs.setInt(_kBest, r.$2);
    await prefs.setString(_kLast, today);
    return r;
  }

  /* Read-only view for display: derived from the same history, so
     the number can never drift from the week strip. A pending
     today does not zero the count. */
  static Future<(int, int)> current() async {
    final prefs = await SharedPreferences.getInstance();
    final days = await _loadDays(prefs);
    return _compute(
        days, prefs.getString(_kSince) ?? '', prefs.getInt(_kBest) ?? 0);
  }

  /* The done-day set + the first tracked day, for the week strip.
     Days before 'since' are unknown (never rendered as ice). */
  static Future<(Set<String>, String)> history() async {
    final prefs = await SharedPreferences.getInstance();
    final days = await _loadDays(prefs);
    return (days, prefs.getString(_kSince) ?? '');
  }

  /* Load-time reconciliation: run the migration (stats are the
     fallback seed), lift the best floor from the stats copy (the
     cloud may hold the record), and return the values stats
     should show. */
  static Future<(int, int)> reconcile(Map<String, dynamic> stats) async {
    final prefs = await SharedPreferences.getInstance();
    final days = await _loadDays(prefs, stats);
    if (days.isNotEmpty && prefs.getString(_kSince) == null) {
      await prefs.setString(
          _kSince, days.reduce((a, b) => a.compareTo(b) < 0 ? a : b));
    }
    final sBest =
        math.max(statInt(stats, 'bestStreak'), statInt(stats, 'streak'));
    if (sBest > (prefs.getInt(_kBest) ?? 0)) {
      await prefs.setInt(_kBest, sBest);
    }
    final cur = await current();
    await prefs.setInt(_kCount, cur.$1);
    await prefs.setInt(_kBest, cur.$2);
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
  'share_banner_perm': (
    'Друзья не видят тебя на карте: геолокация для приложения выключена',
    'החברים לא רואים אותך במפה: המיקום לאפליקציה כבוי',
    "Friends can't see you on the map: location is off for the app"
  ),
  'share_banner_gps': (
    'Друзья не видят тебя на карте: геолокация на телефоне выключена',
    'החברים לא רואים אותך במפה: שירותי המיקום בטלפון כבויים',
    "Friends can't see you on the map: location services are off on your phone"
  ),
  'share_banner_allow': ('Разрешить', 'אישור', 'Allow'),
  'me_no_position': (
    'Не получилось найти тебя на карте',
    'לא הצלחנו למצוא אותך במפה',
    "Couldn't find you on the map"
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
  /* v2.0.17: Friends tab, pings (приветы) and stickers. */
  /* v2.0.22: the owner renamed the system «Друзья» → «Общее» —
     the values below are the new wording; keys and code names keep
     the old 'friends' identifiers (wording change only). */
  'nav_friends': ('Общее', 'כללי', 'General'),
  'friends_search_hint': ('Поиск по нику…', 'חיפוש לפי כינוי…', 'Search by nickname…'),
  /* v2.0.21: one friends system — everyone registered is already
     a friend; the request-era keys (requests/accept/add/sent) are
     gone with the request UI. */
  'friends_none': ('Пока никого нет', 'אין כאן אף אחד עדיין', 'Nobody here yet'),
  'friends_none_hint': (
    'Как только кто-то зарегистрируется, он сразу появится здесь — список общий для всех.',
    'ברגע שמישהו נרשם, הוא יופיע כאן מיד — הרשימה משותפת לכולם.',
    'As soon as someone registers, they show up here — the list is shared by everyone.'
  ),
  'friends_all_note': (
    'Здесь все, кто зарегистрировался в приложении. Просто жми на призрака и кидай привет или стикер.',
    'כאן כל מי שנרשם לאפליקציה. פשוט לוחצים על רוח ושולחים היי או סטיקר.',
    'Everyone registered in the app is here. Just tap a ghost and send a hi or a sticker.'
  ),
  'friends_cancel': ('Отменить', 'ביטול', 'Cancel'),
  'friends_not_found': ('Никого не нашлось', 'לא נמצא אף אחד', 'Nobody found'),
  'friends_error': (
    'Что-то пошло не так — попробуй ещё раз',
    'משהו השתבש — נסה שוב',
    'Something went wrong — try again'
  ),
  'friends_guest': (
    'Войди в аккаунт — и здесь будут все люди приложения и твои приветы.',
    'היכנס לחשבון — וכל האנשים באפליקציה וההיי שלך יופיעו כאן.',
    'Sign in — and everyone in the app and your his will show up here.'
  ),
  'friends_list_title': ('Общее', 'כללי', 'General'),
  'ping_hi_btn': ('Привет', 'היי', 'Say hi'),
  'ping_sticker_btn': ('Стикер', 'סטיקר', 'Sticker'),
  'ping_sent_hi': ('Привет отправлен 👋', 'ההיי נשלח 👋', 'Hi sent 👋'),
  'ping_sent_sticker': ('Стикер отправлен', 'הסטיקר נשלח', 'Sticker sent'),
  'ping_signin': (
    'Войди, чтобы кидать приветы и стикеры',
    'היכנס כדי לשלוח היי וסטיקרים',
    'Sign in to send his and stickers'
  ),
  'ping_inbox_title': ('Приветы и стикеры', 'היי וסטיקרים', 'His & stickers'),
  'ping_inbox_empty': (
    'Пока пусто — тебе ещё не кидали приветов.',
    'ריק בינתיים — עוד לא שלחו לך היי.',
    'Empty for now — nobody has sent you a hi yet.'
  ),
  'ping_hi_text': ('👋 Привет!', '👋 היי!', '👋 Hi!'),
  /* v2.0.28: invites — a ping with a place attached (item H). */
  'invite_btn': ('Пригласить', 'להזמין', 'Invite'),
  'invite_place_btn': ('Пригласить куда-то', 'להזמין למקום', 'Invite to a place'),
  'invite_pick_person': ('Кого пригласить?', 'את מי להזמין?', 'Who to invite?'),
  'invite_pick_place': ('Куда пригласить?', 'לאן להזמין?', 'Where to invite?'),
  'invite_sent': ('Приглашение отправлено', 'ההזמנה נשלחה', 'Invite sent'),
  'invite_nobody': (
    'Пока некого приглашать',
    'אין עדיין את מי להזמין',
    'Nobody to invite yet'
  ),
  'invite_no_places': (
    'Места не нашлись',
    'לא נמצאו מקומות',
    'No places found'
  ),
  'ping_invite_text': (
    'приглашает тебя в «{place}»',
    'מזמין אותך ל«{place}»',
    'invites you to “{place}”'
  ),
  'ping_save': ('Сохранить', 'שמירה', 'Save'),
  'ping_saved': ('Сохранено', 'נשמר', 'Saved'),
  'ping_delete': ('Удалить', 'מחיקה', 'Delete'),
  /* v2.0.19: the «you got mail» sheet header — a frame filled with
     pluralized counted nouns (pingsSummary). */
  'ping_got_both': (
    'Тебе отправили: {hi} и {st}',
    'נשלחו אליך: {hi} ו{st}',
    'You got: {hi} and {st}'
  ),
  'ping_got_hi': ('Тебе отправили: {hi}', 'נשלחו אליך: {hi}', 'You got: {hi}'),
  'ping_got_st': (
    'Тебе отправили: {st}',
    'נשלחו אליך: {st}',
    'You got: {st}'
  ),
  'ping_n_hi_1': ('{n} привет', 'היי אחד', '{n} hi'),
  'ping_n_hi_2': ('{n} привета', 'שני היי', '{n} his'),
  'ping_n_hi_n': ('{n} приветов', '{n} היי', '{n} his'),
  'ping_n_st_1': ('{n} стикер', 'סטיקר אחד', '{n} sticker'),
  'ping_n_st_2': ('{n} стикера', 'שני סטיקרים', '{n} stickers'),
  'ping_n_st_n': ('{n} стикеров', '{n} סטיקרים', '{n} stickers'),
  'ping_got_ok': ('Отлично', 'מעולה', 'Great'),
  'sticker_pack_title': ('Стикеры', 'סטיקרים', 'Stickers'),
  'sticker_mine_title': ('Мои стикеры', 'הסטיקרים שלי', 'My stickers'),
  'sticker_from_gallery': ('Из галереи', 'מהגלריה', 'From gallery'),
  'sticker_delete_title': ('Удалить стикер?', 'למחוק את הסטיקר?', 'Delete this sticker?'),
  'sticker_delete_body': (
    'Он исчезнет из твоих стикеров.',
    'הוא ייעלם מהסטיקרים שלך.',
    'It will disappear from your stickers.'
  ),
  'sticker_pick_fail': (
    'Не получилось взять картинку — попробуй другую',
    'לא הצלחנו לקחת את התמונה — נסה אחרת',
    'Could not load that image — try another one'
  ),
  'sticker_upload_fail': (
    'Стикер не загрузился — проверь интернет и попробуй ещё раз',
    'הסטיקר לא עלה — בדוק את החיבור ונסה שוב',
    'The sticker did not upload — check your connection and try again'
  ),
  'sticker_save_fail': (
    'Стикер загрузился, но не сохранился — попробуй ещё раз',
    'הסטיקר עלה אבל לא נשמר — נסה שוב',
    'The sticker uploaded but did not save — try again'
  ),
  'sticker_created': ('Стикер готов 🎉', 'הסטיקר מוכן 🎉', 'Sticker ready 🎉'),
  'rel_now': ('только что', 'ממש עכשיו', 'just now'),
  'rel_min': ('{n} мин назад', 'לפני {n} דקות', '{n} min ago'),
  'rel_hour': ('{n} ч назад', 'לפני {n} שעות', '{n} h ago'),
  'rel_day': ('{n} д назад', 'לפני {n} ימים', '{n} d ago'),
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
    'Люди сейчас в деле · {n}',
    'אנשים שבפנים עכשיו · {n}',
    'People in right now · {n}'
  ),
  'deal_guest_note': (
    'Ты пока гость 👻 Войди в аккаунт — и здесь будут все, кто сейчас в деле.',
    'אתה אורח בינתיים 👻 היכנס לחשבון — וכאן יופיעו כל מי שנמצאים עכשיו בפנים.',
    "You're a guest for now 👻 Sign in — and everyone who is in will show up here."
  ),
  'deal_none': (
    'Пока никто не в деле. Будь первым 🔥',
    'אף אחד עוד לא בפנים. תהיה הראשון 🔥',
    'Nobody is in yet. Be the first 🔥'
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
  'crowd_friends': (' · люди рядом: {n}', ' · אנשים בקרבת מקום: {n}', ' · people nearby: {n}'),
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
  'cancel_route': ('Отменить маршрут', 'ביטול המסלול', 'Cancel route'),
  'deal_no_city': (
    'Город ещё не загрузился — попробуй через пару секунд',
    'העיר עדיין לא נטענה — נסה שוב בעוד כמה שניות',
    'The city has not loaded yet — try again in a few seconds'
  ),
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
  /* v2.0.26: staged notification-check lines (see _runPushCheck). */
  'notif_check_perm': ('Разрешение', 'הרשאה', 'Permission'),
  'notif_check_token': (
    'Токен на телефоне',
    'טוקן בטלפון',
    'Token on this phone'
  ),
  'notif_check_server': ('Токен на сервере', 'טוקן בשרת', 'Token on server'),
  'notif_check_display': (
    'Показ уведомлений',
    'הצגת התראות',
    'Notification display'
  ),
  'notif_check_error': ('Ошибка: {e}', 'שגיאה: {e}', 'Error: {e}'),
  'notif_st_yes': ('да', 'כן', 'yes'),
  'notif_st_no': ('нет', 'לא', 'no'),
  'notif_st_granted': ('разрешено', 'אושר', 'allowed'),
  'notif_st_denied': ('не разрешено', 'לא אושר', 'not allowed'),
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
  'nick_hint': ('От 2 до 20 символов', 'בין 2 ל־20 תווים', '2 to 20 characters'),
  'nick_taken': ('Этот ник уже занят', 'הכינוי הזה כבר תפוס', 'That nickname is already taken'),
  'nick_save_fail': ('Не удалось сохранить ник', 'לא ניתן היה לשמור את הכינוי', 'Could not save the nickname'),
  'nick_saved': ('Ник обновлён', 'הכינוי עודכן', 'Nickname updated'),
  'save_btn': ('Сохранить', 'שמירה', 'Save'),
  'cancel_btn': ('Отмена', 'ביטול', 'Cancel'),
  'map_mode_label': ('Режим на карте', 'מצב במפה', 'Map mode'),
  'mode_visible': ('Видимый', 'גלוי', 'Visible'),
  'mode_ghost': ('Призрак', 'רוח', 'Ghost'),
  'mode_offline': ('Невидимка', 'בלתי נראה', 'Invisible'),
  'bg_loc_hint': (
    'В режимах «Видимый» и «Призрак» местоположение обновляется даже в фоне — для этого нужно разрешение на геолокацию «Всегда». В «Невидимке» передача местоположения полностью останавливается.',
    'במצבים «גלוי» ו«רוח» המיקום ממשיך להתעדכן גם ברקע — לשם כך נדרשת הרשאת מיקום «תמיד». במצב «בלתי נראה» שידור המיקום נעצר לגמרי.',
    'In Visible and Ghost modes your location keeps updating in the background — that needs the “Always” location permission. In Invisible mode location sharing stops completely.'
  ),
  'bg_loc_note': (
    'Ты на радаре — местоположение обновляется',
    'אתה על הרדאר — המיקום מתעדכן',
    "You're on the radar — location updating"
  ),
  'signin_create': ('Войти / Создать аккаунт', 'כניסה / יצירת חשבון', 'Sign in / Create account'),
  'account_why': (
    'Аккаунт нужен для людей на карте, своего ника и синхронизации. Всё остальное работает и так.',
    'החשבון נדרש לאנשים במפה, לכינוי שלך ולסנכרון. כל השאר עובד גם ככה.',
    'An account is needed for people on the map, your own nickname and sync. Everything else works anyway.'
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
  'notif_friends': ('Люди в деле и онлайн', 'אנשים בפנים ומחוברים', 'People in and online'),
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
/* v2.0.28: the sort mark — two TI chevrons (up/down) standing in
   for the stock ↕ glyph the Places sort chip used to print as
   text (it rendered as a gray boxed system glyph, off-brand next
   to the TI chips). Drawn from the same monoline chevronBack,
   rotated into ∧ / ∨. */
class SortMark extends StatelessWidget {
  const SortMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: math.pi / 2,
          child: const TiradIcon(TIGlyph.chevronBack,
              size: 8, color: T.iconGray),
        ),
        Transform.rotate(
          angle: -math.pi / 2,
          child: const TiradIcon(TIGlyph.chevronBack,
              size: 8, color: T.iconGray),
        ),
      ],
    );
  }
}

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
  cloudRain, snow, snowflake, fog, storm, phone, globe, trash, users, voteBox,
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
      case TIGlyph.snowflake:
        /* v2.0.25: the streak's ICE marker — a six-arm flake in the
           same monoline stroke: three axes through the centre with
           small chevrons near each tip. */
        line(12, 3.5, 12, 20.5);
        line(4.6, 7.75, 19.4, 16.25);
        line(19.4, 7.75, 4.6, 16.25);
        // chevrons at the vertical tips
        line(9.2, 6.2, 12, 3.8);
        line(14.8, 6.2, 12, 3.8);
        line(9.2, 17.8, 12, 20.2);
        line(14.8, 17.8, 12, 20.2);
        // chevrons at the diagonal tips
        line(7.3, 6.6, 4.9, 8.1);
        line(8.2, 9.7, 4.9, 8.1);
        line(16.7, 17.4, 19.1, 15.9);
        line(15.8, 14.3, 19.1, 15.9);
        line(16.7, 6.6, 19.1, 8.1);
        line(15.8, 9.7, 19.1, 8.1);
        line(7.3, 17.4, 4.9, 15.9);
        line(8.2, 14.3, 4.9, 15.9);
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
  int _tab = 0; // 0 map · 1 places · 2 friends · 3 route · 4 profile
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
  /* v2.0.17: incoming pings (приветы + stickers) — the Friends tab
     inbox and the unseen badge on the «Друзья» nav slot. */
  List<Ping> _pings = [];
  /* v2.0.19: «you got mail» — unseen pings are also surfaced in a
     sheet on entry and when new ones land mid-session (the owner:
     «хочу чтоб когда заходили в приложение оно отсвечивалось на
     экране, типо тебе отправили так и так столько то столько
     стикеров»). _presentedPingIds remembers everything already
     shown this launch (or seen live on the Friends tab) so no ping
     is ever presented twice. */
  final Set<String> _presentedPingIds = {};
  bool _pingSheetOpen = false;
  /* v2.0.28: the expired-ping cleanup runs once per launch. */
  bool _pingsCleanupDone = false;
  Timer? _friendsTimer;
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
    // v2.0.17: piggyback the ~30 s friends cadence (the same rhythm
    // MapTab refreshes friend markers at) — while the app is open,
    // the friends list (v2.0.21: all users) and incoming pings stay
    // fresh without a realtime subscription.
    _friendsTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (myUidOrNull != null) {
        _loadFriends();
        _loadPings();
      }
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
    _friendsTimer?.cancel();
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
        myModeNotifier.value = (profile['mode'] as String?) ?? 'visible';
        LocationService.applySharing();
        // v2.0.28: the profile just landed — put me on friends' maps
        // NOW (one-shot fix + presence write), not whenever the
        // stream/map cycle happens to produce a first fix.
        LocationService.kickPresence();
        // v2.0.28: and clear out my expired (>24 h) pings, once.
        _cleanupExpiredPings();
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
      _loadPings();
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

  /* v2.0.25: every profile edit (mode, nickname, avatar) funnels
     through here — keep the app-wide mode mirror and the background
     location gate in sync with the edit, immediately. */
  void _onProfileChanged(Map<String, dynamic> p) {
    setState(() => _profile = p);
    final m = (p['mode'] as String?) ?? 'visible';
    if (myModeNotifier.value != m) myModeNotifier.value = m;
    LocationService.applySharing();
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

  /* v2.0.21: ONE friends system (owner's word) — every registered
     user is automatically everyone's friend, no requests and no
     accepting. This list = ALL profiles except me, online first,
     then by name; it feeds the Friends tab and the «Я в деле»
     sheet. The friendships table still exists in the database but
     the app no longer reads or gates on it. Fetch capped at 500. */
  Future<void> _loadFriends() async {
    final uid = myUidOrNull;
    if (uid == null) {
      if (mounted) setState(() => _friends = []);
      return;
    }
    try {
      final profs = await supa
          .from('profiles')
          .select('id, name, avatar, avatar_url, online, mode, city')
          .neq('id', uid)
          .limit(500);
      if (!mounted) return;
      final list = <Friend>[
        for (final p in profs as List)
          friendFromProfile(Map<String, dynamic>.from(p as Map)),
      ]..sort((a, b) {
          if (a.online != b.online) return a.online ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      setState(() => _friends = list);
    } catch (_) {}
  }

  /* v2.0.28: resolve a bundled Place by id (invite pings carry
     one); null when the id isn't in the bundle. */
  Place? _placeById(String id) {
    if (id.isEmpty) return null;
    for (final p in _places) {
      if (p.id == id) return p;
    }
    return null;
  }

  /* v2.0.17: incoming pings (приветы + stickers) for the Friends tab
     inbox and the unseen badge. Latest 30, newest first; sender
     profiles are fetched in one query and joined in memory.
     v2.0.28: pings live 24 HOURS (owner). The query asks the server
     only for rows younger than the cutoff and the in-memory build
     re-checks every parsed timestamp, so an expired ping can never
     render or count — not in the «Общее» inbox, not in the badge,
     not in the on-entry sheet — even while its row still exists.
     _cleanupExpiredPings() below removes the rows themselves. */
  Future<void> _loadPings() async {
    final uid = myUidOrNull;
    if (uid == null) {
      if (mounted && _pings.isNotEmpty) setState(() => _pings = []);
      return;
    }
    try {
      final cutoff = DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 24));
      final rows = await supa
          .from('pings')
          .select(
              'id, from_id, kind, sticker, place_id, place_name, created_at, seen_at')
          .eq('to_id', uid)
          .gte('created_at', cutoff.toIso8601String())
          .order('created_at', ascending: false)
          .limit(30);
      final list = rows as List;
      if (list.isEmpty) {
        if (mounted && _pings.isNotEmpty) setState(() => _pings = []);
        return;
      }
      final senderIds = <String>{
        for (final r in list) (r['from_id'] ?? '').toString(),
      }..remove('');
      final byId = <String, Friend>{};
      if (senderIds.isNotEmpty) {
        final profs = await supa
            .from('profiles')
            .select('id, name, avatar, avatar_url, online, mode, city')
            .inFilter('id', senderIds.toList());
        for (final p in profs as List) {
          final m = Map<String, dynamic>.from(p as Map);
          byId[m['id'] as String] = friendFromProfile(m);
        }
      }
      if (!mounted) return;
      setState(() {
        _pings = [
          for (final r in list)
            if (byId.containsKey(r['from_id']) &&
                // v2.0.28: the 24 h rule, enforced again on the
                // parsed instant — a row the server still returns
                // (clock skew, cached read) dies here, not on screen.
                (DateTime.tryParse((r['created_at'] ?? '').toString()) ??
                        DateTime.now())
                    .isAfter(cutoff))
              Ping(
                id: (r['id'] ?? '').toString(),
                from: byId[r['from_id']]!,
                kind: (r['kind'] as String?) ?? 'hi',
                sticker: r['sticker'] as String?,
                // v2.0.28: invite payload — resolve the bundled
                // Place now (the card's tap target); an id outside
                // the bundle keeps placeName as plain text.
                placeId: (r['place_id'] ?? '').toString().isEmpty
                    ? null
                    : (r['place_id'] ?? '').toString(),
                placeName: r['place_name'] as String?,
                place: _placeById((r['place_id'] ?? '').toString()),
                createdAt:
                    DateTime.tryParse((r['created_at'] ?? '').toString()) ??
                        DateTime.now(),
                seen: r['seen_at'] != null,
              ),
        ];
      });
      // v2.0.19: surface what arrived (launch sheet / new arrivals).
      _maybePresentPings();
    } catch (e) {
      debugPrint('TiradA pings load failed: $e');
    }
  }

  /* v2.0.28: delete my expired pings (older than 24 h) in BOTH
     directions — addressed to me and sent by me — once per launch,
     best-effort. Each direction is attempted independently: if the
     RLS delete policy refuses one of them, that failure stays
     silent (debugPrint only) and the 24 h DISPLAY filter in
     _loadPings remains the guarantee for that direction. */
  Future<void> _cleanupExpiredPings() async {
    if (_pingsCleanupDone) return;
    final uid = myUidOrNull;
    if (uid == null) return;
    _pingsCleanupDone = true;
    final cutoff = DateTime.now()
        .toUtc()
        .subtract(const Duration(hours: 24))
        .toIso8601String();
    try {
      await supa
          .from('pings')
          .delete()
          .eq('to_id', uid)
          .lt('created_at', cutoff);
    } catch (e) {
      debugPrint('TiradA pings cleanup (incoming) failed: $e');
    }
    try {
      await supa
          .from('pings')
          .delete()
          .eq('from_id', uid)
          .lt('created_at', cutoff);
    } catch (e) {
      debugPrint('TiradA pings cleanup (sent) failed: $e');
    }
  }

  /* Opening the Friends tab marks every unseen ping seen — the
     badge clears locally at once, the rows update in the
     background. */
  Future<void> _markPingsSeen() async {
    final uid = myUidOrNull;
    if (uid == null || _pings.every((p) => p.seen)) return;
    setState(() {
      _pings = [for (final p in _pings) p.copyWith(seen: true)];
    });
    try {
      await supa
          .from('pings')
          .update({'seen_at': DateTime.now().toUtc().toIso8601String()})
          .eq('to_id', uid)
          .isFilter('seen_at', null);
    } catch (e) {
      debugPrint('TiradA pings mark-seen failed: $e');
    }
  }

  /* v2.0.19: decide whether the «you got mail» sheet should pop.
     Called after every _loadPings (app start, the ~30 s cadence,
     Friends-tab mutations) and once more when the intro finishes.
     Candidates are unseen pings never presented this launch. On the
     Friends tab the inbox itself is on screen, so candidates are
     silently marked presented instead. When another route or sheet
     is up (or this sheet is already open) the call defers WITHOUT
     marking anything — the next refresh cycle retries. */
  void _maybePresentPings() {
    if (!mounted || myUidOrNull == null) return; // guests: no pings
    if (!_introDone || _loading) return; // shell not visible yet
    final fresh = [
      for (final p in _pings)
        if (!p.seen && !_presentedPingIds.contains(p.id)) p,
    ];
    if (fresh.isEmpty) return;
    if (_tab == 2) {
      _presentedPingIds.addAll(fresh.map((p) => p.id));
      return;
    }
    if (_pingSheetOpen) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _presentedPingIds.addAll(fresh.map((p) => p.id));
    _showNewPingsSheet(fresh);
  }

  Future<void> _showNewPingsSheet(List<Ping> items) async {
    _pingSheetOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => NewPingsSheet(
          pings: items,
          onOpenPlace: _openPlaceFromPing,
        ),
      );
    } finally {
      _pingSheetOpen = false;
    }
    // Dismissed (the «Отлично» button or a swipe down): exactly the
    // presented pings become seen — the tab badge follows at once.
    await _markPingsSeenIds({for (final p in items) p.id});
  }

  /* The seen_at update for an explicit id set (the sheet path);
     _markPingsSeen above stays the Friends tab's mark-all. */
  Future<void> _markPingsSeenIds(Set<String> ids) async {
    if (ids.isEmpty) return;
    if (mounted) {
      setState(() {
        _pings = [
          for (final p in _pings)
            ids.contains(p.id) ? p.copyWith(seen: true) : p,
        ];
      });
    }
    try {
      await supa
          .from('pings')
          .update({'seen_at': DateTime.now().toUtc().toIso8601String()})
          .inFilter('id', ids.toList());
    } catch (e) {
      debugPrint('TiradA pings mark-seen (sheet) failed: $e');
    }
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
    final isNewPlace = !places.contains(p.id);
    if (isNewPlace) {
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
      /* v2.0.25: a place check-in no longer marks the streak day —
         the owner's rule is that a streak day counts ONLY when a
         task is completed (the _bumpStat funnel). */
    }
    /* v2.0.26: a FIRST check-in at a place also pushes the other
       users («<name> зашёл в «<place>»») — fire-and-forget via
       send-fcm, which re-derives the sender from the JWT and
       refuses for «Невидимка» (mirrored here so an offline-mode
       user doesn't even ask). Repeat taps on an already-visited
       place never re-push. */
    if (isNewPlace &&
        myUidOrNull != null &&
        myModeNotifier.value != 'offline') {
      EventPush.checkinPlace(p);
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

  /* v2.0.28: an invite ping's place tap — open the place's card
     with the shell's real wiring (favs, check-in, photo callback),
     whichever surface the ping was tapped on. */
  void _openPlaceFromPing(Place place) {
    showPlaceSheet(
      context,
      place,
      favs: _favs,
      onToggleFav: _toggleFav,
      cityPlaces: _cityPlaces,
      city: _city,
      onCheckIn: _checkIn,
      onPhotoUploaded: _onPhotoUploaded,
    );
  }

  Future<void> _openDeal() async {
    HapticFeedback.mediumImpact();
    // v2.0.14: first «Ты в деле» is a sensible moment to (re)ask the
    // notification permission — «друг в деле» pushes are its point.
    PushService.ensurePermission();
    // v2.0.28: the sheet used to be GATED on `await _loadFriends()`
    // — a network fetch with no timeout — and on a silent
    // `if (_city == null) return;` (owner, live: «Ты в деле не
    // открывается»). On a stalled connection the centre button was
    // a dead tap for as long as the fetch hung. Now the sheet opens
    // IMMEDIATELY with the in-memory friends list (kept fresh by
    // the load + the 30 s cadence) while the refresh runs in the
    // background, and a missing city falls back to the first loaded
    // one — or says so honestly instead of dying in silence.
    _loadFriends();
    if (!mounted) return;
    final city = _city ?? (_cities.isNotEmpty ? _cities.first : null);
    if (city == null) {
      snack(context, tr('deal_no_city'));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DealSheet(
        places: _places.where((p) => p.city == city.id).toList(),
        city: city,
        cities: _cities,
        friends: _friends,
        signedIn: myUidOrNull != null,
        onRoute: () => _selectTab(3),
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
     Tap = the Profile tab. v2.0.20: the bottom bar no longer has a
     Profile slot (Друзья took the far-right place), so this header
     button — top-right, rendered above the IndexedStack on every
     tab — is THE profile entry. */
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
        _selectTab(4);
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

  /* v2.0.17: the single funnel for tab switches (nav slots, header
     avatar, DealSheet «route» callback, Profile «Друзья» row), so the
     side effects stay in sync: the map's first-open location flow and
     the friends tab's ping refresh + seen-marking. */
  void _selectTab(int idx) {
    setState(() => _tab = idx);
    // First time the Map tab is opened: re-run the location flow
    // (the permission may have been granted in Settings meanwhile).
    if (idx == 0 && !_mapTabOpened) {
      _mapTabOpened = true;
      // v2.0.28: once that flow settles, kick a one-shot presence
      // write — a first-open user appears on friends' maps within
      // seconds instead of waiting for a stream event.
      LocationService.ensureLocation(context)
          .then((_) => LocationService.kickPresence());
    }
    // v2.0.28: EVERY map open re-judges the sharing-issue state, so
    // the honesty banner tracks reality (fixed in Settings → gone).
    if (idx == 0) {
      LocationService.refreshShareIssue();
    }
    if (idx == 2) {
      _loadPings();
      _markPingsSeen();
    }
  }

  int get _unseenPings => _pings.where((p) => !p.seen).length;

  /* v2.0.12: nav items are TI glyphs — inactive: monoline gray;
     active: the spec's ActiveIconBadge (white filled glyph on the
     glowing gradient circle). Every slot has the SAME structure
     (36 px icon zone + label under it), so switching tabs changes
     nothing but colours — zero layout shift, the FAB stays centred.
     v2.0.17: an optional count badge (unseen pings on «Друзья»). */
  Widget _navSlot(int idx, TIGlyph glyph, String label, {int badge = 0}) {
    final active = _tab == idx;
    return Pressable(
      onTap: () => _selectTab(idx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: active
                      ? ActiveIconBadge(glyph: glyph, size: 36)
                      : TiradIcon(glyph, size: 23, color: T.iconGray),
                ),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 17),
                      height: 17,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: T.fire,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          // v2.0.18: the label is laid out unconstrained
          // horizontally (centred on the slot centre, softWrap
          // off): a label like «Друзья» (~36–40 dp at 10.5) must
          // never wrap to a second line or lose letters to the
          // slot edge. It can only paint into the slack the
          // geometry note in _bottomNav verifies (v2.0.20: every
          // slot is 57 dp wide at 360 dp screen width, ≥ 15 dp
          // clear of any neighbouring label, ≥ 21.5 dp clear of
          // the «Ты в деле» label).
          UnconstrainedBox(
            constrainedAxis: Axis.vertical,
            child: Text(
              label,
              softWrap: false,
              textAlign: TextAlign.center,
              style: T.body(
                10.5,
                color: active ? T.text : T.faint,
                w: FontWeight.w700,
              ),
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
        // v2.0.20: the owner moved «Профиль» OUT of the bar
        // («перемести раздел профиль сверху справо, а раздел
        // друзья поставь на место профиля»): the Profile tab
        // (index 4, unchanged in the IndexedStack) is now reached
        // ONLY from the header avatar button at the top-right,
        // and «Друзья» takes the far-right slot where «Профиль»
        // used to be. The base row is now [Expanded left group:
        // Карта · Места] [fixed 92 dp empty gap] [Expanded right
        // group: Маршрут · Друзья]. Tab indices are untouched
        // (0 map · 1 places · 2 friends · 3 route · 4 profile) —
        // the bar simply renders four of the five; the Друзья
        // slot keeps its unseen-pings badge, and the active-tab
        // state is still driven by _tab == idx, so no slot
        // highlights while the Profile tab is open.
        //
        // v2.0.18 geometry, recomputed for 2+2 slots: the 2.0.17
        // geometry (two half-width groups, FAB overlaid
        // dead-centre) CROWDED the centre — the «Друзья» slot
        // centre sat only ~27 dp from the panel centre, so the
        // FAB badge and its RadarSweep painted over the «Друзья»
        // icon and the labels overlapped on the baseline
        // (owner's screenshot: «исправь, что это за пиздец»). The
        // fix reserves a REAL centre gap: both groups have flex
        // 1, so each gets exactly (rowWidth − 92) / 2 and the
        // gap's centre IS the panel centre — structurally, in
        // every tab state; the FAB overlay (Positioned.fill +
        // Center) therefore still sits dead-centre, now over
        // empty space. Arithmetic at a 360 dp-wide screen (panel
        // content width 320 after the 12 dp margins and 8 dp
        // padding): groups are 114 wide, every slot is 57 wide;
        // slot centres from the content's left edge — Карта
        // 28.5, Места 85.5, Маршрут 234.5, Друзья 291.5, panel
        // centre 160. The nearest centres (Места and Маршрут,
        // both 74.5 dp from centre — roomier than 2.0.18's
        // 65 dp) clear the FAB badge (radius 29) by 26.5 dp to
        // the 38 dp icon zone, and the full RadarSweep (radius
        // 43) by 12.5 dp to the zone / 13.5 dp to the visible
        // 36 dp badge; even at the pulse peak (scale 1.07 →
        // sweep radius ~46) the sweep clears a selected
        // neighbour's badge by ~10.5 dp — it never covers a
        // neighbouring icon. Labels: «Ты в деле» (~62 dp at
        // 10.5) lives inside the 92 dp gap (129..191 around the
        // centre); «Места» ends ~28 dp before it and «Маршрут»
        // starts ~21.5 dp after it; «Маршрут» / «Друзья» labels
        // are ~15 dp apart — all five labels share the baseline
        // with no overlaps and no font reduction. Panel height
        // (~90 dp), margins, colours and radius are unchanged
        // from 2.0.17.
        //
        // v2.0.17: FIVE tabs (Друзья added at index 2); the bar is
        // a Stack whose base layer is a 75 dp row (the pre-2.0.17
        // panel content height, set by the FAB column). The slots
        // never resize (each is an Expanded Column of fixed
        // structure), so switching tabs shifts nothing. The
        // overlay does not steal slot taps: _DealFab's
        // GestureDetector wraps ONLY its badge circle (see
        // _DealFab), and the Center around it hit-tests nothing by
        // itself; the empty gap outside the circle is not a tap
        // target. The slots keep their full tap areas.
        //
        // v2.0.13 ROOT-CAUSE FIX (panel filled the whole screen)
        // still applies to the ROW: slots must NOT be wrapped in
        // Center/Align there. A Center sizes itself to
        // constraints.maxHeight whenever that is finite and no
        // heightFactor is set — and the Scaffold bottomNavigationBar
        // slot hands this bar loose constraints with maxHeight =
        // the FULL screen height. In v2.0.12 each slot was
        // Expanded(child: Center(...)), so every Center stretched
        // to full height and the panel covered the whole screen.
        // The one Center in the FAB overlay is safe: it lives
        // inside Positioned.fill, and positioned children do not
        // size the Stack — the Stack takes the base row's 75 dp.
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: 75,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _navSlot(0, TIGlyph.mapPin, tr('nav_map')),
                        ),
                        Expanded(
                          child: _navSlot(1, TIGlyph.flame, tr('nav_places')),
                        ),
                      ],
                    ),
                  ),
                  // v2.0.18: the reserved centre gap (see the
                  // geometry note above) — empty space under the
                  // centred FAB, not a tap target.
                  const SizedBox(width: 92),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child:
                              _navSlot(3, TIGlyph.routePath, tr('nav_route')),
                        ),
                        Expanded(
                          child: _navSlot(
                            2,
                            TIGlyph.users,
                            tr('nav_friends'),
                            badge: _unseenPings,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Center(
                child: _DealFab(onTap: _openDeal),
              ),
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
          // v2.0.19: pings may have loaded under the intro — retry
          // the «you got mail» sheet now that the shell is visible.
          _maybePresentPings();
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
                  FriendsTab(
                    friends: _friends,
                    pings: _pings,
                    onOpenFriend: (f) => showFriendSheet(context, f),
                    onPingsChanged: _loadPings,
                    onOpenPlace: _openPlaceFromPing,
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
                    onProfileChanged: _onProfileChanged,
                    onOpenTasks: _openTasks,
                    onOpenFriends: () => _selectTab(2),
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
    // v2.0.17: the GestureDetector wraps ONLY the badge — the FAB
    // now floats as a centred overlay above the nav row (see
    // _bottomNav), and its hit area must stay limited to its
    // circle so the «Друзья» / «Маршрут» slots beside the centre
    // keep their full tap areas. The label under the badge is
    // decoration, not a tap target.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
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
                    /* v2.0.23: tap an in-deal avatar → the zoom
                       viewer (these rows have no tap of their own). */
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => showAvatarZoom(
                        context,
                        name: f.mode == 'ghost' ? tr('ghost') : f.name,
                        avatar: f.avatar,
                        avatarUrl: f.avatarUrl,
                      ),
                      child: CircleAvatar(
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
  Timer? _vibeTimer;
  final TextEditingController _reviewCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _place = widget.place;
    _loadPhotos();
    _loadReviews();
    _loadCrowd();
    // v2.0.24: the busyness numbers are time-derived — while the
    // sheet stays open, re-render once a minute so the % drifts
    // with the curve instead of sitting frozen.
    _vibeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _vibeTimer?.cancel();
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
     filtered on the client, 🔥 counts from photo_reactions.
     v2.0.21: a 'friends'-visibility photo is visible to every
     signed-in user — under the one-system rules everyone in the
     app is a friend. (Same widening in the tournament feed.) */
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
          if (r['visibility'] == 'public' ||
              (uid != null &&
                  (r['user_id'] == uid || r['visibility'] == 'friends')))
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
     profile_locations within ~80 m (excluding me). Best-effort.
     v2.0.25: «Невидимка» users are excluded — their own client
     deletes the location row, and this mode join covers any stale
     row that survived (e.g. the app was killed mid-switch). */
  Future<void> _loadCrowd() async {
    try {
      final uid = myUidOrNull;
      final hidden = <String>{};
      try {
        final profs = await supa
            .from('profiles')
            .select('id, mode')
            .eq('mode', 'offline')
            .limit(500);
        for (final r in profs as List) {
          hidden.add((r as Map)['id'] as String);
        }
      } catch (_) {}
      final rows = await supa
          .from('profile_locations')
          .select('user_id, lat, lng')
          .limit(300);
      var n = 0;
      for (final r in rows as List) {
        if (r['user_id'] == uid) continue;
        if (hidden.contains(r['user_id'])) continue;
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
  /* v2.0.28: «Пригласить» — pick a person and send them an invite
     ping to THIS place (InvitePersonSheet / sendInvitePing).
     Guests get the standard ping login prompt, as elsewhere. */
  Future<void> _openInvite() async {
    if (myUidOrNull == null) {
      snack(context, tr('ping_signin'));
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => InvitePersonSheet(place: _place),
    );
  }

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
    String? photoId;
    try {
      final row = await supa.from('place_photos').insert({
        'place_id': _place.id,
        'user_id': uid,
        'url': url,
        'visibility': vis,
      }).select('id').single();
      photoId = (row as Map)['id']?.toString();
    } catch (e) {
      debugPrint('TiradA place_photos insert failed: $e');
      if (mounted) {
        snack(context, tr('photo_save_fail'));
        setState(() => _uploading = false);
      }
      return;
    }
    // v2.0.26: real push about this check-in (fire-and-forget).
    // Only reachable for 'public'/'friends' — «Не показывать»
    // cancelled the flow above and created no row to validate.
    if (photoId != null) EventPush.checkinPhoto(photoId, _place.name);
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
            GhostButton(
              text: tr('invite_btn'),
              small: true,
              icon: TIGlyph.paperPlane,
              onPressed: _openInvite,
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

class _MapTabState extends State<MapTab> with WidgetsBindingObserver {
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
  /* v2.0.25: registered me-marker images, per mode ('me-marker',
     'me-marker-ghost') — a mode switch registers the other bitmap
     instead of reusing the wrong cover. */
  final Set<String> _meImgNames = {};
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
    WidgetsBinding.instance.addObserver(this);
    MapRouteBus.line.addListener(_onRouteLineChanged);
    myLocationNotifier.addListener(_onMyLocation);
    myModeNotifier.addListener(_onMyModeChanged);
    LocationService.shareIssue.addListener(_onShareIssueChanged);
    rootBundle.loadString('assets/map-style.json').then((s) {
      if (mounted) setState(() => _style = s);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    MapRouteBus.line.removeListener(_onRouteLineChanged);
    myLocationNotifier.removeListener(_onMyLocation);
    myModeNotifier.removeListener(_onMyModeChanged);
    LocationService.shareIssue.removeListener(_onShareIssueChanged);
    _timer?.cancel();
    _zoomDragPointer = null;
    super.dispose();
  }

  /* v2.0.28: returning to the app (e.g. from the system Settings,
     where the permission/GPS was just fixed) re-judges the sharing
     state at once — the honesty banner must not outlive its cause. */
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      LocationService.refreshShareIssue();
    }
  }

  /* v2.0.28: the sharing-issue banner's memory. A dismissal hides
     the CURRENT issue only; when the issue itself changes (denied →
     gps_off, or back after a fix), the banner earns a fresh say. */
  String? _shareIssueSeen;
  bool _shareBannerHidden = false;

  void _onShareIssueChanged() {
    final v = LocationService.shareIssue.value;
    if (v != _shareIssueSeen) {
      _shareIssueSeen = v;
      _shareBannerHidden = false;
    }
    if (mounted) setState(() {});
  }

  /* v2.0.28: the banner's one button does the fix that matches the
     issue: a still-askable denial re-asks in place; a permanent one
     can only be undone in the app settings; GPS-off goes to the
     phone's location settings. Afterwards the state is re-judged
     and a presence kick runs, so a fixed user lands on the map (and
     the banner clears) without any further taps. */
  Future<void> _shareBannerAction(String issue) async {
    try {
      if (issue == 'denied') {
        await Permission.location.request();
      } else if (issue == 'gps_off') {
        await Geolocator.openLocationSettings();
      } else {
        await openAppSettings();
      }
    } catch (_) {}
    await LocationService.refreshShareIssue();
    LocationService.kickPresence();
  }

  /* v2.0.25: my mode changed (in the Profile tab) — presence and
     the me-marker must follow NOW, not on the next 30 s cycle:
     «Невидимка» wipes my location row and my marker at once;
     «Призрак» repaints my marker with the ghost cover. */
  void _onMyModeChanged() {
    _updateMeMarker();
    _presence();
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
    // v2.0.25: the mode is part of the key too — a visible↔ghost
    // switch must repaint the marker on the next refresh, not
    // reuse the other mode's bitmap.
    final cacheKey =
        '${f.id}|${f.avatarUrl ?? f.avatar ?? ''}|${f.online}|${f.mode ?? ''}';
    final cached = _markerCache[cacheKey];
    if (cached != null) return cached;
    // v2.0.10: markers were too small (owner) — bitmap re-painted at
    // 168 px (was 112) with all radii scaled ×1.5; iconSize stays
    // 0.55, so on screen ≈92 px (was ≈62). The status ring also gets
    // a thicker stroke so the online green actually reads at a glance.
    // v2.0.28: STILL too small (owner: «аватарки больше») — bitmap
    // re-painted at 252 px (×1.5 again, every radius/glyph/stroke
    // scaled with it, so the photo source stays sharp) and
    // _refreshFriends shows it at iconSize 0.6: on screen ≈151 px,
    // ≈1.64× the v2.0.10 size.
    const double size = 252;
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
        Path()..addOval(Rect.fromCircle(center: center, radius: 108)),
      );
      canvas.drawImageRect(
        photo,
        crop.isEmpty ? src : crop,
        Rect.fromCircle(center: center, radius: 108),
        Paint(),
      );
      canvas.restore();
    } else {
      canvas.drawCircle(center, 108, Paint()..color = kSurface2);
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
          Rect.fromCenter(center: center, width: 144, height: 144),
          T.iconGray,
          strokeScale: 1.1,
        );
      } else if (f.mode == 'ghost' || isDefault) {
        TIPaint.paint(
          canvas,
          TIGlyph.ghost,
          Rect.fromCenter(center: center, width: 144, height: 144),
          T.iconGray,
          strokeScale: 1.1,
        );
      } else {
        final tp = TextPainter(
          text: TextSpan(
            text: chosen,
            style: const TextStyle(fontSize: 112),
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
      112.5,
      Paint()
        ..color = f.online ? kGreen : kMuted
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12,
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
      // v2.0.21: one friends system — the map shows EVERY registered
      // user (except me), not just accepted friendships. Both fetches
      // capped at 500; the visibility rules below are unchanged
      // (mode 'offline' is never placed, ghost mode renders ghostly).
      final profs = await supa
          .from('profiles')
          .select('id, name, avatar, avatar_url, online, mode')
          .neq('id', uid)
          .limit(500);
      if ((profs as List).isEmpty) return;
      final locs = await supa
          .from('profile_locations')
          .select('user_id, lat, lng')
          .limit(500);
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
        /* v2.0.25: ghost mode is masked at construction (same rule
           as friendFromProfile) — the marker bitmap then has no
           photo to draw and falls into its ghost branch. Before,
           the real avatarUrl reached _friendMarker, whose photo
           branch ran BEFORE any mode check: a ghost with a photo
           stood on the map with his real face. */
        final friend = Friend(
          id: id,
          name: mode == 'ghost'
              ? tr('ghost')
              : ((p['name'] as String?) ?? tr('ghost')),
          avatar: mode == 'ghost' ? null : p['avatar'] as String?,
          avatarUrl: mode == 'ghost' ? null : p['avatar_url'] as String?,
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
            // v2.0.28: 252 px bitmap at 0.6 ≈ 151 px on screen
            // (was 168 px at 0.55 ≈ 92 px) — «аватарки больше».
            iconSize: 0.6,
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
    /* v2.0.25: my marker obeys my mode. «Невидимка» — no marker at
       all, not even on my own map (the owner: «когда невидимка, я
       вообще не должен отображаться на карте»). «Призрак» — the
       marker wears the ghost cover (its own bitmap/image name). */
    final mode = myModeNotifier.value;
    if (mode == 'offline' && myUidOrNull != null) {
      final sym = _meSymbol;
      _meSymbol = null;
      if (sym != null) {
        try {
          await ctl.removeSymbol(sym);
        } catch (_) {}
      }
      return;
    }
    if (myLocationNotifier.value == null) return;
    _meSyncing = true;
    try {
      final ghost = mode == 'ghost' && myUidOrNull != null;
      final imgName = ghost ? 'me-marker-ghost' : 'me-marker';
      if (!_meImgNames.contains(imgName)) {
        try {
          await ctl.addImage(imgName, await _meMarkerBitmap(ghost: ghost));
          _meImgNames.add(imgName);
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
            iconImage: imgName,
            iconSize: 0.75, // 176 px bitmap → ≈132 px on screen
            // (v2.0.29: own marker back to the v2.0.27 size — the
            // 2.0.28 growth was meant for OTHER people only)
          ),
        );
      } else {
        await ctl.updateSymbol(
          _meSymbol!,
          SymbolOptions(geometry: pos, iconImage: imgName),
        );
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

  /* [ghost] (v2.0.25): the disguised cover — no photo is even
     loaded, the disc wears the branded TI ghost. */
  Future<Uint8List> _meMarkerBitmap({bool ghost = false}) async {
    final cacheKey = ghost ? 'me-marker-bitmap-ghost' : 'me-marker-bitmap';
    final cached = _markerCache[cacheKey];
    if (cached != null) return cached;
    // v2.0.29: own marker reverted to the v2.0.27 geometry (bitmap
    // 176 px) — the owner: the 2.0.28 growth («аватарки больше») was
    // for OTHER people's markers only, not his own.
    const double size = 176;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
    final center = const Offset(size / 2, size / 2);
    canvas.drawCircle(center, 86, Paint()..color = T.fire);
    canvas.drawCircle(center, 77, Paint()..color = Colors.white);
    final photo = ghost ? null : await _loadMePhoto();
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
      final myGlyph =
          ghost ? TIGlyph.ghost : tiAvatarGlyph(await _meAvatarValue());
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

  /* v2.0.27: the write itself lives in LocationService.syncPresence
     (shared with the background heartbeat — one path, one semantics);
     this 30 s foreground cycle is unchanged. */
  Future<void> _presence() => LocationService.syncPresence();

  void _onMapCreated(MapLibreMapController ctl) {
    _ctl = ctl;
    _pinsRegistered = false; // new controller → pin images must re-register
    _routeImagesOnMap.clear(); // …and so must the route-marker images
    _routeLineObj = null;
    _routeSymbols.clear();
    _meSymbol = null; // …and the «me» marker belongs to the old style
    _meImgNames.clear();
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

  /* v2.0.17: the sheet itself is the shared showFriendSheet /
     FriendSheet (header + «Привет» / «Стикер» ping actions), also
     used by the Friends tab. */
  void _showFriend(Friend f) => showFriendSheet(context, f);

  /* v2.0.28: the honesty banner (owner: «все друг друга видят»).
     A signed-in visible/ghost user whose phone can't share a
     position was previously invisible in total silence — this says
     so, on the map itself, with the one tap that fixes it. It
     renders only while LocationService.shareIssue names a cause and
     the user hasn't dismissed THAT cause; a successful presence
     write clears the state and the banner is gone. Inset 56 dp
     sideways so the invisible side-zoom strips keep their edges. */
  /* v2.0.29 (item B): «take me to myself» — the Google-Maps-style
     centre-on-me control the owner asked for («кнопка, которая
     направляет тебя к себе, ну как в картах»). Latest fix from
     myLocationNotifier first; if there is none yet, a one-shot fix
     via the 2.0.28 kickPresence machinery (it also feeds the
     notifier), with a bare Geolocator fix as the fallback for the
     cases kickPresence doesn't cover (guest / «Невидимка» —
     centring my own map on me is a local act, it writes nothing).
     If no position can be obtained at all, an honest snack instead
     of a silent dead tap. Zoom 14 — the same zoom the map itself
     picks when it first centres on the user. */
  Future<void> _centerOnMe() async {
    var pos = myLocationNotifier.value;
    if (pos == null) {
      await LocationService.kickPresence();
      pos = myLocationNotifier.value;
    }
    if (pos == null) {
      try {
        final fix = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
        pos = LatLng(fix.latitude, fix.longitude);
        myLocationNotifier.value = pos;
      } catch (_) {}
    }
    if (!mounted) return;
    final p = pos;
    if (p == null) {
      snack(context, tr('me_no_position'));
      return;
    }
    await _ctl?.animateCamera(CameraUpdate.newLatLngZoom(p, 14));
  }

  /* The button itself: circular, dark, TI target glyph — bottom-
     right, mirroring the pulse chip (bottom-left, same T.s12
     insets). It collides with nothing: the route chip and the
     sharing banner live at the top, and the invisible swipe-zoom
     strips end 64 dp above the bottom edge, well above this
     button. Last in the Stack, so its taps are its own. */
  Widget _centerOnMeButton() {
    return Positioned(
      right: T.s12,
      bottom: T.s12,
      child: Pressable(
        onTap: _centerOnMe,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: T.surface.withOpacity(0.92),
            shape: BoxShape.circle,
            border: Border.all(color: T.stroke),
            boxShadow: T.cardDepth,
          ),
          child: const Center(
            child: TiradIcon(TIGlyph.target, size: 24, color: T.iconGray),
          ),
        ),
      ),
    );
  }

  Widget _shareBanner() {
    final issue = LocationService.shareIssue.value;
    if (issue == null || _shareBannerHidden) {
      return const SizedBox.shrink();
    }
    // Guests and «Невидимка» never see it — refreshShareIssue keeps
    // the state null for them; this is the render-side lock.
    if (myUidOrNull == null || myModeNotifier.value == 'offline') {
      return const SizedBox.shrink();
    }
    return Positioned(
      top: 58,
      left: 56,
      right: 56,
      child: Container(
        padding: const EdgeInsets.fromLTRB(T.s12, T.s8, T.s8, T.s8),
        decoration: BoxDecoration(
          color: T.surface.withOpacity(0.94),
          borderRadius: BorderRadius.circular(T.rCard),
          border: Border.all(color: T.fire.withOpacity(0.55)),
          boxShadow: T.cardDepth,
        ),
        child: Row(
          children: [
            const TiradIcon(TIGlyph.mapPin, size: 18, color: T.fire),
            const SizedBox(width: T.s8),
            Expanded(
              child: Text(
                tr(issue == 'gps_off'
                    ? 'share_banner_gps'
                    : 'share_banner_perm'),
                style: T.body(12.5, w: FontWeight.w600),
              ),
            ),
            const SizedBox(width: T.s8),
            GestureDetector(
              onTap: () => _shareBannerAction(issue),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: T.fire.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(T.rPill),
                  border: Border.all(color: T.fire.withOpacity(0.6)),
                ),
                child: Text(
                  tr(issue == 'denied' ? 'share_banner_allow' : 'settings'),
                  style: T.body(12, color: T.salmon, w: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: T.s4),
            GestureDetector(
              onTap: () => setState(() => _shareBannerHidden = true),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: TiradIcon(TIGlyph.x, size: 14, color: T.muted),
              ),
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
        // v2.0.28: the sharing-issue honesty banner (inset past the
        // zoom strips, under the route chip's line).
        _shareBanner(),
        // v2.0.29 (item B): centre-on-me, bottom-right.
        _centerOnMeButton(),
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
  Timer? _vibeTimer;

  static const _sortLabels = {
    'vibe': 'sort_vibe',
    'dist': 'sort_dist',
    'rating': 'sort_rating',
    'price': 'sort_price',
    'name': 'sort_name',
  };

  /* v2.0.28: a TI glyph per sort mode, for the restyled menu. */
  static const _sortIcons = {
    'vibe': TIGlyph.flame,
    'dist': TIGlyph.mapPin,
    'rating': TIGlyph.star,
    'price': TIGlyph.bag,
    'name': TIGlyph.pencil,
  };

  @override
  void initState() {
    super.initState();
    _loadDaily();
    // v2.0.24: busyness is time-derived — refresh the list once a
    // minute so an open tab shows the numbers moving, not frozen.
    _vibeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _vibeTimer?.cancel();
    super.dispose();
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
                            /* v2.0.28 (item I): the sort control,
                               restyled to the brand — the chip now
                               matches its PillButton neighbours
                               (same 14/9 rhythm, near-black surface,
                               red-tinted border) and carries TI
                               vector marks (SortMark + a rotated
                               chevron) instead of the stock ↕ / ▾
                               text glyphs; the menu is a TiradA
                               panel — #0E0E12 surface, 18-radius,
                               red-tinted border, a TI glyph per
                               mode, the active sort in salmon with
                               an ember check. Behaviour unchanged:
                               same five modes, same _sort state. */
                            PopupMenuButton<String>(
                              color: const Color(0xFF0E0E12),
                              elevation: 10,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                    color: T.fire.withOpacity(0.25)),
                              ),
                              initialValue: _sort,
                              onSelected: (v) => setState(() => _sort = v),
                              itemBuilder: (_) => [
                                for (final e in _sortLabels.entries)
                                  PopupMenuItem(
                                    value: e.key,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TiradIcon(
                                          _sortIcons[e.key] ??
                                              TIGlyph.flame,
                                          size: 16,
                                          color: e.key == _sort
                                              ? T.ember
                                              : T.iconGray,
                                          filled: e.key == _sort,
                                        ),
                                        const SizedBox(width: T.s8),
                                        Text(
                                          tr(e.value),
                                          style: e.key == _sort
                                              ? T.body(13.5,
                                                  color: T.salmon,
                                                  w: FontWeight.w800)
                                              : T.body(13.5,
                                                  w: FontWeight.w600),
                                        ),
                                        if (e.key == _sort) ...[
                                          const SizedBox(width: T.s12),
                                          const TiradIcon(TIGlyph.check,
                                              size: 14, color: T.ember),
                                        ],
                                      ],
                                    ),
                                  ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 9),
                                decoration: BoxDecoration(
                                  color: T.surface,
                                  borderRadius:
                                      BorderRadius.circular(T.rPill),
                                  border: Border.all(
                                      color: T.fire.withOpacity(0.30)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SortMark(),
                                    const SizedBox(width: 6),
                                    Text(
                                      tr(_sortLabels[_sort] ?? 'sort_vibe'),
                                      style: T.body(12.5,
                                          w: FontWeight.w700),
                                    ),
                                    const SizedBox(width: 4),
                                    Transform.rotate(
                                      angle: -math.pi / 2,
                                      child: const TiradIcon(
                                          TIGlyph.chevronBack,
                                          size: 10,
                                          color: T.iconGray),
                                    ),
                                  ],
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

  /* «Отменить маршрут» (v2.0.12 as «Удалить маршрут»; v2.0.28: ONE
     TAP, no confirm — the owner: «нельзя отменить маршрут»). The
     old flow put a confirm sheet in front of any route with
     progress and then _deleteActiveRoute silently built a FRESH
     evening route in its place, so a cancelled route looked just
     like a live one and the cancel read as broken. Now the tap
     itself wipes the tracking state (see _deleteActiveRoute) and
     the tab rests with NO active route. XP already credited
     (tasks/routes stats) is NEVER revoked. */
  void _requestDeleteRoute() {
    if (_stops.isEmpty) {
      if (MapRouteBus.line.value?.kind == 'route') MapRouteBus.clear();
      return;
    }
    _deleteActiveRoute();
  }

  void _deleteActiveRoute() {
    if (MapRouteBus.line.value?.kind == 'route') MapRouteBus.clear();
    _done.clear();
    _counted = false;
    // The route's task ticks (the check-in ticks of THIS route) die
    // with it — in memory and in prefs — so nothing about the
    // cancelled route can resurrect inside a later one.
    _routeTasksDone.clear();
    final deadKey = _routeKey;
    if (deadKey.isNotEmpty) {
      () async {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('route_tasks_done_$deadKey');
        } catch (_) {}
      }();
    }
    _stops = [];
    _start = null;
    _startIsCenter = false;
    _road = null;
    _roadSig = '';
    _routeTitleMap = null;
    // Persist the CLEARED state — no replacement route is built.
    // (The next launch's _load treats empty stops as a first open
    // and builds the evening route then, exactly as designed.)
    _persistActive();
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
  /* v2.0.25: ONE segmented stats strip — start · points/distance ·
     time as three cells of a single bar with hairline dividers,
     replacing the three floating mismatched chips. The numbers are
     the same ones the chips showed (incl. the v2.0.15 transport-
     adjusted total time). */
  Widget _statsStrip() {
    Widget cell(TIGlyph g, String text, {int flex = 1}) => Expanded(
          flex: flex,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TiradIcon(g, size: 13, color: T.iconGray),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.body(12, w: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
    /* v2.0.28 (owner: the strip «имеет no style»): restyled into the
       app's panel language — the Places/Общее card surface (T.surface
       near-black) instead of the flat lighter T.surfaceHi, a subtle
       RED-TINTED border instead of the neutral stroke, the stat
       glyphs in the TI soft gray (#9A9AA0, T.iconGray) instead of
       ember orange, the roomier 18 dp card radius and the s12
       padding rhythm. The orange-red gradient stays reserved for
       the primary action (the «Показать на карте» button below) —
       nothing in the strip competes with it. Purely visual: same
       cells, same texts, same flexes. */
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: T.s12, vertical: T.s12),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: T.fire.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          cell(
            TIGlyph.mapPin,
            _startIsCenter ? tr('from_center') : tr('from_you'),
            flex: 2,
          ),
          Container(width: 1, height: 20, color: T.fire.withOpacity(0.14)),
          cell(
            TIGlyph.routePath,
            trf('route_summary', {
                  'n': _stops.length,
                  'd': _fmtDist(_displayTotalKm),
                }) +
                (_counted ? tr('route_summary_done') : ''),
            flex: 4,
          ),
          Container(width: 1, height: 20, color: T.fire.withOpacity(0.14)),
          cell(
            TIGlyph.clock,
            trf('mins_short', {
              // v2.0.15: the OSRM total goes through the transport
              // adjustment (bus = driving ×1.35 + 8 min) — the raw
              // duration was identical for bus/car and, via the
              // profile-blind demo server, for walking too.
              'n': _road != null
                  ? _modeTotalMins(_road!.totalMins).round()
                  : (_displayTotalKm / (_speeds[_transport] ?? 5) * 60)
                      .round(),
            }),
            flex: 3,
          ),
        ],
      ),
    );
  }

  /* v2.0.25: the route preview as a connected vertical TIMELINE —
     numbered neon dots joined by a gradient path line, stop names
     in order, the leg distance riding each connector, a check on
     stops already checked in. Stop names come from _stops (always
     available); leg distances reuse the _legRow maths (OSRM legs
     when landed, straight-line estimates until then). */
  Widget _routeTimeline() {
    double legKm(int leg) {
      final r = _road;
      if (r != null && leg >= 0 && leg < r.legKm.length) return r.legKm[leg];
      final a = leg == 0
          ? _start
          : LatLng(_stops[leg - 1].lat, _stops[leg - 1].lng);
      if (a == null) return 0;
      final b = _stops[leg];
      return haversineKm(a.latitude, a.longitude, b.lat, b.lng);
    }

    Widget dot(int i) => Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _done.contains(i) ? null : T.specGrad,
            color: _done.contains(i) ? T.online : null,
            boxShadow: [
              BoxShadow(
                color: (_done.contains(i) ? T.online : T.fire)
                    .withValues(alpha: 0.45),
                blurRadius: 8,
              ),
            ],
          ),
          child: _done.contains(i)
              ? const TiradIcon(TIGlyph.check,
                  size: 13, color: Colors.white, filled: true)
              : Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        );

    Widget connector(int leg) => Row(
          children: [
            SizedBox(
              width: 26,
              child: Center(
                child: Container(
                  width: 2.5,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        T.fire.withValues(alpha: 0.85),
                        T.ember.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: T.s12),
            Text(
              _fmtDist(legKm(leg)),
              style: T.body(11, color: T.faint, w: FontWeight.w600),
            ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _stops.length; i++) ...[
          if (i > 0) connector(i),
          Row(
            children: [
              dot(i),
              const SizedBox(width: T.s12),
              Expanded(
                child: Text(
                  _stops[i].name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.body(13.5, w: FontWeight.w700),
                ),
              ),
              TiradIcon(
                typeGlyph(_stops[i].type),
                size: 14,
                color: T.iconGray,
              ),
            ],
          ),
        ],
      ],
    );
  }

  /* v2.0.25: a quiet secondary action cell (icon over label) — the
     two secondary route actions share one aligned row of these, at
     one height, instead of odd-width floating buttons. */
  Widget _actionCell(TIGlyph glyph, String label, VoidCallback onTap) {
    return Expanded(
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: T.s8),
          decoration: BoxDecoration(
            color: T.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: T.stroke),
          ),
          child: Column(
            children: [
              TiradIcon(glyph, size: 18, color: T.salmon),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: T.body(11.5, w: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* v2.0.25: one segment of the transport switch — the track (a
     single pill shell) lives in the hero card; the selected segment
     fills with the brand gradient. The tap behaviour is unchanged. */
  Widget _transportPill(String id, String label) {
    final sel = _transport == id;
    return Expanded(
      child: GestureDetector(
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            gradient:
                sel ? const LinearGradient(colors: [kRed, kOrange]) : null,
            borderRadius: BorderRadius.circular(999),
            boxShadow: sel
                ? [BoxShadow(color: kRed.withOpacity(0.45), blurRadius: 14)]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
              ),
            ],
          ),
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
                    /* v2.0.25: a faint radar ring echoes the brand
                       motif around the route badge. */
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: T.fire.withValues(alpha: 0.30),
                                width: 1.2,
                              ),
                            ),
                          ),
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
                        ],
                      ),
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
                  /* v2.0.25: the panel was a scatter of mismatched
                     floating chips and uneven buttons (owner:
                     «выглядает разбросано»). Now one rhythm: a
                     single segmented stats strip, the stops as a
                     connected timeline preview, one segmented
                     transport switch, ONE primary action and the
                     rest as two equal quiet cells. All callbacks
                     are the original ones — composition only. */
                  if (_startIsCenter) ...[
                    const SizedBox(height: T.s12),
                    Row(
                      children: [
                        const TiradIcon(TIGlyph.mapPin,
                            size: 13, color: T.iconGray),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tr('route_start_center'),
                            style: T.body(12, color: T.muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: T.s16),
                  _statsStrip(),
                  const SizedBox(height: T.s16),
                  _routeTimeline(),
                ],
                const SizedBox(height: T.s16),
                hairline(),
                const SizedBox(height: T.s16),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: T.surfaceHi,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: T.stroke),
                  ),
                  child: Row(
                    children: [
                      _transportPill('walk', tr('tp_walk')),
                      _transportPill('bus', tr('tp_bus')),
                      _transportPill('car', tr('tp_car')),
                    ],
                  ),
                ),
                const SizedBox(height: T.s16),
                PressButton(
                  text: tr('route_show_map'),
                  icon: TIGlyph.routePath,
                  onPressed: _showOnMap,
                ),
                const SizedBox(height: T.s12),
                Row(
                  children: [
                    _actionCell(
                      TIGlyph.dice,
                      tr('route_reshuffle'),
                      _reshuffle,
                    ),
                    const SizedBox(width: T.s8),
                    _actionCell(
                      TIGlyph.check,
                      tr('route_save'),
                      _saveRoute,
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
          // v2.0.28: labelled as what it is — «Отменить маршрут»,
          // one tap, no confirm (see _requestDeleteRoute).
          if (_stops.isNotEmpty) ...[
            const SizedBox(height: T.s24),
            DangerButton(
              text: tr('cancel_route'),
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
        if (r['visibility'] == 'public' ||
              (uid != null &&
                  (r['user_id'] == uid || r['visibility'] == 'friends')))
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
  /* Weekly quest ticks (v2.0.14, Item 7): persisted per calendar
     week — the weekId() bucket (Sunday→Saturday, v2.0.24) that also
     selects this week's quest — as 'week_done_<bucket>' (JSON step
     indices) plus a 'week_counted_<bucket>' flag so the finish
     credits stats.quests exactly once. One-way ticks: no un-tick,
     no XP farming. Ticks stored under the pre-v2.0.24 epoch bucket
     are orphaned: the current week's ticks reset once. */
  final Set<int> _weekDone = {};
  bool _weekCounted = false;
  SharedPreferences? _prefs;

  int get _weekBucket => weekId();

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
        : (_week[weekId() % _week.length] as Map).cast<String, dynamic>();
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

/* The one title shown under the nick — highest earned wins.
   v2.0.25: the XP rungs now mirror kLevels EXACTLY (this ladder
   used to jump 100 → 500, so a 250–499 XP user — «Тусовщик» in
   the profile progress — was titled «Бродяга» here). */
String? ghostTitle(Map<String, dynamic> stats, String cityName) {
  final xp = xpOfStats(stats);
  final places = (stats['places'] as List?)?.length ?? 0;
  if (xp >= 4000) return '${tr('lv_myth')} · $cityName';
  if (xp >= 2500) return '${tr('lv_keeper')} · $cityName';
  if (xp >= 1500) return '${tr('lv_night_legend')} · $cityName';
  if (statInt(stats, 'nights') >= 10) return '${tr('t_king')} · $cityName';
  if (places >= 25) return '${tr('b_explorer')} · $cityName';
  if (statInt(stats, 'routes') >= 5) return '${tr('b_architect')} · $cityName';
  if (xp >= 900) return '${tr('lv_city_ghost')} · $cityName';
  if (xp >= 500) return '${tr('ghost')} · $cityName';
  if (xp >= 250) return '${tr('lv_partier')} · $cityName';
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
          .select('id, name, avatar, avatar_url, stats, mode')
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
    /* v2.0.25: a ghost-mode user is masked on the board too — the
       query never even selected mode before, so the board showed
       his real name and photo while every other surface masked
       the name (and the map, until this version, the photo). */
    final ghostMode = row['mode'] == 'ghost';
    final shownName =
        ghostMode ? tr('ghost') : (row['name'] ?? tr('ghost')).toString();
    final shownAvatar = ghostMode ? null : row['avatar']?.toString();
    final shownUrl = ghostMode ? null : row['avatar_url']?.toString();
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
          /* v2.0.23: tap a top-ghost avatar → the zoom viewer (the
             row itself has no tap, so nothing competes). */
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showAvatarZoom(
              context,
              name: shownName,
              avatar: shownAvatar,
              avatarUrl: shownUrl,
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: T.surfaceHi,
              backgroundImage:
                  shownUrl != null ? NetworkImage(shownUrl) : null,
              child: shownUrl == null
                  ? AvatarFace(shownAvatar ?? '👻',
                      glyphSize: 20, emojiSize: 18)
                  : null,
            ),
          ),
          const SizedBox(width: T.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$shownName${mine ? tr('you_suffix') : ''}',
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

/* ---------------- friends tab · pings · stickers (v2.0.17) ----------------
   The owner: «добавь вкладку друзья, и сделай так чтоб когда я на
   карте нажимал на друга я мог кинуть ему там привет или что-то
   ещё», «смайлики… которые я могу кинуть — а точнее стикеры», «и
   чтоб можно было создать свои стикеры из галереи, и сохранение,
   чтоб люди могли сохранить стикер».

   Data contracts (server schema created in parallel):
   · pings(id, from_id, to_id, kind 'hi'|'sticker', sticker,
     created_at, seen_at) — a «привет» or a thrown sticker.
   · user_stickers(id, owner_id, path, created_at) — the user's own
     sticker collection; objects live in the PUBLIC 'stickers'
     bucket at '<uid>/<filename>.png'.
   · A sticker reference is either 'pack:1'…'pack:8' (the bundled
     pack in assets/stickers/) or a bucket path (custom sticker).
   No realtime subscription: pings refresh on app start, on Friends
   tab open and on HomePage's ~30 s friends cadence. */

/* One incoming ping, sender already joined to a Friend. */
class Ping {
  final String id;
  final Friend from;
  final String kind; // 'hi' | 'sticker' | 'invite'
  final String? sticker;
  /* v2.0.28: the invite payload (kind == 'invite'): the place the
     sender invites to, as stored on the pings row. [place] is the
     bundled Place the loader resolved from [placeId]; null when it
     isn't in the bundle — the card then renders [placeName] as
     plain, non-tappable text. */
  final String? placeId;
  final String? placeName;
  final Place? place;
  final DateTime createdAt;
  final bool seen;
  const Ping({
    required this.id,
    required this.from,
    required this.kind,
    this.sticker,
    this.placeId,
    this.placeName,
    this.place,
    required this.createdAt,
    this.seen = false,
  });

  Ping copyWith({bool? seen}) => Ping(
        id: id,
        from: from,
        kind: kind,
        sticker: sticker,
        placeId: placeId,
        placeName: placeName,
        place: place,
        createdAt: createdAt,
        seen: seen ?? this.seen,
      );
}

/* A profiles row → Friend (the join used by pings + friends tab).
   v2.0.25: GHOST MODE IS MASKED HERE, at construction — a ghost's
   Friend carries the «Призрак» name and NO avatar/avatarUrl, so
   every surface that renders a Friend (list rows, sheets, ping
   cards, avatar zoom, the DealSheet) is disguised by construction
   and none of them can leak the photo or the real name. */
Friend friendFromProfile(Map<String, dynamic> p) {
  final mode = p['mode'] as String?;
  final ghost = mode == 'ghost';
  return Friend(
    id: p['id'] as String,
    name: ghost ? tr('ghost') : ((p['name'] as String?) ?? tr('ghost')),
    avatar: ghost ? null : p['avatar'] as String?,
    avatarUrl: ghost ? null : p['avatar_url'] as String?,
    mode: mode,
    cityId: p['city'] as String?,
    online: p['online'] == true,
  );
}

/* «5 мин назад» — compact relative time for the ping inbox. */
String relTime(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return tr('rel_now');
  if (d.inMinutes < 60) return trf('rel_min', {'n': d.inMinutes});
  if (d.inHours < 24) return trf('rel_hour', {'n': d.inHours});
  return trf('rel_day', {'n': d.inDays});
}

/* v2.0.19: plural-form index for the counted nouns in the «you got
   mail» summary — 0 singular, 1 paucal, 2 plural. Russian follows
   the full 1 / 2–4 / 5+ rule with the 11–14 exception; Hebrew uses
   its אחד / שני / N forms; English only splits 1 vs the rest. */
int _pluralForm(int n) {
  switch (appLang.value) {
    case 'he':
      return n == 1 ? 0 : (n == 2 ? 1 : 2);
    case 'en':
      return n == 1 ? 0 : 2;
    default: // ru
      final m10 = n % 10, m100 = n % 100;
      if (m10 == 1 && m100 != 11) return 0;
      if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 1;
      return 2;
  }
}

/* «2 стикера» — base is a kStr stem ('ping_n_hi' / 'ping_n_st')
   with _1 / _2 / _n plural variants. */
String _countedNoun(String base, int n) {
  final form = _pluralForm(n);
  final key = form == 0 ? '${base}_1' : (form == 1 ? '${base}_2' : '${base}_n');
  return trf(key, {'n': n});
}

/* The sheet header: «Тебе отправили: 1 привет и 2 стикера» — a kind
   with a zero count is left out of the sentence entirely. */
String pingsSummary(int hi, int stickers) {
  if (hi > 0 && stickers > 0) {
    return trf('ping_got_both', {
      'hi': _countedNoun('ping_n_hi', hi),
      'st': _countedNoun('ping_n_st', stickers),
    });
  }
  if (hi > 0) return trf('ping_got_hi', {'hi': _countedNoun('ping_n_hi', hi)});
  return trf('ping_got_st', {'st': _countedNoun('ping_n_st', stickers)});
}

bool isPackSticker(String ref) => ref.startsWith('pack:');

String stickerPublicUrl(String path) =>
    supa.storage.from('stickers').getPublicUrl(path);

/* Renders a sticker reference at a square size: bundled asset for
   'pack:N', public bucket URL for a custom sticker path. */
Widget stickerImage(String ref, {double size = 96}) {
  final fallback = SizedBox(
    width: size,
    height: size,
    child: Center(
      child: TiradIcon(TIGlyph.ghost, size: size * 0.5, color: T.iconGray),
    ),
  );
  if (isPackSticker(ref)) {
    return Image.asset(
      'assets/stickers/st${ref.substring(5)}.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
  return Image.network(
    stickerPublicUrl(ref),
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (_, __, ___) => fallback,
  );
}

/* Friend avatar with the online dot — shared by the Friends tab
   rows and PingCard (extracted in v2.0.19 from _FriendsTabState). */
Widget friendAvatar(Friend f, {double radius = 22}) {
  return Stack(
    children: [
      CircleAvatar(
        radius: radius,
        backgroundColor: T.surfaceHi,
        backgroundImage:
            f.avatarUrl != null ? NetworkImage(f.avatarUrl!) : null,
        child: f.avatarUrl == null
            ? AvatarFace(f.avatar,
                glyphSize: radius, emojiSize: radius - 2, ghostForDefault: true)
            : null,
      ),
      if (f.online)
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: T.online,
              shape: BoxShape.circle,
              border: Border.all(color: T.surface, width: 2),
            ),
          ),
        ),
    ],
  );
}

/* v2.0.23: the shared avatar viewer — the owner: «добавь просмотр
   аватарок по ближе». One full-screen overlay used by every avatar
   tap in the app: near-black backdrop, the face as a big circle,
   the name underneath. A photo gets an InteractiveViewer (pinch
   1–4×, pan); the TI glyph and the legacy emoji render through the
   same AvatarFace pipeline, just large. Close: tap anywhere, the
   ✕, or the system back. [photo] (an explicit provider — the
   guest's on-device avatar file) wins over [avatarUrl]. */
void showAvatarZoom(
  BuildContext context, {
  required String name,
  String? avatar,
  String? avatarUrl,
  ImageProvider? photo,
}) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'avatar',
    barrierColor: Colors.black.withValues(alpha: 0.94),
    transitionDuration: const Duration(milliseconds: 180),
    transitionBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
    pageBuilder: (_, __, ___) => AvatarZoomView(
      name: name,
      avatar: avatar,
      avatarUrl: avatarUrl,
      photo: photo,
    ),
  );
}

class AvatarZoomView extends StatelessWidget {
  final String name;
  final String? avatar, avatarUrl;
  final ImageProvider? photo;
  const AvatarZoomView({
    super.key,
    required this.name,
    this.avatar,
    this.avatarUrl,
    this.photo,
  });

  /* The big face: a photo when there is one, falling back to the
     AvatarFace rendering while it loads and if it fails — the same
     glyph / emoji / ghost placeholder the small circles show. */
  Widget _face(double side) {
    final fallback = Container(
      width: side,
      height: side,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: T.surfaceHi,
      ),
      alignment: Alignment.center,
      child: AvatarFace(
        avatar,
        glyphSize: side * 0.52,
        emojiSize: side * 0.5,
        ghostForDefault: true,
      ),
    );
    final provider = photo ??
        (avatarUrl != null && avatarUrl!.isNotEmpty
            ? NetworkImage(avatarUrl!)
            : null);
    if (provider == null) return fallback;
    return ClipOval(
      child: Image(
        image: provider,
        width: side,
        height: side,
        fit: BoxFit.cover,
        frameBuilder: (_, child, frame, __) =>
            frame == null ? fallback : child,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final side = math.min(mq.size.width * 0.84, mq.size.height * 0.58);
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: _face(side),
                  ),
                  const SizedBox(height: T.s20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: T.s24),
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: T.head(20),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: mq.padding.top + T.s8,
              right: T.s12,
              child: Pressable(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: T.surfaceHi,
                  ),
                  alignment: Alignment.center,
                  child: const TiradIcon(TIGlyph.x, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* One ping as a card: sender (tap → their sheet, the reply path),
   the привет line or the sticker, and — for a custom sticker — the
   «Сохранить» affordance. Shared by the Friends tab inbox
   (stickerSize 96, with delete) and the v2.0.19 «you got mail»
   sheet (stickerSize 116, no delete). */
class PingCard extends StatelessWidget {
  final Ping ping;
  final bool saved;
  final VoidCallback? onSave;
  final VoidCallback? onDelete;
  final VoidCallback onOpenSender;
  /* v2.0.28: an invite ping's place tap — the host (HomePage via
     «Общее» / the entry sheet) opens the place's card with its real
     favs/check-in wiring. Null → a minimal sheet fallback. */
  final void Function(Place)? onOpenPlace;
  final double stickerSize;
  const PingCard({
    super.key,
    required this.ping,
    required this.onOpenSender,
    this.saved = false,
    this.onSave,
    this.onDelete,
    this.onOpenPlace,
    this.stickerSize = 96,
  });

  /* v2.0.28: an invite ping's body — «приглашает тебя в «…»» with
     the place name accented; the whole line opens the place's card
     when the loader resolved the bundled Place. Unresolved → the
     same text, plain and non-tappable. The split on '{place}'
     keeps every language's word order intact. */
  Widget _inviteBody(BuildContext context) {
    final p = ping;
    final name = p.place?.name ?? p.placeName ?? '';
    final raw = tr('ping_invite_text');
    if (!raw.contains('{place}')) {
      return Text(
        trf('ping_invite_text', {'place': name}),
        style: T.body(15),
      );
    }
    final parts = raw.split('{place}');
    final text = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: parts.first),
          TextSpan(
            text: name,
            style: T.body(15, color: T.ember, w: FontWeight.w800),
          ),
          if (parts.length > 1)
            TextSpan(text: parts.sublist(1).join('{place}')),
        ],
      ),
      style: T.body(15),
    );
    final place = p.place;
    if (place == null) return text;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final cb = onOpenPlace;
        if (cb != null) {
          cb(place);
        } else {
          showPlaceSheet(
            context,
            place,
            favs: const {},
            onToggleFav: (_) {},
            cityPlaces: [place],
            city: null,
          );
        }
      },
      child: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = ping;
    final canSave = p.kind == 'sticker' &&
        p.sticker != null &&
        !isPackSticker(p.sticker!);
    return Container(
      margin: const EdgeInsets.only(bottom: T.s8),
      padding: const EdgeInsets.all(T.s12),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: T.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              /* v2.0.23: the avatar opens the zoom viewer; the name
                 keeps the old tap → the sender's sheet (reply path). */
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showAvatarZoom(
                  context,
                  name: p.from.mode == 'ghost' ? tr('ghost') : p.from.name,
                  avatar: p.from.avatar,
                  avatarUrl: p.from.avatarUrl,
                ),
                child: friendAvatar(p.from, radius: 18),
              ),
              const SizedBox(width: T.s8),
              GestureDetector(
                onTap: onOpenSender,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.from.mode == 'ghost' ? tr('ghost') : p.from.name,
                      style: T.body(14, w: FontWeight.w700),
                    ),
                    Text(
                      relTime(p.createdAt),
                      style: T.body(11.5, color: T.faint),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (onDelete != null)
                Pressable(
                  onTap: onDelete,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: TiradIcon(TIGlyph.trash, size: 17, color: T.faint),
                  ),
                ),
            ],
          ),
          const SizedBox(height: T.s8),
          if (p.kind == 'hi')
            Text(tr('ping_hi_text'), style: T.body(16))
          else if (p.kind == 'invite')
            _inviteBody(context)
          else if (p.sticker != null)
            stickerImage(p.sticker!, size: stickerSize),
          if (canSave) ...[
            const SizedBox(height: T.s8),
            if (saved)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TiradIcon(TIGlyph.check, size: 14, color: T.online),
                  const SizedBox(width: 5),
                  Text(
                    tr('ping_saved'),
                    style: T.body(12.5, color: T.online, w: FontWeight.w700),
                  ),
                ],
              )
            else
              GhostButton(
                text: tr('ping_save'),
                small: true,
                icon: TIGlyph.plus,
                onPressed: onSave,
              ),
          ],
        ],
      ),
    );
  }
}

/* Pick an image for a custom sticker and re-encode it as PNG,
   KEEPING its transparency — pickAndProcessImage re-encodes to
   JPEG for place photos, which would flatten a sticker's alpha
   onto black. The longest side is capped at 512. Returns null ONLY
   when the user cancels; failures throw ImagePickException (the
   same contract as pickAndProcessImage). */
Future<Uint8List?> pickAndProcessSticker() async {
  try {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x == null) return null;
    final bytes = await x.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;
    var out = decoded;
    const cap = 512;
    if (out.width > cap || out.height > cap) {
      out = out.width >= out.height
          ? img.copyResize(out, width: cap)
          : img.copyResize(out, height: cap);
    }
    return Uint8List.fromList(img.encodePng(out));
  } catch (e) {
    throw ImagePickException(e);
  }
}

/* The friend bottom sheet — opened from a map marker tap and from
   the Friends tab. v2.0.17 adds the actions area: «Привет» and
   «Стикер» throw a ping at the friend (pings table). */
/* v2.0.28: the bundled places, parsed once and cached — the same
   assets/places.json + Place.fromJson HomePage loads at startup.
   The invite place picker opens from a person's card, where no
   HomePage list is in scope, so it reads the bundle through here. */
List<Place>? _bundledPlacesCache;

Future<List<Place>> loadBundledPlaces() async {
  final cached = _bundledPlacesCache;
  if (cached != null) return cached;
  try {
    final raw = await rootBundle.loadString('assets/places.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => Place.fromJson(e as Map<String, dynamic>))
        .toList();
    _bundledPlacesCache = list;
    return list;
  } catch (e) {
    debugPrint('TiradA bundled places load failed: $e');
    return const [];
  }
}

/* v2.0.28: send an invite ping — a pings row {kind: 'invite',
   place_id, place_name} plus the same EventPush.ping() the hi /
   sticker sends fire, so send-fcm composes the recipient's push
   from the row. False on any failure (the caller surfaces the
   standard error snack and keeps its picker open). */
Future<bool> sendInvitePing({
  required String toId,
  required Place place,
}) async {
  final uid = myUidOrNull;
  if (uid == null) return false;
  try {
    final row = await supa.from('pings').insert({
      'from_id': uid,
      'to_id': toId,
      'kind': 'invite',
      'place_id': place.id,
      'place_name': place.name,
    }).select('id').single();
    final pingId = (row as Map)['id']?.toString();
    if (pingId != null) EventPush.ping(pingId);
    return true;
  } catch (e) {
    debugPrint('TiradA invite insert failed: $e');
    return false;
  }
}

/* v2.0.28: «Пригласить» on a place card — pick WHO to invite here.
   The list is the same everyone-list «Общее» shows (every profile
   except me, same query/sort as _loadFriends), ghost-masked by
   construction via friendFromProfile. A tap sends the invite for
   THIS sheet's place at once. */
class InvitePersonSheet extends StatefulWidget {
  final Place place;
  const InvitePersonSheet({super.key, required this.place});

  @override
  State<InvitePersonSheet> createState() => _InvitePersonSheetState();
}

class _InvitePersonSheetState extends State<InvitePersonSheet> {
  List<Friend> _people = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = myUidOrNull;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final profs = await supa
          .from('profiles')
          .select('id, name, avatar, avatar_url, online, mode, city')
          .neq('id', uid)
          .limit(500);
      if (!mounted) return;
      final list = <Friend>[
        for (final p in profs as List)
          friendFromProfile(Map<String, dynamic>.from(p as Map)),
      ]..sort((a, b) {
          if (a.online != b.online) return a.online ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      setState(() {
        _people = list;
        _loading = false;
      });
    } catch (e) {
      debugPrint('TiradA invite people load failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pick(Friend f) async {
    if (_sending) return;
    setState(() => _sending = true);
    final ok = await sendInvitePing(toId: f.id, place: widget.place);
    if (!mounted) return;
    if (!ok) {
      setState(() => _sending = false);
      snack(context, tr('friends_error'));
      return;
    }
    // The standard sent-snack, shown on the root context so it
    // survives this sheet closing (the _sendHi pattern).
    final nav = Navigator.of(context);
    nav.pop();
    snack(nav.context, tr('invite_sent'));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.72,
      ),
      child: SheetShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(T.s20, T.s4, T.s20, T.s12),
              child: Text(tr('invite_pick_person'), style: T.head(17)),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(T.s24),
                child: Center(
                  child: CircularProgressIndicator(color: kRed),
                ),
              )
            else if (_people.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(T.s20, 0, T.s20, T.s20),
                child: Text(
                  tr('invite_nobody'),
                  style: T.body(13.5, color: T.muted),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _people.length,
                  itemBuilder: (_, i) {
                    final f = _people[i];
                    return Pressable(
                      onTap: _sending ? null : () => _pick(f),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: T.s20, vertical: T.s8),
                        child: Row(
                          children: [
                            friendAvatar(f, radius: 20),
                            const SizedBox(width: T.s12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.mode == 'ghost'
                                        ? tr('ghost')
                                        : f.name,
                                    style:
                                        T.body(14.5, w: FontWeight.w700),
                                  ),
                                  Text(
                                    f.online
                                        ? tr('online_now')
                                        : tr('seen_recently'),
                                    style: T.body(12,
                                        color: f.online
                                            ? T.online
                                            : T.faint),
                                  ),
                                ],
                              ),
                            ),
                            const TiradIcon(TIGlyph.paperPlane,
                                size: 17, color: T.iconGray),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/* v2.0.28: «Пригласить куда-то» on a person's card — pick WHERE to
   invite this person. Searchable over the bundled places, nearest
   first when a live position is known (vibe order otherwise).
   Pops with true after a successful send; the host FriendSheet
   then closes too, mirroring its _sendHi ending. */
class InvitePlaceSheet extends StatefulWidget {
  final Friend friend;
  const InvitePlaceSheet({super.key, required this.friend});

  @override
  State<InvitePlaceSheet> createState() => _InvitePlaceSheetState();
}

class _InvitePlaceSheetState extends State<InvitePlaceSheet> {
  List<Place> _all = [];
  bool _loading = true;
  bool _sending = false;
  String _q = '';
  final TextEditingController _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await loadBundledPlaces();
    if (!mounted) return;
    final origin = myLocationNotifier.value;
    final sorted = [...list];
    if (origin != null) {
      sorted.sort((a, b) => haversineKm(
              origin.latitude, origin.longitude, a.lat, a.lng)
          .compareTo(
              haversineKm(origin.latitude, origin.longitude, b.lat, b.lng)));
    } else {
      sorted.sort((a, b) => vibeOf(b).compareTo(vibeOf(a)));
    }
    setState(() {
      _all = sorted;
      _loading = false;
    });
  }

  List<Place> get _filtered {
    final q = _q.trim().toLowerCase();
    final base = q.isEmpty
        ? _all
        : _all.where((p) => p.name.toLowerCase().contains(q));
    return base.take(60).toList();
  }

  Future<void> _pick(Place p) async {
    if (_sending) return;
    setState(() => _sending = true);
    final ok = await sendInvitePing(toId: widget.friend.id, place: p);
    if (!mounted) return;
    if (!ok) {
      setState(() => _sending = false);
      snack(context, tr('friends_error'));
      return;
    }
    final nav = Navigator.of(context);
    nav.pop(true);
    snack(nav.context, tr('invite_sent'));
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      child: SheetShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(T.s20, T.s4, T.s20, T.s8),
              child: Text(tr('invite_pick_place'), style: T.head(17)),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(T.s20, 0, T.s20, T.s12),
              child: TextField(
                controller: _searchCtl,
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(hintText: tr('search_hint')),
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(T.s24),
                child: Center(
                  child: CircularProgressIndicator(color: kRed),
                ),
              )
            else if (list.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(T.s20, 0, T.s20, T.s20),
                child: Text(
                  tr('invite_no_places'),
                  style: T.body(13.5, color: T.muted),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final p = list[i];
                    return Pressable(
                      onTap: _sending ? null : () => _pick(p),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: T.s20, vertical: T.s8),
                        child: Row(
                          children: [
                            TiradIcon(typeGlyph(p.type),
                                size: 17, color: T.iconGray),
                            const SizedBox(width: T.s12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        T.body(14.5, w: FontWeight.w700),
                                  ),
                                  Text(
                                    tr(kTypeNames[p.type] ?? 'type_other'),
                                    style: T.body(12, color: T.faint),
                                  ),
                                ],
                              ),
                            ),
                            const TiradIcon(TIGlyph.paperPlane,
                                size: 17, color: T.iconGray),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void showFriendSheet(BuildContext context, Friend f) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => FriendSheet(friend: f),
  );
}

class FriendSheet extends StatefulWidget {
  final Friend friend;
  const FriendSheet({super.key, required this.friend});

  @override
  State<FriendSheet> createState() => _FriendSheetState();
}

class _FriendSheetState extends State<FriendSheet> {
  bool _sendingHi = false;
  bool _stickerSent = false;

  void _promptLogin() {
    snack(context, tr('ping_signin'));
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
    );
  }

  Future<void> _sendHi() async {
    final uid = myUidOrNull;
    if (uid == null) {
      _promptLogin();
      return;
    }
    if (_sendingHi) return;
    setState(() => _sendingHi = true);
    String? pingId;
    try {
      final row = await supa.from('pings').insert({
        'from_id': uid,
        'to_id': widget.friend.id,
        'kind': 'hi',
      }).select('id').single();
      pingId = (row as Map)['id']?.toString();
    } catch (e) {
      debugPrint('TiradA ping (hi) insert failed: $e');
      if (mounted) {
        setState(() => _sendingHi = false);
        snack(context, tr('friends_error'));
      }
      return;
    }
    // v2.0.26: real push to the recipient — fire-and-forget, the
    // function validates this ping row against the caller's JWT.
    if (pingId != null) EventPush.ping(pingId);
    if (!mounted) return;
    final nav = Navigator.of(context);
    nav.pop();
    snack(nav.context, tr('ping_sent_hi'));
  }

  /* The picker's send callback: insert the sticker ping. Throws on
     failure so the picker stays open; the error is surfaced here. */
  Future<void> _sendStickerRef(String ref) async {
    final uid = myUidOrNull;
    if (uid == null) throw StateError('guest');
    String? pingId;
    try {
      final row = await supa.from('pings').insert({
        'from_id': uid,
        'to_id': widget.friend.id,
        'kind': 'sticker',
        'sticker': ref,
      }).select('id').single();
      pingId = (row as Map)['id']?.toString();
    } catch (e) {
      debugPrint('TiradA ping (sticker) insert failed: $e');
      if (mounted) snack(context, tr('friends_error'));
      rethrow;
    }
    // v2.0.26: real push to the recipient (fire-and-forget).
    if (pingId != null) EventPush.ping(pingId);
    _stickerSent = true;
  }

  /* v2.0.28: «Пригласить куда-то» — pick a place and send this
     person an invite ping to it (InvitePlaceSheet/sendInvitePing).
     On success the picker pops with true and this sheet closes
     too, exactly like _sendHi's ending. */
  Future<void> _openInvitePlace() async {
    if (myUidOrNull == null) {
      _promptLogin();
      return;
    }
    final sent = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => InvitePlaceSheet(friend: widget.friend),
    );
    if (sent == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openStickers() async {
    if (myUidOrNull == null) {
      _promptLogin();
      return;
    }
    _stickerSent = false;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StickerPickerSheet(onSend: _sendStickerRef),
    );
    if (!mounted) return;
    if (_stickerSent) {
      final nav = Navigator.of(context);
      nav.pop();
      snack(nav.context, tr('ping_sent_sticker'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.friend;
    return SheetShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(T.s20, T.s4, T.s20, T.s20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                /* v2.0.23: tap the sheet's avatar → the zoom viewer. */
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showAvatarZoom(
                    context,
                    name: f.mode == 'ghost' ? tr('ghost') : f.name,
                    avatar: f.avatar,
                    avatarUrl: f.avatarUrl,
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: T.surfaceHi,
                    backgroundImage:
                        f.avatarUrl != null ? NetworkImage(f.avatarUrl!) : null,
                    child: f.avatarUrl == null
                        ? AvatarFace(f.avatar,
                            glyphSize: 28, emojiSize: 26, ghostForDefault: true)
                        : null,
                  ),
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
            const SizedBox(height: T.s16),
            Row(
              children: [
                Expanded(
                  child: FireButton(
                    text: tr('ping_hi_btn'),
                    small: true,
                    icon: TIGlyph.ghost,
                    onPressed: _sendingHi ? null : _sendHi,
                  ),
                ),
                const SizedBox(width: T.s12),
                Expanded(
                  child: GhostButton(
                    text: tr('ping_sticker_btn'),
                    small: true,
                    icon: TIGlyph.photo,
                    onPressed: _openStickers,
                  ),
                ),
              ],
            ),
            const SizedBox(height: T.s12),
            GhostButton(
              text: tr('invite_place_btn'),
              small: true,
              icon: TIGlyph.paperPlane,
              onPressed: _openInvitePlace,
            ),
          ],
        ),
      ),
    );
  }
}

/* Sticker picker: the bundled pack + the user's own stickers, with
   creation from the gallery and long-press delete. Tapping any
   sticker sends it through [onSend] and closes the picker. */
class StickerPickerSheet extends StatefulWidget {
  final Future<void> Function(String ref) onSend;
  const StickerPickerSheet({super.key, required this.onSend});

  @override
  State<StickerPickerSheet> createState() => _StickerPickerSheetState();
}

class _StickerPickerSheetState extends State<StickerPickerSheet> {
  List<Map<String, dynamic>> _mine = [];
  bool _loading = true;
  bool _creating = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMine();
  }

  Future<void> _loadMine() async {
    final uid = myUidOrNull;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final rows = await supa
          .from('user_stickers')
          .select('id, path, created_at')
          .eq('owner_id', uid)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _mine = [
          for (final r in rows as List) Map<String, dynamic>.from(r as Map),
        ];
        _loading = false;
      });
    } catch (e) {
      debugPrint('TiradA user_stickers load failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send(String ref) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await widget.onSend(ref);
    } catch (_) {
      if (mounted) setState(() => _sending = false);
      return; // stay open — the sender already surfaced the error
    }
    if (mounted) Navigator.of(context).pop();
  }

  /* Create a custom sticker: gallery → PNG (alpha kept, ≤512) →
     'stickers' bucket at '<uid>/<ts>.png' → user_stickers row →
     it appears in «Мои стикеры» at once. Staged errors, like the
     2.0.14 photo fix. */
  Future<void> _createSticker() async {
    final uid = myUidOrNull;
    if (uid == null || _creating) return;
    final Uint8List? bytes;
    try {
      bytes = await pickAndProcessSticker();
    } on ImagePickException catch (e) {
      debugPrint('TiradA sticker pick failed: $e');
      if (mounted) snack(context, tr('sticker_pick_fail'));
      return;
    }
    if (bytes == null || !mounted) return;
    setState(() => _creating = true);
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.png';
    try {
      await supa.storage.from('stickers').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );
    } catch (e) {
      debugPrint('TiradA sticker upload failed: $e');
      if (mounted) {
        snack(context, tr('sticker_upload_fail'));
        setState(() => _creating = false);
      }
      return;
    }
    try {
      await supa.from('user_stickers').insert({
        'owner_id': uid,
        'path': path,
      });
    } catch (e) {
      debugPrint('TiradA user_stickers insert failed: $e');
      if (mounted) {
        snack(context, tr('sticker_save_fail'));
        setState(() => _creating = false);
      }
      return;
    }
    if (!mounted) return;
    setState(() => _creating = false);
    snack(context, tr('sticker_created'));
    _loadMine();
  }

  Future<void> _deleteMine(Map<String, dynamic> row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: T.surface,
        title: Text(tr('sticker_delete_title'), style: T.head(16)),
        content: Text(
          tr('sticker_delete_body'),
          style: T.body(14, color: T.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(tr('friends_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              tr('ping_delete'),
              style: const TextStyle(color: T.salmon),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final id = (row['id'] ?? '').toString();
    final path = (row['path'] ?? '').toString();
    try {
      await supa.from('user_stickers').delete().eq('id', id);
    } catch (e) {
      debugPrint('TiradA user_stickers delete failed: $e');
      if (mounted) snack(context, tr('friends_error'));
      return;
    }
    try {
      await supa.storage.from('stickers').remove([path]);
    } catch (_) {}
    if (mounted) {
      setState(() => _mine.removeWhere((r) => r['id'] == row['id']));
    }
  }

  Widget _tile(Widget child, {VoidCallback? onTap, VoidCallback? onLongPress}) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: T.surfaceHi,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: T.stroke),
        ),
        padding: const EdgeInsets.all(6),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(T.s20, T.s4, T.s20, T.s20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sectionLabel(tr('sticker_pack_title'), glyph: TIGlyph.flame),
                GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var i = 1; i <= 8; i++)
                      _tile(
                        Image.asset(
                          'assets/stickers/st$i.png',
                          fit: BoxFit.contain,
                        ),
                        onTap: () => _send('pack:$i'),
                      ),
                  ],
                ),
                const SizedBox(height: T.s20),
                sectionLabel(tr('sticker_mine_title'), glyph: TIGlyph.star),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: T.s16),
                    child: Center(
                      child: CircularProgressIndicator(color: kRed),
                    ),
                  )
                else
                  GridView.count(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _tile(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_creating)
                              const CircularProgressIndicator(
                                color: kRed,
                                strokeWidth: 2,
                              )
                            else
                              const TiradIcon(TIGlyph.plus,
                                  size: 24, color: T.iconGray),
                            const SizedBox(height: 4),
                            Text(
                              tr('sticker_from_gallery'),
                              textAlign: TextAlign.center,
                              style: T.body(9.5, color: T.muted),
                            ),
                          ],
                        ),
                        onTap: _creating ? null : _createSticker,
                      ),
                      for (final row in _mine)
                        _tile(
                          Image.network(
                            stickerPublicUrl((row['path'] ?? '').toString()),
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: TiradIcon(TIGlyph.ghost,
                                  size: 24, color: T.iconGray),
                            ),
                          ),
                          onTap: () =>
                              _send((row['path'] ?? '').toString()),
                          onLongPress: () => _deleteMine(row),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------- «you got mail» sheet (v2.0.19) ----------------
   Presented by HomePage over whatever tab is showing: on entry
   with everything unseen, and mid-session with just the newly
   arrived items. The header is the counted summary («Тебе
   отправили: 1 привет и 2 стикера»); the body is the shared
   PingCard list with the sticker big (116 dp — the sticker is the
   point); dismissal marks exactly these pings seen (HomePage's
   _markPingsSeenIds). Save state mirrors the inbox: the sheet
   loads its own saved-paths set and runs the same insert. */
class NewPingsSheet extends StatefulWidget {
  final List<Ping> pings;
  /* v2.0.28: an invite ping's place tap (see PingCard.onOpenPlace). */
  final void Function(Place)? onOpenPlace;
  const NewPingsSheet({super.key, required this.pings, this.onOpenPlace});

  @override
  State<NewPingsSheet> createState() => _NewPingsSheetState();
}

class _NewPingsSheetState extends State<NewPingsSheet> {
  final Set<String> _savedPaths = {};

  @override
  void initState() {
    super.initState();
    _loadSavedPaths();
  }

  Future<void> _loadSavedPaths() async {
    final uid = myUidOrNull;
    if (uid == null) return;
    try {
      final rows = await supa
          .from('user_stickers')
          .select('path')
          .eq('owner_id', uid);
      if (!mounted) return;
      setState(() {
        _savedPaths
          ..clear()
          ..addAll([
            for (final r in rows as List) (r['path'] ?? '').toString(),
          ]);
      });
    } catch (e) {
      debugPrint('TiradA saved stickers load failed: $e');
    }
  }

  /* The inbox's save flow, verbatim: insert the path into my
     collection, then flip the card to «Сохранено». */
  Future<void> _saveSticker(Ping p) async {
    final uid = myUidOrNull;
    final path = p.sticker;
    if (uid == null || path == null) return;
    try {
      await supa.from('user_stickers').insert({
        'owner_id': uid,
        'path': path,
      });
    } catch (e) {
      debugPrint('TiradA sticker save failed: $e');
      if (mounted) snack(context, tr('friends_error'));
      return;
    }
    if (mounted) setState(() => _savedPaths.add(path));
  }

  /* Reply path: close this sheet first, then open the friend's
     sheet on the navigator's context (the FriendSheet pattern). */
  void _openSender(Ping p) {
    final nav = Navigator.of(context);
    nav.pop();
    showFriendSheet(nav.context, p.from);
  }

  @override
  Widget build(BuildContext context) {
    final hi = widget.pings.where((p) => p.kind == 'hi').length;
    final st = widget.pings.length - hi;
    return SheetShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(T.s20, T.s4, T.s20, T.s20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              pingsSummary(hi, st),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: T.s16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.52,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final p in widget.pings)
                    PingCard(
                      ping: p,
                      stickerSize: 116,
                      saved: p.sticker != null &&
                          _savedPaths.contains(p.sticker),
                      onSave: () => _saveSticker(p),
                      onOpenSender: () => _openSender(p),
                      onOpenPlace: widget.onOpenPlace,
                    ),
                ],
              ),
            ),
            const SizedBox(height: T.s12),
            FireButton(
              text: tr('ping_got_ok'),
              icon: TIGlyph.check,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- friends tab ----------------
   v2.0.21: ONE friends system (the Profile tab keeps only a
   «Друзья» jump row) — every registered user is automatically
   everyone's friend, so this tab is simply everyone: all
   profiles, owned by HomePage and flowing in as the friends
   prop, sorted online-first, a nickname filter over them, and
   the ping inbox («Приветы и стикеры») above the list. No
   requests, no accepting — the friendships table is no longer
   read or written here. The tab owns the filter text and the
   saved-sticker set. */
class FriendsTab extends StatefulWidget {
  final List<Friend> friends;
  final List<Ping> pings;
  final void Function(Friend) onOpenFriend;
  final VoidCallback onPingsChanged;
  /* v2.0.28: an invite ping's place tap (see PingCard.onOpenPlace). */
  final void Function(Place)? onOpenPlace;
  const FriendsTab({
    super.key,
    required this.friends,
    required this.pings,
    required this.onOpenFriend,
    required this.onPingsChanged,
    this.onOpenPlace,
  });

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  final Set<String> _savedPaths = {};

  @override
  void initState() {
    super.initState();
    _loadSavedPaths();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /* The nickname filter over the all-users list — local, the list
     is already in memory (HomePage caps it at 500 profiles). */
  List<Friend> get _shown {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.friends;
    return [
      for (final f in widget.friends)
        if (f.name.toLowerCase().contains(q)) f,
    ];
  }

  Future<void> _loadSavedPaths() async {
    final uid = myUidOrNull;
    if (uid == null) return;
    try {
      final rows = await supa
          .from('user_stickers')
          .select('path')
          .eq('owner_id', uid);
      if (!mounted) return;
      setState(() {
        _savedPaths
          ..clear()
          ..addAll([
            for (final r in rows as List) (r['path'] ?? '').toString(),
          ]);
      });
    } catch (e) {
      debugPrint('TiradA saved stickers load failed: $e');
    }
  }

  Future<void> _savePingSticker(Ping p) async {
    final uid = myUidOrNull;
    final path = p.sticker;
    if (uid == null || path == null) return;
    try {
      await supa.from('user_stickers').insert({
        'owner_id': uid,
        'path': path,
      });
    } catch (e) {
      debugPrint('TiradA sticker save failed: $e');
      if (mounted) snack(context, tr('friends_error'));
      return;
    }
    if (mounted) setState(() => _savedPaths.add(path));
  }

  Future<void> _deletePing(Ping p) async {
    try {
      await supa.from('pings').delete().eq('id', p.id);
    } catch (e) {
      debugPrint('TiradA ping delete failed: $e');
      if (mounted) snack(context, tr('friends_error'));
      return;
    }
    widget.onPingsChanged();
  }

  /* v2.0.19: the avatar rendering lives in the shared friendAvatar
     (PingCard uses it too); this stays as the tab's local shortcut. */
  Widget _avatar(Friend f, {double radius = 22}) =>
      friendAvatar(f, radius: radius);

  Widget _personRow(Friend f, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: T.s8),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: T.stroke),
      ),
      child: ListTile(
        onTap: onTap,
        /* v2.0.23: the avatar intercepts its own tap → the zoom
           viewer; the rest of the row still opens the friend sheet
           (the inner GestureDetector wins the arena over the tile's
           InkWell, the standard leading-button pattern). */
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showAvatarZoom(
            context,
            name: f.mode == 'ghost' ? tr('ghost') : f.name,
            avatar: f.avatar,
            avatarUrl: f.avatarUrl,
          ),
          child: _avatar(f),
        ),
        title: Text(
          f.mode == 'ghost' ? tr('ghost') : f.name,
          style: T.body(15, w: FontWeight.w700),
        ),
        subtitle: Text(
          f.online ? tr('online_now') : tr('seen_recently'),
          style: T.body(12, color: f.online ? T.online : T.faint),
        ),
      ),
    );
  }

  /* v2.0.19: the row rendering lives in the shared PingCard (the
     «you got mail» sheet renders the same card bigger); this wires
     it to the tab's saved-set, delete and reply callbacks. */
  Widget _pingRow(Ping p) {
    final canSave = p.kind == 'sticker' &&
        p.sticker != null &&
        !isPackSticker(p.sticker!);
    return PingCard(
      ping: p,
      saved: canSave && _savedPaths.contains(p.sticker),
      onSave: () => _savePingSticker(p),
      onDelete: () => _deletePing(p),
      onOpenSender: () => widget.onOpenFriend(p.from),
      onOpenPlace: widget.onOpenPlace,
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = myUidOrNull;
    if (uid == null) {
      return GlowBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(T.s16, T.s12, T.s16, T.s24),
          children: [
            EmptyState(
              glyph: TIGlyph.users,
              title: tr('nav_friends'),
              hint: tr('friends_guest'),
            ),
            FireButton(
              text: tr('ping_signin'),
              icon: TIGlyph.ghost,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      );
    }
    return GlowBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(T.s16, T.s12, T.s16, T.s24),
        children: [
          TextField(
            controller: _searchCtrl,
            style: T.body(15),
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: tr('friends_search_hint'),
              hintStyle: T.body(14, color: T.faint),
              filled: true,
              fillColor: T.surface,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: T.stroke),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: T.stroke),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: T.fire),
              ),
            ),
          ),
          const SizedBox(height: T.s16),
          sectionLabel(tr('ping_inbox_title'), glyph: TIGlyph.chat),
          if (widget.pings.isEmpty)
            Text(
              tr('ping_inbox_empty'),
              style: T.body(13, color: T.muted),
            )
          else
            for (final p in widget.pings) _pingRow(p),
          const SizedBox(height: T.s16),
          sectionLabel(tr('friends_list_title'), glyph: TIGlyph.users),
          Text(
            tr('friends_all_note'),
            style: T.body(12.5, color: T.muted),
          ),
          const SizedBox(height: T.s8),
          if (widget.friends.isEmpty)
            EmptyState(
              glyph: TIGlyph.users,
              title: tr('friends_none'),
              hint: tr('friends_none_hint'),
            )
          else if (_shown.isEmpty)
            Text(
              tr('friends_not_found'),
              style: T.body(13, color: T.muted),
            )
          else
            for (final f in _shown)
              _personRow(f, onTap: () => widget.onOpenFriend(f)),
        ],
      ),
    );
  }
}

/* v2.0.25: the streak week card — renders the REAL per-day history
   (StreakService) for the current Sun–Sat week (the app's week):
   a flame for a completed day, ICE (the TI snowflake) for a missed
   tracked day, a pending outline for today before its first task,
   a plain empty cell for future days and for days before the
   history starts. The header count comes from the stats mirror —
   the same numbers xpOfStats reads; both derive from the one day
   map, so they cannot disagree. */
class _StreakWeekCard extends StatefulWidget {
  final Map<String, dynamic> stats;
  const _StreakWeekCard({required this.stats});

  @override
  State<_StreakWeekCard> createState() => _StreakWeekCardState();
}

class _StreakWeekCardState extends State<_StreakWeekCard> {
  Set<String> _days = {};
  String _since = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_StreakWeekCard old) {
    super.didUpdateWidget(old);
    if (statInt(old.stats, 'streak') != statInt(widget.stats, 'streak') ||
        statInt(old.stats, 'bestStreak') !=
            statInt(widget.stats, 'bestStreak')) {
      _load();
    }
  }

  Future<void> _load() async {
    final h = await StreakService.history();
    if (!mounted) return;
    setState(() {
      _days = h.$1;
      _since = h.$2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stats;
    final streak = statInt(s, 'streak');
    final bestStreak = math.max(streak, statInt(s, 'bestStreak'));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sunday = today.subtract(Duration(days: now.weekday % 7));
    // 0 done · 1 ice · 2 today, pending · 3 plain empty
    int stateOf(int i) {
      final d = sunday.add(Duration(days: i));
      final key = dayKeyOf(d);
      if (_days.contains(key)) return 0;
      if (d.isAtSameMomentAs(today)) return 2;
      if (d.isBefore(today) &&
          _since.isNotEmpty &&
          key.compareTo(_since) >= 0) {
        return 1;
      }
      return 3;
    }

    Widget cell(int i) {
      final st = stateOf(i);
      final d = sunday.add(Duration(days: i));
      final isToday = d.isAtSameMomentAs(today);
      return Column(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: st == 0 ? T.fireGradV : null,
              color: st == 0
                  ? null
                  : (st == 1 ? const Color(0xFF1E2E3A) : T.surfaceHi),
              border: st == 0
                  ? null
                  : Border.all(
                      color: st == 1
                          ? const Color(0xFF5B7A8C)
                          : (st == 2
                              ? T.ember.withValues(alpha: 0.55)
                              : T.faint.withValues(alpha: 0.4))),
              boxShadow: st == 0
                  ? [
                      BoxShadow(
                        color: T.fire.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: st == 0
                ? const TiradIcon(TIGlyph.flame,
                    size: 15, color: Colors.white, filled: true)
                : st == 1
                    ? const TiradIcon(TIGlyph.snowflake,
                        size: 16, color: Color(0xFFA9CCE3))
                    : st == 2
                        ? const TiradIcon(TIGlyph.flame,
                            size: 15, color: T.faint)
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
            [
              tr('wd_7'),
              tr('wd_1'),
              tr('wd_2'),
              tr('wd_3'),
              tr('wd_4'),
              tr('wd_5'),
              tr('wd_6')
            ][i],
            style: T.body(10,
                color: isToday ? T.ember : T.faint, w: FontWeight.w700),
          ),
        ],
      );
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
              Text(trf('streak_line', {'n': streak}), style: T.head(15)),
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
            children: [for (var i = 0; i < 7; i++) cell(i)],
          ),
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
  /* v2.0.17: the friends system moved to its own tab — Profile
     keeps a single «Друзья» jump row. */
  final VoidCallback onOpenFriends;
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
    required this.onOpenFriends,
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

  /* Settings → «Проверить уведомления». v2.0.26: a STAGED report
     instead of the old single line — the old check read back only
     the (empty) device_tokens table and showed the same
     «notif_token_none» text even when the real failure was the
     display path (its result was `shown ? status : token_none`),
     so it could never say WHERE the chain breaks. Now each stage
     is named: Firebase initialised → permission → token fetched
     on this phone (probe() also re-registers it) → token row on
     the server → a real local test notification for the display
     path. The stages are independent: the local notification
     firing proves ONLY the display path, never FCM delivery. */
  Future<void> _runPushCheck(void Function(VoidCallback) setPageState) async {
    if (_pushChecking) return;
    setPageState(() {
      _pushChecking = true;
      _pushCheckResult = null;
    });
    await PushService.ensurePermission();
    await LocalNotify.requestPermission();
    String status;
    if (myUidOrNull == null) {
      status = tr('notif_guest_push');
    } else {
      final p = await PushService.probe();
      String yn(bool v) => tr(v ? 'notif_st_yes' : 'notif_st_no');
      var server = yn(false);
      try {
        final s = await PushService.tokenStatus();
        if (s.count > 0) {
          final t = s.last?.toLocal();
          final when = t == null
              ? ''
              : ' · ${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')} '
                  '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
          server = '${yn(true)}$when';
        }
      } catch (e) {
        debugPrint('TiradA device_tokens status failed: $e');
      }
      final lines = <String>[
        'Firebase: ${yn(p.firebase)}',
        '${tr('notif_check_perm')}: '
            '${tr(p.permGranted ? 'notif_st_granted' : 'notif_st_denied')}',
        '${tr('notif_check_token')}: ${yn(p.tokenOk)}',
        '${tr('notif_check_server')}: $server',
        if (p.error != null) trf('notif_check_error', {'e': p.error!}),
      ];
      status = lines.join('\n');
    }
    final shown =
        await LocalNotify.show(tr('notif_test_title'), tr('notif_test_body'));
    if (!mounted) return;
    setPageState(() {
      _pushChecking = false;
      // The display stage is its own line — it no longer overwrites
      // the registration stages the way the old single line did.
      _pushCheckResult = myUidOrNull == null
          ? status
          : '$status\n${tr('notif_check_display')}: '
              '${tr(shown ? 'notif_st_yes' : 'notif_st_no')}';
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

  bool _nickSaving = false;

  /* v2.0.25: nickname editing — before, the «Ник призрака» block
     was a read-only Text: the name was written ONCE at sign-up
     (from the email prefix) and no code path ever updated
     profiles.name again, so the owner simply had nowhere to change
     it. Now: dialog → validated update of the SAME profiles.name
     every surface reads (map marker, «Общее», sheets, board) →
     onProfileChanged refreshes the UI at once; the value persists
     in the DB, so it survives re-login. The DB has a unique index
     on lower(name) (the sign-up flow relies on it), so a taken
     nick surfaces as a localized «taken» error; any other failure
     shows a generic save error — never a silent no-op. */
  Future<void> _editNick() async {
    final uid = myUidOrNull;
    if (uid == null || _nickSaving) return;
    final current = (widget.profile?['name'] as String?) ?? '';
    final ctl = TextEditingController(text: current);
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: T.surface,
        title: Text(tr('ghost_nick_label'), style: T.head(16)),
        content: TextField(
          controller: ctl,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(hintText: tr('nick_hint')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr('cancel_btn')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctl.text),
            child: Text(tr('save_btn')),
          ),
        ],
      ),
    );
    if (res == null || !mounted) return;
    final name = res.trim();
    if (name.length < 2 || name == current) return;
    setState(() => _nickSaving = true);
    try {
      await supa.from('profiles').update({'name': name}).eq('id', uid);
      widget.onProfileChanged({...?widget.profile, 'name': name});
      if (mounted) snack(context, tr('nick_saved'));
    } catch (e) {
      debugPrint('TiradA nickname update failed: $e');
      if (mounted) {
        final s = e.toString().toLowerCase();
        final taken = s.contains('23505') ||
            s.contains('duplicate') ||
            s.contains('unique');
        snack(context, tr(taken ? 'nick_taken' : 'nick_save_fail'));
      }
    } finally {
      if (mounted) setState(() => _nickSaving = false);
    }
  }

  /* v2.0.25: sign-out stops the background location service and
     takes me off the map (location row deleted, online=false)
     BEFORE the session ends — previously it was a bare signOut()
     and the ghost stayed «online» at his last spot. */
  Future<void> _signOut() async {
    final uid = myUidOrNull;
    await LocationService.stopAll();
    if (uid != null) {
      try {
        await supa.from('profile_locations').delete().eq('user_id', uid);
      } catch (_) {}
      try {
        await supa.from('profiles').update({'online': false}).eq('id', uid);
      } catch (_) {}
    }
    myModeNotifier.value = 'visible';
    await supa.auth.signOut();
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
                  'TiradA anon · 2.0.29',
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
    /* v2.0.25: this used to pass the raw kStr KEY ('lv_district_ghost')
       into the line — resolve it through tr() like levelOf() does. */
    final nextName = nextXp == null ? null : tr(kLevels[lvNum].$2);
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
              /* v2.0.23: LONG-press my own big avatar → the zoom
                 viewer. The plain tap keeps its job (the change-
                 avatar sheet — the hint under the avatar says so),
                 so the viewer takes the free gesture instead of
                 hijacking the tap. The guest's on-device photo goes
                 through the explicit FileImage provider. */
              onLongPress: () {
                HapticFeedback.selectionClick();
                showAvatarZoom(
                  context,
                  name: nick,
                  avatar: avatarEmoji,
                  avatarUrl: avatarUrl,
                  photo: (!signedIn && _guestAvatarPath != null)
                      ? FileImage(File(_guestAvatarPath!))
                      : null,
                );
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
            /* v2.0.25: the nick block is now a button — tap opens
               the editor (it used to be a dead read-only label). */
            GestureDetector(
              onTap: _editNick,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kRed.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _nickSaving ? '…' : nick,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    const TiradIcon(TIGlyph.pencil,
                        size: 15, color: T.iconGray),
                  ],
                ),
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
            const SizedBox(height: 10),
            /* v2.0.25: what the modes mean for background location —
               the explanation that accompanies the background
               permission ask (applySharing requests it when a
               sharing mode is picked). */
            Text(
              tr('bg_loc_hint'),
              style: T.body(12, color: T.muted),
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
          _StreakWeekCard(stats: s),
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
              onPressed: _signOut,
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
            'TiradA anon · 2.0.29',
            textAlign: TextAlign.center,
            style: T.body(11.5, color: T.faint),
          ),
          const SizedBox(height: 20),
          /* Two dedicated pages (v2.0.10, owner's word): Settings —
             language, vibration and all notification toggles moved
             there out of this scroll; Creators — the about page. The
             «О приложении» and «Политика конфиденциальности» buttons
             are gone. */
          /* v2.0.17: the friends system lives in the «Друзья» tab
             now — this row is the only trace of it left here. */
          PressButton(
            text: tr('nav_friends'),
            small: true,
            primary: false,
            icon: TIGlyph.users,
            onPressed: widget.onOpenFriends,
          ),
          const SizedBox(height: 10),
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

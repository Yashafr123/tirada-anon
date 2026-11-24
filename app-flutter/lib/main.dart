// TiradA anon — native app (Flutter), v2.0.4 UI.
// UI mirrors the web version (tirada-anon.vercel.app): near-black bg with
// dark-red corner glows, fire-red/orange gradients, pill chips, «Я в деле»
// sheet, route timeline, «Мой призрак» profile. Same Supabase backend,
// same local on-phone persistence, same assets as before.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpClient;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, HapticFeedback;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const kSupaUrl = 'https://qrlyuvnfkrufnnladclf.supabase.co';
const kSupaAnon =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFybHl1dm5ma3J1Zm5ubGFkY2xmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUzNDA5OTQsImV4cCI6MjExMDkxNjk5NH0.JyIVlJjLG7co0kv215Jesykwy9XCMqpRlqY3Nh-lKrw';

/* Web palette. */
const kBg = Color(0xFF0B0B0D);
const kSurface = Color(0xFF141418);
const kSurface2 = Color(0xFF1C1C22);
const kRed = Color(0xFFE11D1D);
const kOrange = Color(0xFFFF7A1A);
const kGreen = Color(0xFF22C55E);
const kText = Color(0xFFF2F2F5);
const kMuted = Color(0xFF9A9AA3);

Color get kBorder => kRed.withOpacity(0.35);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: kSupaUrl, anonKey: kSupaAnon);
  runApp(const TiradaApp());
}

SupabaseClient get supa => Supabase.instance.client;
String get myUid => supa.auth.currentUser!.id;
String? get myUidOrNull => supa.auth.currentUser?.id;

/* Last real location seen by the map — shared with the «Я в деле» sheet. */
final ValueNotifier<LatLng?> myLocationNotifier = ValueNotifier<LatLng?>(null);

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
  if (pl == null) return '';
  if (pl == 0) return 'Бесплатно';
  return '₪' * pl.clamp(1, 4);
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

/* ---------------- design system (web look) ---------------- */

BoxDecoration cardDecoration() => BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: kBorder),
      boxShadow: [
        BoxShadow(
          color: kRed.withOpacity(0.12),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );

Widget sectionLabel(String text, {Color color = kMuted}) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );

/* Dark bg with dark-red radial glows in the corners (web style). */
class GlowBackground extends StatelessWidget {
  final Widget child;
  const GlowBackground({super.key, required this.child});

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
        const ColoredBox(color: kBg, child: SizedBox.expand()),
        Positioned(top: -130, left: -110, child: _blob(kRed, 0.20)),
        Positioned(bottom: -150, right: -120, child: _blob(kOrange, 0.13)),
        Positioned(top: 220, right: -170, child: _blob(kRed, 0.10)),
        child,
      ],
    );
  }
}

/* Pressable gradient (primary) / dark-red-border (secondary) button with
   haptic tick and a slight scale-down press animation. */
class PressButton extends StatefulWidget {
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
  State<PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<PressButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final radius = BorderRadius.circular(widget.small ? 14 : 20);
    return AnimatedScale(
      scale: _down && enabled ? 0.96 : 1,
      duration: const Duration(milliseconds: 120),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: widget.primary
              ? LinearGradient(
                  colors: [kRed, kOrange],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: widget.primary ? null : kSurface,
          borderRadius: radius,
          border: widget.primary
              ? null
              : Border.all(color: kRed.withOpacity(0.7), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: kRed.withOpacity(
                  !enabled ? 0.08 : (widget.primary ? 0.45 : 0.20)),
              blurRadius: widget.small ? 12 : 22,
              offset: const Offset(0, 6),
            ),
          ],
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
                    HapticFeedback.lightImpact();
                    widget.onPressed!();
                  }
                : null,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: widget.small ? 10 : 16,
                horizontal: widget.small ? 16 : 22,
              ),
              child: Text(
                widget.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.small ? 14 : 16.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
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
        BoxShadow(color: kRed.withOpacity(0.55), blurRadius: 46, spreadRadius: 4),
        BoxShadow(color: kOrange.withOpacity(0.25), blurRadius: 90, spreadRadius: 18),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.asset('assets/icon.png', height: size, width: size),
    ),
  );
}

/* Pulsing LIVE dot. */
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
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = 0.75 + _c.value * 0.45;
        return Container(
          width: widget.size * t,
          height: widget.size * t,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kRed,
            boxShadow: [
              BoxShadow(color: kRed.withOpacity(0.8), blurRadius: 10, spreadRadius: 2),
            ],
          ),
        );
      },
    );
  }
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
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(
          primary: kRed,
          surface: kSurface,
          onSurface: kText,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: kText,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: kRed.withOpacity(0.25)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: kRed.withOpacity(0.25)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kRed, width: 1.4),
          ),
          hintStyle: const TextStyle(color: kMuted),
        ),
        cardTheme: CardThemeData(
          color: kSurface,
          elevation: 6,
          shadowColor: kRed.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: kRed.withOpacity(0.35)),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: kSurface2,
          contentTextStyle: const TextStyle(color: kText),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          behavior: SnackBarBehavior.floating,
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(child: glowIcon(140)),
                const SizedBox(height: 18),
                const Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'TiradA '),
                    TextSpan(
                      text: 'anon',
                      style: TextStyle(color: kOrange),
                    ),
                  ]),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'твой город · твои правила',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kMuted, fontSize: 15),
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
  List<Place> _places = [];
  List<City> _cities = [];
  City? _city;
  Map<String, dynamic>? _profile;
  Map<String, dynamic> _stats = normStats(null);
  final Set<String> _favs = {};
  bool _loading = true;
  int? _temp;
  List<Friend> _friends = [];
  int _tickerIdx = 0;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _tickerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _tickerIdx++);
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
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
      if (profile != null) _persistLocal();
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
    setState(() {
      if (_favs.contains(p.id)) {
        _favs.remove(p.id);
      } else {
        _favs.add(p.id);
      }
    });
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

  /* Current temperature from Open-Meteo (free, no key). Hidden on failure. */
  Future<void> _fetchTemp(City c) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=${c.lat}&longitude=${c.lng}&current=temperature_2m',
      );
      final req = await client.getUrl(uri);
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final t = (data['current'] as Map?)?['temperature_2m'];
      if (t is num && mounted) setState(() => _temp = t.round());
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
        decoration: const BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: kMuted.withOpacity(0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Выбери город',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
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
          const Text.rich(
            TextSpan(children: [
              TextSpan(text: 'TiradA '),
              TextSpan(text: 'anon', style: TextStyle(color: kRed)),
            ]),
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
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
                '☀️ $_temp°',
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

  Widget _navSlot(int idx, String emoji, String label) {
    final active = _tab == idx;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _tab = idx);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: active ? 14 : 10,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: active ? kRed.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? kRed.withOpacity(0.6) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 19)),
            if (active) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
            _navSlot(0, '📍', 'Карта'),
            _navSlot(1, '🔥', 'Места'),
            _DealFab(onTap: _openDeal),
            _navSlot(2, '🗺️', 'Маршрут'),
            _navSlot(3, '👻', 'Профиль'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kRed)),
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
                  ),
                  PlacesTab(
                    places: _cityPlaces,
                    city: _city,
                    favs: _favs,
                    onToggleFav: _toggleFav,
                    onOpenTasks: _openTasks,
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
            child: Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [kRed, kOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: kRed.withOpacity(0.65),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Text('🔥', style: TextStyle(fontSize: 27)),
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
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: kBorder),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: kMuted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('🔥', textAlign: TextAlign.center, style: TextStyle(fontSize: 38)),
            const SizedBox(height: 6),
            const Text.rich(
              TextSpan(children: [
                TextSpan(text: 'Я в '),
                TextSpan(text: 'деле', style: TextStyle(color: kOrange)),
              ]),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
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
                Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: kGreen,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'Сейчас в сети: $onlineCount',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
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
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              decoration: cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '🗳️ Куда идём?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ссылка-приглашение: https://tirada-anon.vercel.app — отправь её друзьям',
                          ),
                        ),
                      );
                    },
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

/* ---------------- place sheet (shared) ---------------- */

void showPlaceSheet(
  BuildContext context,
  Place p, {
  required bool isFav,
  required void Function(Place) onToggleFav,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: kSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${kTypeEmoji[p.type] ?? '📍'}  ${p.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? kRed : kMuted,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onToggleFav(p);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            children: [
              if (p.rating != null)
                Text(
                  '⭐ ${p.rating!.toStringAsFixed(1)}${p.reviews != null ? ' · ${p.reviews} отзывов' : ''}',
                  style: const TextStyle(color: kText),
                ),
              if (priceText(p).isNotEmpty)
                Text(priceText(p), style: const TextStyle(color: kText)),
              Text(
                '🔥 движ ${vibeOf(p)}%',
                style: const TextStyle(
                  color: kOrange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (p.address.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(p.address, style: const TextStyle(color: kMuted)),
          ],
        ],
      ),
    ),
  );
}

/* ---------------- map tab: places, friends, presence ---------------- */

class MapTab extends StatefulWidget {
  final List<Place> places;
  final List<City> cities;
  final City? city;
  final void Function(City) onCity;
  final Set<String> favs;
  final void Function(Place) onToggleFav;
  const MapTab({
    super.key,
    required this.places,
    required this.cities,
    required this.city,
    required this.onCity,
    required this.favs,
    required this.onToggleFav,
  });

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  MapLibreMapController? _ctl;
  String? _style;
  bool _styleReady = false;
  final Map<String, Place> _circlePlace = {};
  final Map<String, Friend> _symbolFriend = {};
  final Map<String, Uint8List> _markerCache = {};
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

  Future<void> _drawPlaces() async {
    final ctl = _ctl;
    if (ctl == null || !_styleReady) return;
    await ctl.clearCircles();
    _circlePlace.clear();
    for (final p in widget.places) {
      final c = await ctl.addCircle(
        CircleOptions(
          geometry: LatLng(p.lat, p.lng),
          circleRadius: 7,
          circleColor: '#${typeColor(p.type).value.toRadixString(16).padLeft(8, '0').substring(2)}',
          circleStrokeWidth: 2,
          circleStrokeColor: '#0B0B0D',
          circleOpacity: 0.95,
        ),
      );
      _circlePlace[c.id] = p;
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
      await ctl.clearSymbols();
      _symbolFriend.clear();
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
          ),
        );
        _symbolFriend[sym.id] = friend;
      }
    } catch (_) {}
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
    ctl.onCircleTapped.add((c) {
      final p = _circlePlace[c.id];
      if (p != null && mounted) {
        showPlaceSheet(
          context,
          p,
          isFav: widget.favs.contains(p.id),
          onToggleFav: widget.onToggleFav,
        );
      }
    });
    ctl.onSymbolTapped.add((s) {
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
    return MapLibreMap(
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
        _presence();
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
    );
  }
}

/* ---------------- places tab ---------------- */

class PlacesTab extends StatefulWidget {
  final List<Place> places;
  final City? city;
  final Set<String> favs;
  final void Function(Place) onToggleFav;
  final VoidCallback onOpenTasks;
  const PlacesTab({
    super.key,
    required this.places,
    required this.city,
    required this.favs,
    required this.onToggleFav,
    required this.onOpenTasks,
  });

  @override
  State<PlacesTab> createState() => _PlacesTabState();
}

class _PlacesTabState extends State<PlacesTab> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = widget.places
        .where((p) => p.name.toLowerCase().contains(_q.toLowerCase()))
        .toList()
      ..sort((a, b) => vibeOf(b).compareTo(vibeOf(a)));
    return GlowBackground(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Text(
                  widget.city?.name ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.places.length} мест',
                  style: const TextStyle(color: kMuted),
                ),
                const Spacer(),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Поиск места…'),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 6, bottom: 10),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final p = list[i];
                final fav = widget.favs.contains(p.id);
                final v = vibeOf(p);
                return GestureDetector(
                  onTap: () => showPlaceSheet(
                    context,
                    p,
                    isFav: fav,
                    onToggleFav: widget.onToggleFav,
                  ),
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.5,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                [
                                  if (p.rating != null)
                                    '⭐ ${p.rating!.toStringAsFixed(1)}',
                                  if (priceText(p).isNotEmpty) priceText(p),
                                  if (p.address.isNotEmpty) p.address,
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: kMuted, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            Text(
                              '$v%',
                              style: const TextStyle(
                                color: kOrange,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const Text(
                              'движ',
                              style: TextStyle(color: kMuted, fontSize: 9.5),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            fav ? Icons.favorite : Icons.favorite_border,
                            color: fav ? kRed : kMuted,
                          ),
                          onPressed: () => widget.onToggleFav(p),
                        ),
                      ],
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
    } catch (_) {}
    if (mounted) setState(() {});
  }

  List<Place> get _route {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Маршрут пройден целиком · +40 XP 🎉')),
        );
      }
    }
  }

  Widget _transportPill(String id, String label) {
    final sel = _transport == id;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _transport = id);
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
          const Text.rich(
            TextSpan(children: [
              TextSpan(text: 'Маршрут на '),
              TextSpan(text: 'вечер', style: TextStyle(color: kOrange)),
            ]),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
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

/* ---------------- tasks page: AI day, daily task, week quest ---------------- */

class TasksPage extends StatefulWidget {
  final Map<String, dynamic> stats;
  final VoidCallback onTaskDone;
  final void Function(int xp) onAiXp;
  const TasksPage({
    super.key,
    required this.stats,
    required this.onTaskDone,
    required this.onAiXp,
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
                  const Text(
                    '🎯 Задачник',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                  ),
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
                            ? const Chip(
                                label: Text('Выполнено ✓'),
                                backgroundColor: kSurface2,
                              )
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
                        ? const Chip(
                            label: Text('Выполнено ✓'),
                            backgroundColor: kSurface2,
                          )
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

/* ---------------- profile tab: «Мой призрак» + about ---------------- */

class ProfileTab extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final Map<String, dynamic> stats;
  final Set<String> favs;
  final List<Place> places;
  final City? city;
  final void Function(Map<String, dynamic>) onProfileChanged;
  final VoidCallback onOpenTasks;
  const ProfileTab({
    super.key,
    required this.profile,
    required this.stats,
    required this.favs,
    required this.places,
    required this.city,
    required this.onProfileChanged,
    required this.onOpenTasks,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  int? _guestNumber;

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
      if (mounted) setState(() => _guestNumber = n);
    } catch (_) {}
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
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: kOrange,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kMuted, fontSize: 9.5, height: 1.15),
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
    final avatarEmoji = (p?['avatar'] as String?) ?? '👻';
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
          const Text.rich(
            TextSpan(children: [
              TextSpan(text: 'Мой '),
              TextSpan(text: 'призрак', style: TextStyle(color: kOrange)),
            ]),
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 18),
          Center(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                if (!signedIn) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const LoginPage()),
                  );
                }
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
                      : null,
                  color: kSurface2,
                ),
                alignment: Alignment.center,
                child: avatarUrl == null
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
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
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
                    Container(
                      width: 62,
                      height: 62,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient:
                            const LinearGradient(colors: [kRed, kOrange]),
                        boxShadow: [
                          BoxShadow(
                              color: kRed.withOpacity(0.55), blurRadius: 18),
                        ],
                      ),
                      child: Text(
                        '$lvNum',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lvName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '$xp XP',
                          style: const TextStyle(
                            color: kOrange,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    children: [
                      Container(height: 10, color: kSurface2),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 10,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [kRed, kOrange]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
          const SizedBox(height: 14),
          PressButton(
            text: '🎯 Задачник',
            onPressed: widget.onOpenTasks,
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
          const SizedBox(height: 28),
          /* ---------------- About ---------------- */
          Center(child: glowIcon(118)),
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

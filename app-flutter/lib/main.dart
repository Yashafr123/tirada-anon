// TiradA anon — native app (Flutter).
// Same brand, same recoloured CARTO map style, same Supabase backend as
// the web version: accounts, profiles, friends, locations, favorites,
// stats and the AI day are shared with the site.
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

const kSupaUrl = 'https://qrlyuvnfkrufnnladclf.supabase.co';
const kSupaAnon =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFybHl1dm5ma3J1Zm5ubGFkY2xmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUzNDA5OTQsImV4cCI6MjExMDkxNjk5NH0.JyIVlJjLG7co0kv215Jesykwy9XCMqpRlqY3Nh-lKrw';

const kBg = Color(0xFF050505);
const kSurface = Color(0xFF121216);
const kSurface2 = Color(0xFF1A1A21);
const kRed = Color(0xFFFF2A1E);
const kRedDark = Color(0xFFE50914);
const kText = Color(0xFFF2F2F5);
const kMuted = Color(0xFF9A9AB0);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: kSupaUrl, anonKey: kSupaAnon);
  runApp(const TiradaApp());
}

SupabaseClient get supa => Supabase.instance.client;
String get myUid => supa.auth.currentUser!.id;
String? get myUidOrNull => supa.auth.currentUser?.id;

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
      return const Color(0xFFFF2A1E);
  }
}

String priceText(Place p) {
  final pl = p.priceLevel;
  if (pl == null) return '';
  if (pl == 0) return 'Бесплатно';
  return '₪' * pl.clamp(1, 4);
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

/* ---------------- juicy style helpers ---------------- */

/* The button you want to press: red gradient, neon glow, haptic tick. */
Widget glowButton({
  required String text,
  required VoidCallback? onPressed,
  bool small = false,
}) {
  return DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFF3B2F), Color(0xFFD90429), Color(0xFF8F0318)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(small ? 12 : 18),
      boxShadow: [
        BoxShadow(
          color: kRed.withOpacity(onPressed == null ? 0.12 : 0.5),
          blurRadius: small ? 12 : 22,
          spreadRadius: 1,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(small ? 12 : 18),
        onTap: onPressed == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed();
              },
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: small ? 9 : 16,
            horizontal: small ? 16 : 22,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: small ? 14 : 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    ),
  );
}

/* Outlined neon button — the second thing you want to press. */
Widget neonOutlineButton({
  required String text,
  required VoidCallback? onPressed,
}) {
  return DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: kRed.withOpacity(0.85), width: 1.6),
      boxShadow: [
        BoxShadow(color: kRed.withOpacity(0.22), blurRadius: 14),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onPressed();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );
}

/* App icon wrapped in a pulsing red halo. */
Widget glowIcon(double size) {
  return Container(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: kRed.withOpacity(0.55), blurRadius: 46, spreadRadius: 6),
        BoxShadow(color: kRedDark.withOpacity(0.35), blurRadius: 90, spreadRadius: 22),
      ],
    ),
    child: Image.asset('assets/icon.png', height: size),
  );
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
          backgroundColor: kBg,
          foregroundColor: kText,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0B0B0E),
          selectedItemColor: kRed,
          unselectedItemColor: kMuted,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w800),
          elevation: 18,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: kSurface2,
          selectedColor: kRedDark,
          side: BorderSide(color: kRed.withOpacity(0.35)),
          labelStyle: const TextStyle(color: kText),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          showCheckmark: false,
          elevation: 4,
          pressElevation: 8,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kRedDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: kMuted),
        ),
        cardTheme: CardThemeData(
          color: kSurface,
          elevation: 7,
          shadowColor: kRed.withOpacity(0.28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: kRed.withOpacity(0.14)),
          ),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              glowIcon(150),
              const SizedBox(height: 12),
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [Color(0xFFFF6B5E), kRed, Color(0xFF8F0318)],
                ).createShader(r),
                child: const Text(
                  'TiradA anon',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
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
              glowButton(
                text: _busy ? 'Секунду…' : '🚀 Войти',
                onPressed: _busy ? null : () => _go(false),
              ),
              const SizedBox(height: 12),
              neonOutlineButton(
                text: '✨ Создать аккаунт',
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
    );
  }
}

/* ---------------- home: shared state + tabs ---------------- */

class Friend {
  final String id, name;
  final String? avatar, avatarUrl, mode;
  final bool online;
  final double? lat, lng;
  const Friend({
    required this.id,
    required this.name,
    this.avatar,
    this.avatarUrl,
    this.mode,
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
  int _tab = 0;
  List<Place> _places = [];
  List<City> _cities = [];
  City? _city;
  Map<String, dynamic>? _profile;
  Map<String, dynamic> _stats = normStats(null);
  final Set<String> _favs = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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
      if (!mounted) return;
      setState(() {
        _places = places;
        _cities = cities;
        _city = cities.firstWhere(
          (c) => c.id == (profile?['city'] as String? ?? 'karmiel'),
          orElse: () => cities.first,
        );
        _profile = profile;
        _stats = normStats(profile?['stats']);
        final favs = profile?['favorites'];
        if (favs is List) {
          _favs.addAll(favs.map((e) => e.toString()));
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Place> get _cityPlaces =>
      _city == null ? [] : _places.where((p) => p.city == _city!.id).toList();

  Future<void> _toggleFav(Place p) async {
    setState(() {
      if (_favs.contains(p.id)) {
        _favs.remove(p.id);
      } else {
        _favs.add(p.id);
      }
    });
    final uid = myUidOrNull;
    if (uid == null) return; // guest: favorites live only in memory
    try {
      await supa
          .from('profiles')
          .update({'favorites': _favs.toList()}).eq('id', uid);
    } catch (_) {}
  }

  Future<void> _saveStats() async {
    final uid = myUidOrNull;
    if (uid == null) return; // guest: stats live only in memory
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kRed)),
      );
    }
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          MapTab(
            places: _cityPlaces,
            cities: _cities,
            city: _city,
            onCity: (c) => setState(() => _city = c),
            favs: _favs,
            onToggleFav: _toggleFav,
          ),
          PlacesTab(
            places: _cityPlaces,
            city: _city,
            favs: _favs,
            onToggleFav: _toggleFav,
          ),
          TasksTab(
            stats: _stats,
            onTaskDone: () => _bumpStat('tasks', 1),
            onAiXp: _addAiXp,
          ),
          ProfileTab(
            profile: _profile,
            stats: _stats,
            favs: _favs,
            places: _places,
            city: _city,
            onProfileChanged: (p) => setState(() => _profile = p),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) {
          HapticFeedback.selectionClick();
          setState(() => _tab = i);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Карта'),
          BottomNavigationBarItem(icon: Icon(Icons.place), label: 'Места'),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Задания',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }
}

/* ---------------- place card (shared) ---------------- */

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
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? kRed : kMuted,
                  ),
                  onPressed: () {
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
              ],
            ),
            if (p.address.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(p.address, style: const TextStyle(color: kMuted)),
            ],
          ],
        ),
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
          circleStrokeColor: '#050505',
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
        ..color = f.online ? kRed : kMuted
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
    final uid = myUidOrNull;
    if (uid == null) return; // guest: nowhere to write presence
    try {
      final pos = await ctl.requestMyLocationLatLng();
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  f.online ? 'Сейчас в сети' : 'Был(а) недавно',
                  style: const TextStyle(color: kMuted),
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
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                children: [
                  for (final c in widget.cities)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.name),
                        selected: c.id == city.id,
                        selectedColor: kRedDark,
                        backgroundColor: kSurface,
                        labelStyle: TextStyle(
                          color: c.id == city.id ? Colors.white : kText,
                        ),
                        onSelected: (_) => widget.onCity(c),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/* ---------------- places tab ---------------- */

class PlacesTab extends StatefulWidget {
  final List<Place> places;
  final City? city;
  final Set<String> favs;
  final void Function(Place) onToggleFav;
  const PlacesTab({
    super.key,
    required this.places,
    required this.city,
    required this.favs,
    required this.onToggleFav,
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
        .toList();
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(
                  widget.city?.name ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.places.length} мест',
                  style: const TextStyle(color: kMuted),
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
              itemCount: list.length,
              itemBuilder: (_, i) {
                final p = list[i];
                final fav = widget.favs.contains(p.id);
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: ListTile(
                    leading: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: typeColor(p.type).withOpacity(0.45),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        backgroundColor: typeColor(p.type).withOpacity(0.2),
                        child: Text(kTypeEmoji[p.type] ?? '📍'),
                      ),
                    ),
                  title: Text(p.name),
                  subtitle: Text(
                    [
                      if (p.rating != null)
                        '⭐ ${p.rating!.toStringAsFixed(1)}',
                      if (priceText(p).isNotEmpty) priceText(p),
                      if (p.address.isNotEmpty) p.address,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kMuted),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      fav ? Icons.favorite : Icons.favorite_border,
                      color: fav ? kRed : kMuted,
                    ),
                    onPressed: () => widget.onToggleFav(p),
                  ),
                    onTap: () => showPlaceSheet(
                      context,
                      p,
                      isFav: fav,
                      onToggleFav: widget.onToggleFav,
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

/* ---------------- tasks tab: AI day, daily task, week quest ---------------- */

class TasksTab extends StatefulWidget {
  final Map<String, dynamic> stats;
  final VoidCallback onTaskDone;
  final void Function(int xp) onAiXp;
  const TasksTab({
    super.key,
    required this.stats,
    required this.onTaskDone,
    required this.onAiXp,
  });

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
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

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Text(
          t,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
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
    return SafeArea(
      child: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Задания',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          if (_drop != null && aiTasks.isNotEmpty) ...[
            _sectionTitle('🤖 ИИ дня'),
            for (final t in aiTasks)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${aiText(t['title'])}  ·  +${(t['xp'] as num?)?.toInt() ?? 0} XP',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
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
                          : glowButton(
                              text: 'Готово ✓',
                              small: true,
                              onPressed: () =>
                                  _completeAi(t as Map<String, dynamic>),
                            ),
                    ],
                  ),
                ),
              ),
            if (_drop!['quest'] != null) ...[
              _sectionTitle('🗺️ Квест дня: ${aiText(_drop!['quest']['title'])}'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  aiText(_drop!['quest']['desc']),
                  style: const TextStyle(color: kMuted),
                ),
              ),
            ],
            if (_drop!['route_theme'] != null) ...[
              _sectionTitle(
                '🌙 Тема маршрута: ${aiText(_drop!['route_theme']['title'])}',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  aiText(_drop!['route_theme']['desc']),
                  style: const TextStyle(color: kMuted),
                ),
              ),
            ],
          ],
          _sectionTitle('🎯 Задание дня'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
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
                      : glowButton(
                          text: 'Готово ✓',
                          small: true,
                          onPressed: _completeDaily,
                        ),
                ],
              ),
            ),
          ),
          if (weekQuest != null) ...[
            _sectionTitle('🗓️ Квест недели: ${weekQuest['theme']}'),
            for (final s in (weekQuest['steps'] as List? ?? []))
              ListTile(
                dense: true,
                leading: const Icon(Icons.circle, size: 8, color: kRed),
                title: Text(s.toString()),
              ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/* ---------------- profile tab ---------------- */

class ProfileTab extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final Map<String, dynamic> stats;
  final Set<String> favs;
  final List<Place> places;
  final City? city;
  final void Function(Map<String, dynamic>) onProfileChanged;
  const ProfileTab({
    super.key,
    required this.profile,
    required this.stats,
    required this.favs,
    required this.places,
    required this.city,
    required this.onProfileChanged,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Future<void> _setMode(String mode) async {
    final p = {...?widget.profile, 'mode': mode};
    widget.onProfileChanged(p);
    final uid = myUidOrNull;
    if (uid == null) return;
    try {
      await supa.from('profiles').update({'mode': mode}).eq('id', uid);
    } catch (_) {}
  }

  Widget _statTile(String label, String value) => Container(
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kRed.withOpacity(0.22)),
          boxShadow: [
            BoxShadow(color: kRed.withOpacity(0.13), blurRadius: 10),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (supa.auth.currentUser == null) {
      // Guest view: browsing works without an account; sign-in is optional.
      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            glowIcon(130),
            const SizedBox(height: 16),
            const Text(
              'Ты смотришь как гость 👻',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Карта, места и задания открыты без аккаунта. '
              'Аккаунт нужен для друзей на карте, своего ника и синхронизации.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            glowButton(
              text: '🚀 Войти / Создать аккаунт',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LoginPage()),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Создатели: Yasha · @black_prince_18  •  Вард · @WardDeveloper  •  Сева · @Severarin',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }
    final p = widget.profile;
    final name = (p?['name'] as String?) ?? 'Призрак';
    final avatarEmoji = (p?['avatar'] as String?) ?? '👤';
    final avatarUrl = p?['avatar_url'] as String?;
    final mode = (p?['mode'] as String?) ?? 'visible';
    final xp = xpOfStats(widget.stats);
    final (lvNum, lvName, nextXp) = levelOf(xp);
    final curThreshold = kLevels[lvNum - 1].$1;
    final progress = nextXp == null
        ? 1.0
        : ((xp - curThreshold) / (nextXp - curThreshold)).clamp(0.0, 1.0);
    final favPlaces = widget.favs
        .map((id) => widget.places.where((pl) => pl.id == id).firstOrNull)
        .whereType<Place>()
        .toList();
    final visited = (widget.stats['places'] as List?)?.length ?? 0;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: kSurface2,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(avatarEmoji, style: const TextStyle(fontSize: 34))
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      supa.auth.currentUser?.email ?? '',
                      style: const TextStyle(color: kMuted),
                    ),
                    if (widget.city != null)
                      Text(
                        '📍 ${widget.city!.name}',
                        style: const TextStyle(color: kMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Уровень $lvNum · $lvName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text('$xp XP', style: const TextStyle(color: kRed)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: kSurface2,
                      color: kRed,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nextXp == null
                        ? 'Максимальный уровень'
                        : 'До следующего уровня: ${nextXp - xp} XP',
                    style: const TextStyle(color: kMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Режим на карте',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final (v, label) in [
                ('visible', '👁 Видимый'),
                ('ghost', '👻 Призрак'),
                ('offline', '🚫 Невидимка'),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: mode == v,
                  selectedColor: kRedDark,
                  backgroundColor: kSurface,
                  onSelected: (_) => _setMode(v),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.25,
            children: [
              _statTile('Мест', '$visited'),
              _statTile('Заданий', '${statInt(widget.stats, 'tasks')}'),
              _statTile('Маршрутов', '${statInt(widget.stats, 'routes')}'),
              _statTile('Фото', '${statInt(widget.stats, 'photos')}'),
              _statTile('Ночей', '${statInt(widget.stats, 'nights')}'),
              _statTile('Стрик', '${statInt(widget.stats, 'streak')} дн.'),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            '❤️ Избранное',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (favPlaces.isEmpty)
            const Text(
              'Пока пусто — жми сердечко у мест',
              style: TextStyle(color: kMuted),
            ),
          for (final fp in favPlaces)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Text(kTypeEmoji[fp.type] ?? '📍'),
              title: Text(fp.name),
              subtitle: Text(fp.city, style: const TextStyle(color: kMuted)),
            ),
          const SizedBox(height: 18),
          neonOutlineButton(
            text: 'Выйти',
            onPressed: () => supa.auth.signOut(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Создатели: Yasha · @black_prince_18  •  Вард · @WardDeveloper  •  Сева · @Severarin',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

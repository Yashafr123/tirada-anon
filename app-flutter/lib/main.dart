// TiradA anon — native app (Flutter), phase 1:
// brand shell, Supabase sign-in, the same recoloured CARTO map style as
// the web version, real places on the map and in a list, profile tab.
// Backend is the same Supabase project as the site — accounts, friends
// and places are shared.
import 'dart:convert';
import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kSupaUrl = 'https://qrlyuvnfkrufnnladclf.supabase.co';
const kSupaAnon =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFybHl1dm5ma3J1Zm5ubGFkY2xmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUzNDA5OTQsImV4cCI6MjExMDkxNjk5NH0.JyIVlJjLG7co0kv215Jesykwy9XCMqpRlqY3Nh-lKrw';

const kBg = Color(0xFF050505);
const kSurface = Color(0xFF121216);
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
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: kRedDark,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kRed, width: 1.4),
          ),
          labelStyle: const TextStyle(color: kMuted),
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
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? supa.auth.currentSession;
        if (session != null) return const HomePage();
        return const LoginPage();
      },
    );
  }
}

// ---------------- data ----------------

class Place {
  final String city;
  final String name;
  final String type;
  final double lat;
  final double lng;
  final double? rating;
  final int? reviews;
  final int? priceLevel;
  final String? address;

  Place.fromJson(Map<String, dynamic> j)
      : city = j['city'] as String,
        name = j['name'] as String,
        type = (j['type'] as String?) ?? 'place',
        lat = (j['lat'] as num).toDouble(),
        lng = (j['lng'] as num).toDouble(),
        rating = (j['rating'] as num?)?.toDouble(),
        reviews = (j['reviews'] as num?)?.toInt(),
        priceLevel = (j['priceLevel'] as num?)?.toInt(),
        address = j['address'] as String?;

  String get priceText {
    switch (priceLevel) {
      case 0:
        return 'Бесплатно';
      case 1:
        return '₪';
      case 2:
        return '₪₪';
      case 3:
        return '₪₪₪';
      case 4:
        return '₪₪₪₪';
      default:
        return '';
    }
  }
}

class City {
  final String id;
  final String name;
  final double lat;
  final double lng;
  City.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        name = j['name'] as String,
        lat = (j['lat'] as num).toDouble(),
        lng = (j['lng'] as num).toDouble();
}

const kTypeEmoji = {
  'cafe': '☕',
  'bar': '🍸',
  'park': '🌳',
  'club': '🔊',
  'hookah': '💨',
  'beach': '🏖️',
  'view': '👀',
  'market': '🛍️',
  'restaurant': '🍽️',
};

const kTypeColor = {
  'cafe': '#FFB020',
  'bar': '#FF2A1E',
  'park': '#3DDC84',
  'club': '#C86BFF',
  'hookah': '#4DC3FF',
  'beach': '#29E6D5',
  'view': '#FFD23F',
  'market': '#FF8A5C',
  'restaurant': '#FF6B9D',
};

// ---------------- login ----------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _run(bool signUp) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (signUp) {
        await supa.auth
            .signUp(email: _email.text.trim(), password: _pass.text);
      } else {
        await supa.auth.signInWithPassword(
            email: _email.text.trim(), password: _pass.text);
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 26),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Image.asset('assets/icon.png',
                      width: 118, height: 118, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text('TiradA anon',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4)),
              ),
              const Center(
                child: Text('твой город · твои правила',
                    style: TextStyle(color: kMuted, fontSize: 14)),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Пароль'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!,
                    style: const TextStyle(color: kRed, fontSize: 13.5)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : () => _run(false),
                child: Text(_busy ? 'Секунду…' : 'Войти'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _busy ? null : () => _run(true),
                child: const Text('Создать аккаунт',
                    style: TextStyle(color: kMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- home ----------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;
  List<Place> _places = [];
  List<City> _cities = [];
  String _cityId = 'karmiel';
  String? _styleString;
  MaplibreMapController? _map;
  final Map<Circle, Place> _circlePlace = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final placesRaw = await rootBundle.loadString('assets/places.json');
    final citiesRaw = await rootBundle.loadString('assets/cities.json');
    final style = await rootBundle.loadString('assets/map-style.json');
    final places = (jsonDecode(placesRaw) as List)
        .map((e) => Place.fromJson(e as Map<String, dynamic>))
        .toList();
    final allCities = (jsonDecode(citiesRaw) as List)
        .map((e) => City.fromJson(e as Map<String, dynamic>))
        .toList();
    final withPlaces = <String>{for (final p in places) p.city};
    final cities = allCities.where((c) => withPlaces.contains(c.id)).toList()
      ..sort((a, b) {
        if (a.id == 'karmiel') return -1;
        if (b.id == 'karmiel') return 1;
        return a.name.compareTo(b.name);
      });
    if (!mounted) return;
    setState(() {
      _places = places;
      _cities = cities;
      _styleString = style;
      _loaded = true;
    });
  }

  List<Place> get _cityPlaces =>
      _places.where((p) => p.city == _cityId).toList();

  City get _city => _cities.firstWhere((c) => c.id == _cityId,
      orElse: () => _cities.isNotEmpty
          ? _cities.first
          : City.fromJson(
              {'id': 'karmiel', 'name': 'Кармиэль', 'lat': 32.9155, 'lng': 35.2960}));

  Future<void> _drawPlaces() async {
    final map = _map;
    if (map == null) return;
    await map.clearCircles();
    _circlePlace.clear();
    for (final p in _cityPlaces) {
      final circle = await map.addCircle(CircleOptions(
        geometry: LatLng(p.lat, p.lng),
        circleColor: kTypeColor[p.type] ?? '#E8E8FF',
        circleRadius: 7,
        circleStrokeColor: '#0B0B0E',
        circleStrokeWidth: 1.6,
        circleOpacity: 0.95,
      ));
      _circlePlace[circle] = p;
    }
  }

  void _onCircleTapped(Circle circle) {
    final p = _circlePlace[circle];
    if (p != null) _showPlace(p);
  }

  void _showPlace(Place p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(kTypeEmoji[p.type] ?? '📍',
                  style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(p.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 10),
            if (p.rating != null)
              Text('⭐ ${p.rating} · ${p.reviews ?? 0} отзывов',
                  style: const TextStyle(color: kMuted, fontSize: 14.5)),
            if (p.priceText.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('💰 ${p.priceText}',
                  style: const TextStyle(color: kMuted, fontSize: 14.5)),
            ],
            if (p.address != null && p.address!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('📍 ${p.address}',
                  style: const TextStyle(color: kMuted, fontSize: 14.5)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: kRed),
        ),
      );
    }
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          _mapTab(),
          _placesTab(),
          _soonTab('🎯', 'Задания и квесты уже в пути'),
          _profileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Карта'),
          BottomNavigationBarItem(icon: Icon(Icons.place), label: 'Места'),
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events), label: 'Задания'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
        ],
      ),
    );
  }

  Widget _mapTab() {
    return Stack(
      children: [
        if (_styleString != null)
          MaplibreMap(
            styleString: _styleString!,
            initialCameraPosition: CameraPosition(
              target: LatLng(_city.lat, _city.lng),
              zoom: 13,
            ),
            onMapCreated: (c) {
              _map = c;
              c.onCircleTapped.add(_onCircleTapped);
            },
            onStyleLoadedCallback: _drawPlaces,
            myLocationEnabled: false,
            compassEnabled: false,
            attributionButtonMargins: const Point(-100, -100),
          ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _cities.length,
              itemBuilder: (_, i) {
                final c = _cities[i];
                final active = c.id == _cityId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c.name),
                    selected: active,
                    onSelected: (_) async {
                      setState(() => _cityId = c.id);
                      await _map?.animateCamera(CameraUpdate.newLatLngZoom(
                          LatLng(c.lat, c.lng), 13));
                      _drawPlaces();
                    },
                    selectedColor: kRedDark,
                    backgroundColor: const Color(0xCC121216),
                    labelStyle: TextStyle(
                        color: active ? Colors.white : kText,
                        fontWeight: FontWeight.w600),
                    side: BorderSide.none,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _placesTab() {
    final list = _cityPlaces;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
            child: Text('${_city.name} · ${list.length} мест',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final p = list[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: kSurface,
                    child: Text(kTypeEmoji[p.type] ?? '📍',
                        style: const TextStyle(fontSize: 18)),
                  ),
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    [
                      if (p.rating != null) '⭐ ${p.rating}',
                      if (p.priceText.isNotEmpty) p.priceText,
                      if (p.address != null) p.address!,
                    ].join(' · '),
                    style: const TextStyle(color: kMuted),
                  ),
                  onTap: () => _showPlace(p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _soonTab(String emoji, String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 14),
          Text(text,
              style: const TextStyle(color: kMuted, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _profileTab() {
    final user = supa.auth.currentUser;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Профиль',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 18),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/icon.png',
                    width: 84, height: 84, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(user?.email ?? '',
                  style: const TextStyle(color: kMuted, fontSize: 15)),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => supa.auth.signOut(),
                child: const Text('Выйти'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

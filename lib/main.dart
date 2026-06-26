import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vtr;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
const String kBaseUrl = 'https://konomap-backend-production.up.railway.app';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ZoWayApp());
}

class ZoWayApp extends StatelessWidget {
  const ZoWayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZoWay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: GoogleFonts.nunito().fontFamily,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F8A5F)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ── SPLASH ──
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
   Future.delayed(const Duration(seconds: 3), () async {
  if (mounted) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const ProfilSetupScreen()));
    } else {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }
});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F8A5F),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ZoWayLogo(size: 120),
            const SizedBox(height: 20),
            const Text('ZoWay',
              style: TextStyle(color: Colors.white, fontSize: 36,
                fontWeight: FontWeight.w700, letterSpacing: -1)),
            const SizedBox(height: 6),
            const Text('Ensemble sur la route',
              style: TextStyle(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
// ── LOGIN ──
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _codeSent = false;
  bool _loading = false;
  String _verificationId = '';

  Future<void> _envoyerCode() async {
    setState(() => _loading = true);
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: '+225${_phoneController.text.trim()}',
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (mounted) {
          Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const ProfilSetupScreen()));
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.message}')));
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
          _loading = false;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verifierCode() async {
    setState(() => _loading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code incorrect !')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ZoWayLogo(size: 100),
              const SizedBox(height: 16),
              const Text('ZoWay',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900,
                  color: Color(0xFF1A237E))),
              const Text('Ensemble sur la route',
                style: TextStyle(fontSize: 14, color: Color(0xFFFF6B00))),
              const SizedBox(height: 48),
              if (!_codeSent) ...[
                const Text('Entrez votre numéro de téléphone',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixText: '+225 ',
                    hintText: '07 00 00 00 00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF6B00), width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _loading ? null : _envoyerCode,
                    child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Recevoir le code SMS',
                          style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ] else ...[
                const Text('Entrez le code reçu par SMS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 60),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 24,
                    fontWeight: FontWeight.w700, letterSpacing: 8),
                  decoration: InputDecoration(
                    hintText: '000000',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF6B00), width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _loading ? null : _verifierCode,
                    child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirmer',
                          style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _codeSent = false),
                  child: const Text('Changer de numéro'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
// ── PROFIL SETUP ──
class ProfilSetupScreen extends StatefulWidget {
  const ProfilSetupScreen({super.key});
  @override
  State<ProfilSetupScreen> createState() => _ProfilSetupScreenState();
}

class _ProfilSetupScreenState extends State<ProfilSetupScreen> {
  final _pseudoController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ZoWayLogo(size: 80),
              const SizedBox(height: 24),
              const Text('Bienvenue sur ZoWay ! 🎉',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900,
                  color: Color(0xFF1A237E))),
              const SizedBox(height: 8),
              const Text('Comment tu veux qu\'on t\'appelle ?',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 32),
              TextField(
                controller: _pseudoController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Ex: Kouassi, Ama, Romeo...',
                  prefixIcon: const Icon(Icons.person_outline,
                    color: Color(0xFFFF6B00)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF6B00), width: 2)),
                  labelText: 'Pseudo ou prénom (facultatif)',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _loading ? null : () {
                    final pseudo = _pseudoController.text.trim();
                    if (pseudo.isNotEmpty) {
                      nomUtilisateur = pseudo;
                    }
                    Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()));
                  },
                  child: const Text('Commencer !',
                    style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const HomeScreen())),
                child: const Text('Passer pour l\'instant',
                  style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ── DONNÉES GLOBALES ──
List<Map<String, dynamic>> lieuxData = [];

// Données streak et points
int streakJours = 3;
int pointsTotal = 47;
String nomUtilisateur = 'Moi';
String quartierUtilisateur = 'Abidjan';
String _getNiveau(int points) {
  if (points >= 500) return '🏆 Expert ZoWay';
  if (points >= 300) return '⭐ Guide local';
  if (points >= 150) return '🧭 Mappeur';
  if (points >= 50)  return '📍 Explorateur';
  return '🗺️ Passant';
}
DateTime derniereConnexion = DateTime.now();

// Classement quartier
final List<Map<String, dynamic>> classement = [
  {'nom': 'Ama K.', 'quartier': 'Cocody', 'points': 312, 'niveau': '⭐ Guide local'},
  {'nom': 'Moussa T.', 'quartier': 'Cocody', 'points': 287, 'niveau': '🧭 Mappeur'},
  {'nom': 'Kofi A.', 'quartier': 'Cocody', 'points': 241, 'niveau': '🧭 Mappeur'},
  {'nom': 'Fatou M.', 'quartier': 'Cocody', 'points': 198, 'niveau': '🧭 Mappeur'},
  {'nom': 'Aya D.', 'quartier': 'Cocody', 'points': 156, 'niveau': '📍 Explorateur'},
  {'nom': 'Koffi B.', 'quartier': 'Cocody', 'points': 134, 'niveau': '📍 Explorateur'},
  {'nom': 'Adjoua S.', 'quartier': 'Cocody', 'points': 98, 'niveau': '📍 Explorateur'},
  {'nom': nomUtilisateur, 'quartier': 'Cocody', 'points': pointsTotal, 'niveau': _getNiveau(pointsTotal), 'moi': true},
];

// ── HOME ──
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const CarteScreen(),
      const ValiderScreen(),
      const ClassementScreen(),
      ProfilScreen(onPointsAdded: (pts) => setState(() => pointsTotal += pts)),
    ];

    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        indicatorColor: const Color(0xFFE8F7F2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Color(0xFF0F8A5F)),
            label: 'Carte',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle, color: Color(0xFF0F8A5F)),
            label: 'Valider',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard, color: Color(0xFF0F8A5F)),
            label: 'Classement',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF0F8A5F)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ── CARTE ──
class CarteScreen extends StatefulWidget {
  const CarteScreen({super.key});
  @override
  State<CarteScreen> createState() => _CarteScreenState();
}

class _CarteScreenState extends State<CarteScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedPoint;
  LatLng _maPosition = const LatLng(5.3569, -3.9464);
  bool _gpsCharge = false;
  String _filtreType = 'Tous';
String? _filtreSousType;
  // Catégories du filtre = source unique + 'Tous' en tête
  final Map<String, IconData> _filtreIcones = {'Tous': Icons.map, ...kCategorieIcones};
  // Sous-catégories du filtre/marqueurs = source unique
  final Map<String, Map<String, IconData>> _filtreIconesSous = kSousCategories;
  double? _direction = 0;
  double _vitesse = 0.0;
  double _precision = 0.0;
  StreamSubscription<Position>? _positionStream;
  // ── Enregistrement de voies (façon « paving » Waze, 100 % local) ──
  bool _enregistreTrajet = false;
  List<LatLng> _traceEnCours = [];
  List<List<LatLng>> _voiesEnregistrees = [];
  final FlutterTts _tts = FlutterTts();
  String _langueNavigation = 'Français';

final Map<String, String> _languesTTS = {
  'Français': 'fr-FR',
  'Anglais': 'en-US',
};

Future<void> _parler(String texte) async {
  await _tts.setLanguage(_languesTTS[_langueNavigation] ?? 'fr-FR');
  await _tts.setSpeechRate(0.5);
  await _tts.setVolume(1.0);
  await _tts.speak(texte);
}
List<Map<String, dynamic>> _alertesData = [];
List<LatLng> _itineraire = [];
LatLng? _destination;
String _distanceInfo = '';
String _distanceTexte = ''; // ex: « 3.2 km »
String _dureeTexte = '';    // ex: « 8 min »
bool _navigationActive = false;

final List<Map<String, dynamic>> _typesAlertes = [
  {'type': 'Embouteillage', 'emoji': '🚗', 'couleur': Colors.red},
  {'type': 'Accident', 'emoji': '💥', 'couleur': Colors.red},
  {'type': 'Travaux', 'emoji': '🚧', 'couleur': Colors.orange},
  {'type': 'Inondation', 'emoji': '🌊', 'couleur': Colors.blue},
  {'type': 'Contrôle police', 'emoji': '🚔', 'couleur': Colors.purple},
  {'type': 'Pénurie carburant', 'emoji': '⛽', 'couleur': Colors.brown},
  {'type': 'Nid de poule', 'emoji': '🕳️', 'couleur': Colors.grey},
  {'type': 'Arbre tombé', 'emoji': '🌳', 'couleur': Colors.green},
  {'type': 'Contrôle radar', 'emoji': '📡', 'couleur': Colors.indigo},
  {'type': 'Coupeur de route', 'emoji': '🔪', 'couleur': Colors.red},
];
// Style vectoriel MapTiler chargé au démarrage, et son thème SANS libellés
// (toutes les couches de type « symbol » sont retirées -> aucun nom/POI du
// fournisseur, mais tout le détail des voies entre les lots).
Style? _vectorStyle;
vtr.Theme? _mapTheme;

Future<void> _loadMapStyle() async {
  try {
    final style = await StyleReader(
      uri: 'https://api.maptiler.com/maps/streets-v2/style.json?key={key}',
      apiKey: kMapTilerKey,
    ).read();
    // On ne garde que les couches non-textuelles (fond, surfaces, lignes…).
    final theme = style.theme.copyWith(types: const {
      vtr.ThemeLayerType.background,
      vtr.ThemeLayerType.fill,
      vtr.ThemeLayerType.fillExtrusion,
      vtr.ThemeLayerType.line,
      vtr.ThemeLayerType.raster,
      vtr.ThemeLayerType.unsupported,
    });
    if (mounted) {
      setState(() {
        _vectorStyle = style;
        _mapTheme = theme;
      });
    }
  } catch (e) {
    debugPrint('Erreur chargement style vectoriel: $e');
  }
}

@override
void initState() {
  super.initState();
_initLocation();
_chargerLieux();
_chargerAlertes();
_loadMapStyle();
_chargerVoies();
FlutterCompass.events!.listen((event) {
  if (mounted) {
    setState(() => _direction = event.heading);
  }
});
}
Future<void> _calculerItineraire(LatLng destination) async {
  try {
    final url = 'https://router.project-osrm.org/route/v1/driving/'
      '${_maPosition.longitude},${_maPosition.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=polyline';
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final route = data['routes'][0];
      final geometry = route['geometry'];
      final distance = (route['distance'] / 1000).toStringAsFixed(1);
      final duration = (route['duration'] / 60).toStringAsFixed(0);
      
      final points = decodePolyline(geometry)
        .map((p) => LatLng(p[0].toDouble(), p[1].toDouble()))
        .toList();
      // OSRM "snappe" le départ et l'arrivée sur la route la plus proche :
      // on raccorde le tracé à la vraie position et au lieu exact, pour que
      // la flèche de départ et l'épingle d'arrivée tombent au bon endroit.
      points.insert(0, _maPosition);
      points.add(destination);

      setState(() {
        _itineraire = points;
        _destination = destination;
        _distanceInfo = '$distance km · $duration min';
        _distanceTexte = '$distance km';
        _dureeTexte = '$duration min';
        _navigationActive = true;
      });

      _parler('Itinéraire calculé. Distance $distance kilomètres, durée estimée $duration minutes.');
    }
  } catch (e) {
    debugPrint('Erreur itinéraire: $e');
  }
}
Future<void> _chargerLieux() async {
  try {
    final response = await http.get(Uri.parse('$kBaseUrl/lieux'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        lieuxData = data.map((l) => Map<String, dynamic>.from(l)).toList();
      });
    }
  } catch (e) {
    debugPrint('Erreur chargement lieux: $e');
  }
}

Future<void> _chargerAlertes() async {
  try {
    final response = await http.get(Uri.parse('$kBaseUrl/alertes'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        _alertesData = data.map((a) => Map<String, dynamic>.from(a)).toList();
      });
    }
  } catch (e) {
   debugPrint('Erreur chargement alertes: $e');
  }
}

  Future<void> _initLocation() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      
      // Position initiale
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      if (mounted) {
        setState(() {
          _maPosition = LatLng(pos.latitude, pos.longitude);
          _vitesse = pos.speed;
          _precision = pos.accuracy;
          _gpsCharge = true;
        });
      WidgetsBinding.instance.addPostFrameCallback((_) {
       Future.delayed(const Duration(milliseconds: 300), () {
         if (mounted) _mapController.move(_maPosition, 15);
       });
     });
      }

      // Suivi en temps réel
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5, // mise à jour tous les 5 mètres
        ),
      ).listen((Position pos) {
        if (mounted) {
          setState(() {
            _maPosition = LatLng(pos.latitude, pos.longitude);
            _vitesse = pos.speed;
            _precision = pos.accuracy;
            // Enregistrement : on ajoute le point à la voie en cours.
            if (_enregistreTrajet) _traceEnCours.add(_maPosition);
          });
          if (_navigationActive) {
            _mapController.move(_maPosition, 17);
            if (_direction != null) {
              _mapController.rotate(-_direction!);
            }
          }
        }
      });
    }
  } catch (e) {
    debugPrint('Erreur GPS: $e');
  }
}

  // ── Enregistrement de voies (100 % local, manuel) ──
  void _demarrerEnregistrement() {
    setState(() {
      _enregistreTrajet = true;
      _traceEnCours = [_maPosition];
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('🔴 Enregistrement du trajet démarré'),
      backgroundColor: Color(0xFFFF6B00)));
  }

  Future<void> _arreterEnregistrement() async {
    final trace = List<LatLng>.from(_traceEnCours);
    setState(() {
      _enregistreTrajet = false;
      _traceEnCours = [];
    });
    if (trace.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Trajet trop court, rien enregistré')));
      }
      return;
    }
    setState(() => _voiesEnregistrees.add(trace));
    await _sauverVoies();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✅ Voie enregistrée sur ta carte'),
        backgroundColor: Color(0xFF0F8A5F)));
    }
  }

  Future<void> _chargerVoies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final brut = prefs.getString('voies_enregistrees');
      if (brut == null) return;
      final List<dynamic> data = jsonDecode(brut);
      final voies = data.map<List<LatLng>>((v) => (v as List)
        .map<LatLng>((p) => LatLng((p[0] as num).toDouble(),
          (p[1] as num).toDouble())).toList()).toList();
      if (mounted) setState(() => _voiesEnregistrees = voies);
    } catch (e) {
      debugPrint('Erreur chargement voies: $e');
    }
  }

  Future<void> _sauverVoies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _voiesEnregistrees
        .map((v) => v.map((p) => [p.latitude, p.longitude]).toList())
        .toList();
      await prefs.setString('voies_enregistrees', jsonEncode(data));
    } catch (e) {
      debugPrint('Erreur sauvegarde voies: $e');
    }
  }

  // Liste des voies enregistrées avec suppression (contrôle utilisateur).
  void _gererVoies() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('🛣️ Mes voies enregistrées',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              if (_voiesEnregistrees.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Aucune voie enregistrée pour l'instant.",
                    style: TextStyle(color: Colors.grey)),
                ),
              ..._voiesEnregistrees.asMap().entries.map((e) {
                final i = e.key;
                return ListTile(
                  leading: const Icon(Icons.route, color: Color(0xFFFF6B00)),
                  title: Text('Voie ${i + 1} · ${e.value.length} points'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      setState(() => _voiesEnregistrees.removeAt(i));
                      await _sauverVoies();
                      setSheetState(() {});
                    },
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'validated': return const Color(0xFF0F8A5F);
      case 'probable':  return const Color(0xFFEF9F27);
      case 'contested': return const Color(0xFFD85A30);
      default:          return const Color(0xFFEF9F27);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'validated': return 'Validé';
      case 'probable':  return 'Probable';
      case 'contested': return 'Contesté';
      default:          return 'En attente';
    }
  }

  void _ouvrirDetail(Map<String, dynamic> lieu) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 
        MediaQuery.of(context).padding.bottom + 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre grise en haut
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            // Icône type de lieu
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: _statusColor(lieu['status']).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(_typeEmoji(lieu['type']),
                  style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lieu['nom'],
                    style: const TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor(lieu['status']).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_statusLabel(lieu['status']),
                        style: TextStyle(
                          color: _statusColor(lieu['status']),
                          fontWeight: FontWeight.w600,
                          fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    Text('${lieu['type']}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.person_outline, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text('Soumis par ${lieu['par']}',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const Spacer(),
            const Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${lieu['votes']} votes',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
          const SizedBox(height: 16),
          // Barre d'actions façon Google Maps (scrollable horizontalement).
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _actionFiche(
                icon: Icons.directions,
                label: 'Itinéraire',
                color: const Color(0xFF1A237E),
                onTap: () {
                  Navigator.pop(context);
                  _calculerItineraire(LatLng(lieu['lat'], lieu['lng']));
                },
              ),
              _actionFiche(
                icon: Icons.navigation,
                label: 'Démarrer',
                color: const Color(0xFF0F8A5F),
                onTap: () {
                  Navigator.pop(context);
                  _calculerItineraire(LatLng(lieu['lat'], lieu['lng']));
                  _mapController.move(
                    LatLng(lieu['lat'], lieu['lng']), 16);
                },
              ),
              _actionFiche(
                icon: Icons.call,
                label: 'Appeler',
                color: const Color(0xFF1565C0),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📞 Appeler — bientôt disponible')));
                },
              ),
              _actionFiche(
                icon: _favoris.contains(lieu['nom'])
                  ? Icons.bookmark : Icons.bookmark_border,
                label: 'Enregistrer',
                color: const Color(0xFFD08700),
                onTap: () => _enregistrerLieu(lieu),
              ),
              _actionFiche(
                icon: Icons.share,
                label: 'Partager',
                color: const Color(0xFF6A1B9A),
                onTap: () => _partagerLieu(lieu),
              ),
              _actionFiche(
                icon: Icons.edit,
                label: 'Modifier',
                color: const Color(0xFF455A64),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✏️ Modifier — bientôt disponible')));
                },
              ),
              _actionFiche(
                icon: Icons.more_horiz,
                label: 'Plus',
                color: Colors.grey,
                onTap: () {
                  Navigator.pop(context);
                  _plusActions(lieu);
                },
              ),
            ]),
          ),
        ],
      ),
    ),
  );
}

// ── Fiche de lieu : actions façon Google Maps ──
final Set<String> _favoris = {};

// Bouton d'action circulaire (icône + libellé) de la fiche de lieu.
Widget _actionFiche({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey[800],
              fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}

void _enregistrerLieu(Map<String, dynamic> lieu) {
  final nom = lieu['nom']?.toString() ?? '';
  setState(() {
    _favoris.contains(nom) ? _favoris.remove(nom) : _favoris.add(nom);
  });
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(_favoris.contains(nom)
      ? '🔖 « $nom » enregistré'
      : '« $nom » retiré des enregistrés'),
  ));
}

Future<void> _partagerLieu(Map<String, dynamic> lieu) async {
  final nom = lieu['nom']?.toString() ?? 'Lieu';
  final lien = 'https://maps.google.com/?q=${lieu['lat']},${lieu['lng']}';
  final RenderBox? box = context.findRenderObject() as RenderBox?;
  await Share.share(
    '$nom — sur ZoWay\n$lien',
    subject: nom,
    sharePositionOrigin: box != null
      ? box.localToGlobal(Offset.zero) & box.size
      : null,
  );
}

// Menu « Plus » : actions secondaires (confirmer, signaler, centrer).
void _plusActions(Map<String, dynamic> lieu) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.thumb_up_outlined,
              color: Color(0xFF0F8A5F)),
            title: const Text('Confirmer ce lieu'),
            onTap: () {
              Navigator.pop(context);
              setState(() => pointsTotal += 2);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('👍 Vote enregistré · +2 pts'),
                  backgroundColor: Color(0xFF0F8A5F)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: Color(0xFFD85A30)),
            title: const Text('Signaler un problème'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚩 Signalement envoyé · +8 pts')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.my_location, color: Color(0xFF1A237E)),
            title: const Text('Centrer sur ce lieu'),
            onTap: () {
              Navigator.pop(context);
              _mapController.move(LatLng(lieu['lat'], lieu['lng']), 16);
            },
          ),
        ],
      ),
    ),
  );
}

// Cap (en radians, 0 = nord, sens horaire) du point a vers le point b.
double _bearing(LatLng a, LatLng b) {
  final dLon = (b.longitude - a.longitude) * math.pi / 180;
  final lat1 = a.latitude * math.pi / 180;
  final lat2 = b.latitude * math.pi / 180;
  final y = math.sin(dLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  return math.atan2(y, x);
}

String _typeEmoji(String type) {
  switch (type) {
    case 'Carrefour': return '🚦';
    case 'Rue': return '🛣️';
    case 'Quartier': return '🏘️';
    case 'Monument': return '🏛️';
    case 'Commerce': return '🏪';
    default: return '📍';
  }
}

  void _ouvrirFormulaire(LatLng point) {
    setState(() { _selectedPoint = point; });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NommerSheet(
        latLng: point,
        onSubmit: (nom, type, description) {
  _soumettreNouveauLieu(nom, type, description, point);
setState(() {
  _selectedPoint = null;
  pointsTotal += 5;
});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Lieu soumis ! +5 pts'),
              backgroundColor: Color(0xFF0F8A5F)));
        },
        onCancel: () => setState(() => _selectedPoint = null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !_gpsCharge
  ? Container(
      color: Colors.white,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZoWayLogo(size: 80),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Color(0xFFFF6B00)),
            SizedBox(height: 16),
            Text('Localisation en cours…',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    )
  : Stack(children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _maPosition ?? const LatLng(5.3569, -3.9464),
            initialZoom: 15,
            maxZoom: 19,
            minZoom: 10,
            onTap: null,
          ),
          children: [
            // Fond MapTiler VECTORIEL (style perso « sans libellés ») :
            // l'app dessine la carte à partir du style.json -> aucun nom du
            // fournisseur, seules les données ZoWay nommées apparaissent.
            if (_vectorStyle != null && _mapTheme != null)
              VectorTileLayer(
                tileProviders: _vectorStyle!.providers,
                theme: _mapTheme!,
                maximumZoom: 18,
              ),
            // Voies enregistrées (local) + trace en cours d'enregistrement.
            PolylineLayer(
              polylines: [
                for (final voie in _voiesEnregistrees)
                  Polyline(points: voie, strokeWidth: 4,
                    color: const Color(0xFFFF6B00).withOpacity(0.7)),
                if (_enregistreTrajet && _traceEnCours.length > 1)
                  Polyline(points: _traceEnCours, strokeWidth: 5,
                    color: const Color(0xFFFF6B00)),
              ],
            ),
            if (_itineraire.isNotEmpty)
             PolylineLayer(
              polylines: [
               Polyline(
                points: _itineraire,
                strokeWidth: 5,
               color: const Color(0xFF1A237E),
              ),
            ],
          ),
            // Flèche au départ (orientée vers le trajet) + épingle à l'arrivée.
            if (_itineraire.isNotEmpty)
              MarkerLayer(markers: [
                Marker(
                  point: _itineraire.first,
                  width: 40, height: 40,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F8A5F),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(blurRadius: 4, color: Colors.black38)],
                    ),
                    child: Transform.rotate(
                      angle: _itineraire.length > 1
                        ? _bearing(_itineraire.first, _itineraire[1])
                        : 0,
                      child: const Icon(Icons.navigation,
                        color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ]),
            // Bulle (distance · temps) À CÔTÉ du tracé : la pointe (à gauche
            // de la bulle) se pose sur un point du tracé. alignment centerRight
            // -> le point est au bord gauche, la bulle s'étend vers la droite.
            if (_itineraire.isNotEmpty && _distanceInfo.isNotEmpty)
              MarkerLayer(markers: [
                Marker(
                  point: _itineraire[_itineraire.length ~/ 2],
                  width: 120, height: 52,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pointe dirigée vers la gauche, posée sur le tracé.
                      SizedBox(
                        width: 8, height: 16,
                        child: CustomPaint(
                          painter: _LeftTailPainter(const Color(0xFF1A237E)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(blurRadius: 4, color: Colors.black38)],
                        ),
                        // Distance en haut, temps en dessous (plus compact).
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_distanceTexte,
                              style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w800, fontSize: 13)),
                            Text(_dureeTexte,
                              style: const TextStyle(color: Colors.white70,
                                fontWeight: FontWeight.w600, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            MarkerLayer(markers: [
              Marker(
                point: _maPosition,
                width: 24, height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: _gpsCharge ? Colors.blue : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [BoxShadow(
                      color: (_gpsCharge ? Colors.blue : Colors.grey).withOpacity(0.4),
                      blurRadius: 8, spreadRadius: 3,
                    )],
                  ),
                ),
              ),
              ..._alertesData.map((alerte) {
  final typeInfo = _typesAlertes.firstWhere(
    (t) => t['type'] == alerte['type'],
    orElse: () => {'type': 'Autre', 'emoji': '⚠️', 'couleur': Colors.orange},
  );
  return Marker(
    point: LatLng(alerte['lat'], alerte['lng']),
    width: 44, height: 44,
    child: GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${typeInfo['emoji']} ${alerte['type']}'),
            backgroundColor: typeInfo['couleur'],
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: typeInfo['couleur'],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: Center(
          child: Text(typeInfo['emoji'],
            style: const TextStyle(fontSize: 18)),
        ),
      ),
    ),
  );
}).toList(),
              ...lieuxData.where((lieu) {
  if (_filtreType == 'Tous') return true;
  final sousCat = lieu['sous_categorie'] ?? lieu['type'];
  final cat = lieu['categorie'] ?? '';
  if (_filtreSousType != null) return sousCat == _filtreSousType;
  final sousCats = _filtreIconesSous[_filtreType]?.keys.toList() ?? [];
  if (sousCats.isNotEmpty) return sousCats.contains(sousCat) || cat == _filtreType;
  return cat == _filtreType || sousCat == _filtreType;
}).map((lieu) => Marker(
                point: LatLng(lieu['lat'], lieu['lng']),
                width: 160, height: 55,
                child: GestureDetector(
                  onTap: () => _ouvrirDetail(lieu),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Nom composé à gauche
                    Flexible(
                      child: Text(
                        lieu['nom'] ?? '',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: _statusColor(lieu['status']),
                          shadows: const [
                            Shadow(blurRadius: 3, color: Colors.white, offset: Offset(1, 1)),
                            Shadow(blurRadius: 3, color: Colors.white, offset: Offset(-1, 1)),
                            Shadow(blurRadius: 3, color: Colors.white, offset: Offset(1, -1)),
                            Shadow(blurRadius: 3, color: Colors.white, offset: Offset(-1, -1)),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Cercle + tige groupés et centrés ensemble
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: _statusColor(lieu['status']),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black38, spreadRadius: 1)],
                          ),
                          child: Icon(
                            _filtreIconesSous[lieu['categorie']]?[lieu['sous_categorie']] ??
                            _filtreIcones[lieu['categorie']] ??
                            Icons.place,
                            color: Colors.white, size: 14),
                        ),
                        // Tige noire, centrée sous le cercle
                        Container(width: 2, height: 10, color: Colors.black87),
                      ],
                    ),
                  ],
                ),
                ),
              )),
              if (_selectedPoint != null)
                Marker(
                  point: _selectedPoint!,
                  width: 20, height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
            ]),
          ],
        ),

Positioned(
  // right: 14 (et non 16) car la boîte du bouton fait 48px : ça le centre
  // sur la même verticale que la boussole/langue (cercles 44px à right: 16).
  bottom: 145, right: 14,
  child: _BoutonAlertePulsant(
    onTap: () => _ouvrirFormulaireAlerte(),
  ),
),
Positioned(
  top: 100, left: 16, right: 16,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: [
      for (final type in ['Tous', 'Localités', 'Voirie', 'Lieux publics', 'Plus...'])
        GestureDetector(
          onTap: () {
            if (type == 'Plus...') {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  expand: false,
                  builder: (_, controller) => ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Toutes les catégories',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      for (final cat in _filtreIcones.keys.where((k) => k != 'Tous')) ...[
                        ListTile(
                          leading: Icon(_filtreIcones[cat], color: const Color(0xFFFF6B00)),
                          title: Text(cat, style: const TextStyle(fontWeight: FontWeight.w700)),
                          trailing: _filtreType == cat
                            ? const Icon(Icons.check, color: Color(0xFFFF6B00))
                            : null,
                          onTap: () {
                            setState(() => _filtreType = cat);
                            Navigator.pop(context);
                          },
                        ),
                        if (_filtreIconesSous.containsKey(cat))
                          Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (_filtreIconesSous[cat]!).entries.map((e) =>
                                GestureDetector(
                                  onTap: () {
  setState(() {
    _filtreType = cat;
    _filtreSousType = null;
  });
  Navigator.pop(context);
},
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _filtreType == e.key
                                        ? const Color(0xFFFF6B00)
                                        : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(e.value, size: 14,
                                        color: _filtreType == e.key ? Colors.white : Colors.black87),
                                      const SizedBox(width: 4),
                                      Text(e.key,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _filtreType == e.key ? Colors.white : Colors.black87,
                                        )),
                                    ]),
                                  ),
                                ),
                              ).toList(),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            } else {
              setState(() {
  _filtreType = type;
  _filtreSousType = null;
});
            }
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _filtreType == type
                ? const Color(0xFFFF6B00)
                : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black26)],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_filtreIcones[type] ?? Icons.more_horiz,
                size: 14,
                color: _filtreType == type ? Colors.white : Colors.black87),
              const SizedBox(width: 4),
              Text(type,
                style: TextStyle(
                  color: _filtreType == type ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                )),
            ]),
          ),
        ),
    ]),
  ),
  if (_filtreType != 'Tous' && _filtreIconesSous.containsKey(_filtreType)) ...[
    const SizedBox(height: 8),
    SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        GestureDetector(
          onTap: () => setState(() => _filtreSousType = null),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _filtreSousType == null
                ? const Color(0xFFFF6B00)
                : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black26)],
            ),
            child: Text('Tous',
              style: TextStyle(
                fontSize: 11,
                color: _filtreSousType == null ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              )),
          ),
        ),
        for (final entry in _filtreIconesSous[_filtreType]!.entries)
          GestureDetector(
            onTap: () => setState(() => _filtreSousType = entry.key),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _filtreSousType == entry.key
                  ? const Color(0xFFFF6B00)
                  : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black26)],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(entry.value, size: 12,
                  color: _filtreSousType == entry.key ? Colors.white : Colors.black87),
                const SizedBox(width: 4),
                Text(entry.key,
                  style: TextStyle(
                    fontSize: 11,
                    color: _filtreSousType == entry.key ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  )),
              ]),
            ),
          ),
      ]),
    ),
  ],
  ],
  ),
),
Positioned(
  top: 40, left: 12, right: 12,
  child: Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
    ),
    child: TextField(
      decoration: const InputDecoration(
        hintText: '🔍 Où aller ?',
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: Icon(Icons.search, color: Color(0xFFFF6B00)),
      ),
      onSubmitted: (valeur) async {
        if (valeur.isEmpty) return;
        try {
          // Chercher d'abord dans les lieux ZoWay
          final lieuZoWay = lieuxData.where((l) =>
            l['nom'].toString().toLowerCase()
              .contains(valeur.toLowerCase())).toList();
          if (lieuZoWay.isNotEmpty) {
            final lieu = lieuZoWay.first;
            _mapController.move(LatLng(lieu['lat'], lieu['lng']), 16);
            if (mounted) _ouvrirDetail(lieu);
            return;
          }
          // Sinon chercher sur Nominatim
          final url = 'https://nominatim.openstreetmap.org/search'
            '?q=${Uri.encodeComponent(valeur)}&format=json&limit=1&countrycodes=ci';
          final response = await http.get(Uri.parse(url),
            headers: {'User-Agent': 'ZoWay/1.0'});
          final data = jsonDecode(response.body);
          if (data.isNotEmpty) {
            final lat = double.parse(data[0]['lat']);
            final lon = double.parse(data[0]['lon']);
            final dest = LatLng(lat, lon);
            await _calculerItineraire(dest);
            _mapController.move(dest, 14);
            if (mounted) setState(() {});
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Adresse non trouvée')));
          }
        } catch (e) {
          debugPrint('Erreur recherche: $e');
        }
      },
    ),
  ),
),
// ZoWay texte transparent bas gauche
Positioned(
  bottom: 10, left: 15,
  child: Text('ZoWay',
    style: GoogleFonts.nunito(
      fontWeight: FontWeight.w900,
      fontSize: 16,
      color: const Color(0xFFFF6B00).withOpacity(0.9),
    )),
),
// ── Enregistrement de voies : gérer (haut) + start/stop (bas) ──
Positioned(
  left: 16, bottom: 44,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      GestureDetector(
        onTap: _gererVoies,
        child: Container(
          width: 40, height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)],
          ),
          child: const Icon(Icons.route, color: Color(0xFFFF6B00), size: 22),
        ),
      ),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: _enregistreTrajet
          ? _arreterEnregistrement
          : _demarrerEnregistrement,
        child: Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: _enregistreTrajet
              ? const Color(0xFFD81B30) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black38)],
          ),
          child: Icon(
            _enregistreTrajet ? Icons.stop : Icons.fiber_manual_record,
            color: _enregistreTrajet
              ? Colors.white : const Color(0xFFD81B30),
            size: 28,
          ),
        ),
      ),
    ],
  ),
),
Positioned(
  top: 180, right: 16,
  child: GestureDetector(
    onTap: () {
      if (_direction != null) {
        _mapController.rotate(-_direction!);
      }
    },
    child: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: Transform.rotate(
        angle: ((_direction ?? 0) * 3.14159 / 180),
        child: const Icon(Icons.navigation, color: Color(0xFFFF6B00), size: 24),
      ),
    ),
  ),
), 
Positioned(
  top: 236, right: 16,
  child: GestureDetector(
    onTap: () {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎙️ Langue de navigation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ...['Français', 'Anglais'].map((langue) {
                final actif = _langueNavigation == langue;
                return ListTile(
                  leading: Text(
                    langue == 'Français' ? '🇫🇷' : '🇬🇧',
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(langue),
                  trailing: actif
                    ? const Icon(Icons.check_circle, color: Color(0xFFFF6B00))
                    : null,
                  onTap: () {
                    setState(() => _langueNavigation = langue);
                    Navigator.pop(context);
                    _parler(langue == 'Français'
                      ? 'Navigation en français activée'
                      : 'Navigation in English activated');
                  },
                );
              }).toList(),
              const SizedBox(height: 8),
              const Text('🗣️ Dioula, Baoulé et Bété — bientôt disponibles !',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );
    },
    child: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: const Icon(Icons.record_voice_over, color: Color(0xFFFF6B00), size: 24),
    ),
  ),
),
        Positioned(
          bottom: 85, right: 16,
          child: GestureDetector(
            onTap: () => _mapController.move(_maPosition, 15),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
              ),
              child: const Icon(Icons.my_location, color: Color(0xFF0F8A5F), size: 24),
            ),
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F8A5F),
        foregroundColor: Colors.white,
        onPressed: () {
          if (!_gpsCharge) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('⏳ GPS en cours de chargement...')));
            return;
          }
          _ouvrirFormulaire(_maPosition);
        },
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Nommer un lieu'),
      ),
    );
  }
Future<void> _soumettreNouveauLieu(String nom, String type, String description, LatLng point) async {
  try {
    // Récupérer la ville via GPS
    String ville = 'Inconnue';
    try {
      final geoUrl = 'https://nominatim.openstreetmap.org/reverse'
        '?lat=${point.latitude}&lon=${point.longitude}&format=json';
      final geoResponse = await http.get(Uri.parse(geoUrl),
        headers: {'User-Agent': 'ZoWay/1.0'});
      final geoData = jsonDecode(geoResponse.body);
      ville = geoData['address']['city']
        ?? geoData['address']['town']
        ?? geoData['address']['village']
        ?? 'Inconnue';
    } catch (e) {
      debugPrint('Erreur géocodage: $e');
    }

    final response = await http.post(
      Uri.parse('$kBaseUrl/lieux'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nom': nom,
        'type': type,
        'description': description,
        'lat': point.latitude,
        'lng': point.longitude,
        'par': nomUtilisateur,
        'ville': ville,
        'categorie': type,
        'sous_categorie': type,
      }),
    );
      await _chargerLieux();
    } catch (e) {
      debugPrint('Erreur soumission: $e');
    }
  }
void _ouvrirFormulaireAlerte() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Container(
  padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 60),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🚨 Signaler une alerte',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _typesAlertes.map((t) {
              return GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  await _soumettreAlerte(t['type']);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: (t['couleur'] as Color).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: t['couleur'] as Color),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(t['emoji'],
                      style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(t['type'],
                      style: TextStyle(
                        color: t['couleur'] as Color,
                        fontWeight: FontWeight.w600)),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

Future<void> _soumettreAlerte(String type) async {
  try {
    await http.post(
      Uri.parse('$kBaseUrl/alertes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': type,
        'lat': _maPosition.latitude,
        'lng': _maPosition.longitude,
        'par': nomUtilisateur,
      }),
    );
    await _chargerAlertes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🚨 Alerte $type signalée !'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    debugPrint('Erreur soumission alerte: $e');
  }
}
@override
void dispose() {
  _positionStream?.cancel();
  _tts.stop();
  super.dispose();
}
} // ← fermeture de _CarteScreenState

// Clé API MapTiler (fond de carte). Plan gratuit : 100k tuiles/mois.
// À restreindre à l'app depuis le dashboard MapTiler avant publication.
const String kMapTilerKey = 'bCEH6uKlS7Ah94RkjeYk';

// ════════════════════════════════════════════════════════════════
// SOURCE UNIQUE des catégories → sous-catégories (icônes incluses).
// Utilisée par : la barre de filtres, les marqueurs de la carte ET le
// formulaire « Nommer un lieu ». Tout ajout/modif se fait ICI uniquement.
// ════════════════════════════════════════════════════════════════
const Map<String, IconData> kCategorieIcones = {
  'Localités': Icons.location_city,
  'Voirie': Icons.add_road,
  'Lieux publics': Icons.account_balance,
  'Santé': Icons.local_hospital,
  'Éducation': Icons.school,
  'Religion': Icons.church,
  'Transport': Icons.directions_bus,
  'Restauration': Icons.restaurant,
  'Hébergement': Icons.hotel,
  'Commerce': Icons.store,
  'Finance': Icons.account_balance_wallet,
  'Énergie': Icons.local_gas_station,
  'Loisirs': Icons.sports_soccer,
  'Nature': Icons.park,
  'Agriculture': Icons.grass,
};
const Map<String, Map<String, IconData>> kSousCategories = {
  'Localités': {
    'Quartier': Icons.holiday_village,
    'Sous-quartier': Icons.location_on,
    'Village': Icons.cottage,
    'Cité': Icons.apartment,
    'Résidence': Icons.house,
    'Campement': Icons.cabin,
    'Hameau': Icons.location_on,
  },
  'Voirie': {
    'Rue': Icons.turn_right,
    'Avenue': Icons.add_road,
    'Boulevard': Icons.add_road,
    'Carrefour': Icons.swap_calls,
    'Rond-point': Icons.roundabout_right,
    'Impasse': Icons.block,
    'Pont': Icons.directions,
    'Passage': Icons.transfer_within_a_station,
  },
  'Lieux publics': {
    'Mairie': Icons.account_balance,
    'Préfecture': Icons.account_balance,
    'Sous-préfecture': Icons.account_balance,
    'Commissariat': Icons.local_police,
    'Gendarmerie': Icons.local_police,
    'Tribunal': Icons.gavel,
  },
  'Santé': {
    'Hôpital': Icons.local_hospital,
    'Clinique': Icons.medical_services,
    'Centre de santé': Icons.health_and_safety,
    'Pharmacie': Icons.medication,
    'Cabinet médical': Icons.medical_services,
    'Maternité': Icons.child_care,
  },
  'Éducation': {
    'École primaire': Icons.school,
    'Collège': Icons.school,
    'Lycée': Icons.school,
    'Université': Icons.account_balance,
    'Centre de formation': Icons.cast_for_education,
    'Bibliothèque': Icons.menu_book,
  },
  'Religion': {
    'Église': Icons.church,
    'Mosquée': Icons.mosque,
    'Temple': Icons.temple_buddhist,
    'Cathédrale': Icons.church,
    'Paroisse': Icons.church,
  },
  'Transport': {
    'Gare routière': Icons.directions_bus,
    'Arrêt bus': Icons.bus_alert,
    'Gare ferroviaire': Icons.train,
    'Port': Icons.directions_boat,
    'Aéroport': Icons.flight,
    'Station taxi': Icons.local_taxi,
    'Parking': Icons.local_parking,
  },
  'Restauration': {
    'Maquis': Icons.local_bar,
    'Restaurant': Icons.restaurant,
    'Fast food': Icons.fastfood,
    'Boulangerie': Icons.bakery_dining,
    'Café': Icons.coffee,
    'Bar': Icons.local_bar,
    'Kiosque': Icons.store,
  },
  'Hébergement': {
    'Hôtel': Icons.hotel,
    'Auberge': Icons.house,
    'Résidence': Icons.apartment,
    'Pension': Icons.bed,
    'Motel': Icons.hotel,
  },
  'Commerce': {
    'Marché': Icons.storefront,
    'Supermarché': Icons.shopping_cart,
    'Boutique': Icons.store,
    'Quincaillerie': Icons.hardware,
    'Librairie': Icons.menu_book,
  },
  'Finance': {
    'Banque': Icons.account_balance,
    'Microfinance': Icons.savings,
    'Mobile Money': Icons.phone_android,
    'Bureau de change': Icons.currency_exchange,
    'Assurance': Icons.security,
  },
  'Énergie': {
    'Station essence': Icons.local_gas_station,
    'Station GPL': Icons.local_gas_station,
    'Groupe électrogène': Icons.electrical_services,
  },
  'Loisirs': {
    'Stade': Icons.stadium,
    'Terrain de foot': Icons.sports_soccer,
    'Salle de sport': Icons.fitness_center,
    'Cinéma': Icons.movie,
    'Discothèque': Icons.nightlife,
    'Parc': Icons.park,
  },
  'Nature': {
    'Forêt': Icons.forest,
    'Rivière': Icons.water,
    'Lac': Icons.water,
    'Colline': Icons.terrain,
    'Plage': Icons.beach_access,
    'Champ': Icons.grass,
    'Plantation': Icons.nature,
  },
  'Agriculture': {
    'Coopérative': Icons.group,
    'Moulin': Icons.wind_power,
    'Silo': Icons.warehouse,
    'Ferme': Icons.agriculture,
  },
};
// ── FORMULAIRE NOMMER ──
class _NommerSheet extends StatefulWidget {
  final LatLng latLng;
  final void Function(String nom, String type, String description) onSubmit;
  final VoidCallback onCancel;
  const _NommerSheet({required this.latLng, required this.onSubmit, required this.onCancel});
  @override
  State<_NommerSheet> createState() => _NommerSheetState();
}

 class _NommerSheetState extends State<_NommerSheet> {
  final _nomController = TextEditingController();
  final _descController = TextEditingController();
  String _categorie = 'Localités';
  String? _sousCategorie;
  // Dérivés de la source unique (rétro-compatibilité du code existant).
final Map<String, IconData> _icones = kCategorieIcones;
final Map<String, IconData> _iconesS = {
  for (final subs in kSousCategories.values) ...subs,
};
  // Catégories du formulaire = source unique (catégorie → liste des sous-catégories)
  final Map<String, List<String>> _categories = {
    for (final e in kSousCategories.entries) e.key: e.value.keys.toList(),
  };

  @override
  Widget build(BuildContext context) {
    final sousCats = _categories[_categorie] ?? [];
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('📍 Nommer ce lieu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(
              onPressed: () { widget.onCancel(); Navigator.pop(context); },
              icon: const Icon(Icons.close),
            ),
          ]),
          Text(
            '${widget.latLng.latitude.toStringAsFixed(4)}°N, '
            '${widget.latLng.longitude.abs().toStringAsFixed(4)}°W',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          const Text('NOM DU LIEU',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          TextField(
           controller: _nomController,
           decoration: InputDecoration(
           hintText: _sousCategorie != null 
             ? 'Ex: ${_sousCategorie!} ...' 
             : 'Ex: Carrefour Shell Riviera',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF0F8A5F), width: 1.5),
              ),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          const Text('CATÉGORIE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.keys.map((cat) {
                final active = _categorie == cat;
                return GestureDetector(
                  onTap: () => setState(() {
                    _categorie = cat;
                    _sousCategorie = null;
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFFF6B00) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
  Icon(_icones[cat] ?? Icons.place,
    size: 14,
    color: active ? Colors.white : Colors.black87),
  const SizedBox(width: 4),
  Text(cat,
    style: TextStyle(
      color: active ? Colors.white : Colors.black87,
      fontWeight: FontWeight.w600,
      fontSize: 12,
    )),
]),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          const Text('SOUS-CATÉGORIE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _sousCategorie,
            hint: const Text('Choisir une sous-catégorie'),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            items: sousCats.map((s) =>
              DropdownMenuItem(value: s, child: Row(children: [
                Icon(_iconesS[s] ?? Icons.place, size: 16, color: const Color(0xFFFF6B00)),
                const SizedBox(width: 8),
                Text(s),
              ]))).toList(),
            onChanged: (v) => setState(() => _sousCategorie = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Description (optionnel)',
              hintText: 'Ex: À côté de la pharmacie...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F8A5F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final nom = _nomController.text.trim();
                if (nom.isEmpty) return;
                final type = _sousCategorie ?? _categorie;
                final nomComplet = _sousCategorie != null && !nom.startsWith(_sousCategorie!)
                  ? '${_sousCategorie!} $nom'
                  : nom;
                widget.onSubmit(nomComplet, type, _descController.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Soumettre ce nom',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text('Tu gagneras +5 pts à la soumission',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── VALIDER ──
class ValiderScreen extends StatefulWidget {
  const ValiderScreen({super.key});
  @override
  State<ValiderScreen> createState() => _ValiderScreenState();
}

class _ValiderScreenState extends State<ValiderScreen> {
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      try {
        final response = await http.get(Uri.parse('$kBaseUrl/lieux'));
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          setState(() {
            lieuxData = data.map((l) =>
              Map<String, dynamic>.from(l)).toList();
            _chargement = false;
          });
        } else {
          setState(() => _chargement = false);
        }
      } catch (e) {
        setState(() => _chargement = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final pending = lieuxData
        .where((l) => l['status'] == 'pending' || 
                      l['status'] == 'probable' ||
                      l['status'] == null ||
                      l['status'] == 'en_attente')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${pending.length} lieux à valider',
          style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: pending.isEmpty
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle, color: Color(0xFF0F8A5F), size: 48),
              SizedBox(height: 12),
              Text('Tout est validé !', style: TextStyle(fontSize: 16, color: Colors.grey)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: pending.length,
              itemBuilder: (_, i) {
                final l = pending[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(l['nom'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Soumis par ${l['par']} · ${l['votes']} votes',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F8A5F),
                              side: const BorderSide(color: Color(0xFF0F8A5F)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('👍 Vote enregistré · +2 pts'),
                                  backgroundColor: Color(0xFF0F8A5F)));
                            },
                            icon: const Icon(Icons.thumb_up_outlined, size: 16),
                            label: const Text('Confirmer'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFD85A30),
                              side: const BorderSide(color: Color(0xFFD85A30)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('👎 Vote enregistré · +2 pts')));
                            },
                            icon: const Icon(Icons.thumb_down_outlined, size: 16),
                            label: const Text('Incorrect'),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
// ── CLASSEMENT ──
class ClassementScreen extends StatelessWidget {
  const ClassementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mettre à jour les points de l'utilisateur et trier
    classement.firstWhere((j) => j['moi'] == true)['points'] = pointsTotal;
    classement.firstWhere((j) => j['moi'] == true)['niveau'] = _getNiveau(pointsTotal);
    classement.sort((a, b) => (b['points'] as int).compareTo(a['points'] as int));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classement Cocody',
          style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              backgroundColor: const Color(0xFFFFF3E0),
              label: Text('🔥 $streakJours jours',
                style: const TextStyle(color: Color(0xFFE65100),
                  fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: Column(children: [
        // Podium top 3
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF0F8A5F).withOpacity(0.06),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2ème
              Expanded(child: _PodiumItem(
                rang: 2,
                nom: classement[1]['nom'],
                points: classement[1]['points'],
                hauteur: 80,
                couleur: Colors.grey[400]!,
              )),
              // 1er
              Expanded(child: _PodiumItem(
                rang: 1,
                nom: classement[0]['nom'],
                points: classement[0]['points'],
                hauteur: 110,
                couleur: const Color(0xFFFFD700),
              )),
              // 3ème
              Expanded(child: _PodiumItem(
                rang: 3,
                nom: classement[2]['nom'],
                points: classement[2]['points'],
                hauteur: 60,
                couleur: const Color(0xFFCD7F32),
              )),
            ],
          ),
        ),

        // Liste complète
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: classement.length,
            itemBuilder: (_, i) {
              final joueur = classement[i];
              final estMoi = joueur['moi'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: estMoi
                      ? const Color(0xFF0F8A5F).withOpacity(0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: estMoi
                        ? const Color(0xFF0F8A5F)
                        : Colors.grey[200]!,
                    width: estMoi ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: i < 3
                        ? [const Color(0xFFFFD700), Colors.grey[400]!, const Color(0xFFCD7F32)][i]
                        : const Color(0xFFE8F7F2),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: i < 3 ? Colors.white : const Color(0xFF0F8A5F),
                      ),
                    ),
                  ),
                  title: Row(children: [
                    Text(
                      joueur['nom'],
                      style: TextStyle(
                        fontWeight: estMoi ? FontWeight.w700 : FontWeight.w500,
                        color: estMoi ? const Color(0xFF0F8A5F) : Colors.black,
                      ),
                    ),
                    if (estMoi) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F8A5F),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Toi',
                          style: TextStyle(color: Colors.white, fontSize: 10,
                            fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ]),
                  subtitle: Text(joueur['niveau'],
                    style: const TextStyle(fontSize: 12)),
                  trailing: Text(
                    '${joueur['points']} pts',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: estMoi ? const Color(0xFF0F8A5F) : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Bandeau streak en bas
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6F00), Color(0xFFFFB300)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Text('🔥', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Série de $streakJours jours !',
                  style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 15)),
                const Text('Reviens demain pour continuer ta série',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('+10 pts\ndemain',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 11)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final int rang;
  final String nom;
  final int points;
  final double hauteur;
  final Color couleur;

  const _PodiumItem({
    required this.rang,
    required this.nom,
    required this.points,
    required this.hauteur,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(rang == 1 ? '👑' : rang == 2 ? '🥈' : '🥉',
          style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(nom,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text('$points pts',
          style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 6),
        Container(
          height: hauteur,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: couleur,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text('$rang',
              style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 20)),
          ),
        ),
      ],
    );
  }
}

// ── PROFIL ──
class ProfilScreen extends StatefulWidget {
  final void Function(int pts) onPointsAdded;
  const ProfilScreen({super.key, required this.onPointsAdded});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Future<void> _partagerPosition() async {
    // 1. Vérifier que la localisation est activée
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Active la localisation pour partager ta position.')),
      );
      return;
    }

    // 2. Gérer les permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission de localisation refusée.')),
      );
      return;
    }

    try {
      // 3. Récupérer la position GPS actuelle
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 4. Générer le lien Google Maps
      final String lien =
          'https://maps.google.com/?q=${pos.latitude},${pos.longitude}';

      // 5. Ouvrir le menu de partage natif (Android + iOS/iPad)
      if (!mounted) return;
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      await Share.share(
        'Voici ma position : $lien',
        subject: 'Ma position ZoWay',
        // Requis sur iPad/iOS : l'origine du popover doit être non nulle,
        // sinon la feuille de partage ne s'affiche pas (PlatformException).
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de récupérer la position : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil',
          style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Carte profil
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F8A5F), Color(0xFF1DB87A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(
                    nomUtilisateur.length >= 2
                      ? nomUtilisateur.substring(0, 2).toUpperCase()
                      : nomUtilisateur.toUpperCase(),
                    style: TextStyle(color: Colors.white,
                    fontSize: 18, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
  Flexible(
    child: Text(nomUtilisateur, style: const TextStyle(color: Colors.white,
      fontSize: 17, fontWeight: FontWeight.w600),
      overflow: TextOverflow.ellipsis),
  ),
  const SizedBox(width: 8),
  GestureDetector(
    onTap: () {
      final controller = TextEditingController(text: nomUtilisateur);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Modifier le pseudo'),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Ton pseudo...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final nouveau = controller.text.trim();
                if (nouveau.isNotEmpty) {
                  nomUtilisateur = nouveau;
                }
                Navigator.pop(context);
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      );
    },
    child: const Icon(Icons.edit, color: Colors.white70, size: 16),
  ),
  const SizedBox(width: 8),
  GestureDetector(
  onTap: () {
    final controller = TextEditingController(text: quartierUtilisateur);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ma localité'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Ex: Daloa, Cocody, Yopougon...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final nouveau = controller.text.trim();
              if (nouveau.isNotEmpty) {
                setState(() {
                  quartierUtilisateur = nouveau;
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  },
  child: const Icon(Icons.location_on, color: Colors.white70, size: 16),
  ),
]),
                  const SizedBox(height: 3),
                  Text('${_getNiveau(pointsTotal)} · $quartierUtilisateur',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  // Streak dans le profil
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('🔥 Série de $streakJours jours',
                      style: const TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Bouton Partager ma position
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _partagerPosition,
              icon: const Icon(Icons.share_location),
              label: const Text('Partager ma position',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(children: [
            _StatCard(label: 'Nommés',
              value: '${lieuxData.where((l) => l['par'] == 'Moi').length}'),
            const SizedBox(width: 10),
            _StatCard(label: 'Validés', value: '${lieuxData.where((l) => l['par'] == nomUtilisateur && l['status'] == 'validated').length}'),
            const SizedBox(width: 10),
            _StatCard(label: 'Points', value: '$pointsTotal'),
          ]),
          const SizedBox(height: 16),

          // Progression
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Progression vers Explorateur',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pointsTotal / 50,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF0F8A5F)),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text('$pointsTotal / 50 pts pour le prochain niveau',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // Streak card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6F00), Color(0xFFFFB300)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$streakJours jours de suite !',
                  style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 16)),
                const Text('Continue pour débloquer des bonus',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Récompenses
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('RÉCOMPENSES',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: Colors.grey, letterSpacing: 0.5)),
          ),
          const SizedBox(height: 8),
          const _RewardItem(icon: '📱', titre: '500 FCFA crédit Orange', pts: '250 pts'),
          const _RewardItem(icon: '📱', titre: '1000 FCFA crédit MTN', pts: '500 pts'),
          const _RewardItem(icon: '🏷️', titre: 'Réduction 20% partenaire', pts: '150 pts'),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      ),
    );
  }
}

class _RewardItem extends StatelessWidget {
  final String icon, titre, pts;
  const _RewardItem({required this.icon, required this.titre, required this.pts});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Text(icon, style: const TextStyle(fontSize: 18)),
        title: Text(titre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        trailing: Text(pts,
          style: const TextStyle(color: Color(0xFF0F8A5F), fontWeight: FontWeight.w600)),
      ),
    );
  }
}
class _BoutonAlertePulsant extends StatefulWidget {
  final VoidCallback onTap;
  const _BoutonAlertePulsant({required this.onTap});
  @override
  State<_BoutonAlertePulsant> createState() => _BoutonAlertePulsantState();
}

class _BoutonAlertePulsantState extends State<_BoutonAlertePulsant>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Cercle pulsant extérieur
              Transform.scale(
                scale: _animation.value,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.3),
                  ),
                ),
              ),
              // Bouton principal
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red,
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🚨',
                    style: TextStyle(fontSize: 24)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
class ZoWayLogo extends StatelessWidget {
  final double size;
  const ZoWayLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ZoWayPainter(),
      ),
    );
  }
}

class _ZoWayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Fond orange arrondi
    final bgPaint = Paint()..color = const Color(0xFFFF6B00);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.22),
    );
    canvas.drawRRect(rect, bgPaint);

    // Corps bulle
    final bullePaint = Paint()..color = const Color(0xFFFF6B00);
    final bulleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.1, h * 0.15, w * 0.8, h * 0.65),
      Radius.circular(w * 0.35),
    );
    canvas.drawRRect(bulleRect, bullePaint);

    // Oeil gauche blanc
    final oeilBlanc = Paint()..color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.35, h * 0.48),
        width: w * 0.28,
        height: h * 0.30,
      ),
      oeilBlanc,
    );

    // Oeil droit blanc
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.65, h * 0.48),
        width: w * 0.28,
        height: h * 0.30,
      ),
      oeilBlanc,
    );

    // Pupille gauche
    final pupillePaint = Paint()..color = const Color(0xFF1A237E);
    canvas.drawCircle(Offset(w * 0.37, h * 0.50), w * 0.10, pupillePaint);

    // Pupille droite
    canvas.drawCircle(Offset(w * 0.67, h * 0.50), w * 0.10, pupillePaint);

    // Reflets
    final refletPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.39, h * 0.46), w * 0.04, refletPaint);
    canvas.drawCircle(Offset(w * 0.69, h * 0.46), w * 0.04, refletPaint);

    // Sourire
    final sourirePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.04
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final sourirePath = ui.Path();
    sourirePath.moveTo(w * 0.30, h * 0.68);
    sourirePath.quadraticBezierTo(w * 0.50, h * 0.80, w * 0.70, h * 0.68);
    canvas.drawPath(sourirePath, sourirePaint);

    // Épingle dorée
    final epinglePaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawCircle(Offset(w * 0.50, h * 0.12), w * 0.08, epinglePaint);

    // Tige épingle
    final tigePaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.50, h * 0.20),
      Offset(w * 0.50, h * 0.28),
      tigePaint,
    );

    // Point centre épingle
    final centrePaint = Paint()..color = const Color(0xFFFF6B00);
    canvas.drawCircle(Offset(w * 0.50, h * 0.12), w * 0.03, centrePaint);
  }

  @override
  bool shouldRepaint(_ZoWayPainter oldDelegate) => false;
}
class _PinTailPainter extends CustomPainter {
  final Color color;
  _PinTailPainter(this.color);
  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final paint = ui.Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}

// Pointe de bulle dirigée vers la GAUCHE (apex à gauche, base à droite).
class _LeftTailPainter extends CustomPainter {
  final Color color;
  _LeftTailPainter(this.color);
  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final paint = ui.Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(_LeftTailPainter old) => old.color != color;
}
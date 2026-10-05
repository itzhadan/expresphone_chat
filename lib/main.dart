import 'dart:async';

import 'cozy_pdf_page.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:local_auth/local_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String api = "https://arnonidan.pythonanywhere.com";
const List<String> accessUsers = [
  "admin",
  "יבואן 1",
  "יבואן 2",
  "יבואן 3",
  "יבואן 4",
  "יבואן 5",
  "יבואן 6",
  "יבואן 7",
  "יבואן 8",
  "יבואן 9",
  "עידן",
];
const List<String> visibleAccessUsers = [
  "יבואן 1",
  "יבואן 2",
  "יבואן 3",
  "יבואן 4",
  "יבואן 5",
  "יבואן 6",
  "יבואן 7",
  "יבואן 8",
  "יבואן 9",
  "עידן",
];
const Map<String, String> accessUserLabels = {
  "admin": "",
  "יבואן 1": "יבואן 1",
  "יבואן 2": "יבואן 2",
  "יבואן 3": "יבואן 3",
  "יבואן 4": "יבואן 4",
  "יבואן 5": "יבואן 5",
  "יבואן 6": "יבואן 6",
  "יבואן 7": "יבואן 7",
  "יבואן 8": "יבואן 8",
  "יבואן 9": "יבואן 9",
  "עידן": "עידן הנהלה",
};
// "admin" הוא האדמין הראשי. "עידן" (הנהלה) מנהל הכול, אבל לא רואה את admin
// ולא רואה את המתג של Cozy AI.
const Set<String> managerUsers = {"admin", "עידן"};
bool isManagerUser(String user) => managerUsers.contains(user);
bool isSuperAdminUser(String user) => user == "admin";
String accessUserLabel(String user) => accessUserLabels[user] ?? user;
// קודי הכניסה לא נמצאים באפליקציה. הקוד נבדק בשרת בלבד.
// הקוד של המשתמש שהתחבר נשמר בזיכרון בלבד, ובאחסון מוצפן אם הופעל ביומטרי.
final Map<String, String> _sessionPins = {};
String userPin(String user) => _sessionPins[user] ?? "";
const FlutterSecureStorage _secure = FlutterSecureStorage();
Future<void> savePinSecurely(String user, String pin) async {
  try {
    await _secure.write(key: "pin_$user", value: pin);
  } catch (_) {}
}

Future<String?> loadSavedPin(String user) async {
  try {
    return await _secure.read(key: "pin_$user");
  } catch (_) {
    return null;
  }
}

Future<void> clearSavedPin(String user) async {
  try {
    await _secure.delete(key: "pin_$user");
  } catch (_) {}
}

String mediaUrl(String value) {
  final url = value.trim();
  if (url.isEmpty || url.startsWith("http://") || url.startsWith("https://")) {
    return url;
  }
  return url.startsWith("/") ? "$api$url" : "$api/$url";
}

// נמלים גדולים בעולם (שם, מדינה, קו רוחב, קו אורך) - לצורך "מרחק מהנמל הקרוב"
const List<List<Object>> majorPorts = [
  ["חיפה", "ישראל", 32.8192, 34.9983],
  ["אשדוד", "ישראל", 31.8044, 34.6553],
  ["פורט סעיד", "מצרים", 31.2653, 32.3019],
  ["אלכסנדריה", "מצרים", 31.2001, 29.9187],
  ["איסתנבול", "טורקיה", 41.0082, 28.9784],
  ["מרסין", "טורקיה", 36.7951, 34.6180],
  ["ביירות", "לבנון", 33.9006, 35.5197],
  ["לטקיה", "סוריה", 35.5317, 35.7915],
  ["ג'דה", "ערב הסעודית", 21.5433, 39.1728],
  ["דובאי (ג'בל עלי)", "איחוד האמירויות", 25.0119, 55.0617],
  ["מומבאסה", "קניה", -4.0435, 39.6682],
  ["דאר א-סלאם", "טנזניה", -6.7924, 39.2083],
  ["ג'יבוטי", "ג'יבוטי", 11.5721, 43.1456],
  ["לגוס (אפאפה)", "ניגריה", 6.4432, 3.3690],
  ["טמה", "גאנה", 5.6698, -0.0166],
  ["אבידג'אן", "חוף השנהב", 5.2893, -4.0134],
  ["לומה", "טוגו", 6.1319, 1.2228],
  ["קוטונו", "בנין", 6.3654, 2.4183],
  ["דקאר", "סנגל", 14.6928, -17.4467],
  ["באנג'ול", "גמביה", 13.4432, -16.5844],
  ["פריטאון", "סיירה לאון", 8.4844, -13.2344],
  ["מונרוביה", "ליבריה", 6.3156, -10.8074],
  ["דואלה", "קמרון", 4.0511, 9.7679],
  ["פואנט נואר", "קונגו", -4.7761, 11.8636],
  ["לואנדה", "אנגולה", -8.8147, 13.2302],
  ["דרבן", "דרום אפריקה", -29.8587, 31.0218],
  ["קייפטאון", "דרום אפריקה", -33.9086, 18.4232],
  ["קזבלנקה", "מרוקו", 33.6022, -7.6175],
  ["טנג'יר מד", "מרוקו", 35.8823, -5.5],
  ["תוניס (רדס)", "תוניסיה", 36.8033, 10.2894],
  ["טריפולי", "לוב", 32.9022, 13.1875],
  ["רוטרדם", "הולנד", 51.9496, 4.1453],
  ["אנטוורפן", "בלגיה", 51.2603, 4.4023],
  ["המבורג", "גרמניה", 53.5459, 9.9689],
  ["ברמרהאפן", "גרמניה", 53.5396, 8.5809],
  ["לה הבר", "צרפת", 49.4938, 0.1077],
  ["מרסיי", "צרפת", 43.3081, 5.3697],
  ["ברצלונה", "ספרד", 41.3517, 2.1698],
  ["ולנסיה", "ספרד", 39.4553, -0.3236],
  ["אלחסיראס", "ספרד", 36.1408, -5.4526],
  ["ג'נובה", "איטליה", 44.4056, 8.9463],
  ["טריאסטה", "איטליה", 45.6495, 13.7768],
  ["קופר", "סלובניה", 45.5481, 13.7302],
  ["פיראוס", "יוון", 37.9475, 23.6367],
  ["קונסטנצה", "רומניה", 44.1733, 28.6383],
  ["גדנסק", "פולין", 54.3520, 18.6466],
  ["גדיניה", "פולין", 54.5189, 18.5305],
  ["סנט פטרסבורג", "רוסיה", 59.9311, 30.3609],
  ["מומבאי (נאווה שווה)", "הודו", 18.9490, 72.9525],
  ["קולומבו", "סרי לנקה", 6.9271, 79.8612],
  ["סינגפור", "סינגפור", 1.2644, 103.8200],
  ["שנגחאי", "סין", 31.2304, 121.4737],
  ["הונג קונג", "הונג קונג", 22.2988, 114.1719],
  ["בוסאן", "דרום קוריאה", 35.1028, 129.0403],
  ["יוקוהמה", "יפן", 35.4437, 139.6380],
  ["ניו יורק/ניו ג'רזי", "ארה\"ב", 40.6700, -74.0700],
  ["לוס אנג'לס", "ארה\"ב", 33.7395, -118.2610],
  ["מיאמי", "ארה\"ב", 25.7742, -80.1725],
  ["יוסטון", "ארה\"ב", 29.7300, -95.0100],
  ["סנטוס", "ברזיל", -23.9608, -46.3336],
  ["קרטחנה", "קולומביה", 10.3910, -75.4794],
  ["פנמה סיטי (בלבואה)", "פנמה", 8.9500, -79.5667],
  ["מלבורן", "אוסטרליה", -37.8300, 144.9200],
  ["סידני (בוטני ביי)", "אוסטרליה", -33.9700, 151.2200],
];

List<Map<String, dynamic>> nearbyPorts(
  double lat,
  double lng, {
  int limit = 12,
}) {
  final here = LatLng(lat, lng);
  final dist = const Distance();
  final results = <Map<String, dynamic>>[];
  for (final port in majorPorts) {
    final pLat = port[2] as double;
    final pLng = port[3] as double;
    final km = dist.as(LengthUnit.Kilometer, here, LatLng(pLat, pLng));
    results.add({
      "name": port[0] as String,
      "country": port[1] as String,
      "lat": pLat,
      "lng": pLng,
      "dist": km.round(),
    });
  }
  results.sort((a, b) => (a["dist"] as int).compareTo(b["dist"] as int));
  return results.take(limit).toList();
}

String? nearestPortLabel(double lat, double lng) {
  final ports = nearbyPorts(lat, lng, limit: 3);
  if (ports.isEmpty) return null;
  return ports
      .map((p) => "🚢 ${p["dist"]} ק\"מ מנמל ${p["name"]} (${p["country"]})")
      .join("\n");
}

class PortsNearbyPage extends StatelessWidget {
  final double lat;
  final double lng;
  const PortsNearbyPage({super.key, required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    final ports = nearbyPorts(lat, lng, limit: 12);
    return Scaffold(
      backgroundColor: const Color(0xff0a0f16),
      appBar: AppBar(
        backgroundColor: const Color(0xff102a43),
        title: const Text(
          "📍 מיקום הלקוח ונמלים באזור",
          style: TextStyle(fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 260,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(lat, lng),
                initialZoom: 6,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: "com.example.expresphone_chat",
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(lat, lng),
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 36,
                      ),
                    ),
                    for (final p in ports)
                      Marker(
                        point: LatLng(p["lat"] as double, p["lng"] as double),
                        width: 26,
                        height: 26,
                        child: const Icon(
                          Icons.anchor,
                          color: Color(0xff25d366),
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                "🚢 נמלים לפי מרחק מהלקוח",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
              itemCount: ports.length,
              itemBuilder: (context, i) {
                final p = ports[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff0d1825),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p["name"] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              p["country"] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${p["dist"]} ק\"מ",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff25d366),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(
                                "https://www.google.com/maps/dir/?api=1&origin=$lat,$lng&destination=${p["lat"]},${p["lng"]}",
                              );
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                            icon: const Icon(Icons.navigation, size: 14),
                            label: const Text(
                              "Google",
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff25d366),
                              foregroundColor: const Color(0xff06130d),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: const Size(0, 0),
                            ),
                          ),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(
                                "https://maps.apple.com/?saddr=$lat,$lng&daddr=${p["lat"]},${p["lng"]}",
                              );
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                            icon: const Icon(Icons.navigation, size: 14),
                            label: const Text(
                              "Apple",
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              minimumSize: const Size(0, 0),
                            ),
                          ),
                        ],
                      ),
                    ],
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

Color avatarFallbackColor(String seed) {
  const colors = [
    Color(0xff34c759),
    Color(0xff0a84ff),
    Color(0xffaf52de),
    Color(0xffff9f0a),
    Color(0xffff453a),
    Color(0xff30d5c8),
    Color(0xffffcc00),
    Color(0xff64d2ff),
    Color(0xffbf5af2),
    Color(0xff32d74b),
  ];
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return colors[hash % colors.length];
}

final AudioPlayer _incomingAlertPlayer = AudioPlayer();
final ValueNotifier<bool> appLightMode = ValueNotifier<bool>(false);
bool _firebaseReady = false;

final LocalAuthentication _localAuth = LocalAuthentication();

// מזהה בפועל אילו סוגי ביומטריה זמינים במכשיר, ושומר את זה כדי ש-
// biometricName/biometricLoginIcon יציגו את השם הנכון (Face ID לעומת
// Touch ID/טביעת אצבע) - לא כל מכשיר iOS הוא בהכרח Face ID (לדוגמה iPad
// עם Touch ID).
List<BiometricType> _detectedBiometricTypes = [];

Future<bool> canUseFaceUnlock() async {
  try {
    final supported = await _localAuth.isDeviceSupported();
    final canCheck = await _localAuth.canCheckBiometrics;
    if (!supported || !canCheck) return false;
    final types = await _localAuth.getAvailableBiometrics();
    _detectedBiometricTypes = types;
    return types.contains(BiometricType.face) || types.isNotEmpty;
  } catch (_) {
    return false;
  }
}

class InlineVideoPlayer extends StatefulWidget {
  const InlineVideoPlayer({super.key, required this.url});

  final String url;

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant InlineVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller?.dispose();
      _controller = null;
      _error = null;
      _init();
    }
  }

  Future<void> _init() async {
    try {
      final uri = Uri.parse(widget.url);
      final controller = VideoPlayerController.networkUrl(uri);
      await controller.initialize();
      controller.setLooping(false);
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) {
        setState(() => _error = "לא ניתן לנגן וידאו בתוך הצ׳אט");
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_error != null) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xff101b2a),
        ),
        child: Center(
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xff101b2a),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio == 0
            ? 16 / 9
            : controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    controller.value.isPlaying
                        ? controller.pause()
                        : controller.play();
                  });
                },
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: controller.value.isPlaying ? 0.0 : 1.0,
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xff00d4ff).withValues(alpha: 0.86),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 40,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> askFaceUnlock() async {
  try {
    return await _localAuth.authenticate(
      localizedReason: "הזדהה כדי להיכנס ל-cozycrafts",
      biometricOnly: true,
    );
  } catch (_) {
    return false;
  }
}

bool get _isIosDevice => !kIsWeb && Platform.isIOS;
String get biometricName {
  if (_detectedBiometricTypes.contains(BiometricType.face)) return "Face ID";
  if (_detectedBiometricTypes.contains(BiometricType.fingerprint)) {
    return _isIosDevice ? "Touch ID" : "טביעת אצבע";
  }
  if (_detectedBiometricTypes.isNotEmpty) {
    return _isIosDevice ? "Face ID" : "טביעת אצבע";
  }
  return _isIosDevice ? "Face ID" : "טביעת אצבע";
}

IconData get biometricLoginIcon {
  if (_detectedBiometricTypes.contains(BiometricType.face)) return Icons.face;
  if (_detectedBiometricTypes.contains(BiometricType.fingerprint)) {
    return Icons.fingerprint;
  }
  return _isIosDevice ? Icons.face : Icons.fingerprint;
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

Future<void> _playIncomingAlertSound() async {
  try {
    await _incomingAlertPlayer.stop();
    await _incomingAlertPlayer.play(
      AssetSource("sounds/notify_chime.wav"),
      volume: 1,
    );
  } catch (_) {
    try {
      await _incomingAlertPlayer.play(
        UrlSource("https://arnonidan.pythonanywhere.com/static/glass.mp3"),
        volume: 1,
      );
    } catch (_) {
      SystemSound.play(SystemSoundType.alert);
    }
  }
}

void playIncomingAlert() {
  SystemSound.play(SystemSoundType.alert);
  HapticFeedback.heavyImpact();
  unawaited(_playIncomingAlertSound());
}

Future<void> setupPushNotifications({String? userName}) async {
  try {
    if (!_firebaseReady) {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      _firebaseReady = true;
    }

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await messaging.getToken();
    if (token != null && token.trim().isNotEmpty) {
      await registerPushToken(token, userName: userName);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      unawaited(registerPushToken(newToken, userName: userName));
    });

    FirebaseMessaging.onMessage.listen((message) {
      playIncomingAlert();
    });
  } catch (e) {
    debugPrint("Push setup skipped: $e");
  }
}

Future<void> registerPushToken(String token, {String? userName}) async {
  try {
    await http
        .post(
          Uri.parse("$api/api/register_push_token"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "token": token,
            "platform": Platform.isIOS
                ? "ios"
                : Platform.isAndroid
                ? "android"
                : "other",
            "user": userName ?? "",
            "pin": userPin(userName ?? ""),
          }),
        )
        .timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint("Push token register failed: $e");
  }
}

class AfricaCountryPosition {
  const AfricaCountryPosition(
    this.code,
    this.name,
    this.x,
    this.y, {
    double? labelX,
    double? labelY,
  }) : labelX = labelX ?? x,
       labelY = labelY ?? y;

  final String code;
  final String name;
  final double x;
  final double y;
  final double labelX;
  final double labelY;
}

const List<AfricaCountryPosition> africaCountryPositions = [
  AfricaCountryPosition(
    "dominica",
    "Dominica",
    0.331,
    0.414,
    labelX: 0.250,
    labelY: 0.360,
  ),
  AfricaCountryPosition(
    "dominican_republic",
    "Dominican Republic",
    0.305,
    0.396,
    labelX: 0.350,
    labelY: 0.345,
  ),
  AfricaCountryPosition(
    "morocco",
    "Morocco",
    0.481,
    0.322,
    labelX: 0.455,
    labelY: 0.225,
  ),
  AfricaCountryPosition(
    "senegal",
    "Senegal",
    0.460,
    0.419,
    labelX: 0.385,
    labelY: 0.360,
  ),
  AfricaCountryPosition(
    "gambia",
    "Gambia",
    0.458,
    0.426,
    labelX: 0.365,
    labelY: 0.410,
  ),
  AfricaCountryPosition(
    "guinea_bissau",
    "Guinea-Bissau",
    0.458,
    0.433,
    labelX: 0.360,
    labelY: 0.465,
  ),
  AfricaCountryPosition(
    "guinea",
    "Guinea",
    0.470,
    0.442,
    labelX: 0.385,
    labelY: 0.520,
  ),
  AfricaCountryPosition(
    "sierra_leone",
    "Sierra Leone",
    0.467,
    0.453,
    labelX: 0.365,
    labelY: 0.575,
  ),
  AfricaCountryPosition(
    "liberia",
    "Liberia",
    0.474,
    0.464,
    labelX: 0.390,
    labelY: 0.635,
  ),
  AfricaCountryPosition(
    "ivory_coast",
    "Ivory Coast",
    0.485,
    0.458,
    labelX: 0.460,
    labelY: 0.690,
  ),
  AfricaCountryPosition(
    "ghana",
    "Ghana",
    0.497,
    0.456,
    labelX: 0.515,
    labelY: 0.345,
  ),
  AfricaCountryPosition(
    "togo",
    "Togo",
    0.503,
    0.452,
    labelX: 0.555,
    labelY: 0.390,
  ),
  AfricaCountryPosition(
    "benin",
    "Benin",
    0.506,
    0.448,
    labelX: 0.590,
    labelY: 0.440,
  ),
  AfricaCountryPosition(
    "nigeria",
    "Nigeria",
    0.524,
    0.449,
    labelX: 0.600,
    labelY: 0.320,
  ),
  AfricaCountryPosition(
    "cameroon",
    "Cameroon",
    0.534,
    0.468,
    labelX: 0.625,
    labelY: 0.500,
  ),
  AfricaCountryPosition(
    "central_african_republic",
    "Central African Republic",
    0.558,
    0.463,
    labelX: 0.675,
    labelY: 0.395,
  ),
  AfricaCountryPosition(
    "south_sudan",
    "South Sudan",
    0.587,
    0.459,
    labelX: 0.710,
    labelY: 0.455,
  ),
  AfricaCountryPosition(
    "dr_congo",
    "DR Congo",
    0.566,
    0.516,
    labelX: 0.695,
    labelY: 0.585,
  ),
  AfricaCountryPosition(
    "uganda",
    "Uganda",
    0.590,
    0.492,
    labelX: 0.730,
    labelY: 0.520,
  ),
  AfricaCountryPosition(
    "kenya",
    "Kenya",
    0.605,
    0.500,
    labelX: 0.760,
    labelY: 0.555,
  ),
  AfricaCountryPosition(
    "rwanda",
    "Rwanda",
    0.583,
    0.511,
    labelX: 0.720,
    labelY: 0.650,
  ),
  AfricaCountryPosition(
    "burundi",
    "Burundi",
    0.583,
    0.519,
    labelX: 0.720,
    labelY: 0.715,
  ),
  AfricaCountryPosition(
    "tanzania",
    "Tanzania",
    0.597,
    0.535,
    labelX: 0.750,
    labelY: 0.780,
  ),
  AfricaCountryPosition(
    "zambia",
    "Zambia",
    0.577,
    0.573,
    labelX: 0.515,
    labelY: 0.765,
  ),
  AfricaCountryPosition(
    "malawi",
    "Malawi",
    0.595,
    0.573,
    labelX: 0.650,
    labelY: 0.830,
  ),
  AfricaCountryPosition(
    "mozambique",
    "Mozambique",
    0.599,
    0.604,
    labelX: 0.705,
    labelY: 0.890,
  ),
  AfricaCountryPosition(
    "zimbabwe",
    "Zimbabwe",
    0.581,
    0.606,
    labelX: 0.570,
    labelY: 0.910,
  ),
  AfricaCountryPosition(
    "namibia",
    "Namibia",
    0.547,
    0.626,
    labelX: 0.490,
    labelY: 0.850,
  ),
  AfricaCountryPosition(
    "south_africa",
    "South Africa",
    0.567,
    0.667,
    labelX: 0.555,
    labelY: 0.975,
  ),
  AfricaCountryPosition(
    "lesotho",
    "Lesotho",
    0.578,
    0.664,
    labelX: 0.655,
    labelY: 0.975,
  ),
  AfricaCountryPosition(
    "mauritius",
    "Mauritius",
    0.660,
    0.612,
    labelX: 0.775,
    labelY: 0.900,
  ),
  AfricaCountryPosition(
    "sao_tome",
    "Sao Tome",
    0.518,
    0.499,
    labelX: 0.465,
    labelY: 0.745,
  ),
  AfricaCountryPosition(
    "turkey",
    "Turkey",
    0.597,
    0.283,
    labelX: 0.655,
    labelY: 0.225,
  ),
  AfricaCountryPosition(
    "india",
    "India",
    0.719,
    0.378,
    labelX: 0.735,
    labelY: 0.310,
  ),
  AfricaCountryPosition(
    "sri_lanka",
    "Sri Lanka",
    0.724,
    0.456,
    labelX: 0.735,
    labelY: 0.545,
  ),
  AfricaCountryPosition(
    "myanmar",
    "Myanmar",
    0.767,
    0.383,
    labelX: 0.830,
    labelY: 0.330,
  ),
  AfricaCountryPosition(
    "thailand",
    "Thailand",
    0.781,
    0.417,
    labelX: 0.855,
    labelY: 0.440,
  ),
  AfricaCountryPosition(
    "philippines",
    "Philippines",
    0.839,
    0.433,
    labelX: 0.905,
    labelY: 0.390,
  ),
  AfricaCountryPosition(
    "mongolia",
    "Mongolia",
    0.786,
    0.244,
    labelX: 0.840,
    labelY: 0.185,
  ),
  AfricaCountryPosition(
    "tonga",
    "Tonga",
    0.986,
    0.617,
    labelX: 0.925,
    labelY: 0.710,
  ),
  AfricaCountryPosition(
    "solomon_islands",
    "Solomon Islands",
    0.944,
    0.553,
    labelX: 0.895,
    labelY: 0.595,
  ),
  AfricaCountryPosition(
    "jamaica",
    "Jamaica",
    0.294,
    0.402,
    labelX: 0.220,
    labelY: 0.450,
  ),
  AfricaCountryPosition(
    "ethiopia",
    "Ethiopia",
    0.608,
    0.452,
    labelX: 0.780,
    labelY: 0.475,
  ),
  AfricaCountryPosition(
    "angola",
    "Angola",
    0.550,
    0.568,
    labelX: 0.460,
    labelY: 0.805,
  ),
];

// ===== Realtime (WebSocket) - אותו ערוץ Supabase שהאתר כבר מאזין לו =====
// כשמגיע אירוע (הודעה חדשה נשמרה בשרת), מגדילים את הטיק הזה. מסכים
// שמאזינים לו (כמו ChatPage) מרעננים מיד במקום לחכות לטיימר התקופתי
// הבא - זה מה שנותן את הסנכרון המהיר/הצליל הכמעט-מיידי, בדיוק כמו באתר.
final ValueNotifier<int> realtimeTick = ValueNotifier<int>(0);
const String _supabaseAnonKey =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0bHNxeWVvdmdvcmFkZ3d6Z3p1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1NjM1MzgsImV4cCI6MjA5ODEzOTUzOH0.G7MMTxnHFhemV2jHDxpJTZJVi134wsZKjUiW34PTjzg";
bool _realtimeStarted = false;
int _realtimeReconnectAttempt = 0;

void startRealtimeListener() {
  if (_realtimeStarted) return;
  _realtimeStarted = true;
  _connectRealtimeWebSocket();
}

void _connectRealtimeWebSocket() async {
  try {
    final uri = Uri.parse(
      "wss://ctlsqyeovgoradgwzgzu.supabase.co/realtime/v1/websocket"
      "?apikey=$_supabaseAnonKey&vsn=1.0.0",
    );
    final ws = await WebSocket.connect(
      uri.toString(),
    ).timeout(const Duration(seconds: 10));
    _realtimeReconnectAttempt = 0;

    var ref = 1;
    String nextRef() => "${ref++}";

    ws.add(
      jsonEncode({
        "topic": "realtime:public:realtime_events",
        "event": "phx_join",
        "payload": {
          "config": {
            "broadcast": {"self": false},
            "postgres_changes": [
              {
                "event": "INSERT",
                "schema": "public",
                "table": "realtime_events",
              },
            ],
          },
          "access_token": _supabaseAnonKey,
        },
        "ref": nextRef(),
      }),
    );

    Timer? heartbeat;
    heartbeat = Timer.periodic(const Duration(seconds: 25), (_) {
      try {
        ws.add(
          jsonEncode({
            "topic": "phoenix",
            "event": "heartbeat",
            "payload": {},
            "ref": nextRef(),
          }),
        );
      } catch (_) {}
    });

    ws.listen(
      (data) {
        try {
          final m = jsonDecode(data as String);
          final event = "${m["event"] ?? ""}";
          final payload = (m["payload"] as Map?) ?? {};
          final hasRecord =
              payload["record"] != null ||
              (payload["data"] is Map &&
                  (payload["data"] as Map)["record"] != null);
          if (event == "postgres_changes" || event == "INSERT" || hasRecord) {
            realtimeTick.value++;
          }
        } catch (_) {}
      },
      onError: (_) {
        heartbeat?.cancel();
        _scheduleRealtimeReconnect();
      },
      onDone: () {
        heartbeat?.cancel();
        _scheduleRealtimeReconnect();
      },
      cancelOnError: true,
    );
  } catch (_) {
    _scheduleRealtimeReconnect();
  }
}

void _scheduleRealtimeReconnect() {
  final delaySeconds = (1 << _realtimeReconnectAttempt).clamp(1, 30);
  _realtimeReconnectAttempt++;
  Timer(Duration(seconds: delaySeconds), _connectRealtimeWebSocket);
}

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      // תפיסת שגיאות מסגרת (Flutter framework) - בלי זה, שגיאה לא-תפוסה
      // בזמן בנייה ראשונית של המסך יכולה לגרום למסך ריק/שחור בלי שום
      // הודעה, בלי קריסה מפורשת - בדיוק התופעה שתוארה.
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint("FLUTTER ERROR CAUGHT: ${details.exceptionAsString()}");
      };

      // כברירת מחדל, אם ווידג'ט נכשל בבנייה, Flutter (במצב release) מציג
      // קופסה ריקה/אפורה בלי שום טקסט - בדיוק נראה כמו "מסך ריק" שקט.
      // כאן לפחות נראה משהו ברור, וננסה שהאפליקציה תמשיך לתפקד סביב זה.
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return Material(
          color: const Color(0xff071525),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "⚠️ שגיאה בטעינה\n${details.exceptionAsString()}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        );
      };

      startRealtimeListener();
      runApp(const ExpresphoneApp());
    },
    (error, stack) {
      // תפיסת שגיאות אסינכרוניות לא-תפוסות (מחוץ ל-build) שגם הן יכולות
      // להשאיר את האפליקציה במצב שקט/ריק בלי לקרוס בבירור.
      debugPrint("UNCAUGHT ASYNC ERROR: $error\n$stack");
    },
  );
}

// Build label shown at the bottom of the login screen.
// Codemagic passes the build number with --dart-define=APP_BUILD=...
const String kAppBuild = String.fromEnvironment('APP_BUILD', defaultValue: 'dev');
const String kAppVersionLabel = 'cozycrafts \u00b7 build ' + kAppBuild;

class ExpresphoneApp extends StatelessWidget {
  const ExpresphoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appLightMode,
      builder: (context, lightMode, _) => MaterialApp(
        title: "cozycrafts chat",
        debugShowCheckedModeBanner: false,
        themeMode: lightMode ? ThemeMode.light : ThemeMode.dark,
        theme: ThemeData(
          brightness: Brightness.light,
          useMaterial3: true,
          colorSchemeSeed: const Color(0xff00a884),
          scaffoldBackgroundColor: const Color(0xffeef2f7),
          fontFamily: '.SF Pro Display',
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          colorSchemeSeed: const Color(0xff00d4ff),
          scaffoldBackgroundColor: const Color(0xff040c18),
          fontFamily: '.SF Pro Display',
        ),
        home: const PinPage(),
      ),
    );
  }
}

// =========================================================
// סרטון פתיחה — מהחלל אל העיר, ובסוף "Cozycrafts"
// הקובץ: assets/intro.mp4 (צריך להופיע ב-pubspec.yaml תחת flutter: assets:)
// =========================================================
class IntroSplashPage extends StatefulWidget {
  const IntroSplashPage({super.key});

  @override
  State<IntroSplashPage> createState() => _IntroSplashPageState();
}

class _IntroSplashPageState extends State<IntroSplashPage> {
  VideoPlayerController? _ctrl;
  bool _done = false;
  Timer? _fallback;

  @override
  void initState() {
    super.initState();
    // אם משהו נתקע — לא משאירים את המשתמש במסך הפתיחה
    _fallback = Timer(const Duration(seconds: 10), _finish);
    _start();
  }

  Future<void> _start() async {
    try {
      final c = VideoPlayerController.asset("assets/intro.mp4");
      _ctrl = c;
      await c.initialize();
      await c.setVolume(0);
      c.addListener(() {
        final v = c.value;
        if (v.isInitialized &&
            v.duration > Duration.zero &&
            v.position >= v.duration - const Duration(milliseconds: 150)) {
          _finish();
        }
      });
      if (!mounted) return;
      setState(() {});
      await c.play();
    } catch (e) {
      debugPrint("INTRO VIDEO ERROR: $e");
      _finish();
    }
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    _fallback?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const PinPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _fallback?.cancel();
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _ctrl;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finish, // נגיעה במסך מדלגת על הפתיחה
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (c != null && c.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: c.value.size.width,
                  height: c.value.size.height,
                  child: VideoPlayer(c),
                ),
              ),
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "נגיעה לדילוג",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PinPage extends StatefulWidget {
  const PinPage({super.key});

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  final pin = TextEditingController();
  String error = "";
  List countries = [];
  bool loadingCountries = true;
  String selectedCountry = "all";
  String selectedUser = "יבואן 1";
  bool checkingLogin = false;
  bool biometricAvailable = false;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    loadCountries();
    refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => loadCountries(silent: true),
    );
    realtimeTick.addListener(_onListRealtimeTick);
    Future.delayed(
      const Duration(milliseconds: 400),
      () => _updateBiometricState(),
    );
  }

  void _onListRealtimeTick() {
    if (mounted) loadCountries(silent: true);
  }

  Future<void> _updateBiometricState() async {
    try {
      final canAuth = await canUseFaceUnlock();
      if (!canAuth || !mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final hasAny = accessUsers.any((u) => prefs.getBool("bio_$u") == true);
      if (hasAny && mounted) {
        setState(() => biometricAvailable = true);
        // נסה כניסה אוטומטית עם המשתמש הנוכחי אם מופעל
        if (prefs.getBool("bio_$selectedUser") == true) {
          tryBiometric();
        }
      }
    } catch (_) {}
  }

  Future<void> tryBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // בדוק אם המשתמש הנוכחי הפעיל ביומטרי
      if (prefs.getBool("bio_$selectedUser") != true) {
        if (mounted)
          setState(() => error = "$biometricName לא הופעל עבור $selectedUser");
        return;
      }
      final canAuth = await canUseFaceUnlock();
      if (!canAuth) {
        if (mounted)
          setState(() => error = "$biometricName לא זמין או לא מוגדר במכשיר");
        return;
      }
      final auth = await askFaceUnlock();
      if (auth && mounted) {
        final saved = await loadSavedPin(selectedUser);
        if (saved == null || saved.isEmpty) {
          if (mounted) {
            setState(
              () => error =
                  "הקוד לא שמור במכשיר. היכנס עם קוד, ובטל והפעל מחדש את $biometricName.",
            );
          }
          return;
        }
        // מוודא מול השרת שהקוד השמור עדיין תקף
        final check = await http
            .post(
              Uri.parse("$api/api/check_user"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({"user": selectedUser, "pin": saved}),
            )
            .timeout(const Duration(seconds: 8));
        final checkData = jsonDecode(check.body);
        if (checkData["ok"] != true) {
          await clearSavedPin(selectedUser);
          if (mounted) {
            setState(() => error = "הקוד השתנה. היכנס עם הקוד החדש.");
          }
          return;
        }
        _sessionPins[selectedUser] = saved;
        if (!mounted) return;
        unawaited(setupPushNotifications(userName: selectedUser));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardPage(
              initialCountry: selectedCountry,
              currentUser: selectedUser,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = "שגיאת ביומטרי: $e");
    }
  }

  Future<void> enter() async {
    if (checkingLogin) return;
    if (!accessUsers.contains(selectedUser) || pin.text.trim().isEmpty) {
      setState(() => error = "בחר משתמש והזן PIN");
      SystemSound.play(SystemSoundType.alert);
      return;
    }
    setState(() {
      checkingLogin = true;
      error = "";
    });
    try {
      final r = await http
          .post(
            Uri.parse("$api/api/check_user"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"user": selectedUser, "pin": pin.text.trim()}),
          )
          .timeout(const Duration(seconds: 8));
      final data = jsonDecode(r.body);
      if (data["ok"] != true) {
        setState(() => error = "${data["error"] ?? "כניסה נדחתה"}");
        SystemSound.play(SystemSoundType.alert);
        return;
      }
      _sessionPins[selectedUser] = pin.text.trim();
    } catch (_) {
      setState(() => error = "אין חיבור לשרת. נסה שוב.");
      SystemSound.play(SystemSoundType.alert);
      return;
    } finally {
      if (mounted) setState(() => checkingLogin = false);
    }
    if (!mounted) return;
    unawaited(setupPushNotifications(userName: selectedUser));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardPage(
          initialCountry: selectedCountry,
          currentUser: selectedUser,
        ),
      ),
    );
  }

  Future<void> loadCountries({bool silent = false}) async {
    if (!silent) {
      loadingCountries = true;
      if (mounted) setState(() {});
    }

    try {
      final r = await http.get(Uri.parse("$api/api/countries"));
      final data = jsonDecode(r.body);
      countries = data is List ? data : [];
    } catch (_) {
      countries = [];
    }

    loadingCountries = false;
    if (mounted) setState(() {});
  }

  void selectCountry(String code) {
    setState(() => selectedCountry = code);
    showSnack("נבחרה מדינה: ${countryTitle(code)}. הכנס PIN כדי להמשיך.");
  }

  void showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Map<String, dynamic> get countryByCode {
    return {
      for (final item in countries)
        if (item is Map && item["code"] != null) "${item["code"]}": item,
    };
  }

  String countryTitle(String code) {
    if (code == "all") return "כל המדינות";
    final data = countryByCode[code];
    final fallback =
        "${data?["name"] ?? africaCountryPositions.firstWhere((x) => x.code == code).name}";
    return _countryNameHebrew(code, fallback);
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    realtimeTick.removeListener(_onListRealtimeTick);
    pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapPanel = _AfricaMapPanel(
      countries: countryByCode,
      selectedCountry: selectedCountry,
      loading: loadingCountries,
      onSelectCountry: selectCountry,
      onAdminTap: () {
        setState(() {
          selectedUser = "admin";
          pin.clear();
          error = "";
        });
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xff071525),
      // build label - so we always know which version is installed
      bottomNavigationBar: const SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(top: 2, bottom: 4),
          child: Text(
            kAppVersionLabel,
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0x99ffffff), fontSize: 11),
          ),
        ),
      ),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              color: const Color(0xff071525),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // שם
                  const Expanded(
                    child: Text(
                      "COZYCRAFTS",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xff00d4ff),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // משתמש
                  Container(
                    height: 30,
                    width: 78,
                    decoration: BoxDecoration(
                      color: const Color(0xff0d1825),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedUser,
                        isExpanded: true,
                        dropdownColor: const Color(0xff0d1825),
                        iconEnabledColor: Colors.white54,
                        iconSize: 12,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        items: [
                          for (final user in [
                            if (selectedUser == "admin") "admin",
                            ...visibleAccessUsers,
                          ])
                            DropdownMenuItem(
                              value: user,
                              child: Text(accessUserLabel(user)),
                            ),
                        ],
                        onChanged: (user) {
                          if (user != null) {
                            setState(() {
                              selectedUser = user;
                              pin.clear();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  // PIN
                  SizedBox(
                    width: 58,
                    height: 30,
                    child: TextField(
                      controller: pin,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      maxLength: 4,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                      decoration: InputDecoration(
                        hintText: "PIN",
                        counterText: "",
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 7,
                          horizontal: 8,
                        ),
                        filled: true,
                        fillColor: const Color(0xff0d1825),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                            color: Color(0xff00d4ff),
                          ),
                        ),
                      ),
                      onSubmitted: (_) => unawaited(enter()),
                      onChanged: (v) {
                        if (v.length == 4) {
                          Future.delayed(
                            const Duration(milliseconds: 200),
                            () => unawaited(enter()),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 5),
                  if (biometricAvailable)
                    FutureBuilder<SharedPreferences>(
                      future: SharedPreferences.getInstance(),
                      builder: (ctx, snap) {
                        final enabled =
                            snap.data?.getBool("bio_$selectedUser") == true;
                        return GestureDetector(
                          onTap: tryBiometric,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xff0d1825),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: enabled
                                    ? const Color(0xff008069)
                                    : Colors.white54,
                              ),
                            ),
                            child: Icon(
                              biometricLoginIcon,
                              color: enabled
                                  ? const Color(0xff00d4a0)
                                  : Colors.white70,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(width: 5),
                ],
              ),
            ),
          ),
          if (error.isNotEmpty || checkingLogin)
            Container(
              width: double.infinity,
              color: error.isNotEmpty
                  ? const Color(0xff5c1a1a)
                  : const Color(0xff123a52),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (checkingLogin)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  if (checkingLogin) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      checkingLogin ? "מתחבר..." : error,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: mapPanel),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.pin,
    required this.selectedUser,
    required this.error,
    required this.onUserChanged,
    required this.onLogin,
    this.isLoading = false,
  });

  final TextEditingController pin;
  final String selectedUser;
  final String error;
  final ValueChanged<String?> onUserChanged;
  final VoidCallback onLogin;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "cozycrafts",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        );
        final pinBox = SizedBox(
          width: constraints.maxWidth < 420 ? 70 : 94,
          height: 30,
          child: TextField(
            controller: pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            decoration: InputDecoration(
              hintText: "PIN",
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 5),
              filled: true,
              fillColor: const Color(0xff07111e),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.70),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.70),
                ),
              ),
            ),
            onSubmitted: (_) => onLogin(),
          ),
        );
        final userBox = Container(
          width: constraints.maxWidth < 420 ? 86 : 116,
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xff07111e),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedUser,
              isExpanded: true,
              dropdownColor: const Color(0xff07111e),
              iconEnabledColor: Colors.white,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
              items: [
                for (final user in visibleAccessUsers)
                  DropdownMenuItem(
                    value: user,
                    child: Text(accessUserLabel(user)),
                  ),
              ],
              onChanged: onUserChanged,
            ),
          ),
        );
        final loginButton = SizedBox(
          height: 30,
          child: FilledButton(
            onPressed: isLoading ? null : onLogin,
            style: FilledButton.styleFrom(
              backgroundColor: appLightMode.value
                  ? const Color(0xff2a2f32)
                  : const Color(0xff00d4ff),
              overlayColor: appLightMode.value ? const Color(0xff008069) : null,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    "כניסה",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
          ),
        );

        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            userBox,
            const SizedBox(width: 6),
            pinBox,
            const SizedBox(width: 6),
            loginButton,
          ],
        );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // משתמש
            Container(
              height: 32,
              width: 80,
              decoration: BoxDecoration(
                color: const Color(0xff0d1825),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedUser,
                  isExpanded: true,
                  dropdownColor: const Color(0xff0d1825),
                  iconEnabledColor: Colors.white54,
                  iconSize: 12,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  underline: const SizedBox(),
                  items: [
                    for (final user in visibleAccessUsers)
                      DropdownMenuItem(
                        value: user,
                        child: Text(accessUserLabel(user)),
                      ),
                  ],
                  onChanged: onUserChanged,
                ),
              ),
            ),
            const SizedBox(width: 5),
            // PIN
            SizedBox(
              width: 60,
              height: 32,
              child: TextField(
                controller: pin,
                obscureText: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
                decoration: InputDecoration(
                  hintText: "PIN",
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 7,
                    horizontal: 8,
                  ),
                  filled: true,
                  fillColor: const Color(0xff0d1825),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xff00d4ff)),
                  ),
                ),
                onSubmitted: (_) => onLogin(),
              ),
            ),
            const SizedBox(width: 5),
            // כניסה
            GestureDetector(
              onTap: isLoading ? null : onLogin,
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xff2979ff),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: isLoading
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "כניסה",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AfricaMapPanel extends StatefulWidget {
  const _AfricaMapPanel({
    required this.countries,
    required this.selectedCountry,
    required this.loading,
    required this.onSelectCountry,
    required this.onAdminTap,
  });

  final Map<String, dynamic> countries;
  final String selectedCountry;
  final bool loading;
  final ValueChanged<String> onSelectCountry;
  final VoidCallback onAdminTap;

  @override
  State<_AfricaMapPanel> createState() => _AfricaMapPanelState();
}

class _AfricaMapPanelState extends State<_AfricaMapPanel> {
  final TransformationController mapTransform = TransformationController();
  Size? centeredForSize;

  @override
  void dispose() {
    mapTransform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 6),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final availableHeight = constraints.maxHeight;
              final phone = availableWidth < 620;
              // המפה תמלא את כל הגובה הזמין
              var mapHeight = phone ? availableHeight : availableWidth / 2;
              var mapWidth = mapHeight * 2;
              if (!phone && mapWidth > availableWidth) {
                mapWidth = availableWidth;
                mapHeight = mapWidth / 2;
              }

              final panelSize = Size(availableWidth, availableHeight);
              if (phone && centeredForSize != panelSize) {
                centeredForSize = panelSize;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  // zoom ראשוני שממלא את המסך
                  final scaleX = availableWidth / mapWidth;
                  final scaleY = availableHeight / mapHeight;
                  final scale = scaleX > scaleY ? scaleX : scaleY;
                  final focusX = mapWidth * 0.52;
                  final focusY = mapHeight * 0.50;
                  mapTransform.value = Matrix4.identity()
                    ..translateByDouble(
                      availableWidth / 2 - focusX * scale,
                      availableHeight / 2 - focusY * scale,
                      0,
                      1,
                    )
                    ..scaleByDouble(scale, scale, 1, 1);
                });
              }

              final mapTop = (availableHeight - mapHeight) / 2;
              final map = SizedBox(
                width: mapWidth,
                height: phone ? availableHeight : mapHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: phone ? mapTop : 0,
                      width: mapWidth,
                      height: mapHeight,
                      child: Image.asset(
                        "assets/world_map.png",
                        fit: BoxFit.contain,
                        color: const Color(0xff7a8090).withValues(alpha: 1.0),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                    Positioned(
                      top: phone ? mapTop : 0,
                      width: mapWidth,
                      height: mapHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (final country in africaCountryPositions)
                            _CountryMarker(
                              position: country,
                              data: widget.countries[country.code],
                              selected: widget.selectedCountry == country.code,
                              mapWidth: mapWidth,
                              mapHeight: mapHeight,
                              onTap: () => widget.onSelectCountry(country.code),
                            ),
                          // USA — כניסת ניהול סודית (אותו עיצוב פס אופקי כמו כל מדינה)
                          Positioned(
                            left: mapWidth * 0.06,
                            top: mapHeight * 0.22,
                            child: GestureDetector(
                              onTap: () {
                                widget.onAdminTap();
                              },
                              child: Container(
                                padding: EdgeInsets.fromLTRB(
                                  3,
                                  3,
                                  mapWidth < 300 ? 6 : 8,
                                  3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xf01a1f2e),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: const Color(
                                      0xff00d4ff,
                                    ).withValues(alpha: 0.35),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: mapWidth < 300 ? 20 : 26,
                                      height: mapWidth < 300 ? 20 : 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xff2d3348),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.35,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "🇺🇸",
                                          style: TextStyle(
                                            fontSize: mapWidth < 300 ? 12 : 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      "וושינגטון",
                                      style: TextStyle(
                                        fontSize: mapWidth < 300 ? 9 : 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );

              if (phone) {
                return ClipRect(
                  child: InteractiveViewer(
                    transformationController: mapTransform,
                    constrained: false,
                    minScale: 0.55,
                    maxScale: 5.0,
                    boundaryMargin: EdgeInsets.symmetric(
                      horizontal: mapWidth,
                      vertical: mapHeight,
                    ),
                    child: map,
                  ),
                );
              }

              final mapLeft = (availableWidth - mapWidth) / 2;
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: mapLeft,
                    top: mapTop,
                    width: mapWidth,
                    height: mapHeight,
                    child: map,
                  ),
                ],
              );
            },
          ),
          if (widget.loading)
            const Positioned(
              left: 10,
              top: 10,
              child: Text(
                "טוען מדינות...",
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }
}

class _CountryMarker extends StatelessWidget {
  const _CountryMarker({
    required this.position,
    required this.data,
    required this.selected,
    required this.mapWidth,
    required this.mapHeight,
    required this.onTap,
  });

  final AfricaCountryPosition position;
  final dynamic data;
  final bool selected;
  final double mapWidth;
  final double mapHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = int.tryParse("${data?["unread"] ?? 0}") ?? 0;
    final available = _availableCountForCountry(data);
    final hasUnread = unread > 0;
    final hasAvailable = available > 0;
    final statusColor = hasUnread
        ? const Color(0xffff4444)
        : hasAvailable
        ? const Color(0xff00e676)
        : Colors.blueGrey.shade400;
    final badgeText = hasUnread
        ? (unread > 99 ? "99" : "$unread")
        : (available > 99 ? "99" : "$available");
    final label = _countryNameHebrew(
      position.code,
      "${data?["name"] ?? position.name}",
    );
    final flag = "${data?["flag"] ?? _flagForCountry(position.code)}";
    final point = Offset(position.x * mapWidth, position.y * mapHeight);
    final compact = mapWidth < 300;
    // תגית גדולה יותר עם שם
    final tagWidth = compact ? 80.0 : 110.0;
    final tagHeight = compact ? 32.0 : 40.0;
    final tagLeft = (position.labelX * mapWidth - tagWidth / 2)
        .clamp(0.0, mapWidth > tagWidth ? mapWidth - tagWidth : 0.0)
        .toDouble();
    final tagTop = (position.labelY * mapHeight - tagHeight / 2)
        .clamp(0.0, mapHeight > tagHeight ? mapHeight - tagHeight : 0.0)
        .toDouble();
    // החוט יוצא מתחתית התגית לנקודה
    final leaderStart = Offset(tagLeft + tagWidth / 2, tagTop + tagHeight - 4);

    return Positioned.fill(
      child: Semantics(
        button: true,
        label:
            "$label, ${hasUnread ? "$unread הודעות שלא נקראו" : "$available זמינים"}",
        child: Stack(
          children: [
            // קו גלואו בצבע הסטטוס
            CustomPaint(
              foregroundPainter: _CountryLeaderPainter(
                from: leaderStart,
                to: point,
                color: statusColor,
              ),
              size: Size(mapWidth, mapHeight),
            ),
            // נקודה זוהרת
            Positioned(
              left: point.dx - 7,
              top: point.dy - 7,
              child: GestureDetector(
                onTap: onTap,
                child: _GlowDot(color: statusColor),
              ),
            ),
            // תגית עם שם מדינה
            Positioned(
              left: tagLeft,
              top: tagTop,
              child: GestureDetector(
                onTap: onTap,
                child: _CountryTag(
                  color: Colors.white,
                  badgeColor: statusColor,
                  badgeText: badgeText,
                  flag: flag,
                  label: label,
                  selected: selected,
                  compact: compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _availableCountForCountry(dynamic data) {
  if (data is! Map) return 0;
  const keys = [
    "available",
    "available_count",
    "online",
    "online_count",
    "active",
    "active_count",
  ];
  for (final key in keys) {
    final value = data[key];
    final parsed = int.tryParse("$value");
    if (parsed != null && parsed > 0) return parsed;
    if (value == true) return 1;
  }
  return data["token"] == true ? 1 : 0;
}

class _CountryLeaderPainter extends CustomPainter {
  const _CountryLeaderPainter({
    required this.from,
    required this.to,
    required this.color,
  });

  final Offset from;
  final Offset to;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final halo = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 7.0
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // קו מנוקד
    final dashLen = 5.0;
    final gapLen = 4.0;
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final dist = (Offset(dx, dy)).distance;
    final steps = dist / (dashLen + gapLen);
    final ux = dx / dist;
    final uy = dy / dist;
    canvas.drawLine(from, to, halo);
    canvas.drawLine(from, to, glow);
    for (int i = 0; i < steps; i++) {
      final s = Offset(
        from.dx + ux * i * (dashLen + gapLen),
        from.dy + uy * i * (dashLen + gapLen),
      );
      final e = Offset(s.dx + ux * dashLen, s.dy + uy * dashLen);
      canvas.drawLine(s, e, line);
    }
  }

  @override
  bool shouldRepaint(covariant _CountryLeaderPainter oldDelegate) {
    return from != oldDelegate.from ||
        to != oldDelegate.to ||
        color != oldDelegate.color;
  }
}

class _GlowDot extends StatelessWidget {
  const _GlowDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.80),
            blurRadius: 12,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.40),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.9), blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryTag extends StatelessWidget {
  const _CountryTag({
    required this.color,
    required this.badgeColor,
    required this.badgeText,
    required this.flag,
    required this.label,
    required this.selected,
    required this.compact,
  });

  final Color color;
  final Color badgeColor;
  final String badgeText;
  final String flag;
  final String label;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final flagCircleSize = compact ? 20.0 : 26.0;
    final flagFontSize = compact ? 12.0 : 15.0;
    final nameSize = compact ? 9.0 : 11.0;
    final badgeSize = compact ? 16.0 : 20.0;
    final badgeFont = compact ? 8.0 : 10.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // גוף התגית — pill עגול כמו באתר
        Container(
          padding: EdgeInsets.fromLTRB(3, 3, compact ? 6 : 8, 3),
          decoration: BoxDecoration(
            color: const Color(0xf01a1f2e),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: selected
                  ? Colors.white
                  : const Color(0xff00d4ff).withValues(alpha: 0.35),
              width: selected ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // דגל עגול
              Container(
                width: flagCircleSize,
                height: flagCircleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff2d3348),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(flag, style: TextStyle(fontSize: flagFontSize)),
                ),
              ),
              const SizedBox(width: 5),
              // שם מדינה
              Text(
                label,
                style: TextStyle(
                  fontSize: nameSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 5),
              // badge מספר
              Container(
                constraints: BoxConstraints(minWidth: badgeSize),
                height: badgeSize,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: badgeColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: badgeFont,
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        // שפיץ תחתון
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xf01a1f2e),
            border: Border(
              right: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          transform: Matrix4.rotationZ(0.785398),
          transformAlignment: Alignment.center,
        ),
      ],
    );
  }
}

String _flagForCountry(String code) {
  switch (code) {
    case "algeria":
      return "🇩🇿";
    case "angola":
      return "🇦🇴";
    case "benin":
      return "🇧🇯";
    case "botswana":
      return "🇧🇼";
    case "burkina_faso":
      return "🇧🇫";
    case "burundi":
      return "🇧🇮";
    case "cameroon":
      return "🇨🇲";
    case "cape_verde":
      return "🇨🇻";
    case "central_african_republic":
      return "🇨🇫";
    case "chad":
      return "🇹🇩";
    case "comoros":
      return "🇰🇲";
    case "congo":
      return "🇨🇬";
    case "dr_congo":
      return "🇨🇩";
    case "dominica":
      return "🇩🇲";
    case "dominican_republic":
      return "🇩🇴";
    case "djibouti":
      return "🇩🇯";
    case "egypt":
      return "🇪🇬";
    case "equatorial_guinea":
      return "🇬🇶";
    case "eritrea":
      return "🇪🇷";
    case "eswatini":
      return "🇸🇿";
    case "ethiopia":
      return "🇪🇹";
    case "jamaica":
      return "🇯🇲";
    case "pending":
      return "⏳";
    case "gabon":
      return "🇬🇦";
    case "gambia":
      return "🇬🇲";
    case "ghana":
      return "🇬🇭";
    case "guinea":
      return "🇬🇳";
    case "guinea_bissau":
      return "🇬🇼";
    case "ivory_coast":
      return "🇨🇮";
    case "india":
      return "🇮🇳";
    case "kenya":
      return "🇰🇪";
    case "lesotho":
      return "🇱🇸";
    case "liberia":
      return "🇱🇷";
    case "libya":
      return "🇱🇾";
    case "madagascar":
      return "🇲🇬";
    case "malawi":
      return "🇲🇼";
    case "mali":
      return "🇲🇱";
    case "mauritania":
      return "🇲🇷";
    case "mauritius":
      return "🇲🇺";
    case "mongolia":
      return "🇲🇳";
    case "morocco":
      return "🇲🇦";
    case "mozambique":
      return "🇲🇿";
    case "namibia":
      return "🇳🇦";
    case "niger":
      return "🇳🇪";
    case "nigeria":
      return "🇳🇬";
    case "myanmar":
      return "🇲🇲";
    case "philippines":
      return "🇵🇭";
    case "rwanda":
      return "🇷🇼";
    case "sao_tome":
      return "🇸🇹";
    case "senegal":
      return "🇸🇳";
    case "seychelles":
      return "🇸🇨";
    case "sierra_leone":
      return "🇸🇱";
    case "somalia":
      return "🇸🇴";
    case "south_africa":
      return "🇿🇦";
    case "south_sudan":
      return "🇸🇸";
    case "solomon_islands":
      return "🇸🇧";
    case "sri_lanka":
      return "🇱🇰";
    case "sudan":
      return "🇸🇩";
    case "tanzania":
      return "🇹🇿";
    case "thailand":
      return "🇹🇭";
    case "togo":
      return "🇹🇬";
    case "tonga":
      return "🇹🇴";
    case "tunisia":
      return "🇹🇳";
    case "turkey":
      return "🇹🇷";
    case "uganda":
      return "🇺🇬";
    case "western_sahara":
      return "🇪🇭";
    case "zambia":
      return "🇿🇲";
    case "zimbabwe":
      return "🇿🇼";
    default:
      return "🏳️";
  }
}

String _countryNameHebrew(String code, [String fallback = ""]) {
  final clean = code
      .toLowerCase()
      .trim()
      .replaceAll("-", "_")
      .replaceAll(" ", "_");
  const names = {
    "all": "הכל",
    "usa": "ארצות הברית",
    "israel": "ישראל",
    "uganda": "אוגנדה",
    "zambia": "זמביה",
    "india": "הודו",
    "burundi": "בורונדי",
    "tonga": "טונגה",
    "liberia": "ליבריה",
    "gambia": "גמביה",
    "nigeria": "ניגריה",
    "sierra_leone": "סיירה לאון",
    "sri_lanka": "סרי לנקה",
    "cameroon": "קמרון",
    "kenya": "קניה",
    "malawi": "מלאווי",
    "myanmar": "מיאנמר",
    "rwanda": "רואנדה",
    "turkey": "טורקיה",
    "ghana": "גאנה",
    "thailand": "תאילנד",
    "sao_tome": "סאו טומה ופרינסיפה",
    "mongolia": "מונגוליה",
    "dominica": "דומיניקה",
    "dominican_republic": "הרפובליקה הדומיניקנית",
    "ivory_coast": "חוף השנהב",
    "tanzania": "טנזניה",
    "central_african_republic": "הרפובליקה המרכז-אפריקאית",
    "philippines": "הפיליפינים",
    "south_africa": "דרום אפריקה",
    "morocco": "מרוקו",
    "mauritius": "מאוריציוס",
    "guinea": "גינאה",
    "lesotho": "לסוטו",
    "guinea_bissau": "גינאה ביסאו",
    "zimbabwe": "זימבבואה",
    "benin": "בנין",
    "south_sudan": "דרום סודן",
    "togo": "טוגו",
    "namibia": "נמיביה",
    "senegal": "סנגל",
    "mozambique": "מוזמביק",
    "solomon_islands": "איי שלמה",
    "dr_congo": "קונגו הדמוקרטית",
    "jamaica": "ג׳מייקה",
    "ethiopia": "אתיופיה",
    "angola": "אנגולה",
    "pending": "ממתינים לבחירת מדינה",
  };
  final value = names[clean];
  if (value != null) return value;
  return fallback.trim().isNotEmpty ? fallback : code;
}

class SavedLocationsPage extends StatefulWidget {
  const SavedLocationsPage({super.key, required this.currentUser});
  final String currentUser;

  @override
  State<SavedLocationsPage> createState() => _SavedLocationsPageState();
}

class _SavedLocationsPageState extends State<SavedLocationsPage> {
  bool loading = true;
  String error = "";
  List locations = [];
  bool showList = false;
  final MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = "";
    });
    try {
      final r = await http
          .post(
            Uri.parse("$api/api/locations"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "user": widget.currentUser,
              "pin": userPin(widget.currentUser),
            }),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(r.body);
      if (data["ok"] == true) {
        setState(() {
          locations = data["locations"] ?? [];
          loading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => fitAllMarkers());
      } else {
        setState(() {
          error = "${data["error"] ?? "שגיאה בטעינת מיקומים"}";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "שגיאת חיבור לשרת";
        loading = false;
      });
    }
  }

  List<LatLng> get points => locations
      .map<LatLng?>((loc) {
        final lat = loc["lat"];
        final lng = loc["lng"];
        if (lat == null || lng == null) return null;
        return LatLng((lat as num).toDouble(), (lng as num).toDouble());
      })
      .whereType<LatLng>()
      .toList();

  void fitAllMarkers() {
    final pts = points;
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      mapController.move(pts.first, 6);
      return;
    }
    final bounds = LatLngBounds.fromPoints(pts);
    mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
    );
  }

  Future<void> openInMaps(dynamic loc) async {
    final lat = loc["lat"];
    final lng = loc["lng"];
    final uri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("לא הצלחתי לפתוח את המפה")));
    }
  }

  void showLocationSheet(dynamic loc) {
    final lightMode = appLightMode.value;
    showModalBottomSheet(
      context: context,
      backgroundColor: lightMode ? Colors.white : const Color(0xff0f1e30),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(loc["flag"] ?? "🌍", style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${loc["name"] ?? ""}",
                        style: TextStyle(
                          color: lightMode
                              ? const Color(0xff2a2f32)
                              : Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${loc["country_name"] ?? ""}  •  ${loc["created_at"] ?? ""}",
                        style: TextStyle(
                          color: lightMode
                              ? const Color(0xff667781)
                              : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff25d366),
                foregroundColor: const Color(0xff06130d),
              ),
              onPressed: () {
                Navigator.pop(context);
                final lat = double.tryParse("${loc["lat"] ?? ""}") ?? 0;
                final lng = double.tryParse("${loc["lng"] ?? ""}") ?? 0;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PortsNearbyPage(lat: lat, lng: lng),
                  ),
                );
              },
              icon: const Icon(Icons.anchor),
              label: const Text("🚢 נמלים באזור וניווט"),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: lightMode ? const Color(0xff2a2f32) : null,
              ),
              onPressed: () {
                Navigator.pop(context);
                openInMaps(loc);
              },
              icon: const Icon(Icons.map),
              label: const Text("פתח ב-Google Maps"),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                final lat = loc["lat"];
                final lng = loc["lng"];
                final uri = Uri.parse(
                  "https://maps.apple.com/?daddr=$lat,$lng",
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.map_outlined),
              label: const Text("פתח ב-Apple Maps"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lightMode = appLightMode.value;
    return Scaffold(
      backgroundColor: lightMode
          ? const Color(0xffeef2f7)
          : const Color(0xff050d1a),
      appBar: AppBar(
        backgroundColor: lightMode ? Colors.white : const Color(0xff040e1c),
        foregroundColor: lightMode ? const Color(0xff2a2f32) : Colors.white,
        title: const Text("🗺️ מיקומי לקוחות"),
        actions: [
          IconButton(
            tooltip: showList ? "הצג מפה" : "הצג רשימה",
            onPressed: () => setState(() => showList = !showList),
            icon: Icon(showList ? Icons.map : Icons.list),
          ),
          IconButton(onPressed: load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      error,
                      style: TextStyle(
                        color: lightMode
                            ? const Color(0xff667781)
                            : Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: load,
                      child: const Text("נסה שוב"),
                    ),
                  ],
                ),
              ),
            )
          : locations.isEmpty
          ? Center(
              child: Text(
                "עדיין לא התקבלו מיקומים מלקוחות",
                style: TextStyle(
                  color: lightMode ? const Color(0xff667781) : Colors.white54,
                ),
              ),
            )
          : showList
          ? ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: locations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final loc = locations[i];
                return Container(
                  decoration: BoxDecoration(
                    color: lightMode
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: lightMode
                          ? const Color(0xffd1d7db)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: ListTile(
                    leading: Text(
                      loc["flag"] ?? "🌍",
                      style: const TextStyle(fontSize: 26),
                    ),
                    title: Text(
                      "${loc["name"] ?? ""}",
                      style: TextStyle(
                        color: lightMode
                            ? const Color(0xff2a2f32)
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "${loc["country_name"] ?? ""}  •  ${loc["created_at"] ?? ""}",
                      style: TextStyle(
                        color: lightMode
                            ? const Color(0xff667781)
                            : Colors.white60,
                      ),
                    ),
                    trailing: Icon(
                      Icons.map,
                      color: lightMode
                          ? const Color(0xff2a2f32)
                          : const Color(0xff00d4ff),
                    ),
                    onTap: () => showLocationSheet(loc),
                  ),
                );
              },
            )
          : FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: points.isNotEmpty
                    ? points.first
                    : const LatLng(10, 20),
                initialZoom: 2.5,
                minZoom: 1.5,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: "com.example.expresphone_chat",
                ),
                MarkerLayer(
                  markers: [
                    for (final loc in locations)
                      if (loc["lat"] != null && loc["lng"] != null)
                        Marker(
                          point: LatLng(
                            (loc["lat"] as num).toDouble(),
                            (loc["lng"] as num).toDouble(),
                          ),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => showLocationSheet(loc),
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xffff3b3b),
                              size: 36,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 4),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _VoiceResult {
  final String text;
  final int failed;
  const _VoiceResult(this.text, this.failed);
}

/// A transcription that must stop (expired job, server error): shown to the user as is.
class _VoiceStop implements Exception {
  final String message;
  const _VoiceStop(this.message);
}

// ===== Cozy AI =====
const String cozyAiApi = "https://ai.expresphone.com/api/ai";
const String cozyAiVoiceApi =
    "https://ai.expresphone.com/api/voice/transcribe-client";
const String cozyAiVoiceJobsApi = "https://ai.expresphone.com/api/voice/jobs";

class CozyAiPage extends StatefulWidget {
  const CozyAiPage({super.key, this.currentUser = ""});
  final String currentUser;

  @override
  State<CozyAiPage> createState() => _CozyAiPageState();
}

class _CozyAiPageState extends State<CozyAiPage> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  // מה ה-AI יודע לעשות: מוצג בתחילת כל שיחה
  static const String _capabilities =
      "💬 לענות על שאלות ולהסביר מה לעשות\n"
      "🖼️ לנתח תמונה של תקלה או של הודעת שגיאה\n"
      "🎙️ להקליט הודעה או לתמלל קובץ שמע — עד 20 דקות, תמיד בעברית (גם משפה אחרת)\n"
      "🎥 וידאו: תמלול בלבד, או תמלול + הסבר של מה שרואים — עד 20 דקות ו-60 מגה\n"
      "🗣️ לדבר בעברית ולקבל קובץ שמע בשפה אחרת (אנגלית, רוסית, ערבית ועוד)\n"
      "📧 לשלוח תשובה במייל או בוואטסאפ (כפתור מתחת לתשובה, או לכתוב \"שלח לי במייל\")\n"
      "📄 לערוך PDF: החלפת טקסט וטיוטה לשיתוף\n"
      "🕘 לשמור את השיחות שלך ולחזור אליהן\n\n"
      "לחץ על 📎 כדי להוסיף תמונה, וידאו, הקלטה, קובץ קול או PDF.";
  final List<Map<String, String>> _messages = [
    {
      "role": "assistant",
      "text": "שלום 👋 אני Cozy AI. זה מה שאני יודע לעשות:\n\n$_capabilities",
    },
  ];

  bool _busy = false;
  int _generation = 0;
  int _pickGeneration = 0;
  bool _picking = false;
  String? _pendingImage;
  // וידאו מצורף: התמלול ופרטי הסרטון, נשלחים למודל יחד עם לוח התמונות (_pendingImage)
  String? _pendingVideoNote;
  // התמלול של הווידאו: מוצג למשתמש בראש התשובה
  String? _pendingVideoTranscript;
  // דבר בעברית -> קול בשפה אחרת: הטקסט בעברית שמחכה לבחירת שפה
  String? _pendingSpeakText;
  final AudioPlayer _speakPlayer = AudioPlayer();
  StreamSubscription<void>? _speakDone;
  String? _playingPath;
  String _mode = "auto";
  http.Client? _client;

  // ---- שיחות שמורות בשרת Cozy (לפי המשתמש המחובר, משותף לאתר ולאפליקציה) ----
  static const String _greeting =
      "שיחה חדשה 👋 זה מה שאני יודע לעשות:\n\n$_capabilities";
  int? _conversationId;
  Future<void> _saveQueue = Future.value();
  // הקשר השיחה (בלי הודעת הפתיחה) - נשלח למודל עם כל שאלה
  final List<Map<String, String>> _ctx = [];

  Map<String, String> _historyHeaders() => {
    "Content-Type": "application/json",
    // שם המשתמש בעברית ("יבואן 1") נשלח ב-base64 כדי שלא ישתבש בכותרת HTTP
    "X-App-User-B64": base64Encode(utf8.encode(widget.currentUser)),
    "X-App-Pin": userPin(widget.currentUser),
    // שאר הקריאות לשרת שולחות את השם רגיל; שם באנגלית (admin) נשלח גם כך
    if (RegExp(r'^[\x20-\x7E]+$').hasMatch(widget.currentUser))
      "X-App-User": widget.currentUser,
  };

  Future<Map<String, dynamic>> _historyCall(
    String method,
    String path, {
    Object? body,
  }) async {
    final headers = _historyHeaders();
    final payload = body == null ? null : jsonEncode(body);
    // שרת ה-AI הוא ai.expresphone.com; שרת האפליקציה הראשי כגיבוי
    final aiBase = cozyAiApi.replaceFirst(RegExp(r'/api/ai/?$'), '');
    final bases = <String>[aiBase, api];
    final errors = <String>[];
    for (final base in bases) {
      try {
        final uri = Uri.parse("$base$path");
        late http.Response r;
        if (method == "POST") {
          r = await http
              .post(uri, headers: headers, body: payload)
              .timeout(const Duration(seconds: 20));
        } else if (method == "DELETE") {
          r = await http
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 20));
        } else {
          r = await http
              .get(uri, headers: headers)
              .timeout(const Duration(seconds: 20));
        }
        final data = jsonDecode(utf8.decode(r.bodyBytes));
        if (r.statusCode < 200 ||
            r.statusCode >= 300 ||
            data is! Map ||
            data["ok"] == false) {
          final msg = data is Map ? "${data["error"] ?? "error"}" : "error";
          throw Exception("${Uri.parse(base).host} ${r.statusCode}: $msg");
        }
        return Map<String, dynamic>.from(data);
      } catch (e) {
        errors.add("${e.toString().replaceFirst("Exception: ", "")}");
      }
    }
    throw Exception(errors.join("\n"));
  }

  Future<int?> _ensureConversation() async {
    if (_conversationId != null) return _conversationId;
    if (widget.currentUser.isEmpty) return null;
    try {
      final data = await _historyCall(
        "POST",
        "/api/ai/conversations",
        body: {"model": _mode},
      );
      final id = data["id"];
      if (id is num) _conversationId = id.toInt();
    } catch (_) {}
    return _conversationId;
  }

  void _saveMessage(String role, String content, {bool hasImage = false}) {
    final id = _conversationId;
    if (id == null || content.trim().isEmpty) return;
    _saveQueue = _saveQueue.then((_) async {
      try {
        await _historyCall(
          "POST",
          "/api/ai/conversations/$id/messages",
          body: {
            "role": role,
            "content": content,
            "has_image": hasImage ? 1 : 0,
          },
        );
      } catch (_) {}
    });
  }

  Future<List<Map<String, dynamic>>> _loadConversations() async {
    final data = await _historyCall("GET", "/api/ai/conversations");
    final list = data["conversations"];
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  void _newConversation() {
    _stop();
    _pickGeneration++;
    setState(() {
      _conversationId = null;
      _ctx.clear();
      _saveQueue = Future.value();
      _pendingImage = null;
      _pendingVideoNote = null;
        _pendingVideoTranscript = null;
      _pendingSpeakText = null;
      _picking = false;
      _messages
        ..clear()
        ..add({"role": "assistant", "text": _greeting});
    });
  }

  Future<void> _openConversation(int id) async {
    _stop();
    _pickGeneration++;
    try {
      final data = await _historyCall("GET", "/api/ai/conversations/$id");
      final msgs = data["messages"];
      if (!mounted) return;
      setState(() {
        _conversationId = id;
        _saveQueue = Future.value();
        _ctx.clear();
        _pendingImage = null;
        _pendingVideoNote = null;
        _pendingVideoTranscript = null;
        _pendingSpeakText = null;
        _picking = false;
        _messages.clear();
        if (msgs is List) {
          for (final m in msgs) {
            if (m is! Map) continue;
            final role = "${m["role"]}" == "user" ? "user" : "assistant";
            final content = "${m["content"] ?? ""}";
            _messages.add({
              "role": role,
              "text": (m["has_image"] == true ? "🖼️ " : "") + content,
            });
            _ctx.add({"role": role, "content": content});
          }
        }
        if (_messages.isEmpty) {
          _messages.add({"role": "assistant", "text": _greeting});
        }
      });
      _toBottom();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("לא ניתן לפתוח את השיחה כרגע.")),
      );
    }
  }

  Future<void> _showHistory() async {
    if (widget.currentUser.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("צריך להתחבר כדי לראות שיחות שמורות.")),
      );
      return;
    }
    final label = accessUserLabel(widget.currentUser);
    final picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _CozyAiHistorySheet(
        userLabel: label.isEmpty ? widget.currentUser : label,
        activeId: _conversationId,
        load: _loadConversations,
        remove: (id) async {
          await _historyCall("DELETE", "/api/ai/conversations/$id");
          if (id == _conversationId) {
            _conversationId = null;
            _ctx.clear();
          }
        },
      ),
    );
    if (!mounted || picked == null) return;
    if (picked < 0) {
      _newConversation();
    } else {
      await _openConversation(picked);
    }
  }

  void _showCozyGuide() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text(
            "🤖 ברוכים הבאים ל־Cozy AI",
            textDirection: TextDirection.rtl,
          ),
          content: const Text(
            "אפשר להשתמש ב־Cozy AI כך:\n\n"
            "💬 לשאול שאלה ולקבל תשובה\n"
            "🖼️ לצרף תמונה לניתוח\n"
            "📷 לצלם תמונה\n"
            "🎙️ להקליט קול לתמלול\n"
            "🎵 לצרף קובץ קול\n"
            "📄 לערוך PDF\n"
            "🕘 השיחות נשמרות, אפשר לחזור אליהן מסמל ההיסטוריה\n\n"
            "כל האפשרויות נמצאות בתוך הסיכה 📎.",
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("הבנתי, מתחילים"),
            ),
          ],
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _speakDone = _speakPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingPath = null);
    });
    _showCozyGuide();
  }

  @override
  void dispose() {
    _generation++;
    _pickGeneration++;
    _client?.close();
    _input.dispose();
    _scroll.dispose();
    _speakDone?.cancel();
    _speakPlayer.dispose();
    super.dispose();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _pickAiImage() async {
    if (_busy || _picking) return;
    final generation = ++_pickGeneration;
    setState(() => _picking = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
      if (file == null) return;
      if (await file.length() > 5 * 1024 * 1024) {
        throw const FormatException("בחר תמונה עד 5 MB.");
      }
      final bytes = await file.readAsBytes();
      final jpeg =
          bytes.length >= 3 &&
          bytes[0] == 255 &&
          bytes[1] == 216 &&
          bytes[2] == 255;
      final png =
          bytes.length >= 8 &&
          bytes[0] == 137 &&
          bytes[1] == 80 &&
          bytes[2] == 78 &&
          bytes[3] == 71;
      final webp =
          bytes.length >= 12 &&
          ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
          ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP';
      if (bytes.length > 5 * 1024 * 1024 || !(jpeg || png || webp)) {
        throw const FormatException(
          "צרף JPG, PNG או WebP. אפשר לצרף צילום מסך במקום HEIC.",
        );
      }
      if (!mounted || generation != _pickGeneration) return;
      setState(() {
        _pendingImage = base64Encode(bytes);
        _pendingVideoNote = null;
        _pendingVideoTranscript = null;
      });
    } catch (error) {
      if (!mounted || generation != _pickGeneration) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is FormatException
                ? error.message
                : "לא ניתן לבחור תמונה. בדוק הרשאת גישה לתמונות.",
          ),
        ),
      );
    } finally {
      if (mounted && generation == _pickGeneration)
        setState(() => _picking = false);
    }
  }

  static const int _voiceMaxMinutes = 20;
  static const int _voiceFileLimit = 48 * 1024 * 1024;

  /// One short piece of audio in a single request (about 2 minutes at most).
  Future<String> _transcribeVoiceBytes(
    List<int> bytes,
    String filename,
    MediaType type,
  ) async {
    final request = http.MultipartRequest("POST", Uri.parse(cozyAiVoiceApi));
    request.headers["X-Xpressphone-Client"] = "cozy-mobile-v1";
    request.fields["consent"] = "yes";
    request.files.add(
      http.MultipartFile.fromBytes(
        "file",
        bytes,
        filename: filename,
        contentType: type,
      ),
    );
    final response = await request.send().timeout(const Duration(seconds: 90));
    final payload = jsonDecode(await response.stream.bytesToString());
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        payload is! Map) {
      throw FormatException(
        payload is Map && "${payload["error"]}".trim().isNotEmpty
            ? "${payload["error"]}"
            : "התמלול לא הצליח.",
      );
    }
    final text = "${payload["text"] ?? ""}".trim();
    if (text.isEmpty) throw const FormatException("לא התקבל תמלול ברור.");
    return text;
  }

  /// A long recording (up to 20 minutes): uploaded once as a job. The server splits it,
  /// transcribes it piece by piece, and the app polls until the text is ready.
  Future<_VoiceResult> _transcribeLongBytes(
    List<int> bytes,
    String filename,
    MediaType type, {
    void Function(String)? onProgress,
  }) async {
    onProgress?.call("מעלה את ההקלטה...");
    final request = http.MultipartRequest(
      "POST",
      Uri.parse(cozyAiVoiceJobsApi),
    );
    request.headers["X-Xpressphone-Client"] = "cozy-mobile-v1";
    request.fields["consent"] = "yes";
    request.files.add(
      http.MultipartFile.fromBytes(
        "file",
        bytes,
        filename: filename,
        contentType: type,
      ),
    );
    final response = await request.send().timeout(const Duration(minutes: 5));
    final started = jsonDecode(await response.stream.bytesToString());
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        started is! Map) {
      throw FormatException(
        started is Map && "${started["error"]}".trim().isNotEmpty
            ? "${started["error"]}"
            : "התמלול לא התחיל.",
      );
    }
    final id = "${started["job_id"]}";
    var misses = 0;
    for (;;) {
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!mounted) throw const _VoiceStop("בוטל.");
      try {
        final poll = await http
            .get(
              Uri.parse("$cozyAiVoiceJobsApi/$id"),
              headers: const {"X-Xpressphone-Client": "cozy-mobile-v1"},
            )
            .timeout(const Duration(seconds: 20));
        final info = jsonDecode(utf8.decode(poll.bodyBytes));
        if (poll.statusCode == 404) {
          throw const _VoiceStop("המשימה פגה. שלח את ההקלטה שוב.");
        }
        if (poll.statusCode < 200 || poll.statusCode >= 300 || info is! Map) {
          throw StateError("poll failed");
        }
        misses = 0;
        final status = "${info["status"]}";
        if (status == "done") {
          return _VoiceResult(
            "${info["text"] ?? ""}".trim(),
            (info["failed"] as num?)?.toInt() ?? 0,
          );
        }
        if (status == "error") {
          throw _VoiceStop("${info["error"] ?? "התמלול נכשל."}");
        }
        final total = (info["total"] as num?)?.toInt() ?? 0;
        final done = (info["done"] as num?)?.toInt() ?? 0;
        onProgress?.call(
          total > 0
              ? "מתמלל $done מתוך $total..."
              : (status == "queued" ? "ממתין בתור..." : "מכין את ההקלטה..."),
        );
      } on _VoiceStop {
        rethrow;
      } catch (_) {
        // a temporary network problem while polling: try again a few times
        if (++misses >= 5) rethrow;
      }
    }
  }

  /// Short audio: one request. Long audio: a job. [seconds] is the length when it is known (recording).
  Future<_VoiceResult> _transcribeAudioBytes(
    List<int> bytes,
    String filename,
    MediaType type, {
    double? seconds,
    void Function(String)? onProgress,
  }) async {
    final small = seconds == null
        ? bytes.length <= 700 * 1024
        : (seconds <= 100 && bytes.length <= 1800 * 1024);
    if (small) {
      onProgress?.call("מתמלל את ההקלטה...");
      return _VoiceResult(
        await _transcribeVoiceBytes(bytes, filename, type),
        0,
      );
    }
    return _transcribeLongBytes(bytes, filename, type, onProgress: onProgress);
  }

  Future<T> _withVoiceProgress<T>(
    String title,
    Future<T> Function(ValueNotifier<String> progress) work,
  ) async {
    final progress = ValueNotifier<String>("מתחיל...");
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(title, textDirection: TextDirection.rtl),
            content: Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: progress,
                    builder: (_, text, __) =>
                        Text(text, textDirection: TextDirection.rtl),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      return await work(progress);
    } finally {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      progress.dispose();
    }
  }

  /// Short text: sent to the AI as a question (as before). Long text: shown as a message and copied.
  Future<void> _deliverVoiceTranscript(_VoiceResult result) async {
    final transcript = result.text.trim();
    if (transcript.isEmpty) throw const FormatException("לא התקבל תמלול ברור.");
    if (!mounted) return;
    if (result.failed > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${result.failed} קטעים לא תומללו (מסומנים בתמלול)."),
        ),
      );
    }
    if (transcript.length <= 1500) {
      _input.text = transcript;
      await _ask();
      return;
    }
    final words = transcript.split(RegExp(r"\s+")).length;
    await Clipboard.setData(ClipboardData(text: transcript));
    if (!mounted) return;
    setState(() {
      _messages.add({
        "role": "assistant",
        "text": "📝 התמלול מוכן ($words מילים) והועתק ללוח:\n\n$transcript",
      });
    });
    _toBottom();
  }

  Future<void> _pickAiAudioFile() async {
    if (_busy || _picking) return;

    setState(() => _picking = true);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          "aac",
          "aiff",
          "amr",
          "m4a",
          "mp3",
          "mp4",
          "oga",
          "ogg",
          "opus",
          "wav",
          "webm",
        ],
        withData: true,
      );

      final file = result?.files.single;
      if (file == null) return;

      final ext = file.name.contains(".")
          ? file.name.split(".").last.toLowerCase()
          : "";

      final bytes =
          file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());

      if (bytes == null || bytes.isEmpty) {
        throw const FormatException("לא הצלחתי לקרוא את קובץ הקול.");
      }

      if (bytes.length > _voiceFileLimit) {
        throw const FormatException(
          "קובץ הקול גדול מדי. המגבלה היא 48MB (ועד 20 דקות).",
        );
      }

      if (!mounted) return;

      final approved =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text(
                "תמלול קובץ קול",
                textDirection: TextDirection.rtl,
              ),
              content: const Text(
                "הקובץ (עד 20 דקות) יישלח ל-Google לתמלול ולתרגום לעברית. הוא אינו נשמר.",
                textDirection: TextDirection.rtl,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("ביטול"),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("מאשר"),
                ),
              ],
            ),
          ) ??
          false;
      if (!approved || !mounted) return;

      final subtype =
          const {
            "mp3": "mpeg",
            "m4a": "mp4",
            "mp4": "mp4",
            "oga": "ogg",
            "opus": "ogg",
          }[ext] ??
          (ext.isEmpty ? "mpeg" : ext);
      setState(() => _busy = true);
      _VoiceResult transcript;
      try {
        transcript = await _withVoiceProgress(
          "מתמלל קובץ קול",
          (progress) => _transcribeAudioBytes(
            bytes,
            file.name,
            MediaType("audio", subtype),
            onProgress: (text) => progress.value = text,
          ),
        );
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      await _deliverVoiceTranscript(transcript);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is FormatException
                  ? error.message
                  : (error is _VoiceStop
                        ? error.message
                        : "לא ניתן לעבד את קובץ הקול. נסה שוב."),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  static const int _videoFileLimit = 60 * 1024 * 1024;
  static const int _videoTranscriptLimit = 6000;

  /// Uploads the video to the app server. It returns one image with 6 moments
  /// from the video and the soundtrack as a small audio file.
  /// [onlyAudio]: only the soundtrack (for "תמלול וידאו").
  Future<Map<String, dynamic>> _prepareVideo(
    XFile file, {
    bool onlyAudio = false,
  }) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$api/api/ai/video_prepare"),
    );
    request.headers.addAll(_historyHeaders()..remove("Content-Type"));
    if (onlyAudio) request.fields["only_audio"] = "1";
    final name = file.name.isNotEmpty ? file.name : "video.mp4";
    if (file.path.isNotEmpty && await File(file.path).exists()) {
      request.files.add(
        await http.MultipartFile.fromPath("file", file.path, filename: name),
      );
    } else {
      request.files.add(
        http.MultipartFile.fromBytes(
          "file",
          await file.readAsBytes(),
          filename: name,
        ),
      );
    }
    final response = await request.send().timeout(const Duration(minutes: 6));
    final body = await response.stream.bytesToString();
    dynamic data;
    try {
      data = jsonDecode(body);
    } catch (_) {
      data = null;
    }
    if (response.statusCode == 413) {
      throw const FormatException("הסרטון גדול מדי. המגבלה היא 60 מגה.");
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data is! Map ||
        data["ok"] != true) {
      throw FormatException(
        data is Map && "${data["error"] ?? ""}".trim().isNotEmpty
            ? "${data["error"]}"
            : "לא הצלחתי לעבד את הסרטון.",
      );
    }
    return Map<String, dynamic>.from(data);
  }

  /// Backup transcription on the app server (used when the transcription server fails).
  Future<String> _transcribeOnServer(
    List<int> bytes,
    String filename,
    MediaType type,
  ) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse("$api/api/ai/transcribe_media"),
    );
    request.headers.addAll(_historyHeaders()..remove("Content-Type"));
    request.files.add(
      http.MultipartFile.fromBytes(
        "file",
        bytes,
        filename: filename,
        contentType: type,
      ),
    );
    final response = await request.send().timeout(const Duration(minutes: 5));
    dynamic data;
    try {
      data = jsonDecode(await response.stream.bytesToString());
    } catch (_) {
      data = null;
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data is! Map ||
        data["ok"] != true) {
      throw FormatException(
        data is Map && "${data["error"] ?? ""}".trim().isNotEmpty
            ? "${data["error"]}"
            : "התמלול לא הצליח.",
      );
    }
    return "${data["text"] ?? ""}".trim();
  }

  static String _clock(num seconds) {
    final s = seconds.round();
    return "${s ~/ 60}:${(s % 60).toString().padLeft(2, "0")}";
  }

  /// [transcribeOnly] true: "תמלול וידאו" - only the text of what is said.
  /// false: "שלח וידאו" - the transcript and an explanation of what is seen, sent at once.
  Future<void> _pickAiVideo({bool transcribeOnly = false}) async {
    if (_busy || _picking) return;
    final generation = ++_pickGeneration;
    setState(() => _picking = true);
    var sendNow = false;
    try {
      final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (file == null) return;
      final size = await file.length();
      if (size > _videoFileLimit) {
        throw const FormatException(
          "הסרטון גדול מדי. המגבלה היא 60 מגה (ועד 20 דקות). אפשר לקצר אותו בגלריה ולנסות שוב.",
        );
      }
      if (!mounted || generation != _pickGeneration) return;

      final approved =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(
                transcribeOnly ? "תמלול וידאו" : "שליחת וידאו",
                textDirection: TextDirection.rtl,
              ),
              content: Text(
                transcribeOnly
                    ? "השמע מהסרטון (עד 20 דקות) יישלח ל-Google לתמלול ולתרגום לעברית. הסרטון נמחק מהשרת מיד בסיום ואינו נשמר."
                    : "הסרטון (עד 20 דקות) יעלה לשרת: יילקחו ממנו 6 תמונות, והשמע יישלח ל-Google לתמלול ולתרגום לעברית. תקבל תמלול והסבר של מה שרואים. הסרטון נמחק מהשרת מיד בסיום ואינו נשמר.",
                textDirection: TextDirection.rtl,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text("ביטול"),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text("מאשר"),
                ),
              ],
            ),
          ) ??
          false;
      if (!approved || !mounted || generation != _pickGeneration) return;

      setState(() => _busy = true);
      late Map<String, dynamic> prep;
      var transcript = "";
      var transcriptNote = "";
      var failed = 0;
      try {
        await _withVoiceProgress(
          transcribeOnly ? "מתמלל וידאו" : "מעבד וידאו",
          (progress) async {
            final mb = (size / (1024 * 1024)).toStringAsFixed(1);
            progress.value = transcribeOnly
                ? "מעלה את הסרטון ($mb MB)..."
                : "מעלה את הסרטון ($mb MB) ומכין תמונות...";
            prep = await _prepareVideo(file, onlyAudio: transcribeOnly);
            final audio = "${prep["audio"] ?? ""}";
            if (prep["has_audio"] != true || audio.isEmpty) {
              transcriptNote = "בסרטון אין פס קול.";
              return;
            }
            final audioBytes = base64Decode(audio);
            final audioName = "${prep["audio_name"] ?? "audio.ogg"}";
            final mime = "${prep["audio_mime"] ?? "audio/ogg"}".split("/");
            final audioType = MediaType(
              mime.first,
              mime.length > 1 ? mime[1] : "ogg",
            );
            var firstError = "";
            // 1. שרת התמלול הרגיל (כמו הקלטות)
            try {
              final result = await _transcribeAudioBytes(
                audioBytes,
                audioName,
                audioType,
                seconds: (prep["seconds"] as num?)?.toDouble(),
                onProgress: (text) => progress.value = text.replaceAll(
                  "ההקלטה",
                  "השמע מהסרטון",
                ),
              );
              transcript = result.text.trim();
              failed = result.failed;
            } on _VoiceStop catch (e) {
              firstError = e.message;
            } on FormatException catch (e) {
              firstError = e.message;
            } catch (_) {
              firstError = "שגיאה";
            }
            // 2. גיבוי: השרת של האפליקציה מתמלל בעצמו (כמו הודעות קוליות בוואטסאפ)
            if (transcript.isEmpty) {
              progress.value = "מנסה תמלול בדרך נוספת...";
              try {
                transcript = await _transcribeOnServer(
                  audioBytes,
                  audioName,
                  audioType,
                );
                failed = 0;
              } on FormatException catch (e) {
                transcriptNote = "${firstError} ${e.message}".contains("ברור")
                    ? "לא נשמע בסרטון דיבור ברור."
                    : "התמלול לא הצליח (${e.message}).";
              } catch (_) {
                transcriptNote = "התמלול לא הצליח.";
              }
              if (transcript.isEmpty && transcriptNote.isEmpty) {
                transcriptNote = "לא נשמע בסרטון דיבור ברור.";
              }
            }
          },
        );
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      if (!mounted || generation != _pickGeneration) return;

      final seconds = (prep["seconds"] as num?) ?? 0;
      final length = seconds > 0 ? " (${_clock(seconds)})" : "";
      if (failed > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$failed קטעים לא תומללו (מסומנים בתמלול).")),
        );
      }

      // ---- 1. תמלול וידאו: רק הטקסט ----
      if (transcribeOnly) {
        if (transcript.isEmpty) {
          throw FormatException(
            transcriptNote.isEmpty ? "לא התקבל תמלול." : transcriptNote,
          );
        }
        final userText = "🎥 תמלול וידאו$length";
        final answerText = "📝 תמלול הסרטון:\n\n$transcript";
        setState(() {
          _messages.add({"role": "user", "text": userText});
          _messages.add({"role": "assistant", "text": answerText});
        });
        _toBottom();
        await _ensureConversation();
        _saveMessage("user", userText);
        _saveMessage("assistant", answerText);
        _ctx.add({"role": "user", "content": userText});
        _ctx.add({"role": "assistant", "content": answerText});
        return;
      }

      // ---- 2. שלח וידאו: תמלול + הסבר של מה שרואים, נשלח מיד ----
      final times = (prep["times"] is List)
          ? (prep["times"] as List).map((t) => "$t").join(", ")
          : "";
      final frames = (prep["frames"] as num?)?.toInt() ?? 1;
      final cut = transcript.length > _videoTranscriptLimit;
      final forModel = cut
          ? "${transcript.substring(0, _videoTranscriptLimit)} ..."
          : transcript;
      final note = StringBuffer()
        ..writeln("[וידאו מצורף${seconds > 0 ? " — אורך ${_clock(seconds)}" : ""}]")
        ..writeln(
          frames > 1
              ? "התמונה המצורפת היא לוח של $frames רגעים מהסרטון לפי הסדר (ממוספרים 1 עד $frames, עם הזמן בפינה)${times.isNotEmpty ? ": $times" : ""}."
              : "התמונה המצורפת היא רגע מתוך הסרטון.",
        );
      if (transcript.isNotEmpty) {
        note
          ..writeln(
            cut
                ? "תמלול הדיבור בסרטון (החלק הראשון בלבד — התמלול ארוך):"
                : "תמלול הדיבור בסרטון (מתורגם לעברית):",
          )
          ..writeln('"""')
          ..writeln(forModel)
          ..writeln('"""');
      } else if (transcriptNote.isNotEmpty) {
        note.writeln(transcriptNote);
      }
      note.write(
        "המשתמש כבר רואה את התמלול, אז אל תחזור עליו. הסבר מה רואים בסרטון ומה קורה בו, "
        "וקשר את זה למה שנאמר. ענה לפי התמונות והתמלול בלבד; אל תנחש מה קרה בין הרגעים שבתמונה, ואם משהו לא ברור, אמור זאת.",
      );

      setState(() {
        _pendingImage = "${prep["image"]}";
        _pendingVideoNote = note.toString();
        _pendingVideoTranscript = transcript.isNotEmpty
            ? transcript
            : (transcriptNote.isNotEmpty ? transcriptNote : "אין תמלול.");
        _picking = false;
      });
      sendNow = true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is FormatException
                  ? error.message
                  : (error is TimeoutException
                        ? "העלאת הסרטון לקחה יותר מדי זמן. נסה סרטון קצר יותר."
                        : "לא ניתן לעבד את הסרטון. בדוק הרשאת גישה לסרטונים ונסה שוב."),
            ),
          ),
        );
      }
    } finally {
      if (mounted && generation == _pickGeneration) {
        setState(() => _picking = false);
      }
    }
    // נשלח מיד: מה שכתוב בשורת הכתיבה (אם יש) נשלח כשאלה על הסרטון
    if (sendNow && mounted && generation == _pickGeneration) await _ask();
  }

  // ---- דבר בעברית -> קובץ שמע בשפה אחרת ----
  static const int _speakMaxMinutes = 3;

  /// After the Hebrew recording is transcribed: asks in which language to create the audio.
  void _startSpeak(String hebrew) {
    final text = hebrew.trim();
    if (text.isEmpty) throw const FormatException("לא התקבל תמלול ברור.");
    setState(() {
      _pendingSpeakText = text;
      _messages.add({"role": "user", "text": "🎙️ $text"});
      _messages.add({
        "role": "assistant",
        "text":
            "באיזו שפה ליצור את קובץ השמע?\nכתוב שם של שפה, למשל: אנגלית, רוסית, ערבית, צרפתית, ספרדית, אמהרית.\n(או \"ביטול\")",
      });
    });
    _toBottom();
  }

  /// The user typed a language: translate + create the audio file.
  Future<void> _speakTo(String language) async {
    final hebrew = _pendingSpeakText;
    if (hebrew == null) return;
    final typed = language.trim();
    if (const ["ביטול", "בטל", "cancel"].contains(typed.toLowerCase())) {
      setState(() {
        _pendingSpeakText = null;
        _input.clear();
        _messages.add({"role": "user", "text": typed});
        _messages.add({"role": "assistant", "text": "בוטל."});
      });
      _toBottom();
      return;
    }
    final answer = <String, String>{
      "role": "assistant",
      "text": "🔊 מתרגם ויוצר קובץ שמע...",
    };
    setState(() {
      _busy = true;
      _input.clear();
      _messages.add({"role": "user", "text": typed});
      _messages.add(answer);
    });
    _toBottom();
    try {
      final headers = _historyHeaders();
      final r = await http
          .post(
            Uri.parse("$api/api/ai/speak"),
            headers: headers,
            body: jsonEncode({"text": hebrew, "lang": typed}),
          )
          .timeout(const Duration(seconds: 90));
      dynamic data;
      try {
        data = jsonDecode(utf8.decode(r.bodyBytes));
      } catch (_) {
        data = null;
      }
      if (r.statusCode < 200 ||
          r.statusCode >= 300 ||
          data is! Map ||
          data["ok"] != true) {
        final msg = data is Map && "${data["error"] ?? ""}".trim().isNotEmpty
            ? "${data["error"]}"
            : "יצירת קובץ השמע לא הצליחה.";
        // נשאר מחכה לשפה: אפשר לכתוב שוב
        if (mounted) {
          setState(
            () => answer["text"] = "$msg\nכתוב שוב שם של שפה, או \"ביטול\".",
          );
        }
        return;
      }
      final bytes = base64Decode("${data["audio"]}");
      final dir = await getTemporaryDirectory();
      final path =
          "${dir.path}/cozy_${data["lang"]}_${DateTime.now().millisecondsSinceEpoch}.mp3";
      await File(path).writeAsBytes(bytes, flush: true);
      final text = "🔊 ${data["language"] ?? typed}:\n${data["translated"] ?? ""}";
      if (!mounted) return;
      setState(() {
        answer["text"] = text;
        answer["audio_path"] = path;
        _pendingSpeakText = null;
      });
      await _ensureConversation();
      _saveMessage("user", "🎙️ $hebrew\n← $typed");
      _saveMessage("assistant", text);
      _ctx.add({"role": "user", "content": "🎙️ $hebrew"});
      _ctx.add({"role": "assistant", "content": text});
      unawaited(_playSpeak(path));
    } on TimeoutException {
      if (mounted) {
        setState(
          () => answer["text"] =
              "הבקשה מתעכבת יותר מדי. כתוב שוב שם של שפה כדי לנסות שוב.",
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => answer["text"] =
              "יצירת קובץ השמע לא הצליחה. כתוב שוב שם של שפה כדי לנסות שוב.",
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _toBottom();
      }
    }
  }

  Future<void> _playSpeak(String path) async {
    try {
      if (_playingPath == path) {
        await _speakPlayer.stop();
        if (mounted) setState(() => _playingPath = null);
        return;
      }
      await _speakPlayer.stop();
      if (mounted) setState(() => _playingPath = path);
      await _speakPlayer.play(DeviceFileSource(path));
    } catch (_) {
      if (mounted) {
        setState(() => _playingPath = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("לא ניתן לנגן את הקובץ.")),
        );
      }
    }
  }

  Future<void> _shareSpeak(String path, String text) async {
    try {
      await Share.shareXFiles([
        XFile(path, mimeType: "audio/mpeg"),
      ], text: text.replaceFirst(RegExp(r"^🔊 [^\n]*\n"), ""));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("לא ניתן לשתף את הקובץ.")),
        );
      }
    }
  }

  /// [speak]: record Hebrew and then create an audio file in another language.
  Future<void> _recordAiVoice({bool speak = false}) async {
    if (_busy || _picking) return;
    final approved =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(
              speak ? "דבר בעברית ← קול בשפה אחרת" : "תמלול הקלטה",
              textDirection: TextDirection.rtl,
            ),
            content: Text(
              speak
                  ? "דבר בעברית (עד $_speakMaxMinutes דקות). אחרי ההקלטה אשאל באיזו שפה ליצור את קובץ השמע. ההקלטה נשלחת ל-Google לתמלול, לתרגום ולהקראה, ואינה נשמרת."
                  : "ההקלטה (עד 20 דקות) תישלח ל-Google לתמלול ולתרגום לעברית. היא אינה נשמרת.",
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("ביטול"),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("מאשר"),
              ),
            ],
          ),
        ) ??
        false;
    if (!approved || !mounted) return;

    final recorder = FlutterSoundRecorder();
    var opened = false;
    Timer? limit;
    Timer? ticker;
    final elapsed = ValueNotifier<int>(0);
    try {
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        throw const FormatException("צריך לאשר גישה למיקרופון.");
      }
      await recorder.openRecorder();
      opened = true;
      final isIos = !kIsWeb && Platform.isIOS;
      final dir = await getTemporaryDirectory();
      final ext = isIos ? "m4a" : "aac";
      final codec = isIos ? Codec.aacMP4 : Codec.aacADTS;
      final subtype = isIos ? "mp4" : "aac";
      final path =
          "${dir.path}/cozy_voice_${DateTime.now().millisecondsSinceEpoch}.$ext";
      final startedAt = DateTime.now();
      await recorder.startRecorder(toFile: path, codec: codec);
      if (!mounted) return;

      ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        elapsed.value++;
      });
      final maxMinutes = speak ? _speakMaxMinutes : _voiceMaxMinutes;
      limit = Timer(Duration(minutes: maxMinutes), () {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      String clock(int seconds) =>
          "${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, "0")}";
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("🎙️ מקליט...", textDirection: TextDirection.rtl),
          content: ValueListenableBuilder<int>(
            valueListenable: elapsed,
            builder: (_, seconds, __) => Text(
              "לחץ עצור כשתסיים.\nזמן: ${clock(seconds)} מתוך $maxMinutes:00",
              textDirection: TextDirection.rtl,
            ),
          ),
          actions: [
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.stop),
              label: Text(speak ? "עצור" : "עצור ותמלל"),
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            ),
          ],
        ),
      );
      limit.cancel();
      ticker.cancel();
      await recorder.stopRecorder();
      final seconds =
          DateTime.now().difference(startedAt).inMilliseconds / 1000.0;
      final bytes = await File(path).readAsBytes();
      try {
        await File(path).delete();
      } catch (_) {}
      if (bytes.length < 1000) throw const FormatException("לא נקלט קול.");
      if (!mounted) return;
      setState(() => _busy = true);
      _VoiceResult transcript;
      try {
        transcript = await _withVoiceProgress(
          "מתמלל את ההקלטה",
          (progress) => _transcribeAudioBytes(
            bytes,
            "voice.$ext",
            MediaType("audio", subtype),
            seconds: seconds,
            onProgress: (text) => progress.value = text,
          ),
        );
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      if (speak) {
        if (!mounted) return;
        _startSpeak(transcript.text);
      } else {
        await _deliverVoiceTranscript(transcript);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is FormatException
                  ? error.message
                  : (error is _VoiceStop
                        ? error.message
                        : "לא ניתן לתמלל כרגע. נסה שוב."),
            ),
          ),
        );
      }
    } finally {
      limit?.cancel();
      ticker?.cancel();
      elapsed.dispose();
      if (opened) {
        try {
          await recorder.closeRecorder();
        } catch (_) {}
      }
      if (mounted && _busy) setState(() => _busy = false);
    }
  }


  // ---- תפריט 📎: כל האפשרויות בכרטיסים צבעוניים, שתיים בשורה ----
  Widget _attachSheet(BuildContext ctx) {
    Widget tile(
      String action,
      IconData icon,
      String title,
      String subtitle,
      Color a,
      Color b,
    ) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.pop(ctx, action),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      a.withValues(alpha: 0.24),
                      b.withValues(alpha: 0.10),
                    ],
                  ),
                  border: Border.all(color: a.withValues(alpha: 0.55)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [a, b],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: a.withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.68),
                              fontSize: 11.5,
                              height: 1.25,
                            ),
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

    Widget row(List<Widget> tiles) => IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: tiles),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "מה תרצה לצרף? ✨",
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            row([
              tile("image", Icons.photo, "תמונה", "מהגלריה",
                  const Color(0xff3b82f6), const Color(0xff06b6d4)),
              tile("camera", Icons.camera_alt, "צילום", "צלם עכשיו",
                  const Color(0xff14b8a6), const Color(0xff22c55e)),
            ]),
            row([
              tile("video", Icons.videocam, "שלח וידאו", "תמלול + מה רואים",
                  const Color(0xff8b5cf6), const Color(0xffec4899)),
              tile("video_transcribe", Icons.subtitles, "תמלול וידאו",
                  "רק מה שנאמר", const Color(0xfff43f5e), const Color(0xfff97316)),
            ]),
            row([
              tile("speak", Icons.record_voice_over, "קול בשפה אחרת",
                  "דבר בעברית ← קובץ שמע",
                  const Color(0xfff59e0b), const Color(0xffeab308)),
              tile("record", Icons.mic, "הקלט קול", "לתמלול לעברית",
                  const Color(0xffef4444), const Color(0xffdb2777)),
            ]),
            row([
              tile("audio", Icons.audio_file, "קובץ קול", "תמלול קובץ",
                  const Color(0xff6366f1), const Color(0xff3b82f6)),
              tile("pdf", Icons.picture_as_pdf, "עריכת PDF", "החלפת טקסט",
                  const Color(0xff10b981), const Color(0xff84cc16)),
            ]),
            const SizedBox(height: 8),
            Text(
              "וידאו והקלטות עד 20 דקות · וידאו עד 60 מגה",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ask() async {
    final question = _input.text.trim();
    final picture = _pendingImage;
    // "שלח לי במייל / בוואטסאפ ..." - פותח חלון שליחה עם התשובה האחרונה
    if (picture == null &&
        _pendingSpeakText == null &&
        question.isNotEmpty &&
        !_busy &&
        !_picking) {
      final command = _parseSendCommand(question);
      if (command != null) {
        _input.clear();
        await _openSendDialog(
          command.channel,
          command.text.isNotEmpty ? command.text : _lastAnswerText(),
          to: command.to,
        );
        return;
      }
    }
    // מחכים לשפה של קובץ השמע: מה שנכתב הוא שם השפה
    if (_pendingSpeakText != null && picture == null && question.isNotEmpty) {
      if (_busy || _picking) return;
      await _speakTo(question);
      return;
    }
    final videoNote = picture == null ? null : _pendingVideoNote;
    // "שלח וידאו": התשובה בשתי שורות - 1. התמלול 2. מה רואים בסרטון
    final videoHeader = videoNote == null
        ? ""
        : "📝 תמלול:\n${_pendingVideoTranscript ?? "אין תמלול."}\n\n🎥 מה רואים בסרטון:\n";
    try {
      // נשלח עם המשתמש: כשה-AI כבוי לכולם, אדמין עדיין יכול להשתמש בו
      final response = await http
          .get(
            Uri.parse("$api/api/cozy-ai/status"),
            headers: _historyHeaders(),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (data["enabled"] != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cozy AI אינו זמין כרגע.")),
          );
        }
        return;
      }
    } catch (_) {}
    if ((question.isEmpty && picture == null) || _busy || _picking) return;
    if (question.length > 12000) return;
    final generation = ++_generation;
    final answer = <String, String>{
      "role": "assistant",
      "text": picture == null
          ? "מתחיל..."
          : (videoNote != null
                ? "${videoHeader}מנתח את הסרטון..."
                : "מנתח תמונה..."),
    };
    final shownText = videoNote != null
        ? "🎥 ${question.isEmpty ? "תמלל והסבר מה רואים בסרטון" : question}"
        : (question.isEmpty ? "מה רואים בתמונה?" : question);
    final modelText = videoNote != null
        ? "$videoNote\n\nהבקשה של המשתמש: "
              "${question.isEmpty ? "הסבר מה רואים בסרטון ומה קורה בו." : question}"
        : (question.isEmpty
              ? "תאר מה רואים בתמונה וקרא טקסט ברור בלי לנחש."
              : question);
    setState(() {
      _busy = true;
      _messages.add({
        "role": "user",
        "text": shownText,
        if (picture != null) "image": picture,
      });
      _messages.add(answer);
      _pendingImage = null;
      _pendingVideoNote = null;
        _pendingVideoTranscript = null;
      _input.clear();
    });
    _toBottom();
    final client = http.Client();
    _client = client;
    try {
      await _ensureConversation();
      if (!mounted || generation != _generation) return;
      final contextForModel = _ctx
          .skip(_ctx.length > 12 ? _ctx.length - 12 : 0)
          .map(
            (m) => {
              "role": m["role"] ?? "user",
              "content": (m["content"] ?? "").length > 4000
                  ? (m["content"] ?? "").substring(0, 4000)
                  : (m["content"] ?? ""),
            },
          )
          .toList();
      _saveMessage("user", shownText, hasImage: picture != null);
      // לווידאו: התמלול נשמר בהקשר, כדי שאפשר יהיה לשאול עליו שאלות המשך
      _ctx.add({
        "role": "user",
        "content": videoNote != null ? modelText : shownText,
      });
      final req = http.Request("POST", Uri.parse(cozyAiApi));
      req.headers["Content-Type"] = "application/json";
      req.body = jsonEncode({
        "message": modelText,
        "model": _mode,
        if (picture != null) "images": [picture],
        if (_conversationId != null) "conversation_id": _conversationId,
        if (contextForModel.isNotEmpty) "history": contextForModel,
      });
      // A local model can take a little while to start producing its first token.
      // Do not treat that normal startup time as a network failure.
      final response = await client
          .send(req)
          .timeout(const Duration(seconds: 120));
      if (!mounted || generation != _generation) return;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception("HTTP ${response.statusCode}");
      }
      var full = "";
      await for (final chunk
          in response.stream
              .transform(utf8.decoder)
              .timeout(const Duration(seconds: 180))) {
        if (!mounted || generation != _generation) return;
        full += chunk;
        setState(
          () => answer["text"] = videoHeader +
              (full.isEmpty
                  ? (videoNote != null ? "מנתח את הסרטון..." : "מתחיל...")
                  : full),
        );
        _toBottom();
      }
      if (mounted && generation == _generation && full.trim().isEmpty) {
        setState(() => answer["text"] = "${videoHeader}לא התקבלה תשובה.");
      }
      if (generation == _generation && full.trim().isNotEmpty) {
        _saveMessage("assistant", videoHeader + full.trim());
        _ctx.add({"role": "assistant", "content": full.trim()});
      }
    } on TimeoutException {
      if (mounted && generation == _generation) {
        setState(
          () => answer["text"] =
              "${videoHeader}הבקשה מתעכבת יותר מדי. נסה שוב בעוד רגע.",
        );
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(
          () => answer["text"] =
              "${videoHeader}לא ניתן להשלים את התשובה כרגע. נסה שוב.",
        );
      }
    } finally {
      client.close();
      if (mounted && generation == _generation) {
        _client = null;
        setState(() => _busy = false);
        _toBottom();
      }
    }
  }

  void _stop() {
    _generation++;
    _client?.close();
    _client = null;
    if (mounted)
      setState(() {
        if (_busy &&
            _messages.isNotEmpty &&
            _messages.last["role"] == "assistant") {
          _messages.last["text"] = "${_messages.last["text"] ?? ""}\n[נעצר]";
        }
        _busy = false;
      });
  }

  // ---- שליחה במייל / בוואטסאפ ----
  bool _canSend(Map<String, String> msg) {
    if (msg["role"] != "assistant") return false;
    final text = (msg["text"] ?? "").trim();
    if (text.length < 2) return false;
    if (text.startsWith("שלום 👋") ||
        text.startsWith("שיחה חדשה") ||
        text == "בוטל." ||
        text.startsWith("באיזו שפה ליצור")) {
      return false;
    }
    // לא בזמן שהתשובה עוד נכתבת
    if (_busy && _messages.isNotEmpty && identical(_messages.last, msg)) {
      return false;
    }
    return true;
  }

  String _lastAnswerText() {
    for (final m in _messages.reversed) {
      if (_canSend(m)) return m["text"] ?? "";
    }
    return "";
  }

  static final RegExp _emailRe = RegExp(r"[^\s@<>]+@[^\s@<>]+\.[A-Za-z]{2,}");
  static final RegExp _phoneRe = RegExp(r"\+?\d[\d-]{7,}\d");

  /// "שלח לו למייל dani@gmail.com אני מאחר" -> (email, dani@gmail.com, "אני מאחר").
  /// No message in the command -> text is "" (the last answer is used).
  ({String channel, String to, String text})? _parseSendCommand(String text) {
    final t = text.trim();
    final start = RegExp(r"^(תשלחי|תשלח|שלחי|שלח|send)\s*", caseSensitive: false);
    if (!start.hasMatch(t)) return null;
    const emailWords = r"(אימייל|מייל|מיל|דואר|email|mail)";
    const waWords = r"(וואטסאפ|ווטסאפ|וואצאפ|ווצאפ|ואטסאפ|ווצפ|whatsapp)";
    String? channel;
    if (RegExp(emailWords, caseSensitive: false).hasMatch(t)) channel = "email";
    if (RegExp(waWords, caseSensitive: false).hasMatch(t)) channel = "whatsapp";
    if (channel == null) return null;
    final email = _emailRe.firstMatch(t)?.group(0);
    final phone = _phoneRe.firstMatch(t)?.group(0);
    final to = channel == "email"
        ? (email ?? "")
        : (phone?.replaceAll(RegExp(r"[\s-]"), "") ?? "");

    // מה שנשאר אחרי הפקודה, הערוץ והנמען = ההודעה
    var rest = t.replaceFirst(start, "");
    if (email != null) rest = rest.replaceFirst(email, " ");
    if (phone != null) rest = rest.replaceFirst(phone, " ");
    rest = rest.replaceFirst(
      RegExp("(דרך |ב|ל|מ)?($emailWords|$waWords)", caseSensitive: false),
      " ",
    );
    const filler = {
      "לו", "לה", "לי", "להם", "להן", "את", "זה", "הודעה", "ההודעה",
      "ל", "ב", "מ", "עם", "דרך", "אל", "לכתובת", "למספר", "מספר",
      ":", "-", ",", "–", "ל-", "ב-", "מ-", "ל־", "ב־", "מ־", "ל:",
    };
    final words = rest.trim().split(RegExp(r"\s+"));
    while (words.isNotEmpty && filler.contains(words.first)) {
      words.removeAt(0);
    }
    final message = words.join(" ").trim();
    // "שלח לי במייל את התמלול" - מתכוון לתשובה האחרונה, לא למילה "התמלול"
    const refs = {
      "התמלול", "התשובה", "התרגום", "הטקסט", "הסיכום", "זה", "הזה",
      "את זה", "הכל", "הכול", "את הכל", "את הכול", "אותו", "אותה",
    };
    final isRef = refs.contains(message) ||
        refs.contains(message.replaceFirst(RegExp(r"^את\s+"), ""));
    return (
      channel: channel,
      to: to,
      text: message.length >= 2 && !isRef ? message : "",
    );
  }

  Future<void> _openSendDialog(
    String channel,
    String text, {
    String to = "",
  }) async {
    final isEmail = channel == "email";
    final toCtrl = TextEditingController(text: to);
    final textCtrl = TextEditingController(text: text.trim());
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isEmail ? "📧 שליחה במייל" : "💬 שליחה בוואטסאפ",
          textDirection: TextDirection.rtl,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: toCtrl,
                keyboardType:
                    isEmail ? TextInputType.emailAddress : TextInputType.phone,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: isEmail ? "כתובת מייל" : "מספר וואטסאפ",
                  hintText: isEmail
                      ? "ריק = למייל שלי"
                      : "ריק = לוואטסאפ שלי · למשל 0521234567",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textCtrl,
                minLines: 3,
                maxLines: 8,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: "מה לשלוח (אפשר לערוך)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("ביטול"),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send),
            label: const Text("שלח"),
          ),
        ],
      ),
    );
    final target = toCtrl.text.trim();
    final body = textCtrl.text.trim();
    toCtrl.dispose();
    textCtrl.dispose();
    if (go != true || !mounted) return;
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("אין מה לשלוח.")),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("שולח..."), duration: Duration(seconds: 2)),
    );
    String result;
    try {
      final r = await http
          .post(
            Uri.parse("$api/api/ai/send"),
            headers: _historyHeaders(),
            body: jsonEncode({
              "channel": channel,
              "to": target.isEmpty ? "me" : target,
              "text": body,
            }),
          )
          .timeout(const Duration(seconds: 60));
      dynamic data;
      try {
        data = jsonDecode(utf8.decode(r.bodyBytes));
      } catch (_) {
        data = null;
      }
      if (r.statusCode >= 200 &&
          r.statusCode < 300 &&
          data is Map &&
          data["ok"] == true) {
        result = target.isEmpty
            ? (isEmail ? "✅ נשלח למייל שלך" : "✅ נשלח לוואטסאפ שלך")
            : "✅ נשלח ל-${data["to"] ?? target}";
      } else {
        result =
            "❌ ${data is Map ? (data["error"] ?? "השליחה נכשלה") : "השליחה נכשלה"}";
      }
    } catch (_) {
      result = "❌ השליחה נכשלה. בדוק חיבור לאינטרנט.";
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result, textDirection: TextDirection.rtl)),
    );
  }

  Widget _bubble(Map<String, String> msg) {
    final user = msg["role"] == "user";
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: user ? const Color(0xff075e54) : const Color(0xff15283a),
          borderRadius: BorderRadius.circular(14),
          border: user
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg["image"] != null)
              Image.memory(
                base64Decode(msg["image"]!),
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Text("לא ניתן להציג את התמונה"),
              ),
            SelectableText(
              msg["text"] ?? "",
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.45,
              ),
            ),
            if (_canSend(msg))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          _openSendDialog("email", msg["text"] ?? ""),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xff7dd3fc),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.email_outlined, size: 18),
                      label: const Text("מייל"),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _openSendDialog("whatsapp", msg["text"] ?? ""),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xff4ade80),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.chat_outlined, size: 18),
                      label: const Text("וואטסאפ"),
                    ),
                  ],
                ),
              ),
            if (msg["audio_path"] != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => _playSpeak(msg["audio_path"]!),
                      icon: Icon(
                        _playingPath == msg["audio_path"]
                            ? Icons.stop
                            : Icons.play_arrow,
                      ),
                      label: Text(
                        _playingPath == msg["audio_path"] ? "עצור" : "השמע",
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _shareSpeak(msg["audio_path"]!, msg["text"] ?? ""),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.share),
                      label: const Text("שתף / שמור"),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final light = appLightMode.value;
    return Scaffold(
      backgroundColor: light
          ? const Color(0xffeef2f7)
          : const Color(0xff050d18),
      appBar: AppBar(
        backgroundColor: light ? Colors.white : const Color(0xff07111e),
        foregroundColor: light ? const Color(0xff2a2f32) : Colors.white,
        title: const Text(
          "Cozy AI",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _mode,
                  dropdownColor: const Color(0xff10263d),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  iconEnabledColor: Colors.white70,
                  items: const [
                    DropdownMenuItem(
                      value: "auto",
                      child: Text("✨ אוטומטי · DeepSeek"),
                    ),
                    DropdownMenuItem(
                      value: "deepseek",
                      child: Text("⚡ DeepSeek V4.1 Flash · ענן"),
                    ),
                    DropdownMenuItem(
                      value: "kimi",
                      child: Text("🧠 Kimi K3 · ענן · הכי חכם"),
                    ),
                    DropdownMenuItem(
                      value: "dicta",
                      child: Text("🖥 DictaLM 12B · מקומי"),
                    ),
                    DropdownMenuItem(
                      value: "qwen",
                      child: Text("👁 Qwen 3.5 4B · תמונות וטקסט"),
                    ),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) {
                          if (v != null) setState(() => _mode = v);
                        },
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: "השיחות שלי",
            onPressed: _showHistory,
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: "שיחה חדשה",
            onPressed: _newConversation,
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _bubble(_messages[i]),
              ),
            ),
            if (_pendingSpeakText != null && _pendingImage == null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "🗣️ כתוב באיזו שפה ליצור את קובץ השמע ולחץ שלח",
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    IconButton(
                      tooltip: "ביטול",
                      onPressed: () =>
                          setState(() => _pendingSpeakText = null),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            if (_pendingImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Image.memory(
                      base64Decode(_pendingImage!),
                      height: 70,
                      width: 70,
                      fit: BoxFit.contain,
                    ),
                    Expanded(
                      child: Text(
                        _pendingVideoNote != null
                            ? "🎥 וידאו מצורף: רגעים מהסרטון + תמלול · כתוב שאלה או לחץ שלח"
                            : "תמונה אחת עד 5 MB · ניתוח במודל ראייה",
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    IconButton(
                      tooltip: _pendingVideoNote != null
                          ? "הסר וידאו"
                          : "הסר תמונה",
                      onPressed: () => setState(() {
                        _pendingImage = null;
                        _pendingVideoNote = null;
        _pendingVideoTranscript = null;
                      }),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: BoxDecoration(
                color: light ? Colors.white : const Color(0xff091725),
                border: Border(
                  top: BorderSide(
                    color: light
                        ? Colors.black12
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: "צרף",
                    onPressed: _busy || _picking
                        ? null
                        : () async {
                            final action = await showModalBottomSheet<String>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: const Color(0xff0b1623),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(26),
                                ),
                              ),
                              builder: (ctx) => _attachSheet(ctx),
                            );

                            if (!mounted || action == null) return;

                            if (action == "image") {
                              await _pickAiImage();
                            } else if (action == "video") {
                              await _pickAiVideo();
                            } else if (action == "video_transcribe") {
                              await _pickAiVideo(transcribeOnly: true);
                            } else if (action == "record") {
                              await _recordAiVoice();
                            } else if (action == "speak") {
                              await _recordAiVoice(speak: true);
                            } else if (action == "audio") {
                              await _pickAiAudioFile();
                            } else if (action == "camera") {
                              final picked = await ImagePicker().pickImage(
                                source: ImageSource.camera,
                                maxWidth: 1600,
                                maxHeight: 1600,
                                imageQuality: 90,
                              );
                              if (picked != null && mounted) {
                                final bytes = await picked.readAsBytes();
                                if (bytes.length <= 5 * 1024 * 1024) {
                                  setState(
                                    () {
                                      _pendingImage = base64Encode(bytes);
                                      _pendingVideoNote = null;
        _pendingVideoTranscript = null;
                                    },
                                  );
                                }
                              }
                            } else if (action == "pdf") {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CozyPdfPage(apiUrl: cozyAiApi),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.attach_file),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textDirection: TextDirection.rtl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _ask(),
                      decoration: InputDecoration(
                        hintText: "כתוב שאלה או צרף תמונה...",
                        filled: true,
                        fillColor: light
                            ? const Color(0xfff3f6fa)
                            : const Color(0xff10202f),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_busy)
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                      onPressed: _stop,
                      icon: const Icon(Icons.stop),
                    )
                  else
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xff25d366),
                        foregroundColor: const Color(0xff06130d),
                      ),
                      onPressed: _ask,
                      icon: const Icon(Icons.send),
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

class _CozyAiHistorySheet extends StatefulWidget {
  const _CozyAiHistorySheet({
    required this.userLabel,
    required this.activeId,
    required this.load,
    required this.remove,
  });

  final String userLabel;
  final int? activeId;
  final Future<List<Map<String, dynamic>>> Function() load;
  final Future<void> Function(int id) remove;

  @override
  State<_CozyAiHistorySheet> createState() => _CozyAiHistorySheetState();
}

class _CozyAiHistorySheetState extends State<_CozyAiHistorySheet> {
  List<Map<String, dynamic>>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _items = null;
      _error = null;
    });
    try {
      final items = await widget.load();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "לא ניתן לטעון שיחות כרגע.\n$e");
    }
  }

  Future<void> _delete(int id) async {
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("מחיקת שיחה", textDirection: TextDirection.rtl),
            content: const Text(
              "למחוק את השיחה?",
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("ביטול"),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("מחק"),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    try {
      await widget.remove(id);
    } catch (_) {}
    if (mounted) _reload();
  }

  Widget _body() {
    final items = _items;
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: Text(_error!)),
      );
    }
    if (items == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text("עדיין אין שיחות קודמות.")),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final id = (item["id"] as num).toInt();
        final title = "${item["title"] ?? ""}".trim();
        return ListTile(
          selected: id == widget.activeId,
          title: Text(
            title.isEmpty ? "שיחה ללא כותרת" : title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text("${item["when"] ?? ""}"),
          trailing: IconButton(
            tooltip: "מחק שיחה",
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(id),
          ),
          onTap: () => Navigator.pop(context, id),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  "השיחות של ${widget.userLabel}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, -1),
                  icon: const Icon(Icons.add),
                  label: const Text("שיחה חדשה"),
                ),
              ),
              Flexible(child: _body()),
            ],
          ),
        ),
      ),
    );
  }
}
// ===== /Cozy AI =====

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    this.initialCountry = "all",
    this.currentUser = "",
  });

  final String initialCountry;
  final String currentUser;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List countries = [];
  List chats = [];
  String selectedCountry = "all";
  String search = "";
  bool loadingCountries = true;
  bool loadingChats = true;
  String chatsError = "";
  String countriesError = "";
  int lastTotalUnread = 0;
  bool countriesLoadedOnce = false;
  bool biometricEnabled = false;
  bool loadingProfilePics = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    selectedCountry = widget.initialCountry;
    loadAll();
    _checkBiometricEnabled();
    timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => loadAll(silent: true),
    );
    // הודעה חדשה (realtime) מרעננת את רשימת הצ'אטים מיד
    realtimeTick.addListener(_onChatsRealtimeTick);
  }

  void _onChatsRealtimeTick() {
    if (mounted) loadAll(silent: true);
  }

  Future<void> _checkBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted)
      setState(
        () => biometricEnabled =
            prefs.getBool("bio_${widget.currentUser}") == true,
      );
  }

  @override
  void dispose() {
    timer?.cancel();
    realtimeTick.removeListener(_onChatsRealtimeTick);
    super.dispose();
  }

  Future<void> loadAll({bool silent = false}) async {
    await Future.wait([
      loadCountries(silent: silent),
      loadChats(selectedCountry, silent: silent),
    ]);
    fetchMissingProfilePics();
  }

  Future<void> fetchMissingProfilePics() async {
    if (loadingProfilePics) return;
    final missing = chats
        .where(
          (x) =>
              "${x["wa_id"] ?? ""}".trim().isNotEmpty &&
              "${x["profile_pic"] ?? ""}".trim().isEmpty,
        )
        .take(8)
        .toList();
    if (missing.isEmpty) return;

    loadingProfilePics = true;
    try {
      for (final chat in missing) {
        final waId = "${chat["wa_id"] ?? ""}".trim();
        final country = "${chat["country"] ?? selectedCountry}".trim();
        if (waId.isEmpty) continue;
        try {
          final r = await http
              .post(
                Uri.parse("$api/api/fetch_profile_pic"),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode({"wa_id": waId, "country": country}),
              )
              .timeout(const Duration(seconds: 6));
          if (r.statusCode == 200 && r.body.trimLeft().startsWith("{")) {
            final data = jsonDecode(r.body);
            final url = "${data["url"] ?? ""}".trim();
            if (data["ok"] == true && url.isNotEmpty && mounted) {
              setState(() => chat["profile_pic"] = url);
            }
          }
        } catch (_) {}
      }
    } finally {
      loadingProfilePics = false;
    }
  }

  Future<void> loadCountries({bool silent = false}) async {
    if (!silent) {
      loadingCountries = true;
      countriesError = "";
      if (mounted) setState(() {});
    }

    try {
      final r = await http
          .get(Uri.parse("$api/api/countries"))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode < 200 || r.statusCode >= 300) {
        throw Exception("countries ${r.statusCode}");
      }
      final data = jsonDecode(r.body);
      countries = data is List ? data : [];
      countriesLoadedOnce = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("cached_countries", jsonEncode(countries));
      final newUnread = countries.fold<int>(
        0,
        (sum, item) => sum + (int.tryParse("${item["unread"] ?? 0}") ?? 0),
      );

      if (countriesLoadedOnce &&
          lastTotalUnread > 0 &&
          newUnread > lastTotalUnread &&
          mounted) {
        playIncomingAlert();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("🔔 הודעה חדשה נכנסה")));
      }
      lastTotalUnread = newUnread;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString("cached_countries");
      if (cached != null && cached.isNotEmpty && countries.isEmpty) {
        final data = jsonDecode(cached);
        if (data is List) {
          countries = data;
          countriesLoadedOnce = true;
        }
      }
      if (!silent && countries.isEmpty) {
        countriesError = "לא הצלחתי לטעון מדינות. נסה שוב.";
      }
    } finally {
      loadingCountries = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> loadChats(String country, {bool silent = false}) async {
    selectedCountry = country;

    if (!silent) {
      loadingChats = true;
      chatsError = "";
      if (mounted) setState(() {});
    }

    try {
      final uri = Uri.parse("$api/api/chats").replace(
        queryParameters: {"country": country, "username": widget.currentUser},
      );
      final r = await http.get(uri).timeout(const Duration(seconds: 8));
      if (r.statusCode < 200 || r.statusCode >= 300) {
        throw Exception("chats ${r.statusCode}");
      }
      final data = jsonDecode(r.body);
      chats = data is List ? data : [];
    } catch (_) {
      if (!silent) chatsError = "השרת לא החזיר שיחות. בדוק אינטרנט ונסה שוב.";
    } finally {
      loadingChats = false;
      if (mounted) setState(() {});
    }
  }

  List get filteredChats {
    final q = search.trim().toLowerCase();
    if (q.isEmpty) return chats;
    return chats.where((x) {
      final name = "${x["name"] ?? ""}".toLowerCase();
      final phone = "${x["wa_id"] ?? ""}".toLowerCase();
      return name.contains(q) || phone.contains(q);
    }).toList();
  }

  String _countryCodeOf(dynamic value) {
    final raw = "$value".trim().toLowerCase();
    return raw.replaceAll(" ", "_");
  }

  int _chatUnread(dynamic chat) {
    for (final key in const ["unread", "unread_count", "unreadCount"]) {
      final value = int.tryParse("${chat[key] ?? 0}") ?? 0;
      if (value > 0) return value;
    }
    return 0;
  }

  int countryUnread(dynamic x) {
    final apiUnread = int.tryParse("${x["unread"] ?? 0}") ?? 0;
    final code = _countryCodeOf(x["code"] ?? "");
    if (code.isEmpty) return apiUnread;

    final localUnread = chats.fold<int>(0, (sum, chat) {
      final chatCountry = _countryCodeOf(
        chat["country"] ?? chat["country_code"] ?? chat["code"] ?? "",
      );
      if (chatCountry != code) return sum;
      return sum + _chatUnread(chat);
    });
    return apiUnread > localUnread ? apiUnread : localUnread;
  }

  Future<bool> updateChatTag(dynamic chat, String tag) async {
    final waId = "${chat["wa_id"] ?? ""}".trim();
    if (waId.isEmpty) return false;
    final oldTag = "${chat["tag"] ?? ""}";
    setState(() => chat["tag"] = tag);
    try {
      final res = await http
          .post(
            Uri.parse("$api/api/set_tag"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"wa_id": waId, "tag": tag}),
          )
          .timeout(const Duration(seconds: 8));
      if (!res.body.trimLeft().startsWith("{")) {
        throw Exception("השרת לא מעודכן. צריך להעלות את קובץ האתר המעודכן.");
      }
      final data = jsonDecode(res.body);
      if (res.statusCode >= 300 || data["ok"] != true) {
        throw Exception(data["error"] ?? res.statusCode);
      }
      await loadAll(silent: true);
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() => chat["tag"] = oldTag);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("שמירת תגית נכשלה: $e")));
      return false;
    }
  }

  Future<void> deleteChat(dynamic chat) async {
    final waId = "${chat["wa_id"] ?? ""}".trim();
    final name = "${chat["name"] ?? waId}".trim();
    if (waId.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff111827),
        title: const Text("למחוק צ׳אט?", style: TextStyle(color: Colors.white)),
        content: Text(
          "הצ׳אט עם ${name.isEmpty ? waId : name} יימחק מהרשימה ומההודעות אצלך.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ביטול"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("מחק"),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final res = await http
          .post(
            Uri.parse("$api/api/delete_chat"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"wa_id": waId}),
          )
          .timeout(const Duration(seconds: 8));
      if (!res.body.trimLeft().startsWith("{")) {
        throw Exception("השרת לא מעודכן. צריך להעלות את קובץ האתר המעודכן.");
      }
      final data = jsonDecode(res.body);
      if (res.statusCode >= 300 || data["ok"] != true) {
        throw Exception(data["error"] ?? res.statusCode);
      }
      setState(() => chats.removeWhere((x) => "${x["wa_id"]}" == waId));
      await loadAll(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("מחיקת צ׳אט נכשלה: $e")));
    }
  }

  Future<void> toggleBlockChat(dynamic chat, bool blocked) async {
    final waId = "${chat["wa_id"] ?? ""}".trim();
    if (waId.isEmpty) return;
    final oldValue = chat["blocked"] == true;
    setState(() => chat["blocked"] = blocked);
    try {
      final res = await http
          .post(
            Uri.parse("$api/api/block_chat"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"wa_id": waId, "blocked": blocked}),
          )
          .timeout(const Duration(seconds: 8));
      if (!res.body.trimLeft().startsWith("{")) {
        throw Exception("השרת לא מעודכן. צריך להעלות את קובץ האתר המעודכן.");
      }
      final data = jsonDecode(res.body);
      if (res.statusCode >= 300 || data["ok"] != true) {
        throw Exception(data["error"] ?? res.statusCode);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(blocked ? "איש הקשר נחסם" : "איש הקשר נפתח")),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => chat["blocked"] = oldValue);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("עדכון חסימה נכשל: $e")));
    }
  }

  Future<void> chooseProfilePicForChat(dynamic chat) async {
    final waId = "${chat["wa_id"] ?? ""}".trim();
    if (waId.isEmpty) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 900,
        requestFullMetadata: false,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final ext = picked.name.contains(".")
          ? picked.name.split(".").last.toLowerCase()
          : "jpg";
      final safeExt = ["jpg", "jpeg", "png", "webp"].contains(ext)
          ? ext
          : "jpg";
      final uploadName = "profile_$waId.$safeExt";
      final req = http.MultipartRequest(
        "POST",
        Uri.parse("$api/api/set_profile_pic"),
      );
      req.headers["X-App-User"] = widget.currentUser;
      req.headers["X-App-Pin"] = userPin(widget.currentUser);
      req.fields["wa_id"] = waId;
      req.files.add(
        http.MultipartFile.fromBytes(
          "file",
          bytes,
          filename: uploadName,
          contentType: safeExt == "png"
              ? MediaType("image", "png")
              : safeExt == "webp"
              ? MediaType("image", "webp")
              : MediaType("image", "jpeg"),
        ),
      );

      final res = await req.send().timeout(const Duration(seconds: 20));
      final body = await res.stream.bytesToString();
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(body);
        final profilePic = "${data["profile_pic"] ?? ""}".trim();
        if (profilePic.isNotEmpty && mounted) {
          setState(() => chat["profile_pic"] = profilePic);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✅ תמונת הלקוח נשמרה")));
        await loadAll(silent: true);
      } else {
        throw Exception(body.isEmpty ? res.statusCode : body);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("שמירת תמונה נכשלה. בדוק הרשאת תמונות באייפון: $e"),
        ),
      );
    }
  }

  void showChatActions(dynamic chat) {
    final name = "${chat["name"] ?? ""}".trim();
    final waId = "${chat["wa_id"] ?? ""}".trim();
    final blocked = chat["blocked"] == true || "${chat["blocked"]}" == "1";
    final tagColors = {
      "VIP": Colors.amber,
      "ממתין": Colors.orange,
      "טופל": Colors.green,
      "חשוב": Colors.red,
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                child: Column(
                  children: [
                    Text(
                      name.isEmpty ? waId : name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(waId, style: const TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
              const Divider(color: Colors.white12),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "תגיות",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ...["VIP", "ממתין", "טופל", "חשוב", ""].map(
                (t) => ListTile(
                  leading: t.isEmpty
                      ? const Icon(Icons.label_off, color: Colors.grey)
                      : CircleAvatar(
                          radius: 8,
                          backgroundColor: tagColors[t] ?? Colors.blue,
                        ),
                  title: Text(
                    t.isEmpty ? "הסר תגית" : t,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await updateChatTag(chat, t);
                  },
                ),
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: const Icon(
                  Icons.add_a_photo,
                  color: Color(0xff00d4ff),
                ),
                title: const Text(
                  "הוסף / החלף תמונת לקוח",
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  "בחר תמונה מהגלריה שתופיע בעיגול",
                  style: TextStyle(color: Colors.white54),
                ),
                onTap: () {
                  Navigator.pop(context);
                  unawaited(chooseProfilePicForChat(chat));
                },
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: Icon(
                  blocked ? Icons.lock_open : Icons.block,
                  color: blocked ? Colors.greenAccent : Colors.orangeAccent,
                ),
                title: Text(
                  blocked ? "פתח איש קשר" : "חסום איש קשר",
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  blocked
                      ? "מאפשר שוב לשלוח הודעות לאיש קשר זה"
                      : "מונע שליחת הודעות לאיש קשר זה מהמערכת",
                  style: const TextStyle(color: Colors.white54),
                ),
                onTap: () {
                  Navigator.pop(context);
                  unawaited(toggleBlockChat(chat, !blocked));
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  "מחק צ׳אט",
                  style: TextStyle(color: Colors.redAccent),
                ),
                subtitle: const Text(
                  "מוחק את השיחה אצלך במערכת",
                  style: TextStyle(color: Colors.white54),
                ),
                onTap: () {
                  Navigator.pop(context);
                  unawaited(deleteChat(chat));
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = filteredChats;
    final lightMode = appLightMode.value;
    final totalCountryUnread = countries.fold<int>(
      0,
      (sum, country) => sum + countryUnread(country),
    );

    return Scaffold(
      backgroundColor: lightMode
          ? const Color(0xffeef2f7)
          : const Color(0xff050d1a),
      appBar: AppBar(
        backgroundColor: lightMode
            ? const Color(0xffffffff)
            : const Color(0xff040e1c),
        foregroundColor: lightMode ? const Color(0xff2a2f32) : Colors.white,
        title: const Text(
          "cozycrafts chat",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () => loadAll(),
            icon: AnimatedRotation(
              turns: (loadingCountries || loadingChats) ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (loadingCountries || loadingChats)
                      ? const Color(0xffff2f3f)
                      : appLightMode.value
                      ? const Color(0xff2a2f32)
                      : Colors.white.withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: (loadingCountries || loadingChats)
                          ? const Color(0xffff2f3f).withValues(alpha: 0.5)
                          : Colors.transparent,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "⌘",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const PinPage()),
                );
              },
              icon: const Icon(Icons.lock),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(102),
          child: _TopButtonsBar(
            buttons: [
              if (isManagerUser(widget.currentUser))
                _TopChip(
                  label: "ניהול",
                  color: const Color(0xffc39bff),
                  child: IconButton(
                    tooltip: "ניהול",
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AdminPage(currentUser: widget.currentUser),
                        ),
                      );
                    },
                    icon: const Icon(Icons.admin_panel_settings),
                  ),
                ),
              _TopChip(
                label: "AI",
                color: const Color(0xffffd54f),
                child: IconButton(
                  tooltip: "Cozy AI",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CozyAiPage(currentUser: widget.currentUser),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome),
                ),
              ),
              _TopChip(
                label: "מיקומים",
                color: const Color(0xff69f0ae),
                child: IconButton(
                  tooltip: "מיקומים שמורים",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SavedLocationsPage(currentUser: widget.currentUser),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_outlined),
                ),
              ),
              _TopChip(
                label: lightMode ? "לילה" : "יום",
                color: const Color(0xffffab40),
                child: IconButton(
                  tooltip: lightMode ? "מצב כהה" : "מצב בהיר",
                  onPressed: () {
                    appLightMode.value = !appLightMode.value;
                    setState(() {});
                  },
                  icon: Icon(lightMode ? Icons.dark_mode : Icons.light_mode),
                ),
              ),
              _TopChip(
                label: biometricName,
                color: const Color(0xff40c4ff),
                child: IconButton(
                  tooltip: biometricEnabled
                      ? "בטל כניסה עם $biometricName"
                      : "הפעל כניסה עם $biometricName",
                  onPressed: () async {
                    try {
                      final canAuth = await canUseFaceUnlock();
                      if (!canAuth) {
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "$biometricName לא זמין או לא מוגדר במכשיר",
                              ),
                            ),
                          );
                        return;
                      }
                      if (biometricEnabled) {
                        // כיבוי
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove("bio_${widget.currentUser}");
                        await clearSavedPin(widget.currentUser);
                        if (mounted) setState(() => biometricEnabled = false);
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("🔓 כניסה עם $biometricName בוטלה"),
                            ),
                          );
                      } else {
                        // הפעלה
                        final auth = await askFaceUnlock();
                        if (!auth) return;
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool("bio_${widget.currentUser}", true);
                        await savePinSecurely(
                          widget.currentUser,
                          userPin(widget.currentUser),
                        );
                        if (mounted) setState(() => biometricEnabled = true);
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "✅ כניסה עם $biometricName הופעלה עבור ${widget.currentUser}",
                              ),
                            ),
                          );
                      }
                    } catch (e) {
                      if (context.mounted)
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("שגיאה: $e")));
                    }
                  },
                  icon: Icon(
                    biometricLoginIcon,
                    color: appLightMode.value
                        ? const Color(0xff2a2f32)
                        : biometricEnabled
                        ? const Color(0xff00d4ff)
                        : Colors.white38,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          final chatColumn = Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  onChanged: (v) => setState(() => search = v),
                  decoration: InputDecoration(
                    hintText: "🔍 חיפוש לקוח / מספר",
                    filled: true,
                    fillColor: appLightMode.value
                        ? Colors.white
                        : const Color(0xff071525),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: loadingChats
                    ? const Center(child: CircularProgressIndicator())
                    : chatsError.isNotEmpty
                    ? _LoadError(
                        message: chatsError,
                        onRetry: () => loadChats(selectedCountry),
                      )
                    : list.isEmpty
                    ? const Center(
                        child: Text(
                          "אין שיחות להצגה",
                          style: TextStyle(fontSize: 22),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: list.length,
                        itemBuilder: (context, i) => chatCard(list[i]),
                      ),
              ),
            ],
          );

          final countryItems = loadingCountries
              ? const Center(child: CircularProgressIndicator())
              : countriesError.isNotEmpty
              ? _LoadError(message: countriesError, onRetry: loadAll)
              : ListView(
                  scrollDirection: Axis.vertical,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    countryCircle("🌍", "הכל", "all", totalCountryUnread, true),
                    ...countries.map((x) {
                      final code = "${x["code"] ?? ""}";
                      return countryCircle(
                        "${x["flag"] ?? "🌍"}",
                        _countryNameHebrew(code, "${x["name"] ?? ""}"),
                        code,
                        countryUnread(x),
                        x["token"] == true,
                      );
                    }),
                  ],
                );

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                Container(
                  width: MediaQuery.sizeOf(context).width < 390 ? 86 : 94,
                  decoration: BoxDecoration(
                    color: lightMode ? Colors.white : const Color(0xff071525),
                    border: Border(
                      left: BorderSide(
                        color: lightMode
                            ? const Color(0xffd1d7db)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: countryItems,
                ),
                Expanded(child: chatColumn),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget countryCircle(
    String flag,
    String name,
    String code,
    int unread,
    bool hasToken,
  ) {
    final active = selectedCountry == code;
    final compact = MediaQuery.sizeOf(context).width < 390;
    final hasUnread = unread > 0;

    return GestureDetector(
      onTap: () => loadChats(code),
      child: Container(
        width: compact ? 72 : 78,
        margin: EdgeInsets.symmetric(horizontal: 5, vertical: compact ? 3 : 4),
        decoration: BoxDecoration(
          color: active
              ? (appLightMode.value
                    ? const Color(0xffe8eaed)
                    : const Color(0xff071e30))
              : (appLightMode.value
                    ? const Color(0xfff0f4ff)
                    : const Color(0xff071525)),
          borderRadius: BorderRadius.circular(compact ? 12 : 14),
          border: Border.all(
            color: hasUnread
                ? const Color(0xffff3b3b)
                : active
                ? (appLightMode.value
                      ? const Color(0xff2a2f32)
                      : const Color(0xff00d4ff))
                : (appLightMode.value
                      ? const Color(0xff111b21)
                      : Colors.white.withValues(alpha: 0.1)),
            width: hasUnread
                ? 3
                : active
                ? (appLightMode.value ? 3 : 2)
                : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  (hasUnread
                          ? const Color(0xffff3b3b)
                          : (hasToken
                                ? (appLightMode.value
                                      ? const Color(0xff9aa5ad)
                                      : Colors.greenAccent)
                                : const Color(0xff00d4ff)))
                      .withValues(alpha: hasUnread ? 0.75 : 0.12),
              blurRadius: hasUnread ? 24 : 12,
              spreadRadius: hasUnread ? 1.5 : 0,
            ),
            if (hasUnread)
              BoxShadow(
                color: const Color(0xffff3b3b).withValues(alpha: 0.55),
                blurRadius: 34,
                spreadRadius: 4,
              ),
          ],
        ),
        child: Stack(
          children: [
            if (hasUnread)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Color(0xffff3b3b),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(18),
                    ),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(flag, style: TextStyle(fontSize: compact ? 23 : 26)),
                  SizedBox(height: compact ? 1 : 2),
                  Icon(
                    Icons.circle,
                    size: compact ? 6 : 7,
                    color: hasUnread
                        ? const Color(0xffff3b3b)
                        : (hasToken
                              ? (appLightMode.value
                                    ? const Color(0xff9aa5ad)
                                    : Colors.greenAccent)
                              : Colors.grey),
                  ),
                  SizedBox(height: compact ? 1 : 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: compact ? 10.5 : 11,
                        fontWeight: FontWeight.w700,
                        color: appLightMode.value
                            ? const Color(0xff0c1b2e)
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (hasUnread)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffff3b3b),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xffff3b3b).withValues(alpha: 0.75),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    unread > 99 ? "99+" : "$unread",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget chatCard(dynamic x) {
    final name = "${x["name"] ?? ""}".trim();
    final waId = "${x["wa_id"] ?? ""}";
    final unread = int.tryParse("${x["unread"] ?? 0}") ?? 0;
    final lastSeen = "${x["last_seen"] ?? ""}";
    final online = x["online"] == true;
    final tag = "${x["tag"] ?? ""}".trim();
    final blocked = x["blocked"] == true || "${x["blocked"]}" == "1";
    final profilePic = mediaUrl("${x["profile_pic"] ?? ""}");
    final fallbackColor = avatarFallbackColor("$waId$name");

    Future<void> openChat() async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            waId: waId,
            name: name.isEmpty ? waId : name,
            country: "${x["country"] ?? selectedCountry}",
            currentUser: widget.currentUser,
          ),
        ),
      );
      loadAll(silent: true);
    }

    Widget avatar() {
      return Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xff101b2c),
          border: Border.all(
            color: profilePic.isNotEmpty
                ? Colors.white.withValues(alpha: 0.90)
                : fallbackColor.withValues(alpha: 0.95),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: profilePic.isNotEmpty
              ? Image.network(
                  profilePic,
                  width: 45,
                  height: 45,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _avatarFallback(name, 21, fallbackColor),
                )
              : _avatarFallback(name, 21, fallbackColor),
        ),
      );
    }

    Widget tagChip() {
      final color =
          {
            "VIP": Colors.amber,
            "ממתין": Colors.orange,
            "טופל": Colors.green,
            "חשוב": Colors.red,
          }[tag] ??
          Colors.blue;
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text("🏷️ $tag", style: TextStyle(fontSize: 10, color: color)),
      );
    }

    return InkWell(
      onTap: openChat,
      onLongPress: () => showChatActions(x),
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: appLightMode.value
              ? const Color(0xffffffff)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: (appLightMode.value ? Colors.black : Colors.white)
                  .withValues(alpha: 0.10),
            ),
          ),
        ),
        child: Row(
          children: [
            avatar(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name.isEmpty ? "ללא שם" : name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: appLightMode.value
                                ? Colors.black87
                                : Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _BroadcastExcludeButton(
                        waId: waId,
                        currentUser: widget.currentUser,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "📞 $waId",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: appLightMode.value
                          ? Colors.black54
                          : Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    online
                        ? "🟢 זמין"
                        : (lastSeen.isEmpty
                              ? "⚫ לא מחובר"
                              : "נראה לאחרונה $lastSeen"),
                    style: TextStyle(
                      fontSize: 12,
                      color: online ? Colors.greenAccent : Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (tag.isNotEmpty) tagChip(),
                  if (blocked)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: const Text(
                        "🚫 חסום",
                        style: TextStyle(fontSize: 11, color: Colors.redAccent),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Tooltip(
                  message: "פעולות: תגית / חסימה / מחיקה",
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => showChatActions(x),
                    child: Container(
                      width: 42,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: appLightMode.value
                            ? const Color(0xff2a2f32).withValues(alpha: 0.13)
                            : const Color(0xff00d4ff).withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: appLightMode.value
                              ? const Color(0xff2a2f32).withValues(alpha: 0.4)
                              : const Color(0xff00d4ff).withValues(alpha: 0.32),
                        ),
                      ),
                      child: Icon(
                        Icons.more_horiz,
                        color: appLightMode.value
                            ? const Color(0xff2a2f32)
                            : Colors.white,
                        size: 25,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                unread > 0
                    ? CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.red,
                        child: Text(
                          "$unread",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    : const Icon(Icons.chevron_left, size: 22),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(String name, double fontSize, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.20) ?? color,
            color,
            Color.lerp(color, Colors.black, 0.18) ?? color,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : "👤",
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _BroadcastExcludeButton extends StatefulWidget {
  final String waId;
  final String currentUser;
  const _BroadcastExcludeButton({
    required this.waId,
    required this.currentUser,
  });

  @override
  State<_BroadcastExcludeButton> createState() =>
      _BroadcastExcludeButtonState();
}

class _BroadcastExcludeButtonState extends State<_BroadcastExcludeButton> {
  bool excluded = false;
  bool busy = false;

  Future<void> _toggle() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final res = await http
          .post(
            Uri.parse("$api/api/toggle_broadcast_exclude/${widget.waId}"),
            headers: {
              "X-App-User": widget.currentUser,
              "X-App-Pin": userPin(widget.currentUser),
            },
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => excluded = data["excluded"] == true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 2),
              content: Text(
                excluded
                    ? "🚫 לקוח לא ייכלל בשליחה כוללת"
                    : "✅ לקוח יכלל שוב בשליחה כוללת",
              ),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("שגיאה (${res.statusCode})")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("שגיאת רשת: $e")));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.do_not_disturb_on_outlined,
          size: 22,
          color: excluded
              ? const Color(0xffff3b3b)
              : (appLightMode.value ? Colors.black45 : Colors.white38),
        ),
      ),
    );
  }
}

class _ChatDoodlePainter extends CustomPainter {
  final bool isDark;
  _ChatDoodlePainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xffd8d0c4).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    const tile = 100.0;
    final cols = (size.width / tile).ceil() + 1;
    final rows = (size.height / tile).ceil() + 1;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final ox = c * tile;
        final oy = r * tile;
        canvas.drawCircle(Offset(ox + 15, oy + 15), 6, paint);
        final diamond = ui.Path()
          ..moveTo(ox + 40, oy + 12)
          ..lineTo(ox + 46, oy + 18)
          ..lineTo(ox + 40, oy + 24)
          ..lineTo(ox + 34, oy + 18)
          ..close();
        canvas.drawPath(diamond, paint);
        canvas.drawCircle(Offset(ox + 70, oy + 16), 6, paint);
        canvas.drawLine(
          Offset(ox + 10, oy + 45),
          Offset(ox + 18, oy + 45),
          paint,
        );
        canvas.drawLine(
          Offset(ox + 14, oy + 41),
          Offset(ox + 14, oy + 49),
          paint,
        );
        canvas.drawCircle(Offset(ox + 50, oy + 45), 4, paint);
        final tri = ui.Path()
          ..moveTo(ox + 80, oy + 40)
          ..lineTo(ox + 85, oy + 48)
          ..lineTo(ox + 75, oy + 48)
          ..close();
        canvas.drawPath(tri, paint);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(ox + 28, oy + 70), radius: 8),
          3.4,
          2.9,
          false,
          paint,
        );
        final diamond2 = ui.Path()
          ..moveTo(ox + 62, oy + 65)
          ..lineTo(ox + 69, oy + 72)
          ..lineTo(ox + 62, oy + 79)
          ..lineTo(ox + 55, oy + 72)
          ..close();
        canvas.drawPath(diamond2, paint);
        canvas.drawCircle(Offset(ox + 85, oy + 75), 5, paint);
        canvas.drawLine(
          Offset(ox + 5, oy + 90),
          Offset(ox + 15, oy + 90),
          paint,
        );
        canvas.drawLine(
          Offset(ox + 10, oy + 85),
          Offset(ox + 10, oy + 95),
          paint,
        );
        canvas.drawCircle(Offset(ox + 75, oy + 95), 4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChatDoodlePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 42, color: Colors.orangeAccent),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("נסה שוב"),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// ADMIN PAGE — ניהול משתמשים + לוג פעולות מלא
// =====================================================

enum _AdminTab { users, messages, sent }

class AdminPage extends StatefulWidget {
  const AdminPage({super.key, required this.currentUser});
  final String currentUser;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool loading = true;
  bool cozyAiEnabled = true;
  bool saving = false;
  bool clearingLogs = false;
  String error = "";
  List users = [];
  List logs = [];
  List sentMessages = [];
  bool loadingSent = false;
  int deletingId = -1;
  int sentPage = 1;
  int sentTotal = 0;
  String _sentFilterUser = "all";
  _AdminTab _tab = _AdminTab.users;

  // סינון לוג
  String _logFilterUser = "all";

  @override
  void initState() {
    super.initState();
    loadAdmin();
    if (isSuperAdminUser(widget.currentUser)) loadCozyAiStatus();
  }

  Future<void> loadSentMessages({bool reset = false}) async {
    if (loadingSent) return;
    if (reset) {
      sentPage = 1;
      sentMessages = [];
    }
    setState(() => loadingSent = true);
    try {
      final body = adminBody({
        "page": sentPage,
        "per_page": 50,
        "user_filter": _sentFilterUser == "all" ? "" : _sentFilterUser,
      });
      final r = await http
          .post(
            Uri.parse("$api/api/admin/sent_messages"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(r.body);
      if (r.statusCode >= 300 || data["ok"] != true) throw Exception();
      final newMsgs = data["messages"] is List ? data["messages"] : [];
      sentTotal = (data["total"] as num?)?.toInt() ?? 0;
      if (reset) {
        sentMessages = newMsgs;
      } else {
        sentMessages = [...sentMessages, ...newMsgs];
      }
      sentPage++;
    } catch (_) {
    } finally {
      loadingSent = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> deleteMessage(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("מחק הודעה?"),
        content: const Text("ההודעה תימחק לצמיתות מהמסד."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ביטול"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("מחק"),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => deletingId = id);
    try {
      final r = await http
          .post(
            Uri.parse("$api/api/admin/delete_message"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(adminBody({"id": id})),
          )
          .timeout(const Duration(seconds: 8));
      final data = jsonDecode(r.body);
      if (r.statusCode >= 300 || data["ok"] != true) throw Exception();
      sentMessages.removeWhere((m) => m["id"] == id);
      sentTotal--;
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("שגיאה במחיקת ההודעה")));
    } finally {
      deletingId = -1;
      if (mounted) setState(() {});
    }
  }

  Map<String, dynamic> adminBody([Map<String, dynamic>? extra]) => {
    "user": widget.currentUser,
    "pin": userPin(widget.currentUser),
    ...?extra,
  };

  Future<void> loadAdmin({bool silent = false}) async {
    if (!silent)
      setState(() {
        loading = true;
        error = "";
      });
    try {
      final r = await http
          .post(
            Uri.parse("$api/api/admin/summary"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(adminBody()),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(r.body);
      if (r.statusCode >= 300 || data["ok"] != true) {
        throw Exception("${data["error"] ?? r.statusCode}");
      }
      users = data["users"] is List ? data["users"] : [];
      logs = data["logs"] is List ? data["logs"] : [];
    } catch (_) {
      if (!silent) error = "לא הצלחתי לטעון. ודא שעדכנת את השרת.";
    } finally {
      loading = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> loadCozyAiStatus() async {
    try {
      final response = await http
          .get(Uri.parse("$api/api/cozy-ai/status"))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      // המתג עצמו (לכולם). "enabled" לאדמין תמיד true, לכן מציגים את global_enabled
      if (mounted) {
        setState(
          () => cozyAiEnabled =
              (data["global_enabled"] ?? data["enabled"]) == true,
        );
      }
    } catch (_) {}
  }

  Future<void> setCozyAiEnabled(bool enabled) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final response = await http
          .post(
            Uri.parse("$api/api/admin/cozy-ai"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(adminBody({"enabled": enabled})),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (response.statusCode >= 300 || data["ok"] != true) {
        throw Exception();
      }
      if (mounted) setState(() => cozyAiEnabled = enabled);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("לא הצלחתי לעדכן את Cozy AI")),
        );
      }
      await loadCozyAiStatus();
    } finally {
      saving = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> setUserEnabled(String username, bool enabled) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final r = await http
          .post(
            Uri.parse("$api/api/admin/user_status"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(
              adminBody({"username": username, "enabled": enabled}),
            ),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(r.body);
      if (r.statusCode >= 300 || data["ok"] != true) {
        throw Exception("${data["error"] ?? r.statusCode}");
      }
      await loadAdmin(silent: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("לא הצלחתי לעדכן משתמש")));
      }
    } finally {
      saving = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> clearLogs() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("מחק את כל הלוג?"),
        content: const Text("פעולה זו תמחק את כל היסטוריית הפעולות לצמיתות."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("ביטול"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("מחק הכל"),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => clearingLogs = true);
    try {
      final r = await http
          .post(
            Uri.parse("$api/api/admin/clear_logs"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(adminBody()),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(r.body);
      if (r.statusCode >= 300 || data["ok"] != true) {
        throw Exception("${data["error"] ?? r.statusCode}");
      }
      await loadAdmin(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("✅ הלוג נמחק")));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("שגיאה במחיקת הלוג")));
      }
    } finally {
      clearingLogs = false;
      if (mounted) setState(() {});
    }
  }

  String _actionIcon(String action) {
    if (action.contains("send") || action.contains("POST /api/send"))
      return "📤";
    if (action.contains("upload")) return "📎";
    if (action.contains("login") || action.contains("GET /")) return "🔐";
    if (action.contains("block") || action.contains("disabled")) return "🚫";
    if (action.contains("enabled")) return "✅";
    if (action.contains("forward")) return "↪️";
    if (action.contains("translate")) return "🌍";
    return "•";
  }

  List get _filteredLogs {
    if (_logFilterUser == "all") return logs;
    return logs.where((l) => "${l["username"]}" == _logFilterUser).toList();
  }

  List<String> get _logUsers {
    final seen = <String>{};
    for (final l in logs) {
      final u = "${l["username"] ?? ""}";
      if (u.isNotEmpty) seen.add(u);
    }
    return seen.toList();
  }

  @override
  Widget build(BuildContext context) {
    final light = appLightMode.value;
    final bg = light ? const Color(0xfff2f6fa) : const Color(0xff050d1a);
    final appBg = light ? const Color(0xff0d47a1) : const Color(0xff07111e);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: appBg,
        title: const Text(
          "🛡️ ניהול",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          if (_tab == _AdminTab.messages && logs.isNotEmpty)
            IconButton(
              tooltip: "מחק לוג",
              icon: clearingLogs
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_forever, color: Colors.redAccent),
              onPressed: clearingLogs ? null : clearLogs,
            ),
          if (_tab == _AdminTab.sent)
            IconButton(
              tooltip: "רענן",
              icon: loadingSent
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: loadingSent
                  ? null
                  : () => loadSentMessages(reset: true),
            )
          else
            IconButton(
              onPressed: () => loadAdmin(),
              icon: const Icon(Icons.refresh),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tab = _AdminTab.users),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _tab == _AdminTab.users
                              ? const Color(0xff00e5ff)
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      "👥 משתמשים",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _tab == _AdminTab.users
                            ? const Color(0xff00e5ff)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _tab = _AdminTab.sent);
                    if (sentMessages.isEmpty) loadSentMessages(reset: true);
                  },
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _tab == _AdminTab.sent
                              ? Colors.orangeAccent
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      "📨 נשלחו",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _tab == _AdminTab.sent
                            ? Colors.orangeAccent
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tab = _AdminTab.messages),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _tab == _AdminTab.messages
                              ? const Color(0xff00d4ff)
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      "📋 לוג",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _tab == _AdminTab.messages
                            ? const Color(0xff00d4ff)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? _LoadError(message: error, onRetry: loadAdmin)
          : _tab == _AdminTab.users
          ? _buildUsersTab(light)
          : _tab == _AdminTab.sent
          ? _buildSentTab(light)
          : _buildLogsTab(light),
    );
  }

  Widget _buildUsersTab(bool light) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (isSuperAdminUser(widget.currentUser))
        Card(
          color: cozyAiEnabled
              ? Colors.green.withValues(alpha: 0.14)
              : Colors.red.withValues(alpha: 0.16),
          child: SwitchListTile(
            secondary: Icon(
              cozyAiEnabled ? Icons.smart_toy : Icons.lock,
              color: cozyAiEnabled ? Colors.greenAccent : Colors.redAccent,
            ),
            title: Text(
              cozyAiEnabled
                  ? "🤖 Cozy AI — פעיל לכולם 🟢"
                  : "🤖 Cozy AI — כבוי לכולם 🔴 (רק לך פתוח)",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text("שליטה ב-Cozy AI באפליקציה ובאתר"),
            value: cozyAiEnabled,
            onChanged: saving ? null : setCozyAiEnabled,
          ),
        ),
        const Divider(),
        ...users.map((u) => _userCard(u, light)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _userCard(dynamic user, bool light) {
    final username = "${user["username"] ?? ""}";
    final label = "${user["display_name"] ?? username}";
    final role = "${user["role"] ?? "user"}";
    final enabled = user["enabled"] == true;
    final isAdmin = role == "admin";

    return Card(
      color: light ? const Color(0xfffafbff) : const Color(0xee0d1117),
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isAdmin
              ? Colors.amber.withValues(alpha: 0.5)
              : enabled
              ? Colors.greenAccent.withValues(alpha: 0.3)
              : Colors.redAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isAdmin
                  ? const Color(0xff0094cc)
                  : const Color(0xff005577),
              child: Icon(
                isAdmin ? Icons.admin_panel_settings : Icons.person,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: enabled ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          enabled ? "פעיל" : "חסום",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isAdmin ? "ניהול" : "יבואן",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // admin הראשי יכול לחסום גם את עידן (הנהלה); אף אחד לא חוסם את admin
            if (!isAdmin ||
                (isSuperAdminUser(widget.currentUser) &&
                    !isSuperAdminUser(username)))
              FilledButton(
                onPressed: saving
                    ? null
                    : () => setUserEnabled(username, !enabled),
                style: FilledButton.styleFrom(
                  backgroundColor: enabled
                      ? Colors.red.withValues(alpha: 0.85)
                      : (appLightMode.value
                            ? const Color(0xff2a2f32)
                            : const Color(0xff00d4ff)),
                  foregroundColor: enabled
                      ? Colors.white
                      : (appLightMode.value
                            ? Colors.white
                            : const Color(0xff001020)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  enabled ? "חסום" : "פתח",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              )
            else
              const Icon(Icons.lock_outline, color: Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildSentTab(bool light) {
    final allUsers = users.map((u) => "${u["username"] ?? ""}").toList();

    return Column(
      children: [
        // סינון לפי משתמש
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: light ? const Color(0xff0d47a1) : const Color(0xff07111e),
          child: Row(
            children: [
              const Text(
                "שולח: ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _sentChip("הכל", "all"),
                      ...allUsers.map((u) => _sentChip(u, u)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // סה"כ
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Text(
                "$sentTotal הודעות שנשלחו",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ),
        // רשימה
        Expanded(
          child: sentMessages.isEmpty && !loadingSent
              ? const Center(
                  child: Text("אין הודעות", style: TextStyle(fontSize: 18)),
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollEndNotification &&
                        n.metrics.pixels >= n.metrics.maxScrollExtent - 100 &&
                        !loadingSent &&
                        sentMessages.length < sentTotal) {
                      loadSentMessages();
                    }
                    return false;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                    itemCount: sentMessages.length + (loadingSent ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == sentMessages.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return _sentCard(sentMessages[i], light);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _sentChip(String label, String value) {
    final active = _sentFilterUser == value;
    return GestureDetector(
      onTap: () {
        setState(() => _sentFilterUser = value);
        loadSentMessages(reset: true);
      },
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xff00d4ff)
              : Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xff001020) : Colors.grey.shade400,
            fontWeight: active ? FontWeight.w900 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _sentCard(dynamic msg, bool light) {
    final id = msg["id"] is int
        ? msg["id"] as int
        : int.tryParse("${msg["id"] ?? 0}") ?? 0;
    final sender = "${msg["sender"] ?? ""}";
    final waId = "${msg["wa_id"] ?? ""}";
    final type = "${msg["type"] ?? "text"}";
    final text = "${msg["text"] ?? ""}".trim();
    final media = "${msg["media_file"] ?? ""}";
    final country = "${msg["country"] ?? ""}";
    final createdAt = "${msg["created_at"] ?? ""}";
    final isDeleting = deletingId == id;

    String typeIcon;
    switch (type) {
      case "audio":
        typeIcon = "🎤";
        break;
      case "image":
        typeIcon = "📷";
        break;
      case "video":
        typeIcon = "🎥";
        break;
      case "document":
        typeIcon = "📄";
        break;
      default:
        typeIcon = "💬";
        break;
    }

    return Card(
      color: light ? const Color(0xfffafafa) : const Color(0xff0a0e14),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orangeAccent.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // אייקון סוג
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(typeIcon, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // שולח + שעה
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                sender,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: Colors.orangeAccent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "← $waId",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.greenAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        createdAt.length > 16
                            ? createdAt.substring(5, 16)
                            : createdAt,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // מדינה
                  if (country.isNotEmpty)
                    Text(
                      "🌍 $country",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  // תוכן
                  if (text.isNotEmpty &&
                      text != "🎤 הודעה קולית" &&
                      text != "📷 תמונה")
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        text,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (media.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        "📎 $media",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            // כפתור מחיקה
            IconButton(
              icon: isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
              onPressed: isDeleting ? null : () => deleteMessage(id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsTab(bool light) {
    final filtered = _filteredLogs;
    final logUsers = _logUsers;

    return Column(
      children: [
        // סינון לפי משתמש
        if (logUsers.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: light ? const Color(0xff0d47a1) : const Color(0xff07111e),
            child: Row(
              children: [
                const Text(
                  "סינון: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip("הכל", "all"),
                        ...logUsers.map((u) => _filterChip(u, u)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        // מידע כמות
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Text(
                "${filtered.length} פעולות",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ),
        // רשימת לוג
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    "אין פעולות להצגה",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _logCard(filtered[i], light),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _logFilterUser == value;
    return GestureDetector(
      onTap: () => setState(() => _logFilterUser = value),
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xff00d4ff)
              : Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xff001020) : Colors.grey.shade400,
            fontWeight: active ? FontWeight.w900 : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _logCard(dynamic log, bool light) {
    final username = "${log["username"] ?? ""}";
    final action = "${log["action"] ?? ""}";
    final details = "${log["details"] ?? ""}".trim();
    final createdAt = "${log["created_at"] ?? ""}";
    final ip = "${log["ip"] ?? ""}";
    final icon = _actionIcon(action);

    // נסה לחלץ מידע ספציפי מה-details
    String? toNumber;
    String? msgPreview;
    if (details.isNotEmpty) {
      final toMatch = RegExp(r'to=(\S+)').firstMatch(details);
      if (toMatch != null) toNumber = toMatch.group(1);
      final msgMatch = RegExp(r'msg=(.+)').firstMatch(details);
      if (msgMatch != null) msgPreview = msgMatch.group(1)?.trim();
    }

    return Card(
      color: light ? const Color(0xffffffff) : const Color(0xff0a0e14),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // אייקון פעולה
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.blueGrey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // שם + שעה
                  Row(
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: const Color(0xff00d4ff),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        createdAt.length > 16
                            ? createdAt.substring(5, 16)
                            : createdAt,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // פעולה
                  Text(
                    action,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // למי
                  if (toNumber != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        "📞 $toNumber",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ),
                  // תוכן הודעה
                  if (msgPreview != null && msgPreview.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        "💬 $msgPreview",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade300,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else if (details.isNotEmpty && toNumber == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        details,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  // IP
                  if (ip.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        "🌐 $ip",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
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

class ChatPage extends StatefulWidget {
  final String waId;
  final String name;
  final String country;
  final String currentUser;

  const ChatPage({
    super.key,
    required this.waId,
    required this.name,
    required this.country,
    this.currentUser = "",
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final AudioPlayer chatAudioPlayer = AudioPlayer();
  List msgs = [];
  bool loading = true;
  bool sending = false;
  bool refreshing = false;
  bool _loadingMessages = false;
  Timer? timer;
  int lastCount = 0;
  String playingAudioUrl = "";
  String profilePicUrl = "";
  final Set<String> transcribingAudio = {};
  final Map<String, String> audioTranscripts = {};
  final txt = TextEditingController();
  final messageFocusNode = FocusNode();
  static const int longMessagePreviewLength = 420;
  Map<String, dynamic>? replyingTo;
  Set<String> pinnedMessageKeys = {};
  Set<String> favoriteMessageKeys = {};
  final Set<String> favoritePulseKeys = {};
  final Set<int> selectedMessageIds = {};
  dynamic focusedPinnedMessageId;
  bool _showFavoritesOnly = false;
  bool _emojiPanelOpen = false;

  Future<void> fetchProfilePic() async {
    try {
      final r = await http
          .post(
            Uri.parse("$api/api/fetch_profile_pic"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"wa_id": widget.waId, "country": widget.country}),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(r.body);
      if (data["ok"] == true && data["url"] != null && mounted) {
        setState(() => profilePicUrl = data["url"]);
        showSnack("✅ תמונת פרופיל עודכנה");
      } else {
        showSnack("לא נמצאה תמונת פרופיל");
      }
    } catch (e) {
      showSnack("שגיאה: $e");
    }
  }

  String get pinnedPrefsKey => "pinned_messages_${widget.waId}";
  String get favoritesPrefsKey => "favorite_messages_${widget.waId}";

  String pinKeyFor(dynamic m) {
    final id = "${m["id"] ?? ""}".trim();
    if (id.isNotEmpty && id != "null") return "id:$id";
    return "msg:${m["time"] ?? ""}|${m["media"] ?? ""}|${m["text"] ?? ""}";
  }

  String favoriteKeyFor(dynamic m) => pinKeyFor(m);

  Future<void> loadPinnedMessages() async {
    final prefs = await SharedPreferences.getInstance();
    pinnedMessageKeys = prefs.getStringList(pinnedPrefsKey)?.toSet() ?? {};
  }

  Future<void> savePinnedMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(pinnedPrefsKey, pinnedMessageKeys.toList());
  }

  Future<void> saveFavoriteMessages() async {
    // המועדפים נשמרים בשרת כדי שיהיה סנכרון בין אתר, אייפון וגלקסי.
  }

  List get pinnedMessages => msgs.where((m) => m["pinned"] == true).toList();
  List get visibleMessages => _showFavoritesOnly
      ? msgs.where((m) => isFavoriteMessage(m)).toList()
      : msgs;
  bool isFavoriteMessage(dynamic m) => m is Map && m["favorite"] == true;
  final Map<dynamic, GlobalKey> _msgKeys = {};

  @override
  void initState() {
    super.initState();
    messageFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    chatAudioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => playingAudioUrl = "");
    });
    unawaited(loadPinnedMessages().then((_) => load()));
    // realtime כבר מרענן מיד כשמגיעה הודעה — הטיימר הוא רק גיבוי
    timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) {
        load(silent: true, incremental: true);
      }
    });
    // רענון מיידי כשמגיע אירוע realtime (הודעה חדשה נשמרה בשרת) - לא
    // מחכים לטיימר הבא, בדיוק כמו שהאתר כבר עושה עם ה-WebSocket שלו.
    realtimeTick.addListener(_onRealtimeTick);
  }

  void _onRealtimeTick() {
    if (mounted) load(silent: true, incremental: true);
  }

  @override
  void dispose() {
    timer?.cancel();
    realtimeTick.removeListener(_onRealtimeTick);
    _spinCtrl.dispose();
    chatAudioPlayer.dispose();
    // scrollController disposed
    messageFocusNode.dispose();
    txt.dispose();
    super.dispose();
  }

  void hideKeyboard() {
    messageFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _updateSpinner() {
    if (loading || sending || refreshing) {
      if (!_spinCtrl.isAnimating) _spinCtrl.repeat();
    } else {
      _spinCtrl.stop();
      _spinCtrl.reset();
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || msgs.isEmpty) return;
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted || msgs.isEmpty) return;
      try {
        itemScrollController.jumpTo(index: msgs.length - 1);
      } catch (_) {}
    });
  }

  void scrollToBottomSmooth() {
    scrollToBottom();
  }

  void scrollToBottomNow() {
    if (msgs.isEmpty) return;
    try {
      itemScrollController.scrollTo(
        index: msgs.length - 1,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {}
  }

  Future<void> scrollToMessage(dynamic message) async {
    if (msgs.isEmpty) return;
    final targetId = message["id"];
    final index = msgs.indexWhere((m) => m["id"] == targetId);
    if (index < 0) {
      showSnack("לא מצאתי את ההודעה המוצמדת");
      return;
    }
    if (mounted) {
      setState(() => focusedPinnedMessageId = targetId);
    }
    try {
      itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.22,
      );
      // מחכה שהגלילה תסתיים
      await Future.delayed(const Duration(milliseconds: 450));
    } catch (_) {}
  }

  Future<void> openNextPinnedMessage() async {
    final allPinned = pinnedMessages;
    if (allPinned.isEmpty) return;

    var currentIndex = _pinnedIndex;
    if (focusedPinnedMessageId != null) {
      final focusedIndex = allPinned.indexWhere(
        (m) => "${m["id"]}" == "$focusedPinnedMessageId",
      );
      if (focusedIndex >= 0) currentIndex = focusedIndex;
    }

    final nextIndex = allPinned.length > 1
        ? (currentIndex + 1) % allPinned.length
        : currentIndex.clamp(0, allPinned.length - 1);
    final nextPinned = allPinned[nextIndex];

    if (mounted) {
      setState(() {
        _pinnedIndex = nextIndex;
        focusedPinnedMessageId = nextPinned["id"];
      });
    }

    await scrollToMessage(nextPinned);
  }

  Future<void> toggleAudio(String url) async {
    if (url.isEmpty) return;
    try {
      if (playingAudioUrl == url) {
        await chatAudioPlayer.stop();
        if (mounted) setState(() => playingAudioUrl = "");
        return;
      }
      await chatAudioPlayer.stop();
      await chatAudioPlayer.play(UrlSource(url));
      if (mounted) setState(() => playingAudioUrl = url);
    } catch (_) {
      showSnack("לא הצלחתי להשמיע את ההודעה הקולית");
      if (mounted) setState(() => playingAudioUrl = "");
    }
  }

  Future<void> transcribeMedia(String media, {String label = "מדיה"}) async {
    if (media.isEmpty || transcribingAudio.contains(media)) return;

    setState(() {
      transcribingAudio.add(media);
      sending = true;
    });

    try {
      final r = await http.post(
        Uri.parse("$api/api/transcribe_audio"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"media": media, "target": "he"}),
      );
      final data = jsonDecode(r.body);

      if (r.statusCode < 200 ||
          r.statusCode >= 300 ||
          data is! Map ||
          data["ok"] == false) {
        final error = data is Map ? "${data["error"] ?? ""}".trim() : "";
        showSnack(error.isEmpty ? "שגיאת תמלול" : error);
        return;
      }

      if (data["pending"] == true) {
        showSnack(
          "${data["message"] ?? "התמלול התחיל ברקע. בדוק שוב עוד מעט."}",
        );
        Future.delayed(const Duration(seconds: 10), () async {
          if (!mounted) return;
          await load(silent: true);
          scrollToBottom();
        });
        return;
      }

      final text = "${data["text"] ?? ""}".trim();
      if (text.isNotEmpty) {
        audioTranscripts[media] = text;
      }
      showSnack("התמלול מוכן");
      await load(silent: true);
      scrollToBottom();
    } catch (_) {
      showSnack("לא הצלחתי לתמלל את ה$label");
    } finally {
      if (mounted) {
        setState(() {
          transcribingAudio.remove(media);
          sending = false;
        });
      }
    }
  }

  Future<void> transcribeAudio(String media) =>
      transcribeMedia(media, label: "ההודעה הקולית");

  // ===== שינוי מדינה ללקוח (מספר משותף) =====
  Future<void> _openSwitchCountry() async {
    List group = [];
    try {
      final r = await http
          .get(Uri.parse("$api/api/country_group").replace(
            queryParameters: {"country": widget.country, "wa_id": widget.waId},
          ))
          .timeout(const Duration(seconds: 8));
      final data = jsonDecode(r.body);
      if (data is Map && data["countries"] is List) group = data["countries"];
    } catch (_) {}
    if (!mounted) return;
    if (group.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("המספר הזה משרת מדינה אחת בלבד")),
      );
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                "🔄 לאיזו מדינה להעביר את הלקוח?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            for (final c in group)
              ListTile(
                leading: Text("${c["flag"] ?? "🌍"}",
                    style: const TextStyle(fontSize: 22)),
                title: Text("${c["name_he"] ?? c["name"] ?? c["code"]}"),
                trailing: "${c["code"]}" == widget.country
                    ? const Icon(Icons.check, color: Color(0xff00a884))
                    : null,
                onTap: () => Navigator.pop(ctx, "${c["code"]}"),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || picked == widget.country || !mounted) return;
    try {
      final r = await http
          .post(
            Uri.parse("$api/api/switch_contact_country"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"wa_id": widget.waId, "country": picked}),
          )
          .timeout(const Duration(seconds: 10));
      final ok = r.statusCode >= 200 && r.statusCode < 300;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? "✅ הלקוח הועבר" : "❌ השינוי נכשל")),
      );
      if (ok) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              waId: widget.waId,
              name: widget.name,
              country: picked,
              currentUser: widget.currentUser,
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ אין חיבור לשרת")),
      );
    }
  }

  Future<void> load({bool silent = false, bool incremental = false}) async {
    if (_loadingMessages) return;
    _loadingMessages = true;
    final previousMessages = msgs;
    var shouldScrollToBottom = false;
    var lastKnownId = 0;
    if (incremental && previousMessages.isNotEmpty) {
      for (final m in previousMessages) {
        final id = int.tryParse("${m["id"] ?? ""}") ?? 0;
        if (id > lastKnownId) lastKnownId = id;
      }
    }

    if (mounted) {
      setState(() {
        if (silent) {
          refreshing = true;
        } else {
          loading = true;
        }
      });
    }

    try {
      final uri = Uri.parse("$api/api/messages").replace(
        queryParameters: {
          "wa_id": widget.waId,
          // צ'אט נפרד לכל מדינה: מבקשים רק את ההודעות של המדינה של השיחה
          if (widget.country.trim().isNotEmpty && widget.country != "all")
            "country": widget.country,
          if (incremental && lastKnownId > 0) "since_id": "$lastKnownId",
        },
      );
      final r = await http.get(uri);
      final data = jsonDecode(r.body);
      final fetchedMessages = data is List
          ? data.map((raw) {
              if (raw is! Map) return raw;
              final msg = Map<String, dynamic>.from(raw);
              msg["pinned"] = msg["pinned"] == true;
              msg["favorite"] = msg["favorite"] == true;
              return msg;
            }).toList()
          : [];
      final mergedMessages =
          incremental && silent && lastKnownId > 0 && fetchedMessages.isNotEmpty
          ? [...previousMessages, ...fetchedMessages]
          : fetchedMessages;

      // מניעת כפילויות: אם אותה הודעה (לפי id) מופיעה יותר מפעם אחת
      // (למשל בגלל חפיפת תזמון בין רענון רגיל לרענון מיידי אחרי שליחה),
      // שומרים רק את ההופעה הראשונה שלה.
      final seenIds = <String>{};
      final nextMessages = [];
      for (final m in mergedMessages) {
        final idKey = "${(m as Map)["id"] ?? ""}";
        if (idKey.isNotEmpty) {
          if (seenIds.contains(idKey)) continue;
          seenIds.add(idKey);
        }
        nextMessages.add(m);
      }

      if (incremental && silent && lastKnownId > 0 && fetchedMessages.isEmpty) {
        return;
      }

      if (silent && !messagesChanged(previousMessages, nextMessages)) {
        return;
      }

      msgs = nextMessages;
      shouldScrollToBottom = true;

      final newMessages = lastCount > 0 && msgs.length > lastCount
          ? msgs.skip(lastCount)
          : const Iterable.empty();
      final hasIncomingMessage = newMessages.any(
        (m) => "${m["sender"] ?? ""}" != "out",
      );
      if (hasIncomingMessage && mounted) {
        playIncomingAlert();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("🔔 הודעה חדשה בשיחה")));
      }
      lastCount = msgs.length;
    } catch (_) {
      if (!silent) msgs = [];
    } finally {
      _loadingMessages = false;
      loading = false;
      refreshing = false;
      if (mounted) setState(() {});
    }

    if (shouldScrollToBottom) {
      scrollToBottom();
    }
  }

  bool messagesChanged(List previous, List next) {
    if (previous.length != next.length) return true;
    if (previous.isEmpty && next.isEmpty) return false;

    final previousLast = previous.last;
    final nextLast = next.last;
    return "${previousLast["text"] ?? ""}" != "${nextLast["text"] ?? ""}" ||
        "${previousLast["media"] ?? ""}" != "${nextLast["media"] ?? ""}" ||
        "${previousLast["time"] ?? ""}" != "${nextLast["time"] ?? ""}" ||
        "${previousLast["type"] ?? ""}" != "${nextLast["type"] ?? ""}";
  }

  Future<void> sendTextLang(String targetLang) async {
    String text = txt.text.trim();
    if (text.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      // תרגום דרך השרת (ואם הוא נכשל — גוגל ישירות). אם גם זה נכשל לא שולחים,
      // כדי שהלקוח לא יקבל את ההודעה בעברית.
      final translated = await translateOnly(text, target: targetLang);
      if (!isUsefulTranslation(
            original: text,
            translated: translated,
            target: targetLang,
          ) ||
          (targetLang != "he" &&
              RegExp(r"[\u0590-\u05ff]").hasMatch(translated))) {
        showSnack("התרגום נכשל. ההודעה לא נשלחה — נסה שוב.");
        return;
      }
      final r2 = await http
          .post(
            Uri.parse(api + "/api/send"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "wa_id": widget.waId,
              "sender": widget.currentUser,
              "msg": translated,
              "country": widget.country,
              "reply_to_id": replyingTo?["id"],
              "reply_to_text": replyingTo?["text"],
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (r2.statusCode >= 200 && r2.statusCode < 300) {
        txt.clear();
        setState(() => replyingTo = null);
        await load(silent: true);
        scrollToBottom();
        showSnack("נשלח ב-" + targetLang.toUpperCase());
      } else {
        showSnack(sendErrorMessage(r2.statusCode, r2.body));
      }
    } catch (e) {
      showSnack("לא הצלחתי לשלוח. בדוק אינטרנט ונסה שוב.");
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> sendText({bool translateFirst = false}) async {
    String text = txt.text.trim();
    if (text.isEmpty || sending) return;

    setState(() => sending = true);

    if (translateFirst) {
      final translated = await translateOnly(text, target: "en");
      if (!isUsableEnglishTranslation(original: text, translated: translated)) {
        showSnack("התרגום לאנגלית נכשל. ההודעה לא נשלחה.");
        if (mounted) setState(() => sending = false);
        return;
      }
      text = translated;
    }

    try {
      final r = await http
          .post(
            Uri.parse("$api/api/send"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "wa_id": widget.waId,
              "sender": widget.currentUser,
              "msg": text,
              "country": widget.country,
              "reply_to_id": replyingTo?["id"],
              "reply_to_text": replyingTo?["text"],
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (r.statusCode < 200 || r.statusCode >= 300) {
        showSnack(sendErrorMessage(r.statusCode, r.body));
        return;
      }
      txt.clear();
      setState(() => replyingTo = null);
      await load(silent: true);
      scrollToBottom();
      if (translateFirst) showSnack("נשלח באנגלית");
    } catch (e) {
      showSnack("לא הצלחתי לשלוח. בדוק אינטרנט ונסה שוב.");
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<String> translateOnly(String text, {String target = "he"}) async {
    final original = text.trim();
    try {
      final r = await http
          .post(
            Uri.parse("$api/api/translate"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "text": text,
              "target": target,
              "target_lang": target,
              "to": target,
            }),
          )
          .timeout(const Duration(seconds: 12));
      final data = jsonDecode(r.body);
      final translated = data["ok"] == false
          ? ""
          : "${data["translated"] ?? text}".trim();
      if (isUsefulTranslation(
        original: original,
        translated: translated,
        target: target,
      )) {
        return translated;
      }
    } catch (_) {
      // Fall through to the public fallback below.
    }

    return translateWithGoogleFallback(original, target: target);
  }

  String sendErrorMessage(int statusCode, String body) {
    try {
      final data = jsonDecode(body);
      final error = "${data["error"] ?? ""}";
      if (error.contains("phone_id")) {
        return "זה מזהה עסקי של WhatsApp, לא מספר לקוח. שלח למספר הלקוח.";
      }
      if (error.isNotEmpty) return "שגיאה בשליחה: $error";
    } catch (_) {
      // Keep the simple fallback below.
    }
    return "שגיאה בשליחה: $statusCode";
  }

  Future<String> translateWithGoogleFallback(
    String text, {
    required String target,
  }) async {
    try {
      final uri = Uri.https("translate.googleapis.com", "/translate_a/single", {
        "client": "gtx",
        "sl": "auto",
        "tl": target,
        "dt": "t",
        "q": text,
      });
      final r = await http.get(uri).timeout(const Duration(seconds: 12));
      if (r.statusCode < 200 || r.statusCode >= 300) return text;
      final data = jsonDecode(r.body);
      final pieces = data is List && data.isNotEmpty ? data[0] : null;
      if (pieces is! List) return text;
      final translated = pieces
          .whereType<List>()
          .map((part) => part.isNotEmpty ? "${part.first}" : "")
          .join()
          .trim();
      if (isUsefulTranslation(
        original: text,
        translated: translated,
        target: target,
      )) {
        return translated;
      }
    } catch (_) {
      // Keep the original text when every translation path fails.
    }
    return text;
  }

  bool isUsableEnglishTranslation({
    required String original,
    required String translated,
  }) {
    return isUsefulTranslation(
      original: original,
      translated: translated,
      target: "en",
    );
  }

  bool isUsefulTranslation({
    required String original,
    required String translated,
    required String target,
  }) {
    final cleanOriginal = original.trim();
    final cleanTranslated = translated.trim();
    if (cleanTranslated.isEmpty) return false;
    if (cleanTranslated == cleanOriginal) return false;
    final hasHebrew = RegExp(r"[\u0590-\u05ff]").hasMatch(cleanTranslated);
    if (target == "en") return !hasHebrew;
    if (target == "he") return hasHebrew;
    return true;
  }

  Future<void> showTranslation(String text) async {
    final translated = await translateOnly(text, target: "he");
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🌍 תרגום"),
        content: SelectableText(translated),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("סגור"),
          ),
        ],
      ),
    );
  }

  void showFullText(String title, String text) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              textDirection: Directionality.of(context),
              style: const TextStyle(fontSize: 18, height: 1.35),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("סגור"),
          ),
        ],
      ),
    );
  }

  Widget _locationMapThumb(String lat, String lng, String mapImgUrl) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PortsNearbyPage(
              lat: double.tryParse(lat) ?? 0,
              lng: double.tryParse(lng) ?? 0,
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Image.network(
              mapImgUrl,
              width: 120,
              height: 65,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Image.network(
                "https://static-maps.yandex.ru/1.x/?ll=$lng,$lat&size=120,65&z=15&l=map&pt=$lng,$lat,pm2rdl",
                width: 120,
                height: 65,
                fit: BoxFit.cover,
                errorBuilder: (c2, e2, s2) => Container(
                  width: 120,
                  height: 65,
                  color: Colors.grey.shade800,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
              ),
              loadingBuilder: (c, child, progress) => progress == null
                  ? child
                  : Container(
                      width: 120,
                      height: 65,
                      alignment: Alignment.center,
                      child: const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
            ),
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "📍 מיקום",
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget messageTextBlock(
    String text, {
    String title = "הודעה מלאה",
    TextStyle? style,
  }) {
    final clean = text.trim();
    if (clean.isEmpty) return const SizedBox.shrink();

    // Keep message text independent from any inherited text foreground.
    // Some Android devices can inherit a transparent foreground paint from
    // a parent widget; an explicit colour here keeps every chat message readable.
    final messageColor =
        style?.color ??
        (appLightMode.value ? const Color(0xff18212b) : Colors.white);
    // Do not inherit a foreground Paint here.  On a few Android builds the
    // surrounding chat widget supplies a transparent paint, which leaves the
    // bubble visible but makes every letter disappear.
    final baseStyle = (style ?? const TextStyle(fontSize: 17)).copyWith(
      color: null,
      foreground: ui.Paint()..color = messageColor,
    );

    // הודעת איש קשר משותף (👤) - מציגים ככרטיס מעוצב במקום טקסט גולמי
    if (clean.startsWith("👤 איש קשר משותף")) {
      final lines = clean.split("\n");
      final cname = lines.length > 1 ? lines[1] : "";
      final phones = lines.length > 2
          ? lines.sublist(2).where((l) => l.trim().isNotEmpty).toList()
          : <String>[];

      void openActionSheet(String rawNumber) {
        final number = rawNumber.replaceAll("📞", "").trim();
        var digits = number.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.startsWith('0')) {
          digits = '972${digits.substring(1)}';
        }
        final waIdForChat = digits;
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xff0d1825),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.call, color: Colors.greenAccent),
                  title: Text(
                    "📞 חיוג $number",
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final uri = Uri.parse("tel:$number");
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.chat, color: Color(0xff25d366)),
                  title: const Text(
                    "💬 שלח הודעה",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          waId: waIdForChat,
                          name: cname.isNotEmpty ? cname : waIdForChat,
                          country: widget.country,
                          currentUser: widget.currentUser,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }

      void openNumberPicker() {
        if (phones.isEmpty) return;
        if (phones.length == 1) {
          openActionSheet(phones.first);
          return;
        }
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xff0d1825),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "איזה מספר?",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                for (final ph in phones)
                  ListTile(
                    leading: const Icon(Icons.phone, color: Color(0xff8fb3c9)),
                    title: Text(
                      ph,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      openActionSheet(ph);
                    },
                  ),
              ],
            ),
          ),
        );
      }

      return GestureDetector(
        onTap: openNumberPicker,
        child: Container(
          constraints: const BoxConstraints(minWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xff25d366).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xff25d366).withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xff25d366),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text("👤", style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cname.isNotEmpty ? cname : "איש קשר משותף",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: appLightMode.value
                            ? Colors.black87
                            : Colors.white,
                      ),
                    ),
                    Text(
                      phones.length > 1
                          ? "${phones.length} מספרים · הקישו לבחירה"
                          : "הקישו לפעולה",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff8fb3c9),
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

    // הודעת מיקום (📍) - מציגים מפה קטנה עם סיכה במקום רק טקסט/קישור
    // תופס גם קישור ששולחת האפליקציה עצמה (?q=) וגם קישור שוואטסאפ
    // שולח כשלקוח משתף מיקום (?api=1&query=)
    final locMatch = RegExp(
      r'[?&](?:q|query)=(-?\d+\.\d+),\s*(-?\d+\.\d+)',
    ).firstMatch(clean);
    if (locMatch != null) {
      final lat = locMatch.group(1)!;
      final lng = locMatch.group(2)!;
      final mapImgUrl =
          "https://staticmap.openstreetmap.de/staticmap.php?center=$lat,$lng&zoom=15&size=120x65&markers=$lat,$lng,red-pushpin";
      return _locationMapThumb(lat, lng, mapImgUrl);
    }

    // Check for URLs and make them tappable
    final urlRegex = RegExp(r'https?://[^\s]+');
    if (urlRegex.hasMatch(clean)) {
      final parts = clean.split(urlRegex);
      final matches = urlRegex.allMatches(clean).toList();
      return Wrap(
        children: [
          for (int i = 0; i < parts.length; i++) ...[
            if (parts[i].isNotEmpty) Text(parts[i], style: baseStyle),
            if (i < matches.length)
              GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(matches[i].group(0)!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Text(
                  matches[i].group(0)!,
                  style: baseStyle.copyWith(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ],
      );
    }

    if (clean.length <= longMessagePreviewLength) {
      return Text(clean, style: baseStyle);
    }

    final preview = clean.substring(0, longMessagePreviewLength).trimRight();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$preview...", style: baseStyle),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => showFullText(title, clean),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            foregroundColor: const Color(0xff00d4ff),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.open_in_full, size: 18),
          label: const Text(
            "פתח מלא",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Future<void> chooseAndSendFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          "jpg",
          "jpeg",
          "png",
          "gif",
          "webp",
          "mp4",
          "mov",
          "m4v",
          "webm",
          "mp3",
          "m4a",
          "aac",
          "ogg",
          "opus",
          "wav",
          "pdf",
          "doc",
          "docx",
          "xls",
          "xlsx",
          "txt",
        ],
        withData: true,
      );
      final file = result?.files.single;
      if (file == null) return;
      final bytes =
          file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null) {
        showSnack("לא הצלחתי לקרוא את הקובץ");
        return;
      }
      final name = file.name;
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
      await uploadBytes(
        bytes: bytes,
        filename: name,
        contentType: mediaTypeForExtension(ext),
      );
    } on PlatformException catch (e) {
      showSnack("בחירת קובץ נכשלה: ${e.message ?? e.code}");
    } on TimeoutException {
      showSnack("העלאת הקובץ לקחה יותר מדי זמן. נסה שוב.");
    } catch (e) {
      showSnack("שגיאה: $e");
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> uploadBytes({
    required List<int> bytes,
    required String filename,
    required MediaType contentType,
  }) async {
    if (bytes.length > 15 * 1024 * 1024) {
      showSnack("הקובץ גדול מדי. עד 15MB");
      return;
    }

    setState(() => sending = true);

    final req = http.MultipartRequest("POST", Uri.parse("$api/api/upload"));
    req.fields["sender"] = widget.currentUser;
    req.fields["wa_id"] = widget.waId;
    req.fields["country"] = widget.country;
    req.fields["filename"] = filename;
    req.fields["mime_type"] = contentType.toString();
    req.files.add(
      http.MultipartFile.fromBytes(
        "file",
        bytes,
        filename: filename,
        contentType: contentType,
      ),
    );

    final res = await req.send().timeout(const Duration(seconds: 30));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      showSnack("📎 הקובץ נשלח");
      await load(silent: true);
      scrollToBottom();
    } else {
      final body = await res.stream.bytesToString();
      showSnack(uploadErrorMessage(res.statusCode, body));
    }
  }

  Future<void> pickImageAndSend(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 86);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      // image_picker re-encodes to JPEG when imageQuality is set, but
      // picked.name may still carry the ORIGINAL extension (e.g. .HEIC
      // on iPhone photos). WhatsApp's API rejects HEIC, so we force
      // jpg/jpeg regardless of the original filename to avoid sending
      // mismatched metadata for an already-re-encoded JPEG file.
      final originalExt = fileExtension(picked.name, null).toLowerCase();
      final isAlreadySafe = [
        "jpg",
        "jpeg",
        "png",
        "webp",
      ].contains(originalExt);
      final extension = isAlreadySafe ? originalExt : "jpg";
      final uploadFilename = isAlreadySafe
          ? picked.name
          : "photo_${DateTime.now().millisecondsSinceEpoch}.jpg";
      await uploadBytes(
        bytes: bytes,
        filename: uploadFilename,
        contentType: mediaTypeForExtension(extension),
      );
    } catch (e) {
      showSnack("בחירת תמונה נכשלה: $e");
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> chooseAudioAndSendEnglishText() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          "aac",
          "aiff",
          "amr",
          "m4a",
          "mp3",
          "mp4",
          "oga",
          "ogg",
          "opus",
          "wav",
          "webm",
        ],
        withData: true,
      );
      final file = result?.files.single;
      if (file == null) return;
      final ext = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : '';
      const audioExtensions = {
        "aac",
        "aiff",
        "amr",
        "m4a",
        "mp3",
        "mp4",
        "oga",
        "ogg",
        "opus",
        "wav",
        "webm",
      };
      if (ext.isNotEmpty && !audioExtensions.contains(ext)) {
        showSnack("בחר קובץ קול בלבד");
        return;
      }
      final bytes =
          file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null) {
        showSnack("לא הצלחתי לקרוא את קובץ הקול");
        return;
      }
      final filename = file.name;

      setState(() => sending = true);
      final req = http.MultipartRequest(
        "POST",
        Uri.parse("$api/api/send_voice_english"),
      );
      req.fields["wa_id"] = widget.waId;
      req.fields["country"] = widget.country;
      req.fields["filename"] = filename;
      req.fields["mime_type"] = mediaTypeForExtension(ext).toString();
      req.files.add(
        http.MultipartFile.fromBytes(
          "file",
          bytes,
          filename: filename,
          contentType: mediaTypeForExtension(ext),
        ),
      );
      final res = await req.send().timeout(const Duration(seconds: 90));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        showSnack("🎙️ הקול תומלל ונשלח באנגלית");
        await load(silent: true);
        scrollToBottom();
      } else {
        final body = await res.stream.bytesToString();
        showSnack("תמלול ושליחה נכשלו: ${res.statusCode} $body");
      }
    } catch (e) {
      showSnack("שגיאת קול לאנגלית: $e");
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> sendLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        showSnack("שירות המיקום כבוי");
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          showSnack("אין הרשאת מיקום");
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        showSnack("הרשאת מיקום חסומה");
        return;
      }
      showSnack("🔍 מאתר מיקום...");
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 15));
      final mapsUrl =
          "https://maps.google.com/?q=${pos.latitude},${pos.longitude}";
      final msg =
          "📍 מיקום נוכחי\nקו רוחב: ${pos.latitude.toStringAsFixed(6)}\nקו אורך: ${pos.longitude.toStringAsFixed(6)}\n$mapsUrl";
      setState(() => sending = true);
      final r = await http
          .post(
            Uri.parse("$api/api/send"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "wa_id": widget.waId,
              "sender": widget.currentUser,
              "msg": msg,
              "country": widget.country,
              "reply_to_id": replyingTo?["id"],
              "reply_to_text": replyingTo?["text"],
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (r.statusCode >= 200 && r.statusCode < 300) {
        showSnack("📍 המיקום נשלח");
        await load(silent: true);
        scrollToBottom();
      } else {
        showSnack("שגיאה בשליחת מיקום");
      }
    } catch (e) {
      showSnack("שגיאת מיקום: $e");
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> pickAndSendContact() async {
    try {
      final status = await fc.FlutterContacts.permissions.request(
        fc.PermissionType.read,
      );
      if (status != fc.PermissionStatus.granted) {
        showSnack("צריך הרשאת גישה לאנשי קשר כדי לשלוח איש קשר");
        return;
      }
      final contacts = await fc.FlutterContacts.getAll(
        properties: {fc.ContactProperty.name, fc.ContactProperty.phone},
      );
      if (!mounted) return;
      if (contacts.isEmpty) {
        showSnack("לא נמצאו אנשי קשר בטלפון");
        return;
      }

      final selected = await showModalBottomSheet<fc.Contact>(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xff0d1825),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          String query = "";
          return StatefulBuilder(
            builder: (ctx, setSheetState) {
              final filtered = query.isEmpty
                  ? contacts
                  : contacts
                        .where(
                          (c) => (c.displayName ?? "").toLowerCase().contains(
                            query.toLowerCase(),
                          ),
                        )
                        .toList();
              return SafeArea(
                child: SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.75,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: "חיפוש איש קשר...",
                            hintStyle: TextStyle(color: Colors.grey),
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                          ),
                          onChanged: (v) => setSheetState(() => query = v),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final c = filtered[i];
                            return ListTile(
                              title: Text(
                                c.displayName?.isNotEmpty == true
                                    ? c.displayName!
                                    : "(ללא שם)",
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: c.phones.isNotEmpty
                                  ? Text(
                                      c.phones.first.number,
                                      style: const TextStyle(
                                        color: Color(0xff8fb3c9),
                                      ),
                                    )
                                  : null,
                              onTap: () => Navigator.pop(ctx, c),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
      if (selected == null) return;

      final cname = (selected.displayName ?? "").trim().isNotEmpty
          ? (selected.displayName ?? "").trim()
          : "איש קשר";
      final phones = selected.phones
          .map((p) => p.number.trim())
          .where((n) => n.isNotEmpty)
          .toList();
      if (phones.isEmpty) {
        showSnack("לאיש הקשר הזה אין מספר טלפון שמור");
        return;
      }
      final lines = ["👤 איש קשר משותף", cname, ...phones.map((p) => "📞 $p")];
      final msg = lines.join("\n");
      setState(() => sending = true);
      final r = await http
          .post(
            Uri.parse("$api/api/send"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "wa_id": widget.waId,
              "sender": widget.currentUser,
              "msg": msg,
              "country": widget.country,
              "reply_to_id": replyingTo?["id"],
              "reply_to_text": replyingTo?["text"],
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (r.statusCode >= 200 && r.statusCode < 300) {
        showSnack("👤 איש הקשר נשלח");
        await load(silent: true);
        scrollToBottom();
      } else {
        showSnack("שגיאה בשליחת איש הקשר");
      }
    } catch (e) {
      showSnack("שגיאה בבחירת איש קשר: $e");
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> recordAndSendVoiceEnglish() async {
    final recorder = FlutterSoundRecorder();
    var recorderOpened = false;
    final isIos = !kIsWeb && Platform.isIOS;
    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        showSnack("צריך לאשר מיקרופון כדי להקליט קול");
        return;
      }
      await recorder.openRecorder();
      recorderOpened = true;
      final dir = await getTemporaryDirectory();
      final extension = isIos ? "m4a" : "aac";
      final codec = isIos ? Codec.aacMP4 : Codec.aacADTS;
      final mimeSubType = isIos ? "mp4" : "aac";
      final path =
          "${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.$extension";
      await recorder.startRecorder(toFile: path, codec: codec);
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("🎙️ מקליט..."),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text("לחץ עצור כשתסיים"),
            ],
          ),
          actions: [
            FilledButton.icon(
              icon: const Icon(Icons.stop),
              label: const Text("עצור ושלח"),
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
      await recorder.stopRecorder();
      final file = File(path);
      if (!await file.exists()) {
        showSnack("לא נקלט קול");
        return;
      }
      final bytes = await file.readAsBytes();
      setState(() => sending = true);
      final req = http.MultipartRequest(
        "POST",
        Uri.parse("$api/api/send_voice_english"),
      );
      req.fields["wa_id"] = widget.waId;
      req.fields["country"] = widget.country;
      req.fields["filename"] = "voice.$extension";
      req.fields["mime_type"] = "audio/$mimeSubType";
      req.files.add(
        http.MultipartFile.fromBytes(
          "file",
          bytes,
          filename: "voice.$extension",
          contentType: MediaType("audio", mimeSubType),
        ),
      );
      final res = await req.send().timeout(const Duration(seconds: 90));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        showSnack("🎙️ הקול תומלל ונשלח באנגלית");
        await load(silent: true);
        scrollToBottom();
      } else {
        showSnack("תמלול ושליחה נכשלו");
      }
    } catch (e) {
      showSnack("שגיאת הקלטה: $e");
    } finally {
      if (recorderOpened) {
        try {
          await recorder.closeRecorder();
        } catch (_) {}
      }
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> showAttachmentMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.insert_drive_file,
                color: Colors.orangeAccent,
              ),
              title: const Text("קובץ"),
              onTap: () => Navigator.pop(context, "file"),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Colors.purpleAccent,
              ),
              title: const Text("גלריה"),
              onTap: () => Navigator.pop(context, "gallery"),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: const Color(0xff00d4ff),
              ),
              title: const Text("מצלמה"),
              onTap: () => Navigator.pop(context, "camera"),
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.redAccent),
              title: const Text("שלח מיקום"),
              onTap: () => Navigator.pop(context, "location"),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xff25d366)),
              title: const Text("שלח איש קשר"),
              onTap: () => Navigator.pop(context, "contact"),
            ),
            ListTile(
              leading: const Icon(Icons.mic, color: Colors.greenAccent),
              title: const Text("הקלט קול → שלח באנגלית"),
              onTap: () => Navigator.pop(context, "record_english"),
            ),
            ListTile(
              leading: const Icon(
                Icons.audio_file,
                color: const Color(0xff00d4ff),
              ),
              title: const Text("קובץ קול → שלח באנגלית"),
              onTap: () => Navigator.pop(context, "voice_english"),
            ),
          ],
        ),
      ),
    );

    if (action == "file") await chooseAndSendFile();
    if (action == "gallery") await pickImageAndSend(ImageSource.gallery);
    if (action == "camera") await pickImageAndSend(ImageSource.camera);
    if (action == "location") await sendLocation();
    if (action == "contact") await pickAndSendContact();
    if (action == "record_english") await recordAndSendVoiceEnglish();
    if (action == "voice_english") await chooseAudioAndSendEnglishText();
  }

  Future<void> deleteMessage(dynamic m) async {
    final messageId = "${m["id"] ?? ""}".trim();
    if (messageId.isEmpty) {
      showSnack("אין מזהה הודעה למחיקה");
      return;
    }

    // אדמין — הצג אפשרות מחיקה לכולם
    final isAdmin = isManagerUser(widget.currentUser);
    final isOut = (m["direction"] ?? "") == "out";

    String? choice;
    if (isAdmin && isOut) {
      choice = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("מחיקת הודעה"),
          content: const Text("איך למחוק?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("ביטול"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, "local"),
              child: const Text("מחק אצלי"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, "everyone"),
              child: const Text("🗑️ מחק לכולם"),
            ),
          ],
        ),
      );
    } else {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("מחיקת הודעה"),
          content: const Text("למחוק את ההודעה הזו?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("ביטול"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("מחק"),
            ),
          ],
        ),
      );
      if (ok == true) choice = "local";
    }
    if (choice == null) return;

    try {
      final r = await http.post(
        Uri.parse("$api/api/delete_message"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "message_id": messageId,
          "wa_id": widget.waId,
          "delete_for_everyone": choice == "everyone",
        }),
      );
      if (r.statusCode >= 200 && r.statusCode < 300) {
        showSnack(choice == "everyone" ? "🗑️ נמחק לכולם" : "ההודעה נמחקה");
        await load(silent: true);
      } else {
        showSnack("מחיקה נכשלה: ${r.statusCode}");
      }
    } catch (e) {
      showSnack("שגיאה במחיקה: $e");
    }
  }

  String uploadErrorMessage(int statusCode, String body) {
    if (statusCode >= 500 && body.contains("whatsapp upload failed")) {
      return "הקובץ נבחר, אבל WhatsApp לא קיבל אותו. אם זה HEIC/קובץ נדיר, נסה לשמור כ-JPG/PDF.";
    }
    if (statusCode == 413) return "הקובץ גדול מדי לשליחה.";
    if (statusCode == 415) return "סוג הקובץ לא נתמך לשליחה.";
    return "שגיאה בשליחת קובץ: $statusCode";
  }

  String fileExtension(String name, String? pickerExtension) {
    final fromPicker = (pickerExtension ?? "").toLowerCase().trim();
    if (fromPicker.isNotEmpty) return fromPicker;
    final index = name.lastIndexOf(".");
    if (index == -1 || index == name.length - 1) return "";
    return name.substring(index + 1).toLowerCase();
  }

  MediaType mediaTypeForExtension(String extension) {
    switch (extension) {
      case "jpg":
      case "jpeg":
        return MediaType("image", "jpeg");
      case "png":
        return MediaType("image", "png");
      case "gif":
        return MediaType("image", "gif");
      case "webp":
        return MediaType("image", "webp");
      case "heic":
        return MediaType("image", "heic");
      case "heif":
        return MediaType("image", "heif");
      case "pdf":
        return MediaType("application", "pdf");
      case "txt":
        return MediaType("text", "plain");
      case "csv":
        return MediaType("text", "csv");
      case "doc":
        return MediaType("application", "msword");
      case "docx":
        return MediaType(
          "application",
          "vnd.openxmlformats-officedocument.wordprocessingml.document",
        );
      case "xls":
        return MediaType("application", "vnd.ms-excel");
      case "xlsx":
        return MediaType(
          "application",
          "vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        );
      case "ppt":
        return MediaType("application", "vnd.ms-powerpoint");
      case "pptx":
        return MediaType(
          "application",
          "vnd.openxmlformats-officedocument.presentationml.presentation",
        );
      case "mp3":
        return MediaType("audio", "mpeg");
      case "ogg":
        return MediaType("audio", "ogg");
      case "opus":
        return MediaType("audio", "opus");
      case "m4a":
        return MediaType("audio", "mp4");
      case "wav":
        return MediaType("audio", "wav");
      case "mp4":
        return MediaType("video", "mp4");
      case "mov":
        return MediaType("video", "quicktime");
      case "zip":
        return MediaType("application", "zip");
      case "json":
        return MediaType("application", "json");
      default:
        return MediaType("application", "octet-stream");
    }
  }

  Future<void> shareMessage(dynamic m) async {
    final text = "${m["text"] ?? ""}".trim();
    final media = "${m["media"] ?? ""}".trim();
    final shareText = text.isNotEmpty
        ? text.replaceAll("|||", "\n")
        : media.isNotEmpty
        ? fileUrl(media)
        : "";

    if (shareText.isEmpty) {
      showSnack("אין תוכן לשיתוף");
      return;
    }

    await Share.share(shareText);
  }

  int? messageIdOf(dynamic m) {
    final raw = m["id"];
    if (raw is int) return raw;
    return int.tryParse("$raw");
  }

  List<dynamic> get selectedMessages => msgs.where((m) {
    final id = messageIdOf(m);
    return id != null && selectedMessageIds.contains(id);
  }).toList();

  void toggleSelectMessage(dynamic m) {
    final id = messageIdOf(m);
    if (id == null) {
      showSnack("אין מזהה להודעה");
      return;
    }
    setState(() {
      if (selectedMessageIds.contains(id)) {
        selectedMessageIds.remove(id);
      } else {
        selectedMessageIds.add(id);
      }
    });
    showSnack("נבחרו ${selectedMessageIds.length} הודעות");
  }

  Future<void> shareSelectedMessages() async {
    final items = selectedMessages
        .map((m) {
          final text = "${m["text"] ?? ""}".replaceAll("|||", "\n").trim();
          final media = "${m["media"] ?? ""}".trim();
          if (text.isNotEmpty) return text;
          if (media.isNotEmpty) return fileUrl(media);
          return "";
        })
        .where((s) => s.trim().isNotEmpty)
        .toList();
    if (items.isEmpty) {
      showSnack("אין תוכן לשיתוף");
      return;
    }
    await Share.share(items.join("\n\n---\n\n"));
  }

  Future<void> forwardSelectedMessages() async {
    final items = selectedMessages;
    if (items.isEmpty) return;
    final numbers = await pickForwardTargets(
      title: "↪️ העבר ${items.length} הודעות אל...",
    );
    if (numbers.isEmpty) return;

    int sent = 0;
    final total = items.length * numbers.length;
    for (final m in items) {
      for (final num in numbers) {
        try {
          final r = await http.post(
            Uri.parse("$api/api/forward"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "from_wa_id": widget.waId,
              "forward_to": num,
              "country": "${m["country"] ?? widget.country}",
              "text": "${m["text"] ?? ""}",
              "media": "${m["media"] ?? ""}",
            }),
          );
          if (r.statusCode >= 200 && r.statusCode < 300) sent++;
        } catch (_) {}
      }
    }
    if (mounted) {
      setState(selectedMessageIds.clear);
    }
    showSnack("↪️ הועברו $sent מתוך $total");
  }

  Future<List<String>> pickForwardTargets({
    String title = "↪️ שלח אל...",
  }) async {
    List<Map<String, dynamic>> contactList = [];
    String? fetchError;
    try {
      final r = await http
          .get(Uri.parse("$api/api/contacts"))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        contactList = List<Map<String, dynamic>>.from(data["contacts"] ?? []);
      } else {
        fetchError = r.statusCode == 404
            ? "חסר עדכון באתר: /api/contacts"
            : "שגיאה ${r.statusCode}";
      }
    } catch (e) {
      fetchError = e.toString();
    }
    if (contactList.isEmpty) {
      try {
        final fallbackUri = Uri.parse("$api/api/chats").replace(
          queryParameters: {"country": "all", "username": widget.currentUser},
        );
        final r = await http
            .get(fallbackUri)
            .timeout(const Duration(seconds: 10));
        if (r.statusCode == 200) {
          final data = jsonDecode(r.body);
          final rows = data is List ? data : [];
          contactList = rows
              .map<Map<String, dynamic>>(
                (c) => {
                  "wa_id": c["wa_id"],
                  "name": c["name"] ?? c["wa_id"],
                  "country": c["country"],
                  "unread": c["unread"] ?? 0,
                  "last_seen": c["last_seen"] ?? "",
                  "last_msg": c["last_msg"] ?? "",
                },
              )
              .where((c) => "${c["wa_id"] ?? ""}".trim().isNotEmpty)
              .toList();
          fetchError = null;
        }
      } catch (_) {}
    }

    final selected = <String>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xff071525),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: SizedBox(
            width: 300,
            height: 420,
            child: contactList.isEmpty
                ? Center(
                    child: Text(
                      fetchError != null ? "שגיאה: $fetchError" : "אין צ'אטים",
                      style: const TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: contactList.length,
                    itemBuilder: (_, i) {
                      final c = contactList[i];
                      final waId = "${c["wa_id"] ?? ""}";
                      final name = "${c["name"] ?? waId}";
                      final lastMsg = "${c["last_msg"] ?? ""}";
                      final unread = (c["unread"] ?? 0) as int;
                      final isSel = selected.contains(waId);
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isSel
                              ? const Color(0xff00d4ff)
                              : const Color(0xff0d1825),
                          child: isSel
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.black,
                                  size: 18,
                                )
                              : Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : "?",
                                  style: const TextStyle(
                                    color: Color(0xff00d4ff),
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          lastMsg.isEmpty ? waId : lastMsg,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: unread > 0
                            ? CircleAvatar(
                                radius: 10,
                                backgroundColor: const Color(0xff00d4ff),
                                child: Text(
                                  "$unread",
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () => setS(() {
                          if (isSel) {
                            selected.remove(waId);
                          } else {
                            selected.add(waId);
                          }
                        }),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("ביטול"),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: appLightMode.value
                    ? const Color(0xff2a2f32)
                    : const Color(0xff00d4ff),
                overlayColor: appLightMode.value
                    ? const Color(0xff008069)
                    : null,
                foregroundColor: appLightMode.value
                    ? const Color(0xffffffff)
                    : Colors.black,
              ),
              child: Text("שלח ל-${selected.length}"),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || selected.isEmpty) return [];
    return selected.toList();
  }

  Future<void> forwardMessage(dynamic m, {bool askMode = true}) async {
    final choice = askMode
        ? await showDialog<String>(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xff071525),
              title: const Text(
                "↪️ העבר / שתף",
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.forward,
                      color: Color(0xff00d4ff),
                    ),
                    title: const Text(
                      "העבר לצ'אט",
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      "בחר מרשימת הצ'אטים",
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    onTap: () => Navigator.pop(context, "forward"),
                  ),
                  const Divider(color: Color(0xff1a2a3a)),
                  ListTile(
                    leading: const Icon(Icons.share, color: Color(0xff00d4ff)),
                    title: const Text(
                      "שתף",
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      "שלח לאפליקציות אחרות",
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    onTap: () => Navigator.pop(context, "share"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("ביטול"),
                ),
              ],
            ),
          )
        : "forward";
    if (choice == null) return;

    if (choice == "share") {
      await shareMessage(m);
      return;
    }

    if (choice == "forward") {
      // טען את כל הצ'אטים מהשרת
      List<Map<String, dynamic>> contactList = [];
      String? fetchError;
      try {
        final r = await http
            .get(Uri.parse("$api/api/contacts"))
            .timeout(const Duration(seconds: 10));
        if (r.statusCode == 200) {
          final data = jsonDecode(r.body);
          contactList = List<Map<String, dynamic>>.from(data["contacts"] ?? []);
        } else {
          fetchError = r.statusCode == 404
              ? "חסר עדכון באתר: /api/contacts"
              : "שגיאה ${r.statusCode}";
        }
      } catch (e) {
        fetchError = e.toString();
      }
      if (contactList.isEmpty) {
        try {
          final fallbackUri = Uri.parse("$api/api/chats").replace(
            queryParameters: {"country": "all", "username": widget.currentUser},
          );
          final r = await http
              .get(fallbackUri)
              .timeout(const Duration(seconds: 10));
          if (r.statusCode == 200) {
            final data = jsonDecode(r.body);
            final rows = data is List ? data : [];
            contactList = rows
                .map<Map<String, dynamic>>(
                  (c) => {
                    "wa_id": c["wa_id"],
                    "name": c["name"] ?? c["wa_id"],
                    "country": c["country"],
                    "unread": c["unread"] ?? 0,
                    "last_seen": c["last_seen"] ?? "",
                    "last_msg": c["last_msg"] ?? "",
                  },
                )
                .where((c) => "${c["wa_id"] ?? ""}".trim().isNotEmpty)
                .toList();
            fetchError = null;
          }
        } catch (_) {}
      }

      final selected = <String>{};
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            backgroundColor: const Color(0xff071525),
            title: const Text(
              "↪️ שלח אל...",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            content: SizedBox(
              width: 300,
              height: 420,
              child: contactList.isEmpty
                  ? Center(
                      child: Text(
                        fetchError != null
                            ? "שגיאה: $fetchError"
                            : "אין צ'אטים",
                        style: const TextStyle(color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: contactList.length,
                      itemBuilder: (_, i) {
                        final c = contactList[i];
                        final waId = "${c["wa_id"] ?? ""}";
                        final name = "${c["name"] ?? waId}";
                        final lastMsg = "${c["last_msg"] ?? ""}";
                        final unread = (c["unread"] ?? 0) as int;
                        final isSel = selected.contains(waId);
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: isSel
                                ? const Color(0xff00d4ff)
                                : const Color(0xff0d1825),
                            child: isSel
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.black,
                                    size: 18,
                                  )
                                : Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : "?",
                                    style: const TextStyle(
                                      color: Color(0xff00d4ff),
                                      fontSize: 13,
                                    ),
                                  ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            lastMsg.isEmpty ? waId : lastMsg,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: unread > 0
                              ? CircleAvatar(
                                  radius: 10,
                                  backgroundColor: const Color(0xff00d4ff),
                                  child: Text(
                                    "$unread",
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () => setS(() {
                            if (isSel)
                              selected.remove(waId);
                            else
                              selected.add(waId);
                          }),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("ביטול"),
              ),
              FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: appLightMode.value
                      ? const Color(0xff2a2f32)
                      : const Color(0xff00d4ff),
                  overlayColor: appLightMode.value
                      ? const Color(0xff008069)
                      : null,
                  foregroundColor: appLightMode.value
                      ? const Color(0xffffffff)
                      : Colors.black,
                ),
                child: Text("שלח ל-${selected.length}"),
              ),
            ],
          ),
        ),
      );
      if (confirmed != true || selected.isEmpty) return;
      await _doForward(m, selected.toList());
    }
  }

  Widget messageActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget messageMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 25),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> togglePinnedMessage(dynamic m) async {
    final newPinned = !(m["pinned"] == true);
    setState(() {
      m["pinned"] = newPinned;
    });
    try {
      final res = await http
          .post(
            Uri.parse("$api/api/pin_message"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"id": m["id"], "pinned": newPinned}),
          )
          .timeout(const Duration(seconds: 5));
      final data = jsonDecode(res.body);
      if (data["ok"] != true) throw Exception(data["error"]);
      showSnack(newPinned ? "📌 ההודעה הוצמדה" : "📌 הצמדה בוטלה");
      await load(silent: true);
    } catch (e) {
      setState(() {
        m["pinned"] = !newPinned;
      });
      showSnack("שגיאה: $e");
    }
  }

  Future<void> toggleFavoriteMessage(dynamic m) async {
    final key = favoriteKeyFor(m);
    final nextFavorite = !isFavoriteMessage(m);
    setState(() {
      m["favorite"] = nextFavorite;
      favoritePulseKeys.add(key);
      if (nextFavorite) {
        favoriteMessageKeys.add(key);
      } else {
        favoriteMessageKeys.remove(key);
        if (_showFavoritesOnly && !msgs.any((msg) => isFavoriteMessage(msg))) {
          _showFavoritesOnly = false;
        }
      }
    });
    Future.delayed(const Duration(milliseconds: 360), () {
      if (!mounted) return;
      setState(() => favoritePulseKeys.remove(key));
    });
    try {
      final res = await http
          .post(
            Uri.parse("$api/api/favorite_message"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"id": m["id"], "favorite": nextFavorite}),
          )
          .timeout(const Duration(seconds: 5));
      final data = jsonDecode(res.body);
      if (data["ok"] != true) throw Exception(data["error"]);
      showSnack(nextFavorite ? "⭐ נשמר במועדפים" : "⭐ הוסר מהמועדפים");
      await load(silent: true);
    } catch (e) {
      setState(() {
        m["favorite"] = !nextFavorite;
        if (_showFavoritesOnly && !msgs.any((msg) => isFavoriteMessage(msg))) {
          _showFavoritesOnly = false;
        }
      });
      showSnack("שגיאת מועדפים: $e");
    }
  }

  void showMessageActionSheet(dynamic m, {required bool showTranslate}) {
    final text = "${m["text"] ?? ""}".replaceAll("|||", "\n").trim();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff080f1c),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  messageMenuItem(
                    icon: Icons.reply,
                    label: "הגב",
                    onTap: () {
                      setState(() => replyingTo = m);
                      showSnack("↩️ מגיב להודעה");
                    },
                  ),
                  messageMenuItem(
                    icon: Icons.copy,
                    label: "העתק",
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: text));
                      showSnack("הועתק");
                    },
                  ),
                  messageMenuItem(
                    icon: (m["pinned"] == true)
                        ? Icons.push_pin
                        : Icons.push_pin_outlined,
                    label: (m["pinned"] == true) ? "בטל נעיצה" : "נעץ",
                    onTap: () => togglePinnedMessage(m),
                  ),
                  messageMenuItem(
                    icon: isFavoriteMessage(m) ? Icons.star : Icons.star_border,
                    label: isFavoriteMessage(m)
                        ? "הסר ממועדפים"
                        : "שמור במועדפים",
                    color: const Color(0xffffd54f),
                    onTap: () => toggleFavoriteMessage(m),
                  ),
                  if (showTranslate)
                    messageMenuItem(
                      icon: Icons.translate,
                      label: "תרגם",
                      color: const Color(0xffff5252),
                      onTap: () => showTranslation(
                        "${m["text"] ?? ""}".split("|||").first,
                      ),
                    ),
                  messageMenuItem(
                    icon: Icons.call_received,
                    label: "אליי",
                    color: const Color(0xffa7f3d0),
                    onTap: () => sendMessageToMe(m),
                  ),
                  messageMenuItem(
                    icon: Icons.call_made,
                    label: "אליו",
                    color: const Color(0xffffd166),
                    onTap: sendMyDetailsToCustomer,
                  ),
                  messageMenuItem(
                    icon: Icons.forward,
                    label: "העבר",
                    color: Colors.greenAccent,
                    onTap: () => forwardMessage(m, askMode: false),
                  ),
                  messageMenuItem(
                    icon: Icons.ios_share,
                    label: "שתף",
                    color: const Color(0xff00d4ff),
                    onTap: () => shareMessage(m),
                  ),
                  messageMenuItem(
                    icon: Icons.check_circle_outline,
                    label: "בחר",
                    onTap: () => toggleSelectMessage(m),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _doForward(dynamic m, List<String> numbers) async {
    int sent = 0;
    for (final num in numbers) {
      try {
        final r = await http.post(
          Uri.parse("$api/api/forward"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "from_wa_id": widget.waId,
            "forward_to": num,
            "country": "${m["country"] ?? widget.country}",
            "text": "${m["text"] ?? ""}",
            "media": "${m["media"] ?? ""}",
          }),
        );
        if (r.statusCode >= 200 && r.statusCode < 300) sent++;
      } catch (_) {}
    }
    showSnack("↪️ נשלח ל-$sent מתוך ${numbers.length}");
  }

  Future<void> sendMessageToMe(dynamic m) async {
    try {
      final msgId = m["id"];
      final waId = widget.waId;
      final country = "${m["country"] ?? widget.country}";
      print("SEND TO ME: waId=$waId msgId=$msgId country=$country");
      if (waId.isEmpty) {
        showSnack("שגיאה: אין מספר לקוח");
        return;
      }
      final r = await http
          .post(
            Uri.parse("$api/api/send_to_me"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "from_wa_id": waId,
              "message_id": msgId,
              "country": country,
            }),
          )
          .timeout(const Duration(seconds: 20));
      final data = jsonDecode(r.body);
      if (r.statusCode >= 200 && r.statusCode < 300 && data["ok"] == true) {
        showSnack("✅ נשלח אליך לוואטסאפ");
      } else {
        showSnack("שגיאה: ${data["error"] ?? r.statusCode}");
      }
    } catch (e) {
      showSnack("שגיאה בשליחה אליך: $e");
    }
  }

  Future<void> saveSticker(String mediaFile) async {
    try {
      final r = await http
          .post(
            Uri.parse("$api/api/save_sticker"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"media_file": mediaFile}),
          )
          .timeout(const Duration(seconds: 8));
      final data = jsonDecode(r.body);
      showSnack(
        data["ok"] == true
            ? "📌 מדבקה נשמרה!"
            : "שגיאה: ${data["error"] ?? ""}",
      );
    } catch (e) {
      showSnack("שגיאה: $e");
    }
  }

  Future<void> sendMyDetailsToCustomer() async {
    try {
      final r = await http
          .post(
            Uri.parse("$api/api/send_my_details"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"to": widget.waId, "country": widget.country}),
          )
          .timeout(const Duration(seconds: 20));
      final data = jsonDecode(r.body);
      if (r.statusCode >= 200 && r.statusCode < 300 && data["ok"] == true) {
        showSnack("✅ הפרטים שלך נשלחו ללקוח");
        await load(silent: true);
      } else {
        showSnack("שגיאה: ${data["error"] ?? r.statusCode}");
      }
    } catch (e) {
      showSnack("שגיאה בשליחת הפרטים: $e");
    }
  }

  void showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String fileUrl(String? file) {
    if (file == null || file.isEmpty) return "";
    return "$api/file/$file";
  }

  String? firstMediaUrlInText(String text) {
    final match = RegExp(r'(https?:\/\/\S+|\/file\/\S+)').firstMatch(text);
    if (match == null) return null;
    return match.group(0)?.replaceAll(RegExp(r'[)\],.]+$'), '');
  }

  String mediaNameForTranscribe(String value) {
    final clean = value.trim().split("?").first;
    final fileIndex = clean.indexOf("/file/");
    if (fileIndex >= 0) return clean.substring(fileIndex + 6);
    if (clean.startsWith("http://") || clean.startsWith("https://")) {
      final segments = Uri.tryParse(clean)?.pathSegments ?? const <String>[];
      return segments.isEmpty ? clean : segments.last;
    }
    return clean.startsWith("/") ? clean.split("/").last : clean;
  }

  String countryNameFor(String country) {
    final clean = country.toLowerCase().trim();
    if (clean.isEmpty) return "מדינה לא ידועה";
    for (final item in africaCountryPositions) {
      if (item.code == clean) return _countryNameHebrew(clean, item.name);
    }
    final fallback = clean
        .split("_")
        .where((part) => part.isNotEmpty)
        .map((part) => "${part[0].toUpperCase()}${part.substring(1)}")
        .join(" ");
    return _countryNameHebrew(clean, fallback);
  }

  String countryLabelFor(String country) {
    final clean = country.toLowerCase().trim();
    return "${_flagForCountry(clean)} ${countryNameFor(clean)}";
  }

  @override
  Widget build(BuildContext context) {
    final lightMode = appLightMode.value;
    _updateSpinner();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: lightMode
          ? const Color(0xffeef2f7)
          : const Color(0xff050d18),
      appBar: AppBar(
        backgroundColor: lightMode
            ? const Color(0xffffffff)
            : const Color(0xff202c33),
        foregroundColor: lightMode ? const Color(0xff2a2f32) : Colors.white,
        leadingWidth: 88,
        leading: Row(
          children: [
            IconButton(
              tooltip: "חזור",
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            ),
            CircleAvatar(
              radius: 17,
              backgroundColor: appLightMode.value
                  ? const Color(0xff2a2f32)
                  : const Color(0xff007aaa),
              child: Text(
                widget.name.isNotEmpty ? widget.name[0].toUpperCase() : "👤",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.name),
            Text("📞 ${widget.waId}", style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "שנה מדינה",
            onPressed: _openSwitchCountry,
            icon: const Icon(Icons.public),
          ),
          IconButton(
            tooltip: _showFavoritesOnly ? "כל ההודעות" : "מועדפים",
            onPressed: () {
              setState(() => _showFavoritesOnly = !_showFavoritesOnly);
            },
            icon: Icon(
              _showFavoritesOnly ? Icons.star : Icons.star_border,
              color: _showFavoritesOnly
                  ? const Color(0xffffd54f)
                  : Colors.white70,
            ),
          ),
          IconButton(
            tooltip: lightMode ? "מצב כהה" : "מצב בהיר",
            onPressed: () {
              appLightMode.value = !appLightMode.value;
              setState(() {});
            },
            icon: Icon(lightMode ? Icons.dark_mode : Icons.light_mode),
          ),
          IconButton(
            onPressed: () => load(),
            icon: RotationTransition(
              turns: _spinCtrl,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (loading || sending || refreshing)
                      ? const Color(0xffff2f3f)
                      : appLightMode.value
                      ? const Color(0xff2a2f32)
                      : Colors.white.withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: (loading || sending || refreshing)
                          ? const Color(0xffff2f3f).withValues(alpha: 0.5)
                          : Colors.transparent,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "⌘",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: sending
                ? null
                : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("📦 שלח פתיחה"),
                        content: const Text("לשלוח הודעת פתיחה ללקוח?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text("ביטול"),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text("שלח"),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      setState(() => sending = true);
                      try {
                        final r = await http
                            .get(
                              Uri.parse(
                                "$api/api/send_welcome_now/${widget.waId}",
                              ),
                            )
                            .timeout(const Duration(seconds: 30));
                        if (r.statusCode >= 200 && r.statusCode < 300) {
                          showSnack("📦 הודעת פתיחה נשלחה!");
                          await load(silent: true);
                          scrollToBottom();
                        } else {
                          showSnack("שגיאה: \${r.statusCode}");
                        }
                      } catch (e) {
                        showSnack("שגיאה: \$e");
                      } finally {
                        if (mounted) setState(() => sending = false);
                      }
                    }
                  },
            icon: Icon(
              Icons.rocket_launch,
              color: appLightMode.value
                  ? const Color(0xff2a2f32)
                  : Colors.orange,
            ),
            tooltip: "שלח פתיחה",
          ),
        ],
      ),
      body: Column(
        children: [
          if (pinnedMessages.isNotEmpty) pinnedMessagesBar(),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ChatDoodlePainter(isDark: !lightMode),
                  ),
                ),
                loading
                    ? const Center(child: CircularProgressIndicator())
                    : visibleMessages.isEmpty
                    ? const Center(
                        child: Text(
                          "אין הודעות עדיין",
                          style: TextStyle(fontSize: 20),
                        ),
                      )
                    : GestureDetector(
                        onTap: hideKeyboard,
                        child: ScrollablePositionedList.builder(
                          itemCount: visibleMessages.length,
                          itemScrollController: itemScrollController,
                          itemPositionsListener: itemPositionsListener,
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 82),
                          itemBuilder: (context, i) {
                            final m = visibleMessages[i];
                            final label = "${m["date_label"] ?? ""}";
                            final prevLabel = i > 0
                                ? "${visibleMessages[i - 1]["date_label"] ?? ""}"
                                : "";
                            final showDivider =
                                label.isNotEmpty &&
                                (i == 0 || label != prevLabel);
                            if (!showDivider) return bubble(m);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [dayDivider(label), bubble(m)],
                            );
                          },
                        ),
                      ),
                if (!loading && msgs.isNotEmpty)
                  PositionedDirectional(
                    end: 14,
                    bottom: 14,
                    child: Semantics(
                      button: true,
                      label: "רד לסוף הצ׳אט",
                      child: FloatingActionButton.small(
                        heroTag: "chat-scroll-bottom-${widget.waId}",
                        onPressed: scrollToBottomNow,
                        backgroundColor: appLightMode.value
                            ? const Color(0xff2a2f32)
                            : const Color(0xff53bdeb),
                        foregroundColor: const Color(0xffffffff),
                        child: const Icon(Icons.keyboard_double_arrow_down),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          selectionActionsBar(),
          inputBar(),
        ],
      ),
    );
  }

  int _pinnedIndex = 0;
  int _pinnedScrollIndex = -1; // -1 = לא גללנו עדיין

  Widget selectionActionsBar() {
    if (selectedMessageIds.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: appLightMode.value
            ? const Color(0xffdbeafe)
            : const Color(0xff071525),
        border: const Border(top: BorderSide(color: Color(0xff12324c))),
      ),
      child: Row(
        children: [
          Text(
            "${selectedMessageIds.length} נבחרו",
            style: TextStyle(
              color: appLightMode.value ? Colors.black87 : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          IconButton.filled(
            tooltip: "העבר נבחרים",
            style: IconButton.styleFrom(
              backgroundColor: appLightMode.value
                  ? const Color(0xff2a2f32)
                  : const Color(0xff00d4ff),
              overlayColor: appLightMode.value ? const Color(0xff008069) : null,
              foregroundColor: appLightMode.value
                  ? const Color(0xffffffff)
                  : Colors.black,
            ),
            onPressed: forwardSelectedMessages,
            icon: const Icon(Icons.forward),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: "שתף נבחרים",
            onPressed: shareSelectedMessages,
            icon: const Icon(Icons.ios_share),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: "בטל בחירה",
            onPressed: () => setState(selectedMessageIds.clear),
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget pinnedMessagesBar() {
    final allPinned = pinnedMessages;
    if (allPinned.isEmpty) return const SizedBox.shrink();
    // נוודא שהאינדקס בטווח
    if (_pinnedIndex >= allPinned.length) _pinnedIndex = 0;
    final pinned = allPinned[_pinnedIndex];
    final text = "${pinned["text"] ?? ""}".replaceAll("|||", "  ");
    final media = "${pinned["media"] ?? ""}";
    final preview = text.trim().isNotEmpty
        ? text.trim()
        : media.trim().isNotEmpty
        ? "קובץ / הודעה קולית"
        : "הודעה מוצמדת";
    final shortPreview = preview.length > 80
        ? "${preview.substring(0, 80)}..."
        : preview;

    return Material(
      color: appLightMode.value ? Colors.white : const Color(0xff10243a),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: openNextPinnedMessage,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: appLightMode.value
                    ? const Color(0xff2a2f32)
                    : const Color(0xff00d4ff).withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              // אינדיקטור כמות
              if (allPinned.length > 1)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: appLightMode.value
                        ? const Color(0xff2a2f32).withValues(alpha: 0.12)
                        : const Color(0xff00d4ff).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${_pinnedIndex + 1}/${allPinned.length}",
                    style: TextStyle(
                      fontSize: 10,
                      color: appLightMode.value
                          ? const Color(0xff2a2f32)
                          : const Color(0xff00d4ff),
                    ),
                  ),
                ),
              Icon(
                Icons.push_pin,
                color: appLightMode.value
                    ? const Color(0xff2a2f32)
                    : const Color(0xff00d4ff),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shortPreview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: appLightMode.value
                        ? const Color(0xff10243a)
                        : Colors.white,
                  ),
                ),
              ),
              IconButton(
                tooltip: "בטל הצמדה",
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  setState(() {
                    pinned["pinned"] = false;
                    _pinnedIndex = 0;
                  });
                  try {
                    await http
                        .post(
                          Uri.parse("$api/api/pin_message"),
                          headers: {"Content-Type": "application/json"},
                          body: jsonEncode({
                            "id": pinned["id"],
                            "pinned": false,
                          }),
                        )
                        .timeout(const Duration(seconds: 5));
                    await load(silent: true);
                  } catch (e) {
                    setState(() {
                      pinned["pinned"] = true;
                    });
                    showSnack("שגיאה: $e");
                  }
                },
                icon: const Icon(Icons.close, color: Colors.white54, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget dayDivider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: (appLightMode.value ? Colors.black : Colors.white)
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: appLightMode.value ? Colors.black54 : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget bubble(dynamic m) {
    final msgId = m["id"];
    final key = _msgKeys.putIfAbsent(msgId, () => GlobalKey());
    final sender = "${m["sender"] ?? ""}";
    final mine = sender == "out";
    final type = "${m["type"] ?? "text"}";
    final text = "${m["text"] ?? ""}";
    final media = "${m["media"] ?? ""}";
    final effectiveType = effectiveMessageType(type, media);
    final time = "${m["time"] ?? ""}";
    final country = "${m["country"] ?? ""}";
    final parts = text.split("|||");
    final showText = effectiveType == "text" || media.isEmpty;
    final readStatus = (m["read_status"] ?? "sent").toString();
    final replyText = "${m["reply_to_text"] ?? ""}".trim();
    final isPinned = m["pinned"] == true;
    final isSelected = selectedMessageIds.contains(messageIdOf(m));
    final isFocusedPinned =
        focusedPinnedMessageId != null &&
        "${m["id"]}" == "$focusedPinnedMessageId";

    final flagChip = Tooltip(
      message: countryNameFor(country),
      child: Padding(
        padding: EdgeInsets.only(
          left: mine ? 0 : 6,
          right: mine ? 6 : 0,
          bottom: 6,
        ),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (appLightMode.value ? Colors.black : Colors.white)
                .withValues(alpha: 0.08),
            border: Border.all(
              color: (appLightMode.value ? Colors.black : Colors.white)
                  .withValues(alpha: 0.16),
            ),
          ),
          child: Text(
            _flagForCountry(country),
            style: const TextStyle(fontSize: 20, height: 1),
          ),
        ),
      ),
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine) flagChip,
          GestureDetector(
            key: key,
            onLongPress: () =>
                showMessageActionSheet(m, showTranslate: showText),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 310),
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: effectiveType == "sticker"
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(mine ? 4 : 14),
                  topRight: Radius.circular(mine ? 14 : 4),
                  bottomLeft: const Radius.circular(14),
                  bottomRight: const Radius.circular(14),
                ),
                border: Border(
                  top: isFocusedPinned
                      ? BorderSide(
                          color: appLightMode.value
                              ? const Color(0xff2a2f32)
                              : const Color(0xffffd54f),
                          width: appLightMode.value ? 3 : 2,
                        )
                      : isSelected
                      ? const BorderSide(color: Color(0xff00d4ff), width: 2)
                      : BorderSide.none,
                  bottom: isFocusedPinned
                      ? BorderSide(
                          color: appLightMode.value
                              ? const Color(0xff2a2f32)
                              : const Color(0xffffd54f),
                          width: appLightMode.value ? 3 : 2,
                        )
                      : isSelected
                      ? const BorderSide(color: Color(0xff00d4ff), width: 2)
                      : BorderSide.none,
                  left: !mine
                      ? BorderSide(
                          color: const Color(0xff00d4ff).withValues(alpha: 0.9),
                          width: 4,
                        )
                      : isFocusedPinned
                      ? BorderSide(
                          color: appLightMode.value
                              ? const Color(0xff2a2f32)
                              : const Color(0xffffd54f),
                          width: appLightMode.value ? 3 : 2,
                        )
                      : isSelected
                      ? const BorderSide(color: Color(0xff00d4ff), width: 2)
                      : BorderSide.none,
                  right: mine
                      ? BorderSide(
                          color: const Color(0xff25d366).withValues(alpha: 0.9),
                          width: 4,
                        )
                      : isFocusedPinned
                      ? BorderSide(
                          color: appLightMode.value
                              ? const Color(0xff2a2f32)
                              : const Color(0xffffd54f),
                          width: appLightMode.value ? 3 : 2,
                        )
                      : isSelected
                      ? const BorderSide(color: Color(0xff00d4ff), width: 2)
                      : BorderSide.none,
                ),
                boxShadow: isFocusedPinned
                    ? [
                        BoxShadow(
                          color: appLightMode.value
                              ? const Color(0xff2a2f32).withValues(alpha: 0.28)
                              : const Color(0xffffd54f).withValues(alpha: 0.28),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 17,
                  color: null,
                  foreground: ui.Paint()
                    ..color = appLightMode.value
                        ? const Color(0xff18212b)
                        : Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isSelected)
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Color(0xff00d4ff),
                          ),
                        ),
                      ),
                    if (isPinned)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, bottom: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.push_pin,
                              size: 12,
                              color: appLightMode.value
                                  ? const Color(0xff2a2f32)
                                  : const Color(0xff00d4ff),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              "מוצמד",
                              style: TextStyle(
                                fontSize: 10,
                                color: appLightMode.value
                                    ? const Color(0xff2a2f32)
                                    : const Color(0xff00d4ff),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (replyText.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: const Border(
                            left: BorderSide(
                              color: Color(0xff00d4ff),
                              width: 3,
                            ),
                          ),
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "↩️ ${replyText.length > 80 ? replyText.substring(0, 80) + "..." : replyText}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xff00d4ff),
                          ),
                        ),
                      ),
                    mediaWidget(effectiveType, media, text),
                    if (showText)
                      messageTextBlock(parts.first, title: "הודעה מלאה"),
                    if (showText && parts.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: messageTextBlock(
                          "🌍 ${parts[1]}",
                          title: "תרגום מלא",
                          style: const TextStyle(
                            fontSize: 17,
                            color: Color(0xff00d4ff),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            time,
                            style: TextStyle(
                              fontSize: 10,
                              color: null,
                              foreground: ui.Paint()
                                ..color = appLightMode.value
                                    ? Colors.black45
                                    : Colors.white60,
                            ),
                          ),
                        ),
                        if (mine) ...[
                          const SizedBox(width: 4),
                          Text(
                            readStatus == "read" || readStatus == "delivered"
                                ? "✓✓"
                                : "✓",
                            style: TextStyle(
                              fontSize: 12,
                              color: null,
                              foreground: ui.Paint()
                                ..color = readStatus == "read"
                                    ? const Color(0xff53bdeb)
                                    : (appLightMode.value
                                          ? Colors.black38
                                          : Colors.white54),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (mine) flagChip,
        ],
      ),
    );
  }

  bool isAudioFile(String media) {
    final clean = media.toLowerCase().split("?").first;
    return clean.endsWith(".ogg") ||
        clean.endsWith(".opus") ||
        clean.endsWith(".mp3") ||
        clean.endsWith(".m4a") ||
        clean.endsWith(".aac") ||
        clean.endsWith(".wav");
  }

  bool isVideoFile(String media) {
    final clean = media.toLowerCase().split("?").first;
    return clean.endsWith(".mp4") ||
        clean.endsWith(".mov") ||
        clean.endsWith(".m4v") ||
        clean.endsWith(".webm") ||
        clean.endsWith(".3gp");
  }

  String effectiveMessageType(String type, String media) {
    if (type == "sticker") return "sticker";
    if (media.toLowerCase().endsWith(".webp")) return "sticker";
    if (type == "audio" || isAudioFile(media)) return "audio";
    if (type == "video" || isVideoFile(media)) return "video";
    return type;
  }

  Widget mediaWidget(String type, String media, String text) {
    if (media.isEmpty) {
      final inlineUrl = firstMediaUrlInText(text);
      if (inlineUrl != null && isVideoFile(inlineUrl)) {
        return videoBox(
          mediaUrl(inlineUrl),
          mediaNameForTranscribe(inlineUrl),
          text,
        );
      }
      return const SizedBox.shrink();
    }
    final url = fileUrl(media);

    if (type == "sticker") {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(url, width: 92, height: 92, fit: BoxFit.contain),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => saveSticker(media),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: appLightMode.value
                    ? const Color(0xff2a2f32).withValues(alpha: 0.12)
                    : const Color(0xff00d4ff).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: appLightMode.value
                      ? const Color(0xff2a2f32).withValues(alpha: 0.4)
                      : const Color(0xff00d4ff).withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                "📌 שמור מדבקה",
                style: TextStyle(
                  fontSize: 11,
                  color: appLightMode.value
                      ? const Color(0xff2a2f32)
                      : const Color(0xff00d4ff),
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (type == "image") {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  backgroundColor: Colors.black,
                  appBar: AppBar(
                    backgroundColor: Colors.black,
                    iconTheme: const IconThemeData(color: Colors.white),
                  ),
                  body: Center(
                    child: InteractiveViewer(
                      child: Image.network(url, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              url,
              width: 75,
              height: 75,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  SelectableText("📷 תמונה\n$url"),
            ),
          ),
        ),
      );
    }

    if (type == "audio") return audioBox(url, media, text);
    if (type == "video") return videoBox(url, media, text);
    if (type == "document") return mediaBox("📄 קובץ", url);
    return mediaBox("📎 מדיה", url);
  }

  Widget videoBox(String url, String media, String text) {
    final transcribing = transcribingAudio.contains(media);
    final savedText = (audioTranscripts[media] ?? text).trim();
    final parts = savedText.split("|||");
    final cleanFirst = parts.first.trim();
    final hasTranscript =
        cleanFirst.isNotEmpty &&
        cleanFirst != "🎥 וידאו" &&
        !isVideoFile(cleanFirst) &&
        !cleanFirst.startsWith("http");

    return Container(
      width: 240,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InlineVideoPlayer(url: url),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.tryParse(url);
                    if (uri == null) {
                      showSnack("קישור וידאו לא תקין");
                      return;
                    }
                    final ok = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!ok) showSnack("לא הצלחתי לפתוח את הווידאו");
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text("פתח חיצוני"),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: transcribing
                    ? null
                    : () => transcribeMedia(media, label: "הווידאו"),
                style: FilledButton.styleFrom(
                  backgroundColor: appLightMode.value
                      ? const Color(0xff2a2f32)
                      : const Color(0xff00d4ff),
                  overlayColor: appLightMode.value
                      ? const Color(0xff008069)
                      : null,
                  foregroundColor: const Color(0xffffffff),
                ),
                icon: transcribing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.record_voice_over),
                label: Text(transcribing ? "מתמלל" : "תמלל"),
              ),
            ],
          ),
          if (hasTranscript)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: messageTextBlock(
                parts.length > 1
                    ? "📝 ${parts.first}\n\n🌍 ${parts[1]}"
                    : "📝 ${parts.first}",
                title: "תמלול וידאו",
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xff00d4ff),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget mediaBox(String title, String url) {
    return Container(
      width: 230,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText("$title\n$url"),
    );
  }

  Widget audioBox(String url, String media, String text) {
    final playing = playingAudioUrl == url;
    final transcribing = transcribingAudio.contains(media);
    final savedText = (audioTranscripts[media] ?? text).trim();
    final parts = savedText.split("|||");
    final hasTranscript =
        parts.first.trim().isNotEmpty && parts.first.trim() != "🎤 הודעה קולית";
    return Container(
      width: 250,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FilledButton.icon(
                onPressed: () => toggleAudio(url),
                icon: Icon(playing ? Icons.stop : Icons.play_arrow),
                label: Text(playing ? "עצור" : "השמע"),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: transcribing ? null : () => transcribeAudio(media),
                style: FilledButton.styleFrom(
                  backgroundColor: appLightMode.value
                      ? const Color(0xff2a2f32)
                      : const Color(0xff00d4ff),
                  overlayColor: appLightMode.value
                      ? const Color(0xff008069)
                      : null,
                  foregroundColor: const Color(0xffffffff),
                ),
                icon: transcribing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.record_voice_over),
                label: Text(transcribing ? "מתמלל" : "תמלל"),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "הודעה קולית",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          if (hasTranscript)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  messageTextBlock(
                    parts.length > 1
                        ? "📝 ${parts.first}\n\n🌍 ${parts[1]}"
                        : "📝 ${parts.first}",
                    title: "תמלול מלא",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xff00d4ff),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => showTranslation(parts.first),
                    child: const Text(
                      "🌍 תרגם",
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xff00d4ff),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget inputBar() {
    final keyboardOpen =
        MediaQuery.viewInsetsOf(context).bottom > 0 ||
        messageFocusNode.hasFocus;
    final emojis = [
      "😊",
      "😂",
      "🤣",
      "😍",
      "🥰",
      "😘",
      "😅",
      "😎",
      "🤔",
      "😭",
      "😢",
      "😮",
      "😳",
      "😡",
      "🥳",
      "😇",
      "🙏",
      "👏",
      "👍",
      "👎",
      "💪",
      "🙌",
      "🤝",
      "👌",
      "✌️",
      "👋",
      "👀",
      "💯",
      "✅",
      "❌",
      "⭐",
      "🌟",
      "✨",
      "🔥",
      "❤️",
      "💙",
      "💚",
      "💛",
      "🧡",
      "💜",
      "🖤",
      "🤍",
      "💎",
      "🎉",
      "🎊",
      "🎁",
      "🏆",
      "🎯",
      "💡",
      "📌",
      "📍",
      "📞",
      "📱",
      "📄",
      "📦",
      "🚚",
      "🚗",
      "✈️",
      "🌍",
      "🌈",
      "🌸",
      "🌺",
      "🌋",
      "🍀",
      "🦋",
      "🎵",
      "🎧",
      "📷",
      "🎥",
      "🧵",
      "🪡",
      "🛍️",
      "🧶",
      "👗",
      "👚",
      "👕",
      "👟",
      "💰",
      "💳",
      "🕐",
      "📅",
      "🏠",
      "🏢",
      "🔴",
      "🟢",
      "🔵",
      "🟡",
      "🟣",
      "🟠",
    ];
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(8),
        color: appLightMode.value
            ? Colors.white
            : appLightMode.value
            ? Colors.white
            : appLightMode.value
            ? Colors.white
            : const Color(0xff202c33),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_emojiPanelOpen)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  height: (MediaQuery.sizeOf(context).height * 0.34).clamp(
                    260.0,
                    340.0,
                  ),
                  decoration: BoxDecoration(
                    color: appLightMode.value
                        ? const Color(0xfff4f7fb)
                        : const Color(0xff111827),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xff00d4ff).withValues(alpha: 0.25),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x88000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _EmojiStickerPanel(
                    emojis: emojis,
                    api: api,
                    waId: widget.waId,
                    country: widget.country,
                    onEmoji: (e) {
                      final selection = txt.selection;
                      final start = selection.isValid
                          ? selection.start
                          : txt.text.length;
                      final end = selection.isValid
                          ? selection.end
                          : txt.text.length;
                      txt.text = txt.text.replaceRange(start, end, e);
                      txt.selection = TextSelection.collapsed(
                        offset: start + e.length,
                      );
                    },
                    onStickerSent: () => load(silent: true),
                    onSnack: showSnack,
                  ),
                ),
              ),
            Row(
              children: [
                IconButton(
                  style: IconButton.styleFrom(
                    overlayColor: appLightMode.value
                        ? const Color(0xff008069)
                        : null,
                  ),
                  onPressed: sending
                      ? null
                      : () {
                          if (_emojiPanelOpen) {
                            setState(() => _emojiPanelOpen = false);
                          }
                          showAttachmentMenu();
                        },
                  icon: Icon(
                    Icons.attach_file,
                    color: appLightMode.value
                        ? const Color(0xff2a2f32)
                        : Colors.orangeAccent,
                  ),
                ),
                IconButton(
                  style: IconButton.styleFrom(
                    overlayColor: appLightMode.value
                        ? const Color(0xff008069)
                        : null,
                  ),
                  onPressed: () {
                    hideKeyboard();
                    setState(() => _emojiPanelOpen = !_emojiPanelOpen);
                  },
                  icon: Icon(
                    Icons.emoji_emotions,
                    color: appLightMode.value
                        ? (_emojiPanelOpen
                              ? const Color(0xff008069)
                              : const Color(0xff2a2f32))
                        : (_emojiPanelOpen
                              ? const Color(0xff00d4ff)
                              : Colors.yellowAccent),
                  ),
                ),
                if (keyboardOpen)
                  IconButton(
                    tooltip: "הורד מקלדת",
                    onPressed: hideKeyboard,
                    icon: Icon(
                      Icons.keyboard_hide,
                      color: appLightMode.value
                          ? const Color(0xff2a2f32)
                          : const Color(0xff53bdeb),
                    ),
                  ),
                Expanded(
                  child: TextField(
                    controller: txt,
                    focusNode: messageFocusNode,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    textInputAction: TextInputAction.newline,
                    onTap: () {
                      if (_emojiPanelOpen) {
                        setState(() => _emojiPanelOpen = false);
                      }
                    },
                    onTapOutside: (_) => hideKeyboard(),
                    minLines: 1,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "כתוב הודעה...",
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: appLightMode.value
                          ? Colors.white
                          : const Color(0xff111b21),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: "שלח בשפה",
                  icon: Icon(
                    Icons.translate,
                    color: appLightMode.value
                        ? const Color(0xff2a2f32)
                        : const Color(0xff00d4ff),
                  ),
                  enabled: !sending,
                  onSelected: (lang) {
                    if (_emojiPanelOpen) {
                      setState(() => _emojiPanelOpen = false);
                    }
                    sendTextLang(lang);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: "en", child: Text("אנגלית")),
                    PopupMenuItem(value: "fr", child: Text("צרפתית")),
                    PopupMenuItem(value: "sw", child: Text("סוואהילית")),
                    PopupMenuItem(value: "pt", child: Text("פורטוגזית")),
                    PopupMenuItem(value: "ar", child: Text("ערבית")),
                  ],
                ),
                IconButton(
                  style: IconButton.styleFrom(
                    overlayColor: appLightMode.value
                        ? const Color(0xff008069)
                        : null,
                  ),
                  onPressed: sending
                      ? null
                      : () {
                          if (_emojiPanelOpen) {
                            setState(() => _emojiPanelOpen = false);
                          }
                          sendText();
                        },
                  icon: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.send,
                          color: appLightMode.value
                              ? const Color(0xff2a2f32)
                              : Colors.greenAccent,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiStickerPanel extends StatefulWidget {
  final List<String> emojis;
  final String api, waId, country;
  final Function(String) onEmoji;
  final VoidCallback onStickerSent;
  final Function(String) onSnack;

  const _EmojiStickerPanel({
    required this.emojis,
    required this.api,
    required this.waId,
    required this.country,
    required this.onEmoji,
    required this.onStickerSent,
    required this.onSnack,
  });

  @override
  State<_EmojiStickerPanel> createState() => _EmojiStickerPanelState();
}

class _EmojiStickerPanelState extends State<_EmojiStickerPanel> {
  bool _showStickers = false;
  List _stickers = [];
  bool _loadingStickers = false;

  Future<void> _loadStickers() async {
    if (_loadingStickers) return;
    setState(() => _loadingStickers = true);
    try {
      final r = await http
          .get(Uri.parse("${widget.api}/api/stickers"))
          .timeout(const Duration(seconds: 8));
      if (mounted) {
        setState(() {
          _stickers = jsonDecode(r.body);
          _loadingStickers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStickers = false);
    }
  }

  Future<void> _sendSticker(String mediaFile) async {
    try {
      final r = await http
          .post(
            Uri.parse("${widget.api}/api/send_sticker"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "to": widget.waId,
              "country": widget.country,
              "media_file": mediaFile,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (r.statusCode < 200 || r.statusCode >= 300) {
        widget.onSnack("שגיאה בשליחת מדבקה: ${r.statusCode}");
        return;
      }
      final data = jsonDecode(r.body);
      if (data["ok"] == true) {
        widget.onStickerSent();
        widget.onSnack("✅ מדבקה נשלחה");
      } else {
        widget.onSnack("שגיאה: ${data["error"] ?? ""}");
      }
    } catch (e) {
      widget.onSnack("שגיאה: $e");
    }
  }

  Future<void> _deleteSticker(int id) async {
    await http.post(
      Uri.parse("${widget.api}/api/delete_sticker"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id": id}),
    );
    _loadStickers();
  }

  @override
  Widget build(BuildContext context) {
    final emojiColumns = MediaQuery.sizeOf(context).width < 390 ? 7 : 9;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // טאבים
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showStickers = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: !_showStickers
                            ? (appLightMode.value
                                  ? const Color(0xff2a2f32)
                                  : const Color(0xff00d4ff))
                            : Colors.white24,
                        width: !_showStickers ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        "אימוג׳ים",
                        style: TextStyle(
                          color: !_showStickers
                              ? (appLightMode.value
                                    ? const Color(0xff2a2f32)
                                    : const Color(0xff00d4ff))
                              : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _showStickers = true);
                    _loadStickers();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: _showStickers
                            ? (appLightMode.value
                                  ? const Color(0xff2a2f32)
                                  : const Color(0xff00d4ff))
                            : Colors.white24,
                        width: _showStickers ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        "מדבקות",
                        style: TextStyle(
                          color: _showStickers
                              ? (appLightMode.value
                                    ? const Color(0xff2a2f32)
                                    : const Color(0xff00d4ff))
                              : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // תוכן
        Expanded(
          child: !_showStickers
              ? GridView.count(
                  crossAxisCount: emojiColumns,
                  padding: const EdgeInsets.all(8),
                  children: widget.emojis
                      .map(
                        (e) => GestureDetector(
                          onTap: () => widget.onEmoji(e),
                          child: Center(
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                )
              : _loadingStickers
              ? const Center(child: CircularProgressIndicator())
              : _stickers.isEmpty
              ? const Center(
                  child: Text(
                    "אין מדבקות שמורות",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: _stickers.length,
                  itemBuilder: (ctx, i) {
                    final s = _stickers[i];
                    return GestureDetector(
                      onTap: () => _sendSticker(s["media"]),
                      onLongPress: () async {
                        await _deleteSticker(s["id"]);
                        widget.onSnack("מדבקה נמחקה");
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          "${widget.api}/file/${s["media"]}",
                          fit: BoxFit.contain,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// שורת כפתורים עליונה: קפסולה אחת עם עיגולים צבעוניים ותוויות קטנות
class _TopButtonsBar extends StatelessWidget {
  final List<Widget> buttons;
  const _TopButtonsBar({required this.buttons});

  @override
  Widget build(BuildContext context) {
    final light = appLightMode.value;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: light
              ? const [Color(0xfff7f9fb), Color(0xffe9eef3)]
              : const [Color(0xff10283f), Color(0xff081726)],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: light
              ? const Color(0x22000000)
              : const Color(0xff00d4ff).withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff00d4ff).withValues(alpha: light ? 0 : 0.10),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: buttons,
      ),
    );
  }
}

/// עיגול צבעוני עם אייקון ותווית קטנה מתחת
class _TopChip extends StatelessWidget {
  final String label;
  final Color color;
  final Widget child;
  const _TopChip({
    required this.label,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final light = appLightMode.value;
    final c = light ? Color.lerp(color, Colors.black, 0.35)! : color;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [c.withValues(alpha: 0.30), c.withValues(alpha: 0.10)],
            ),
            border: Border.all(color: c.withValues(alpha: 0.75), width: 1.4),
            boxShadow: [
              BoxShadow(color: c.withValues(alpha: 0.22), blurRadius: 10),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              iconButtonTheme: IconButtonThemeData(
                style: IconButton.styleFrom(
                  foregroundColor: c,
                  backgroundColor: Colors.transparent,
                  minimumSize: const Size(48, 48),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            child: Center(child: child),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: c.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }
}

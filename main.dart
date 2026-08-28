import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';

const String api = "https://arnonidan.pythonanywhere.com";
const String appPin = "8899";
const List<String> accessUsers = [
  "itzik",
  "יבואן 1",
  "יבואן 2",
  "יבואן 3",
  "יבואן 4",
];
final AudioPlayer _incomingAlertPlayer = AudioPlayer();
final ValueNotifier<bool> appLightMode = ValueNotifier<bool>(false);

Future<void> _playIncomingAlertSound() async {
  try {
    await _incomingAlertPlayer.stop();
    await _incomingAlertPlayer.play(
      AssetSource("sounds/incoming_alert.wav"),
      volume: 1,
    );
  } catch (_) {
    SystemSound.play(SystemSoundType.alert);
  }
}

void playIncomingAlert() {
  SystemSound.play(SystemSoundType.alert);
  HapticFeedback.heavyImpact();
  unawaited(_playIncomingAlertSound());
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
];

void main() {
  runApp(const ExpresphoneApp());
}

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
          colorSchemeSeed: Colors.blue,
          scaffoldBackgroundColor: const Color(0xffeef5ff),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          colorSchemeSeed: Colors.green,
          scaffoldBackgroundColor: const Color(0xff04162b),
        ),
        home: const PinPage(),
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
  String selectedUser = accessUsers.first;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    loadCountries();
    refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => loadCountries(silent: true),
    );
  }

  void enter() {
    if (accessUsers.contains(selectedUser) && pin.text.trim() == appPin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(initialCountry: selectedCountry),
        ),
      );
    } else {
      setState(() => error = "שם משתמש או קוד שגויים. נסה שוב.");
      SystemSound.play(SystemSoundType.alert);
    }
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
    return "${data?["name"] ?? africaCountryPositions.firstWhere((x) => x.code == code).name}";
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
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
    );

    return Scaffold(
      backgroundColor: const Color(0xff021225),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.24, -0.26),
            radius: 1.25,
            colors: [Color(0xff0b315f), Color(0xff031b36), Color(0xff010b18)],
            stops: [0.0, 0.48, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  center: Alignment(-0.22, -0.12),
                  radius: 1.08,
                  colors: [
                    Color(0xff0a2d56),
                    Color(0xff031b35),
                    Color(0xff010915),
                  ],
                  stops: [0.0, 0.58, 1.0],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xff6aa9ff).withValues(alpha: 0.26),
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x99000718), blurRadius: 28),
                ],
              ),
              child: Column(
                children: [
                  _Header(
                    pin: pin,
                    selectedUser: selectedUser,
                    error: error,
                    onUserChanged: (user) {
                      if (user == null) return;
                      setState(() => selectedUser = user);
                    },
                    onLogin: enter,
                  ),
                  Expanded(child: mapPanel),
                ],
              ),
            ),
          ),
        ),
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
  });

  final TextEditingController pin;
  final String selectedUser;
  final String error;
  final ValueChanged<String?> onUserChanged;
  final VoidCallback onLogin;

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
              fillColor: const Color(0xff06213f),
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
            color: const Color(0xff06213f),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedUser,
              isExpanded: true,
              dropdownColor: const Color(0xff06213f),
              iconEnabledColor: Colors.white,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
              items: [
                for (final user in accessUsers)
                  DropdownMenuItem(value: user, child: Text(user)),
              ],
              onChanged: onUserChanged,
            ),
          ),
        );
        final loginButton = SizedBox(
          height: 30,
          child: FilledButton(
            onPressed: onLogin,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff2f8cff),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
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

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x33082a50),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.16),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 8),
                  controls,
                ],
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
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
  });

  final Map<String, dynamic> countries;
  final String selectedCountry;
  final bool loading;
  final ValueChanged<String> onSelectCountry;

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
              var mapWidth = phone ? availableWidth * 2.85 : availableWidth;
              var mapHeight = mapWidth / 2;
              if (!phone && mapHeight > availableHeight) {
                mapHeight = availableHeight;
                mapWidth = mapHeight * 2;
              }
              if (phone && mapHeight > availableHeight * 0.94) {
                mapHeight = availableHeight * 0.94;
                mapWidth = mapHeight * 2;
              }

              final panelSize = Size(availableWidth, availableHeight);
              if (phone && centeredForSize != panelSize) {
                centeredForSize = panelSize;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  final scale = availableWidth < 430 ? 0.82 : 0.92;
                  final focusX = mapWidth * 0.62;
                  final focusY = mapHeight * 0.52;
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
                        color: const Color(0xffcfd8de).withValues(alpha: 0.78),
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
        ? Colors.redAccent
        : hasAvailable
        ? Colors.greenAccent
        : Colors.blueGrey.shade200;
    final badgeText = hasUnread
        ? (unread > 99 ? "99" : "$unread")
        : (available > 99 ? "99" : "$available");
    final label = "${data?["name"] ?? position.name}";
    final flag = "${data?["flag"] ?? _flagForCountry(position.code)}";
    final point = Offset(position.x * mapWidth, position.y * mapHeight);
    final compact = mapWidth < 520;
    final tagWidth = compact ? 50.0 : 64.0;
    final tagHeight = compact ? 25.0 : 29.0;
    final tagLeft = (position.labelX * mapWidth - tagWidth / 2)
        .clamp(0.0, mapWidth > tagWidth ? mapWidth - tagWidth : 0.0)
        .toDouble();
    final tagTop = (position.labelY * mapHeight - tagHeight / 2)
        .clamp(0.0, mapHeight > tagHeight ? mapHeight - tagHeight : 0.0)
        .toDouble();
    final leaderStart = Offset(tagLeft + tagWidth / 2, tagTop + tagHeight);

    return Positioned.fill(
      child: Semantics(
        button: true,
        label:
            "$label, ${hasUnread ? "$unread הודעות שלא נקראו" : "$available זמינים"}",
        child: Stack(
          children: [
            CustomPaint(
              foregroundPainter: _CountryLeaderPainter(
                from: leaderStart,
                to: point,
                color: Colors.white,
              ),
              size: Size(mapWidth, mapHeight),
            ),
            Positioned(
              left: point.dx - 6,
              top: point.dy - 6,
              child: GestureDetector(
                onTap: onTap,
                child: _GlowDot(color: statusColor),
              ),
            ),
            Positioned(
              left: tagLeft,
              top: tagTop,
              child: Tooltip(
                message: label,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(18),
                  child: _CountryTag(
                    color: Colors.white,
                    badgeColor: statusColor,
                    badgeText: badgeText,
                    flag: flag,
                    selected: selected,
                    compact: compact,
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
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, halo);
    canvas.drawLine(from, to, glow);
    canvas.drawLine(from, to, line);
    canvas.drawLine(from, to, highlight);
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
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.88),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.72),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.60), blurRadius: 8),
          BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 16),
        ],
      ),
      child: Center(
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.72),
                blurRadius: 5,
              ),
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
    required this.selected,
    required this.compact,
  });

  final Color color;
  final Color badgeColor;
  final String badgeText;
  final String flag;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 50.0 : 64.0;
    final height = compact ? 25.0 : 29.0;
    final flagSize = compact ? 13.0 : 15.0;
    final badgeHeight = compact ? 15.0 : 17.0;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: height - 10,
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xee082a50),
                  border: Border(
                    right: BorderSide(
                      color: color.withValues(alpha: 0.58),
                      width: 1,
                    ),
                    bottom: BorderSide(
                      color: color.withValues(alpha: 0.58),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.16),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: width,
            height: height - 6,
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xee082a50),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.72),
                width: selected ? 2.4 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.14),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Text(flag, style: TextStyle(fontSize: flagSize)),
                const Spacer(),
                const SizedBox(width: 3),
                Container(
                  constraints: BoxConstraints(minWidth: badgeHeight),
                  height: badgeHeight,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withValues(alpha: 0.40),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 7,
                      color: Colors.black,
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

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.initialCountry = "all"});

  final String initialCountry;

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
  Timer? timer;

  @override
  void initState() {
    super.initState();
    selectedCountry = widget.initialCountry;
    loadAll();
    timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => loadAll(silent: true),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> loadAll({bool silent = false}) async {
    await loadCountries(silent: silent);
    await loadChats(selectedCountry, silent: silent);
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
      final newUnread = countries.fold<int>(
        0,
        (sum, item) => sum + (int.tryParse("${item["unread"] ?? 0}") ?? 0),
      );

      if (lastTotalUnread > 0 && newUnread > lastTotalUnread && mounted) {
        playIncomingAlert();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("🔔 הודעה חדשה נכנסה")));
      }
      lastTotalUnread = newUnread;
    } catch (_) {
      if (!silent) countriesError = "לא הצלחתי לטעון מדינות. נסה שוב.";
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
      final uri = Uri.parse(
        "$api/api/chats",
      ).replace(queryParameters: {"country": country});
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

  int countryUnread(dynamic x) => int.tryParse("${x["unread"] ?? 0}") ?? 0;

  @override
  Widget build(BuildContext context) {
    final list = filteredChats;
    final lightMode = appLightMode.value;

    return Scaffold(
      backgroundColor: lightMode
          ? const Color(0xffeef5ff)
          : const Color(0xff021225),
      appBar: AppBar(
        backgroundColor: lightMode
            ? const Color(0xffd8eaff)
            : const Color(0xff06213f),
        title: const Text(
          "cozycrafts chat",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: lightMode ? "מצב כהה" : "מצב בהיר",
            onPressed: () {
              appLightMode.value = !appLightMode.value;
              setState(() {});
            },
            icon: Icon(lightMode ? Icons.dark_mode : Icons.light_mode),
          ),
          IconButton(
            onPressed: () => loadAll(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PinPage()),
              );
            },
            icon: const Icon(Icons.lock),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: MediaQuery.sizeOf(context).width < 390 ? 96 : 108,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: lightMode
                    ? const [Color(0xffd7ecff), Color(0xffeef7ff)]
                    : const [Color(0xff082a50), Color(0xff031b35)],
              ),
            ),
            child: loadingCountries
                ? const Center(child: CircularProgressIndicator())
                : countriesError.isNotEmpty
                ? _LoadError(message: countriesError, onRetry: loadAll)
                : ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      countryCircle("🌍", "ALL", "all", 0, true),
                      ...countries.map(
                        (x) => countryCircle(
                          "${x["flag"] ?? "🌍"}",
                          "${x["name"] ?? ""}",
                          "${x["code"] ?? ""}",
                          countryUnread(x),
                          x["token"] == true,
                        ),
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(
                hintText: "🔍 חיפוש לקוח / מספר",
                filled: true,
                fillColor: const Color(0xff202c33),
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

    return GestureDetector(
      onTap: () => loadChats(code),
      child: Container(
        width: compact ? 76 : 86,
        margin: EdgeInsets.symmetric(horizontal: compact ? 4 : 5),
        decoration: BoxDecoration(
          color: active ? const Color(0xff123f32) : const Color(0xee082a50),
          borderRadius: BorderRadius.circular(compact ? 16 : 19),
          border: Border.all(
            color: active
                ? Colors.greenAccent
                : Colors.white.withValues(alpha: 0.18),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (hasToken ? Colors.greenAccent : Colors.blueAccent)
                  .withValues(alpha: 0.12),
              blurRadius: 12,
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(flag, style: TextStyle(fontSize: compact ? 23 : 27)),
                  SizedBox(height: compact ? 2 : 3),
                  Icon(
                    Icons.circle,
                    size: compact ? 8 : 9,
                    color: hasToken ? Colors.greenAccent : Colors.grey,
                  ),
                  SizedBox(height: compact ? 2 : 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: compact ? 9.5 : 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (unread > 0)
              Positioned(
                top: 7,
                right: 8,
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.red,
                  child: Text(
                    "$unread",
                    style: const TextStyle(fontSize: 11, color: Colors.white),
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

    return Card(
      color: appLightMode.value ? const Color(0xfff0f4ff) : const Color(0xee082a50),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Colors.green,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : "👤",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name.isEmpty ? "ללא שם" : name,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: appLightMode.value ? Colors.black87 : Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📞 $waId",
              style: TextStyle(color: appLightMode.value ? Colors.black54 : Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              online
                  ? "🟢 זמין"
                  : (lastSeen.isEmpty
                        ? "⚫ לא מחובר"
                        : "נראה לאחרונה $lastSeen"),
              style: TextStyle(color: online ? Colors.green : Colors.grey),
            ),
          ],
        ),
        trailing: unread > 0
            ? CircleAvatar(
                backgroundColor: Colors.red,
                child: Text(
                  "$unread",
                  style: const TextStyle(color: Colors.white),
                ),
              )
            : const Icon(Icons.chevron_left),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPage(
                waId: waId,
                name: name.isEmpty ? waId : name,
                country: "${x["country"] ?? selectedCountry}",
              ),
            ),
          );
          loadAll(silent: true);
        },
      ),
    );
  }
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

class ChatPage extends StatefulWidget {
  final String waId;
  final String name;
  final String country;

  const ChatPage({
    super.key,
    required this.waId,
    required this.name,
    required this.country,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController scrollController = ScrollController();
  final AudioPlayer chatAudioPlayer = AudioPlayer();
  List msgs = [];
  bool loading = true;
  bool sending = false;
  Timer? timer;
  int lastCount = 0;
  String playingAudioUrl = "";
  final Set<String> transcribingAudio = {};
  final Map<String, String> audioTranscripts = {};
  final txt = TextEditingController();
  static const int longMessagePreviewLength = 420;

  @override
  void initState() {
    super.initState();
    chatAudioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => playingAudioUrl = "");
    });
    load();
    timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        load(silent: true);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    chatAudioPlayer.dispose();
    scrollController.dispose();
    txt.dispose();
    super.dispose();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !scrollController.hasClients) return;
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }

  void scrollToBottomNow() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
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

  Future<void> transcribeAudio(String media) async {
    if (media.isEmpty || transcribingAudio.contains(media)) return;

    setState(() => transcribingAudio.add(media));

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
      showSnack("לא הצלחתי לתמלל את ההודעה הקולית");
    } finally {
      if (mounted) {
        setState(() => transcribingAudio.remove(media));
      }
    }
  }

  Future<void> load({bool silent = false}) async {
    final previousMessages = msgs;
    var shouldScrollToBottom = false;

    if (!silent) {
      loading = true;
      if (mounted) setState(() {});
    }

    try {
      final r = await http.get(
        Uri.parse("$api/api/messages?wa_id=${widget.waId}"),
      );
      final data = jsonDecode(r.body);
      final nextMessages = data is List ? data : [];

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
      msgs = [];
    }

    loading = false;
    if (mounted) setState(() {});
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
              "msg": text,
              "country": widget.country,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (r.statusCode < 200 || r.statusCode >= 300) {
        showSnack(sendErrorMessage(r.statusCode, r.body));
        return;
      }
      txt.clear();
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
      final translated = "${data["translated"] ?? text}".trim();
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

  Widget messageTextBlock(
    String text, {
    String title = "הודעה מלאה",
    TextStyle? style,
  }) {
    final clean = text.trim();
    if (clean.isEmpty) return const SizedBox.shrink();

    final baseStyle = style ?? const TextStyle(fontSize: 17);
    if (clean.length <= longMessagePreviewLength) {
      return SelectableText(clean, style: baseStyle);
    }

    final preview = clean.substring(0, longMessagePreviewLength).trimRight();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText("$preview...", style: baseStyle),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => showFullText(title, clean),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            foregroundColor: Colors.lightBlueAccent,
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
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        allowMultiple: false,
        type: FileType.any,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final extension = fileExtension(file.name, file.extension);
      final contentType = mediaTypeForExtension(extension);
      final bytes = file.bytes;
      if (bytes == null) {
        showSnack("לא הצלחתי לקרוא את הקובץ");
        return;
      }
      if (bytes.length > 15 * 1024 * 1024) {
        showSnack("הקובץ גדול מדי. עד 15MB");
        return;
      }
      await uploadBytes(
        bytes: bytes,
        filename: file.name,
        contentType: contentType,
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
      final extension = fileExtension(picked.name, null).isEmpty
          ? "jpg"
          : fileExtension(picked.name, null);
      await uploadBytes(
        bytes: bytes,
        filename: picked.name,
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
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        allowMultiple: false,
        type: defaultTargetPlatform == TargetPlatform.iOS
            ? FileType.any
            : FileType.audio,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final extension = fileExtension(file.name, file.extension);
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
      if (extension.isNotEmpty && !audioExtensions.contains(extension)) {
        showSnack("בחר קובץ קול בלבד");
        return;
      }
      final bytes = file.bytes;
      if (bytes == null) {
        showSnack("לא הצלחתי לקרוא את קובץ הקול");
        return;
      }

      setState(() => sending = true);
      final req = http.MultipartRequest(
        "POST",
        Uri.parse("$api/api/send_voice_english"),
      );
      req.fields["wa_id"] = widget.waId;
      req.fields["country"] = widget.country;
      req.fields["filename"] = file.name;
      req.fields["mime_type"] = mediaTypeForExtension(extension).toString();
      req.files.add(
        http.MultipartFile.fromBytes(
          "file",
          bytes,
          filename: file.name,
          contentType: mediaTypeForExtension(extension),
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
      if (!serviceEnabled) { showSnack("שירות המיקום כבוי"); return; }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) { showSnack("אין הרשאת מיקום"); return; }
      }
      if (permission == LocationPermission.deniedForever) { showSnack("הרשאת מיקום חסומה"); return; }
      showSnack("🔍 מאתר מיקום...");
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).timeout(const Duration(seconds: 15));
      final mapsUrl = "https://www.google.com/maps/search/?api=1&query=${pos.latitude},${pos.longitude}";
      final msg = "📍 מיקום נוכחי\nקו רוחב: ${pos.latitude.toStringAsFixed(6)}\nקו אורך: ${pos.longitude.toStringAsFixed(6)}\n$mapsUrl";
      setState(() => sending = true);
      final r = await http.post(Uri.parse("$api/api/send"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"wa_id": widget.waId, "msg": msg, "country": widget.country})).timeout(const Duration(seconds: 15));
      if (r.statusCode >= 200 && r.statusCode < 300) { showSnack("📍 המיקום נשלח"); await load(silent: true); scrollToBottom(); }
      else { showSnack("שגיאה בשליחת מיקום"); }
    } catch (e) { showSnack("שגיאת מיקום: $e"); }
    finally { if (mounted) setState(() => sending = false); }
  }

  Future<void> recordAndSendVoiceEnglish() async {
    final recorder = FlutterSoundRecorder();
    try {
      await recorder.openRecorder();
      final dir = await getTemporaryDirectory();
      final path = "${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac";
      await recorder.startRecorder(toFile: path, codec: Codec.aacADTS);
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("🎙️ מקליט..."),
          content: const Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 12), Text("לחץ עצור כשתסיים")]),
          actions: [FilledButton.icon(icon: const Icon(Icons.stop), label: const Text("עצור ושלח"), style: FilledButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () => Navigator.pop(ctx))],
        ),
      );
      await recorder.stopRecorder();
      final file = File(path);
      if (!await file.exists()) { showSnack("לא נקלט קול"); return; }
      final bytes = await file.readAsBytes();
      setState(() => sending = true);
      final req = http.MultipartRequest("POST", Uri.parse("$api/api/send_voice_english"));
      req.fields["wa_id"] = widget.waId;
      req.fields["country"] = widget.country;
      req.fields["filename"] = "voice.aac";
      req.fields["mime_type"] = "audio/aac";
      req.files.add(http.MultipartFile.fromBytes("file", bytes, filename: "voice.aac", contentType: MediaType("audio", "aac")));
      final res = await req.send().timeout(const Duration(seconds: 90));
      if (res.statusCode >= 200 && res.statusCode < 300) { showSnack("🎙️ הקול תומלל ונשלח באנגלית"); await load(silent: true); scrollToBottom(); }
      else { showSnack("תמלול ושליחה נכשלו"); }
    } catch (e) { showSnack("שגיאת הקלטה: $e"); }
    finally { await recorder.closeRecorder(); if (mounted) setState(() => sending = false); }
  }

  Future<void> showAttachmentMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.insert_drive_file, color: Colors.orangeAccent), title: const Text("קובץ"), onTap: () => Navigator.pop(context, "file")),
            ListTile(leading: const Icon(Icons.photo_library, color: Colors.purpleAccent), title: const Text("גלריה"), onTap: () => Navigator.pop(context, "gallery")),
            ListTile(leading: const Icon(Icons.camera_alt, color: Colors.blueAccent), title: const Text("מצלמה"), onTap: () => Navigator.pop(context, "camera")),
            ListTile(leading: const Icon(Icons.location_on, color: Colors.redAccent), title: const Text("שלח מיקום"), onTap: () => Navigator.pop(context, "location")),
            ListTile(leading: const Icon(Icons.mic, color: Colors.greenAccent), title: const Text("הקלט קול → שלח באנגלית"), onTap: () => Navigator.pop(context, "record_english")),
            ListTile(leading: const Icon(Icons.audio_file, color: Colors.lightBlueAccent), title: const Text("קובץ קול → שלח באנגלית"), onTap: () => Navigator.pop(context, "voice_english")),
          ],
        ),
      ),
    );

    if (action == "file") await chooseAndSendFile();
    if (action == "gallery") await pickImageAndSend(ImageSource.gallery);
    if (action == "camera") await pickImageAndSend(ImageSource.camera);
    if (action == "location") await sendLocation();
    if (action == "record_english") await recordAndSendVoiceEnglish();
    if (action == "voice_english") await chooseAudioAndSendEnglishText();
  }

  Future<void> deleteMessage(dynamic m) async {
    final messageId = "${m["id"] ?? ""}".trim();
    if (messageId.isEmpty) {
      showSnack("אין מזהה הודעה למחיקה");
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("מחיקת הודעה"),
        content: const Text("למחוק את ההודעה הזו מהמערכת?"),
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
    if (ok != true) return;

    try {
      final r = await http.post(
        Uri.parse("$api/api/delete_message"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message_id": messageId, "wa_id": widget.waId}),
      );
      if (r.statusCode >= 200 && r.statusCode < 300) {
        showSnack("ההודעה נמחקה");
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

  Future<void> forwardMessage(dynamic m) async {
    final controller = TextEditingController();
    final forwardTo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("↪️ העברת הודעה"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: "9725XXXXXXXX"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ביטול"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("שלח"),
          ),
        ],
      ),
    );
    // controller dispose removed to avoid dialog crash

    final cleanForwardTo = (forwardTo ?? "").replaceAll(RegExp(r"\D"), "");
    if (cleanForwardTo.isEmpty) return;

    try {
      final r = await http.post(
        Uri.parse("$api/api/forward"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "from_wa_id": widget.waId,
          "forward_to": cleanForwardTo,
          "country": "${m["country"] ?? widget.country}",
          "text": "${m["text"] ?? ""}",
          "media": "${m["media"] ?? ""}",
        }),
      );

      if (r.statusCode >= 200 && r.statusCode < 300) {
        final data = jsonDecode(r.body);
        final sentCountry = data is Map ? "${data["country"] ?? ""}" : "";
        showSnack(
          sentCountry.isEmpty
              ? "↪️ ההודעה הועברה אל $cleanForwardTo"
              : "↪️ הועבר אל $cleanForwardTo דרך $sentCountry",
        );
      } else {
        showSnack("שגיאה בהעברה: ${r.statusCode}");
      }
    } catch (e) {
      showSnack("שגיאה: $e");
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

  String countryNameFor(String country) {
    final clean = country.toLowerCase().trim();
    if (clean.isEmpty) return "מדינה לא ידועה";
    for (final item in africaCountryPositions) {
      if (item.code == clean) return item.name;
    }
    if (clean == "israel") return "Israel";
    return clean
        .split("_")
        .where((part) => part.isNotEmpty)
        .map((part) => "${part[0].toUpperCase()}${part.substring(1)}")
        .join(" ");
  }

  String countryLabelFor(String country) {
    final clean = country.toLowerCase().trim();
    return "${_flagForCountry(clean)} ${countryNameFor(clean)}";
  }

  @override
  Widget build(BuildContext context) {
    final lightMode = appLightMode.value;

    return Scaffold(
      backgroundColor: lightMode
          ? const Color(0xffeef5ff)
          : const Color(0xff0b141a),
      appBar: AppBar(
        backgroundColor: lightMode
            ? const Color(0xffd8eaff)
            : const Color(0xff202c33),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.name),
            Text("📞 ${widget.waId}", style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: lightMode ? "מצב כהה" : "מצב בהיר",
            onPressed: () {
              appLightMode.value = !appLightMode.value;
              setState(() {});
            },
            icon: Icon(lightMode ? Icons.dark_mode : Icons.light_mode),
          ),
          IconButton(onPressed: () => load(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                loading
                    ? const Center(child: CircularProgressIndicator())
                    : msgs.isEmpty
                    ? const Center(
                        child: Text(
                          "אין הודעות עדיין",
                          style: TextStyle(fontSize: 20),
                        ),
                      )
                    : ListView.builder(
                        key: ValueKey("chat-${widget.waId}-${msgs.length}"),
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 82),
                        itemCount: msgs.length,
                        itemBuilder: (context, i) => bubble(msgs[i]),
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
                        backgroundColor: const Color(0xff53bdeb),
                        foregroundColor: const Color(0xff06130d),
                        child: const Icon(Icons.keyboard_double_arrow_down),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          inputBar(),
        ],
      ),
    );
  }

  Widget bubble(dynamic m) {
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

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: mine ? const Color(0xff005c4b) : const Color(0xff202c33),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              countryLabelFor(country),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            mediaWidget(effectiveType, media, text),
            if (showText) messageTextBlock(parts.first, title: "הודעה מלאה"),
            if (showText && parts.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: messageTextBlock(
                  "🌍 ${parts[1]}",
                  title: "תרגום מלא",
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.lightBlueAccent,
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
                    style: const TextStyle(fontSize: 10, color: Colors.white60),
                  ),
                ),
                const SizedBox(width: 10),
                if (showText) ...[
                  GestureDetector(
                    onTap: () => showTranslation(parts.first),
                    child: const Text(
                      "🌍 תרגם",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                GestureDetector(
                  onTap: () => forwardMessage(m),
                  child: const Text(
                    "↪️ העבר",
                    style: TextStyle(fontSize: 12, color: Colors.greenAccent),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => deleteMessage(m),
                  child: const Text(
                    "🗑️ מחק",
                    style: TextStyle(fontSize: 12, color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ],
        ),
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

  String effectiveMessageType(String type, String media) {
    if (type == "audio" || isAudioFile(media)) return "audio";
    return type;
  }

  Widget mediaWidget(String type, String media, String text) {
    if (media.isEmpty) return const SizedBox.shrink();
    final url = fileUrl(media);

    if (type == "image") {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            width: 310,
            height: 230,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                SelectableText("📷 תמונה\n$url"),
          ),
        ),
      );
    }

    if (type == "audio") return audioBox(url, media, text);
    if (type == "video") return mediaBox("🎥 וידאו", url);
    if (type == "document") return mediaBox("📄 קובץ", url);
    return mediaBox("📎 מדיה", url);
  }

  Widget mediaBox(String title, String url) {
    return Container(
      width: 310,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
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
      width: 310,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
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
                  backgroundColor: const Color(0xff25d366),
                  foregroundColor: const Color(0xff06130d),
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
                      fontSize: 15,
                      color: Colors.lightBlueAccent,
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
                        color: Colors.lightBlueAccent,
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
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(8),
        color: const Color(0xff202c33),
        child: Row(
          children: [
            IconButton(
              onPressed: sending ? null : showAttachmentMenu,
              icon: const Icon(Icons.attach_file, color: Colors.orangeAccent),
            ),
            Expanded(
              child: TextField(
                controller: txt,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "כתוב הודעה...",
                  filled: true,
                  fillColor: const Color(0xff111b21),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: sending ? null : () => sendText(translateFirst: true),
              tooltip: "שלח באנגלית",
              icon: const Icon(Icons.translate, color: Colors.lightBlueAccent),
            ),
            IconButton(
              onPressed: sending ? null : () => sendText(),
              icon: sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.greenAccent),
            ),
          ],
        ),
      ),
    );
  }
}

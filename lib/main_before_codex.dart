import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const String api = "https://arnonidan.pythonanywhere.com";
const String appPin = "6044";
const String exportContactsUrl = "$api/api/export_contacts";

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
    "morocco",
    "Morocco",
    0.26,
    0.10,
    labelX: 0.21,
    labelY: 0.04,
  ),
  AfricaCountryPosition(
    "senegal",
    "Senegal",
    0.16,
    0.39,
    labelX: 0.05,
    labelY: 0.34,
  ),
  AfricaCountryPosition(
    "gambia",
    "Gambia",
    0.14,
    0.41,
    labelX: 0.03,
    labelY: 0.43,
  ),
  AfricaCountryPosition(
    "guinea_bissau",
    "Guinea-Bissau",
    0.15,
    0.45,
    labelX: 0.03,
    labelY: 0.51,
  ),
  AfricaCountryPosition(
    "guinea",
    "Guinea",
    0.20,
    0.46,
    labelX: 0.16,
    labelY: 0.56,
  ),
  AfricaCountryPosition(
    "sierra_leone",
    "Sierra Leone",
    0.20,
    0.51,
    labelX: 0.07,
    labelY: 0.61,
  ),
  AfricaCountryPosition(
    "liberia",
    "Liberia",
    0.24,
    0.55,
    labelX: 0.18,
    labelY: 0.67,
  ),
  AfricaCountryPosition(
    "ivory_coast",
    "Ivory Coast",
    0.31,
    0.54,
    labelX: 0.30,
    labelY: 0.64,
  ),
  AfricaCountryPosition(
    "ghana",
    "Ghana",
    0.38,
    0.54,
    labelX: 0.31,
    labelY: 0.43,
  ),
  AfricaCountryPosition("togo", "Togo", 0.42, 0.54, labelX: 0.43, labelY: 0.43),
  AfricaCountryPosition(
    "benin",
    "Benin",
    0.45,
    0.53,
    labelX: 0.49,
    labelY: 0.47,
  ),
  AfricaCountryPosition(
    "nigeria",
    "Nigeria",
    0.50,
    0.52,
    labelX: 0.48,
    labelY: 0.37,
  ),
  AfricaCountryPosition(
    "cameroon",
    "Cameroon",
    0.56,
    0.58,
    labelX: 0.60,
    labelY: 0.50,
  ),
  AfricaCountryPosition(
    "central_african_republic",
    "Central African Republic",
    0.64,
    0.55,
    labelX: 0.66,
    labelY: 0.42,
  ),
  AfricaCountryPosition(
    "south_sudan",
    "South Sudan",
    0.75,
    0.52,
    labelX: 0.78,
    labelY: 0.43,
  ),
  AfricaCountryPosition(
    "dr_congo",
    "DR Congo",
    0.64,
    0.70,
    labelX: 0.55,
    labelY: 0.74,
  ),
  AfricaCountryPosition(
    "uganda",
    "Uganda",
    0.78,
    0.62,
    labelX: 0.72,
    labelY: 0.57,
  ),
  AfricaCountryPosition(
    "kenya",
    "Kenya",
    0.85,
    0.64,
    labelX: 0.87,
    labelY: 0.56,
  ),
  AfricaCountryPosition(
    "rwanda",
    "Rwanda",
    0.75,
    0.68,
    labelX: 0.67,
    labelY: 0.66,
  ),
  AfricaCountryPosition(
    "burundi",
    "Burundi",
    0.76,
    0.71,
    labelX: 0.84,
    labelY: 0.70,
  ),
  AfricaCountryPosition(
    "tanzania",
    "Tanzania",
    0.81,
    0.74,
    labelX: 0.86,
    labelY: 0.78,
  ),
  AfricaCountryPosition(
    "zambia",
    "Zambia",
    0.70,
    0.82,
    labelX: 0.61,
    labelY: 0.84,
  ),
  AfricaCountryPosition(
    "malawi",
    "Malawi",
    0.78,
    0.82,
    labelX: 0.84,
    labelY: 0.86,
  ),
  AfricaCountryPosition(
    "mozambique",
    "Mozambique",
    0.83,
    0.86,
    labelX: 0.86,
    labelY: 0.91,
  ),
  AfricaCountryPosition(
    "zimbabwe",
    "Zimbabwe",
    0.74,
    0.88,
    labelX: 0.70,
    labelY: 0.94,
  ),
  AfricaCountryPosition(
    "namibia",
    "Namibia",
    0.57,
    0.91,
    labelX: 0.47,
    labelY: 0.91,
  ),
  AfricaCountryPosition(
    "south_africa",
    "South Africa",
    0.68,
    0.97,
    labelX: 0.62,
    labelY: 0.88,
  ),
  AfricaCountryPosition(
    "lesotho",
    "Lesotho",
    0.72,
    0.98,
    labelX: 0.78,
    labelY: 0.95,
  ),
  AfricaCountryPosition(
    "mauritius",
    "Mauritius",
    0.99,
    0.92,
    labelX: 0.88,
    labelY: 0.98,
  ),
  AfricaCountryPosition(
    "sao_tome",
    "Sao Tome",
    0.47,
    0.64,
    labelX: 0.39,
    labelY: 0.70,
  ),
];

void main() {
  runApp(const ExpresphoneApp());
}

class ExpresphoneApp extends StatelessWidget {
  const ExpresphoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Expresphone WhatsApp Dashboard",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: const Color(0xff0b141a),
      ),
      home: const PinPage(),
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
    if (pin.text.trim() == appPin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(initialCountry: selectedCountry),
        ),
      );
    } else {
      setState(() => error = "קוד שגוי. נסה שוב.");
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

  Future<void> openExport() async {
    final uri = Uri.parse(exportContactsUrl);
    try {
      final r = await http.head(uri);
      if (r.statusCode == 404) {
        showSnack("ייצוא אנשי קשר עדיין לא מוכן בשרת");
        return;
      }
    } catch (_) {
      // Still try to open the browser; some servers block HEAD but allow GET.
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) showSnack("לא הצלחתי לפתוח את ייצוא אנשי הקשר");
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

  int get totalUnread => countries.fold<int>(
    0,
    (sum, item) => sum + (int.tryParse("${item["unread"] ?? 0}") ?? 0),
  );

  int get activeCountries =>
      countries.where((item) => item is Map && item["token"] == true).length;

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
    final isWide = MediaQuery.sizeOf(context).width >= 840;
    final mapPanel = _AfricaMapPanel(
      countries: countryByCode,
      selectedCountry: selectedCountry,
      loading: loadingCountries,
      totalUnread: totalUnread,
      activeCountries: activeCountries,
      onSelectCountry: selectCountry,
    );
    final loginPanel = _LoginPanel(
      pin: pin,
      error: error,
      selectedCountry: countryTitle(selectedCountry),
      onLogin: enter,
    );

    return Scaffold(
      backgroundColor: const Color(0xff0b141a),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _Header(onExport: openExport),
              const SizedBox(height: 14),
              isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: mapPanel),
                        const SizedBox(width: 14),
                        Expanded(flex: 3, child: loginPanel),
                      ],
                    )
                  : Column(
                      children: [
                        mapPanel,
                        const SizedBox(height: 14),
                        loginPanel,
                      ],
                    ),
              const SizedBox(height: 14),
              _StatsBar(
                totalCountries: africaCountryPositions.length,
                activeCountries: activeCountries,
                unread: totalUnread,
                apiCountries: countries.length,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onExport});

  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = const Row(
          children: [
            Icon(Icons.menu, size: 38, color: Colors.white),
            SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "yvohana",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    "CHAT",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xff2f8cff),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
        final exportButton = OutlinedButton.icon(
          onPressed: onExport,
          icon: const Icon(Icons.upload_file, size: 26),
          label: const Text("Export Contacts", style: TextStyle(fontSize: 18)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xff2383ff)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xff0f1a22),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white24),
          ),
          child: constraints.maxWidth < 620
              ? Column(
                  children: [
                    title,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: exportButton),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: 18),
                    exportButton,
                  ],
                ),
        );
      },
    );
  }
}

class _AfricaMapPanel extends StatelessWidget {
  const _AfricaMapPanel({
    required this.countries,
    required this.selectedCountry,
    required this.loading,
    required this.totalUnread,
    required this.activeCountries,
    required this.onSelectCountry,
  });

  final Map<String, dynamic> countries;
  final String selectedCountry;
  final bool loading;
  final int totalUnread;
  final int activeCountries;
  final ValueChanged<String> onSelectCountry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(-0.20, -0.08),
          radius: 1.08,
          colors: [Color(0xff12345d), Color(0xff071b31), Color(0xff03101d)],
          stops: [0.0, 0.54, 1.0],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xff2f8cff).withValues(alpha: 0.38),
        ),
        boxShadow: const [BoxShadow(color: Color(0x8800183f), blurRadius: 34)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "WELCOME TO",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const Text(
            "AFRICA",
            style: TextStyle(
              fontSize: 58,
              fontWeight: FontWeight.w900,
              color: Color(0xff2691ff),
            ),
          ),
          Text(
            loading
                ? "טוען מדינות..."
                : "$activeCountries פעילות, $totalUnread הודעות שלא נקראו",
            style: const TextStyle(fontSize: 20, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.08,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.78,
                        child: Image.asset(
                          "assets/africa.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    for (final country in africaCountryPositions)
                      _CountryMarker(
                        position: country,
                        data: countries[country.code],
                        selected: selectedCountry == country.code,
                        mapWidth: constraints.maxWidth,
                        mapHeight: constraints.maxHeight,
                        onTap: () => onSelectCountry(country.code),
                      ),
                  ],
                );
              },
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
    final active = data?["token"] == true;
    final statusColor = unread > 0
        ? Colors.redAccent
        : active
        ? Colors.greenAccent
        : _accentColorForCountry(position.code);
    final badgeColor = unread > 0
        ? Colors.redAccent
        : active
        ? Colors.greenAccent
        : statusColor;
    final label = "${data?["name"] ?? position.name}";
    final flag = "${data?["flag"] ?? _flagForCountry(position.code)}";
    final point = Offset(position.x * mapWidth, position.y * mapHeight);
    final tagLeft = (position.labelX * mapWidth - 56)
        .clamp(0.0, mapWidth > 116 ? mapWidth - 116 : 0.0)
        .toDouble();
    final tagTop = (position.labelY * mapHeight - 17)
        .clamp(0.0, mapHeight > 34 ? mapHeight - 34 : 0.0)
        .toDouble();
    final leaderStart = Offset(tagLeft + 58, tagTop + 39);

    return Positioned.fill(
      child: Semantics(
        button: true,
        label:
            "$label, ${unread > 0
                ? "$unread הודעות"
                : active
                ? "פעילה"
                : "לא פעילה"}",
        child: Stack(
          children: [
            CustomPaint(
              size: Size(mapWidth, mapHeight),
              painter: _CountryLeaderPainter(
                from: leaderStart,
                to: point,
                color: Colors.white,
              ),
            ),
            Positioned(
              left: point.dx - 10,
              top: point.dy - 10,
              child: _GlowDot(color: statusColor),
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
                    badgeColor: badgeColor,
                    flag: flag,
                    label: label,
                    selected: selected,
                    unread: unread,
                    active: active,
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
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..strokeWidth = 1.25
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
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.88),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.72),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.62), blurRadius: 10),
          BoxShadow(color: color.withValues(alpha: 0.34), blurRadius: 22),
        ],
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
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
    required this.flag,
    required this.label,
    required this.selected,
    required this.unread,
    required this.active,
  });

  final Color color;
  final Color badgeColor;
  final String flag;
  final String label;
  final bool selected;
  final int unread;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 42,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 27,
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: const Color(0xee101820),
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
            width: 112,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xee101820),
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
                Text(flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16,
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
                    unread > 0
                        ? (unread > 99 ? "99" : "$unread")
                        : (active ? "✓" : ""),
                    style: const TextStyle(
                      fontSize: 8,
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

Color _accentColorForCountry(String code) {
  switch (code) {
    case "ghana":
      return const Color(0xffff3b3b);
    case "nigeria":
      return const Color(0xff35d64b);
    case "cameroon":
      return const Color(0xffffc107);
    case "kenya":
      return const Color(0xffff4f4f);
    case "tanzania":
      return const Color(0xff6cff4a);
    case "dr_congo":
      return const Color(0xff31a8ff);
    case "south_africa":
      return const Color(0xfff1f5f9);
    case "uganda":
      return const Color(0xffff8c1a);
    case "zambia":
      return const Color(0xff00e5a8);
    case "burundi":
      return const Color(0xffff5bd5);
    case "liberia":
      return const Color(0xff5d8cff);
    case "gambia":
      return const Color(0xffff6b6b);
    case "sierra_leone":
      return const Color(0xff4dd7ff);
    case "malawi":
      return const Color(0xffff7043);
    case "rwanda":
      return const Color(0xffffdd33);
    case "ivory_coast":
      return const Color(0xffff9f1c);
    case "central_african_republic":
      return const Color(0xffa78bfa);
    case "morocco":
      return const Color(0xffef4444);
    case "mauritius":
      return const Color(0xff38bdf8);
    case "guinea":
      return const Color(0xffffc857);
    case "lesotho":
      return const Color(0xff60a5fa);
    case "guinea_bissau":
      return const Color(0xfff43f5e);
    case "zimbabwe":
      return const Color(0xff22c55e);
    case "benin":
      return const Color(0xffffd166);
    case "south_sudan":
      return const Color(0xff2dd4bf);
    case "togo":
      return const Color(0xff84cc16);
    case "namibia":
      return const Color(0xfffb7185);
    case "senegal":
      return const Color(0xfffacc15);
    case "mozambique":
      return const Color(0xff14b8a6);
    case "sao_tome":
      return const Color(0xffc084fc);
    default:
      return const Color(0xff9ca3af);
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
    case "sudan":
      return "🇸🇩";
    case "tanzania":
      return "🇹🇿";
    case "togo":
      return "🇹🇬";
    case "tunisia":
      return "🇹🇳";
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

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.pin,
    required this.error,
    required this.selectedCountry,
    required this.onLogin,
  });

  final TextEditingController pin;
  final String error;
  final String selectedCountry;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xff111b24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
        boxShadow: const [BoxShadow(blurRadius: 18, color: Colors.black54)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.lock, size: 30),
              SizedBox(width: 10),
              Text(
                "LOGIN",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            "מדינה נבחרת: $selectedCountry",
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: "PIN",
              prefixIcon: const Icon(Icons.pin),
              filled: true,
              fillColor: const Color(0xff07131c),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onSubmitted: (_) => onLogin(),
          ),
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                error,
                style: const TextStyle(color: Colors.redAccent, fontSize: 20),
              ),
            ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onLogin,
            icon: const Icon(Icons.login, size: 26),
            label: const Text(
              "LOGIN",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar({
    required this.totalCountries,
    required this.activeCountries,
    required this.unread,
    required this.apiCountries,
  });

  final int totalCountries;
  final int activeCountries;
  final int unread;
  final int apiCountries;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.public, "Countries", "$totalCountries"),
      (Icons.check_circle, "Active", "$activeCountries"),
      (Icons.notifications, "Unread", "$unread"),
      (Icons.sync, "Loaded", "$apiCountries"),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff0f1a22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final item in items)
            SizedBox(
              width: 190,
              child: Row(
                children: [
                  CircleAvatar(radius: 24, child: Icon(item.$1)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          item.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
  int lastTotalUnread = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    selectedCountry = widget.initialCountry;
    loadAll();
    timer = Timer.periodic(
      const Duration(seconds: 6),
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
      if (mounted) setState(() {});
    }

    try {
      final r = await http.get(Uri.parse("$api/api/countries"));
      final data = jsonDecode(r.body);
      countries = data is List ? data : [];
      final newUnread = countries.fold<int>(
        0,
        (sum, item) => sum + (int.tryParse("${item["unread"] ?? 0}") ?? 0),
      );

      if (lastTotalUnread > 0 && newUnread > lastTotalUnread && mounted) {
        SystemSound.play(SystemSoundType.alert);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("🔔 הודעה חדשה נכנסה")));
      }
      lastTotalUnread = newUnread;
    } catch (_) {
      countries = [];
    }

    loadingCountries = false;
    if (mounted) setState(() {});
  }

  Future<void> loadChats(String country, {bool silent = false}) async {
    selectedCountry = country;

    if (!silent) {
      loadingChats = true;
      if (mounted) setState(() {});
    }

    try {
      final r = await http.get(Uri.parse("$api/api/chats?country=$country"));
      final data = jsonDecode(r.body);
      chats = data is List ? data : [];
    } catch (_) {
      chats = [];
    }

    loadingChats = false;
    if (mounted) setState(() {});
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

    return Scaffold(
      backgroundColor: const Color(0xff0b141a),
      appBar: AppBar(
        backgroundColor: const Color(0xff202c33),
        title: const Text("💬 Expresphone"),
        actions: [
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
            height: 160,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: const Color(0xff111b21),
            child: loadingCountries
                ? const Center(child: CircularProgressIndicator())
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

    return GestureDetector(
      onTap: () => loadChats(code),
      child: Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: active ? Colors.green : const Color(0xff202c33),
          borderRadius: BorderRadius.circular(46),
          border: Border.all(
            color: active ? Colors.greenAccent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(flag, style: const TextStyle(fontSize: 34)),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.circle,
                    size: 10,
                    color: hasToken ? Colors.greenAccent : Colors.grey,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
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
      color: const Color(0xff202c33),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.green,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : "👤",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name.isEmpty ? "ללא שם" : name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📞 $waId"),
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
              builder: (_) =>
                  ChatPage(waId: waId, name: name.isEmpty ? waId : name),
            ),
          );
          loadAll(silent: true);
        },
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String waId;
  final String name;

  const ChatPage({super.key, required this.waId, required this.name});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController scrollController = ScrollController();
  List msgs = [];
  bool loading = true;
  bool sending = false;
  Timer? timer;
  int lastCount = 0;
  final txt = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        load(silent: true);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    scrollController.dispose();
    txt.dispose();
    super.dispose();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      loading = true;
      if (mounted) setState(() {});
    }

    try {
      final r = await http.get(
        Uri.parse("$api/api/messages?wa_id=${widget.waId}"),
      );
      final data = jsonDecode(r.body);
      msgs = data is List ? data : [];

      if (lastCount > 0 && msgs.length > lastCount && mounted) {
        SystemSound.play(SystemSoundType.alert);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("🔔 הודעה חדשה בשיחה")));
      }
      lastCount = msgs.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      });
    } catch (_) {
      msgs = [];
    }

    loading = false;
    if (mounted) setState(() {});
  }

  Future<void> sendText({bool translateFirst = false}) async {
    String text = txt.text.trim();
    if (text.isEmpty || sending) return;

    setState(() => sending = true);

    if (translateFirst) {
      text = await translateOnly(text, target: "en");
    }

    try {
      await http.post(
        Uri.parse("$api/api/send"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"wa_id": widget.waId, "msg": text}),
      );
      txt.clear();
      await load();
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<String> translateOnly(String text, {String target = "he"}) async {
    try {
      final r = await http.post(
        Uri.parse("$api/api/translate"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text, "target": target}),
      );
      final data = jsonDecode(r.body);
      return "${data["translated"] ?? text}";
    } catch (_) {
      return text;
    }
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

  Future<void> chooseAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        showSnack("לא הצלחתי לקרוא את הקובץ");
        return;
      }
      if (bytes.length > 15 * 1024 * 1024) {
        showSnack("הקובץ גדול מדי. עד 15MB");
        return;
      }

      setState(() => sending = true);

      final req = http.MultipartRequest("POST", Uri.parse("$api/api/upload"));
      req.fields["wa_id"] = widget.waId;
      req.files.add(
        http.MultipartFile.fromBytes("file", bytes, filename: file.name),
      );

      final res = await req.send();
      if (res.statusCode >= 200 && res.statusCode < 300) {
        showSnack("📎 הקובץ נשלח");
        await load();
      } else {
        showSnack("שגיאה בשליחת קובץ: ${res.statusCode}");
      }
    } catch (e) {
      showSnack("שגיאה: $e");
    } finally {
      if (mounted) setState(() => sending = false);
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

    if (forwardTo == null || forwardTo.isEmpty) return;

    try {
      final r = await http.post(
        Uri.parse("$api/api/forward"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "from_wa_id": widget.waId,
          "forward_to": forwardTo,
          "text": "${m["text"] ?? ""}",
          "media": "${m["media"] ?? ""}",
        }),
      );

      if (r.statusCode >= 200 && r.statusCode < 300) {
        showSnack("↪️ ההודעה הועברה");
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

  String flagFor(String country) {
    switch (country.toLowerCase()) {
      case "israel":
        return "🇮🇱";
      case "ghana":
        return "🇬🇭";
      case "nigeria":
        return "🇳🇬";
      case "kenya":
        return "🇰🇪";
      default:
        return "🌍";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0b141a),
      appBar: AppBar(
        backgroundColor: const Color(0xff202c33),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.name),
            Text("📞 ${widget.waId}", style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(onPressed: () => load(), icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : msgs.isEmpty
                ? const Center(
                    child: Text(
                      "אין הודעות עדיין",
                      style: TextStyle(fontSize: 20),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: msgs.length,
                    itemBuilder: (context, i) => bubble(msgs[i]),
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
    final time = "${m["time"] ?? ""}";
    final country = "${m["country"] ?? ""}";
    final parts = text.split("|||");

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
            Text(flagFor(country), style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            mediaWidget(type, media, text),
            if (type == "text" || media.isEmpty)
              Text(parts.first, style: const TextStyle(fontSize: 17)),
            if (parts.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(
                  "🌍 ${parts[1]}",
                  style: const TextStyle(color: Colors.lightBlueAccent),
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
                GestureDetector(
                  onTap: () => forwardMessage(m),
                  child: const Text(
                    "↪️ העבר",
                    style: TextStyle(fontSize: 12, color: Colors.greenAccent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

    if (type == "audio") return mediaBox("🎤 הודעה קולית", url);
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

  Widget inputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(8),
        color: const Color(0xff202c33),
        child: Row(
          children: [
            IconButton(
              onPressed: sending ? null : chooseAndSendFile,
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

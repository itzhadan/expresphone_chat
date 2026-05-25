import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

const String api = "https://arnonidan.pythonanywhere.com";
const String appPin = "6044";

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

  void enter() {
    if (pin.text.trim() == appPin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } else {
      setState(() => error = "קוד שגוי");
      SystemSound.play(SystemSoundType.alert);
    }
  }

  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0b141a),
      body: Center(
        child: Container(
          width: 330,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xff202c33),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(blurRadius: 18, color: Colors.black54)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("🔐", style: TextStyle(fontSize: 54)),
              const SizedBox(height: 12),
              const Text(
                "Expresphone Dashboard",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: pin,
                obscureText: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26),
                decoration: InputDecoration(
                  hintText: "הכנס קוד",
                  filled: true,
                  fillColor: const Color(0xff111b21),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onSubmitted: (_) => enter(),
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(error, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: enter,
                  icon: const Icon(Icons.login),
                  label: const Text("כניסה"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

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
    loadAll();
    timer = Timer.periodic(const Duration(seconds: 6), (_) => loadAll(silent: true));
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🔔 הודעה חדשה נכנסה")),
        );
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
          IconButton(onPressed: () => loadAll(), icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PinPage()));
            },
            icon: const Icon(Icons.lock),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 145,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: const Color(0xff111b21),
            child: loadingCountries
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      countryCircle("🌍", "ALL", "all", 0, true),
                      ...countries.map((x) => countryCircle(
                            "${x["flag"] ?? "🌍"}",
                            "${x["name"] ?? ""}",
                            "${x["code"] ?? ""}",
                            countryUnread(x),
                            x["token"] == true,
                          )),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
          Expanded(
            child: loadingChats
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? const Center(child: Text("אין שיחות להצגה", style: TextStyle(fontSize: 22)))
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

  Widget countryCircle(String flag, String name, String code, int unread, bool hasToken) {
    final active = selectedCountry == code;

    return GestureDetector(
      onTap: () => loadChats(code),
      child: Container(
        width: 110,
        height: 130,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: active ? Colors.green : const Color(0xff202c33),
          borderRadius: BorderRadius.circular(46),
          border: Border.all(color: active ? Colors.greenAccent : Colors.transparent, width: 2),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(flag, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 2),
                  Icon(Icons.circle, size: 10, color: hasToken ? Colors.greenAccent : Colors.grey),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      name,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize:13,fontWeight: FontWeight.bold),
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
                  child: Text("$unread", style: const TextStyle(fontSize: 11, color: Colors.white)),
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
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name.isEmpty ? "ללא שם" : name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📞 $waId"),
            const SizedBox(height: 4),
            Text(
              online ? "🟢 זמין" : (lastSeen.isEmpty ? "⚫ לא מחובר" : "נראה לאחרונה $lastSeen"),
              style: TextStyle(color: online ? Colors.green : Colors.grey),
            ),
          ],
        ),
        trailing: unread > 0
            ? CircleAvatar(backgroundColor: Colors.red, child: Text("$unread", style: const TextStyle(color: Colors.white)))
            : const Icon(Icons.chevron_left),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatPage(waId: waId, name: name.isEmpty ? waId : name)),
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
    timer = Timer.periodic(const Duration(seconds: 5), (_) => load(silent: true));
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
      final r = await http.get(Uri.parse("$api/api/messages?wa_id=${widget.waId}"));
      final data = jsonDecode(r.body);
      msgs = data is List ? data : [];

      if (lastCount > 0 && msgs.length > lastCount && mounted) {
        SystemSound.play(SystemSoundType.alert);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🔔 הודעה חדשה בשיחה")));
      }
      lastCount = msgs.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          Future.delayed(
        const Duration(milliseconds:150),
        () {
          if(
            mounted &&
            scrollController.hasClients
          ){
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration:
                const Duration(milliseconds:250),
              curve: Curves.easeOut,
            );
          }
        },
      );
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
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("סגור"))],
      ),
    );
  }

  Future<void> chooseAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true, allowMultiple: false);
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
      req.files.add(http.MultipartFile.fromBytes("file", bytes, filename: file.name));

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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ביטול")),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text("שלח")),
        ],
      ),
    );
    // no dispose here to avoid crash

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
            Row(
  children:[
    Expanded(
      child: Text(
        "📞 ${widget.waId}",
        style: const TextStyle(fontSize:12),
      ),
    ),
    IconButton(
      icon: const Icon(Icons.arrow_downward),
      onPressed: (){
        if(scrollController.hasClients){
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds:250),
            curve: Curves.easeOut,
          );
        }
      },
    ),
  ],
),
          ],
        ),
        actions: [IconButton(onPressed: () => load(), icon: const Icon(Icons.refresh))],
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : msgs.isEmpty
                    ? const Center(child: Text("אין הודעות עדיין", style: TextStyle(fontSize: 20)))
                    : ListView.builder(
                        controller: scrollController,
                        reverse: false,
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
            if (type == "text" || media.isEmpty) Text(parts.first, style: const TextStyle(fontSize: 17)),
            if (parts.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text("🌍 ${parts[1]}", style: const TextStyle(color: Colors.lightBlueAccent)),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(time, style: const TextStyle(fontSize: 10, color: Colors.white60))),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => showTranslation(parts.first),
                  child: const Text("🌍 תרגם", style: TextStyle(fontSize: 12, color: Colors.lightBlueAccent)),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => forwardMessage(m),
                  child: const Text("↪️ העבר", style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
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
            errorBuilder: (_, __, ___) => SelectableText("📷 תמונה\n$url"),
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
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
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
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send, color: Colors.greenAccent),
            ),
          ],
        ),
      ),
    );
  }
}

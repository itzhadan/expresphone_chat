import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:share_plus/share_plus.dart';

class CozyPdfPage extends StatefulWidget {
  final String apiUrl;
  const CozyPdfPage({super.key, required this.apiUrl});
  @override
  State<CozyPdfPage> createState() => _CozyPdfPageState();
}

class _CozyPdfPageState extends State<CozyPdfPage> {
  final _instruction = TextEditingController();
  Uint8List? _original;
  Uint8List? _result;
  String _name = '';
  String _status = '';
  List<dynamic>? _edits;
  List<dynamic> _counts = [];
  bool _consent = false;
  bool _busy = false;
  int _generation = 0;
  http.Client? _client;

  @override
  void dispose() {
    _generation++;
    _client?.close();
    _instruction.dispose();
    super.dispose();
  }

  void _invalidate() {
    _edits = null;
    _counts = [];
    _result = null;
  }

  Future<void> _pick() async {
    final id = ++_generation;
    setState(() => _busy = true);
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: false,
        withReadStream: true,
      );
      if (!mounted || id != _generation || picked == null) return;
      final file = picked.files.single;
      if (file.size > 5 * 1024 * 1024 || file.readStream == null) {
        throw const FormatException('בחר PDF עד 5 MB.');
      }
      final buffer = BytesBuilder(copy: false);
      await for (final chunk in file.readStream!) {
        if (!mounted || id != _generation) return;
        buffer.add(chunk);
        if (buffer.length > 5 * 1024 * 1024) {
          throw const FormatException('בחר PDF עד 5 MB.');
        }
      }
      if (!mounted || id != _generation) return;
      final raw = buffer.takeBytes();
      if (raw.length > 5 * 1024 * 1024 ||
          raw.length < 5 ||
          ascii.decode(raw.sublist(0, 5), allowInvalid: true) != '%PDF-') {
        throw const FormatException('בחר PDF תקין עד 5 MB.');
      }
      setState(() {
        _original = raw;
        _name = file.name;
        _consent = false;
        _invalidate();
        _status = 'כתוב מה להחליף ובמה. הקובץ טרם נשלח לענן.';
      });
    } catch (_) {
      if (mounted && id == _generation) {
        setState(() => _status = 'לא ניתן לקרוא את הקובץ. בחר PDF עד 5 MB.');
      }
    } finally {
      if (mounted && id == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _request(bool apply) async {
    if (_busy || !_consent || _original == null) return;
    if (apply && _edits == null) return;
    final instruction = _instruction.text.trim();
    if (!apply && instruction.isEmpty) {
      setState(() => _status = 'כתוב קודם הוראת שינוי.');
      return;
    }
    final id = ++_generation;
    final client = http.Client();
    _client = client;
    final original = _original!;
    final approvedEdits = _edits;
    setState(() {
      _busy = true;
      _result = null;
      if (!apply) _invalidate();
      _status = apply ? 'מכין טיוטה עם ההחלפות שאישרת…' : 'מכין הצעת החלפות…';
    });
    try {
      final base = widget.apiUrl.replaceFirst(RegExp(r'/api/ai/?$'), '');
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$base/api/pdf/${apply ? 'apply' : 'plan'}'),
      );
      request.fields['consent'] = 'yes';
      if (apply) {
        request.fields['confirmed'] = 'yes';
        request.fields['edits'] = jsonEncode(approvedEdits);
      } else {
        request.fields['instruction'] = instruction;
      }
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          original,
          filename: 'document.pdf',
          contentType: MediaType('application', 'pdf'),
        ),
      );
      // Deadline covers headers and body, not just the initial connection.
      final response = await (() async {
        final stream = await client.send(request);
        final bytes = BytesBuilder(copy: false);
        await for (final chunk in stream.stream) {
          bytes.add(chunk);
          if (bytes.length > 20 * 1024 * 1024) {
            throw const FormatException('הפלט גדול מדי.');
          }
        }
        return http.Response.bytes(
          bytes.takeBytes(),
          stream.statusCode,
          headers: stream.headers,
        );
      })().timeout(const Duration(seconds: 130));
      if (!mounted || id != _generation) return;
      if (response.statusCode != 200) {
        String message =
            'העיבוד נכשל (${response.statusCode}). נסה שוב מאוחר יותר.';
        try {
          final error = jsonDecode(utf8.decode(response.bodyBytes));
          if (error is Map && error['error'] is String)
            message = error['error'];
        } catch (_) {}
        throw FormatException(message);
      }
      if (apply) {
        final raw = response.bodyBytes;
        if (raw.length < 5 ||
            ascii.decode(raw.sublist(0, 5), allowInvalid: true) != '%PDF-') {
          throw const FormatException('השרת לא החזיר PDF תקין.');
        }
        setState(() {
          _result = raw;
          _edits = null;
          _status = 'הטיוטה מוכנה. שמור או שתף ובדוק את הקובץ לפני שימוש.';
        });
      } else {
        final plan = jsonDecode(utf8.decode(response.bodyBytes));
        if (plan is! Map ||
            plan['edits'] is! List ||
            (plan['edits'] as List).isEmpty ||
            (plan['edits'] as List).length > 10) {
          throw const FormatException(
            'לא התקבלה הצעת החלפות. נסה הוראה מדויקת יותר.',
          );
        }
        setState(() {
          _edits = plan['edits'];
          _counts = plan['counts'] is List ? plan['counts'] : [];
          _status = 'בדוק את כל ההחלפות, ורק אז אשר יצירת טיוטה.';
        });
      }
    } on FormatException catch (e) {
      if (mounted && id == _generation) setState(() => _status = e.message);
    } catch (_) {
      if (mounted && id == _generation) {
        setState(
          () => _status =
              'לא התקבלה תשובה בזמן או שהחיבור נכשל. לא בוצע ניסיון חוזר אוטומטי.',
        );
      }
    } finally {
      client.close();
      if (identical(_client, client)) _client = null;
      if (mounted && id == _generation) setState(() => _busy = false);
    }
  }

  void _cancel() {
    _generation++;
    _client?.close();
    _client = null;
    setState(() {
      _busy = false;
      _invalidate();
      _status =
          'ההמתנה בוטלה. עיבוד שכבר נשלח לענן עשוי להסתיים, אך תוצאתו לא תוצג.';
    });
  }

  Future<void> _share() async {
    final raw = _result;
    if (raw == null) return;
    final box = context.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              raw,
              mimeType: 'application/pdf',
              name: 'edited-draft.pdf',
            ),
          ],
          fileNameOverrides: ['edited-draft.pdf'],
          text: 'טיוטה ערוכה — לא אישור רשמי. יש לבדוק לפני שימוש.',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted)
        setState(
          () => _status = 'השיתוף לא הצליח. הטיוטה עדיין זמינה; נסה שוב.',
        );
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('עריכת PDF — טיוטה')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'החלפות טקסט קצרות בלבד · עד 5 MB ו-10 עמודים. סריקות, חתימות וטפסים אינם נתמכים. המקור לא משתנה.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.upload_file),
            label: Text(_name.isEmpty ? 'בחירת PDF' : _name),
          ),
          TextField(
            controller: _instruction,
            enabled: !_busy,
            maxLength: 2000,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'מה להחליף ובמה?',
              hintText: 'החלף את הטקסט הישן בטקסט החדש',
            ),
            onChanged: (_) => setState(_invalidate),
          ),
          CheckboxListTile(
            value: _consent,
            onChanged: _busy
                ? null
                : (v) => setState(() {
                    _consent = v ?? false;
                    _invalidate();
                  }),
            title: const Text(
              'אני מורשה לשתף את המסמך ומאשר לשלוח אותו לשרת ה-AI ואת הטקסט שבו ל-Google לצורך הצעת תיקונים.',
            ),
          ),
          FilledButton(
            onPressed: _busy || !_consent || _original == null
                ? null
                : () => _request(false),
            child: const Text('הצג החלפות לאישור'),
          ),
          if (_busy) ...[
            const LinearProgressIndicator(),
            TextButton(onPressed: _cancel, child: const Text('ביטול ההמתנה')),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_status),
          ),
          if (_edits != null) ...[
            for (var i = 0; i < _edits!.length; i++)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    'עמוד ${_edits![i]['page']} · מופעים: ${i < _counts.length ? _counts[i] : '?'}\n'
                    'מ: ${_edits![i]['old']}\nל: ${_edits![i]['new']}',
                  ),
                ),
              ),
            const Text('כל פלט יסומן כטיוטה ערוכה, ולא כאישור רשמי.'),
            FilledButton(
              onPressed: _busy ? null : () => _request(true),
              child: const Text('מאשר את ההחלפות — צור טיוטת PDF'),
            ),
          ],
          if (_result != null)
            FilledButton.icon(
              onPressed: _share,
              icon: const Icon(Icons.share),
              label: const Text('שמירה / שיתוף הטיוטה'),
            ),
        ],
      ),
    ),
  );
}

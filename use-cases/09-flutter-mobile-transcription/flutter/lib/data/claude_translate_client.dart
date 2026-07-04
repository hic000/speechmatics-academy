import 'dart:convert';

import 'package:http/http.dart' as http;

import 'translate_client.dart';

/// Claude (Anthropic Messages API) based translation client. Translates a
/// list of strings by asking the model to return a JSON array of the same
/// length and order.
class ClaudeTranslateClient implements TranslateClient {
  ClaudeTranslateClient({
    required this.apiKey,
    http.Client? client,
    this.model = 'claude-haiku-4-5-20251001',
  }) : _http = client ?? http.Client();

  final String apiKey;
  final String model;
  final http.Client _http;

  static const _maxStrings = 40;
  static const _maxChars = 6000;

  @override
  Future<List<String>> translate({
    required List<String> q,
    required String target,
    String? source,
    String format = 'text',
  }) async {
    if (q.isEmpty) return [];
    final out = <String>[];
    for (final batch in _batches(q)) {
      final prompt =
          'Translate each string in this JSON array to $target. '
          'Respond with ONLY a JSON array of strings, same length and same '
          'order as the input, no explanations, no markdown code fences.\n\n'
          '${jsonEncode(batch)}';

      final resp = await _http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': model,
          'max_tokens': 4096,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (resp.statusCode != 200) {
        throw TranslateException(_friendly(resp));
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final contentList = data['content'] as List;
      final textBlock =
          contentList.firstWhere((c) => c['type'] == 'text', orElse: () => null);
      if (textBlock == null) {
        throw TranslateException('Translation failed: empty response from Claude.');
      }
      var text = (textBlock['text'] ?? '').toString().trim();
      text = text
          .replaceAll(RegExp(r'^```json', multiLine: true), '')
          .replaceAll(RegExp(r'^```', multiLine: true), '')
          .replaceAll(RegExp(r'```$', multiLine: true), '')
          .trim();

      List decoded;
      try {
        decoded = jsonDecode(text) as List;
      } catch (_) {
        throw TranslateException('Translation failed: could not parse Claude response.');
      }
      out.addAll(decoded.map((e) => e.toString()));
    }
    return out;
  }

  Iterable<List<String>> _batches(List<String> q) sync* {
    var batch = <String>[];
    var chars = 0;
    for (final s in q) {
      if (batch.isNotEmpty &&
          (batch.length >= _maxStrings || chars + s.length > _maxChars)) {
        yield batch;
        batch = [];
        chars = 0;
      }
      batch.add(s);
      chars += s.length;
    }
    if (batch.isNotEmpty) yield batch;
  }

  String _friendly(http.Response resp) {
    String detail = resp.body;
    try {
      final m = jsonDecode(resp.body);
      if (m is Map && m['error'] is Map && m['error']['message'] != null) {
        detail = m['error']['message'].toString();
      }
    } catch (_) {}
    if (detail.length > 300) detail = '${detail.substring(0, 300)}…';
    return 'Translation failed (HTTP ${resp.statusCode}): $detail';
  }

  @override
  void dispose() => _http.close();
}

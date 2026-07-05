import 'dart:convert';

import 'package:http/http.dart' as http;

import 'translate_client.dart';

/// Google Gemini (Generative Language API) based translation client.
/// Free tier eligible (gemini-3.5-flash / gemini-2.5-flash), no billing
/// account required. Same batching / JSON contract as the other providers.
class GeminiTranslateClient implements TranslateClient {
  GeminiTranslateClient({
    required this.apiKey,
    http.Client? client,
    this.model = 'gemini-3.5-flash',
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
          'Respond with ONLY a JSON object of the form {"translations": [...]} '
          'containing the translations in the same order, no explanations.\n\n'
          '${jsonEncode(batch)}';

      final resp = await _http.post(
        Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent'),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ],
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
          },
        }),
      );

      if (resp.statusCode != 200) {
        throw TranslateException(_friendly(resp));
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw TranslateException('Translation failed: empty response from Gemini.');
      }
      final parts = candidates.first['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw TranslateException('Translation failed: empty response from Gemini.');
      }
      var text = (parts.first['text'] ?? '').toString().trim();
      text = text
          .replaceAll(RegExp(r'^```json', multiLine: true), '')
          .replaceAll(RegExp(r'^```', multiLine: true), '')
          .replaceAll(RegExp(r'```$', multiLine: true), '')
          .trim();

      Map<String, dynamic> decoded;
      try {
        decoded = jsonDecode(text) as Map<String, dynamic>;
      } catch (_) {
        throw TranslateException('Translation failed: could not parse Gemini response.');
      }
      final translations = (decoded['translations'] as List?) ?? [];
      out.addAll(translations.map((e) => e.toString()));
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

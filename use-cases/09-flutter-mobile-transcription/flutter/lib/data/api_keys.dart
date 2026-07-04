import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../app_config.dart';
import 'translate_provider.dart';

/// Resolves and stores the Speechmatics key + one API key per translation
/// provider. Priority for Speechmatics: in-app value (flutter_secure_storage)
/// → `--dart-define` fallback. Provider keys are in-app only.
class ApiKeys {
  ApiKeys([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _smKey = 'sm_api_key';

  Future<String?> speechmatics() async =>
      _nz(await _storage.read(key: _smKey)) ?? _nz(AppConfig.smKeyFromDefine);

  Future<void> setSpeechmatics(String value) =>
      _storage.write(key: _smKey, value: value.trim());

  Future<bool> hasStoredSpeechmatics() async =>
      _nz(await _storage.read(key: _smKey)) != null;

  // ---- per-provider translation keys ----
  String _storageKeyFor(TranslateProvider p) => 'translate_key_${p.id}';

  Future<String?> translateKey(TranslateProvider p) async =>
      _nz(await _storage.read(key: _storageKeyFor(p)));

  Future<void> setTranslateKey(TranslateProvider p, String value) =>
      _storage.write(key: _storageKeyFor(p), value: value.trim());

  Future<bool> hasStoredTranslateKey(TranslateProvider p) async =>
      _nz(await _storage.read(key: _storageKeyFor(p))) != null;

  static String? _nz(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
}

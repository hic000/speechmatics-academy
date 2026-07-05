import 'claude_translate_client.dart';
import 'deepseek_translate_client.dart';
import 'gemini_translate_client.dart';
import 'google_translate_client.dart';
import 'openai_translate_client.dart';
import 'translate_client.dart';

/// The translation providers the user can choose between in Settings.
enum TranslateProvider {
  google,
  claude,
  openai,
  deepseek,
  gemini;

  /// Stable id persisted in SettingsStore / used as the ApiKeys storage key.
  String get id => switch (this) {
        TranslateProvider.google => 'google',
        TranslateProvider.claude => 'claude',
        TranslateProvider.openai => 'openai',
        TranslateProvider.deepseek => 'deepseek',
        TranslateProvider.gemini => 'gemini',
      };

  /// Display label shown in Settings / the debug panel.
  String get label => switch (this) {
        TranslateProvider.google => 'Google Translate',
        TranslateProvider.claude => 'Claude',
        TranslateProvider.openai => 'OpenAI',
        TranslateProvider.deepseek => 'DeepSeek',
        TranslateProvider.gemini => 'Gemini',
      };

  /// Label for the API key input field for this provider.
  String get keyFieldLabel => switch (this) {
        TranslateProvider.google => 'Google Translate API key',
        TranslateProvider.claude => 'Claude (Anthropic) API key',
        TranslateProvider.openai => 'OpenAI API key',
        TranslateProvider.deepseek => 'DeepSeek API key',
        TranslateProvider.gemini => 'Gemini API key',
      };

  static TranslateProvider fromId(String? id) => TranslateProvider.values
      .firstWhere((p) => p.id == id, orElse: () => TranslateProvider.google);
}

/// Builds the right [TranslateClient] for the selected provider + key.
TranslateClient buildTranslateClient(TranslateProvider provider, String apiKey) {
  return switch (provider) {
    TranslateProvider.google => GoogleTranslateClient(apiKey: apiKey),
    TranslateProvider.claude => ClaudeTranslateClient(apiKey: apiKey),
    TranslateProvider.openai => OpenAITranslateClient(apiKey: apiKey),
    TranslateProvider.deepseek => DeepSeekTranslateClient(apiKey: apiKey),
    TranslateProvider.gemini => GeminiTranslateClient(apiKey: apiKey),
  };
}

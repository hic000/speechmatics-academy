/// Shared exception type for every translation provider.
class TranslateException implements Exception {
  TranslateException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Common contract every translation provider client implements. This is
/// what JobController talks to — it never needs to know which provider is
/// behind it.
abstract class TranslateClient {
  Future<List<String>> translate({
    required List<String> q,
    required String target,
    String? source,
    String format = 'text',
  });

  void dispose();
}

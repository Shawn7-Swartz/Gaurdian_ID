import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Production base URL (no trailing slash), e.g. https://your-service.up.railway.app
///
/// Build/run with:
/// `flutter run --dart-define=API_BASE_URL=https://your-service.up.railway.app`
/// `flutter build apk --dart-define=API_BASE_URL=https://...`
const String _kApiBaseFromEnv = String.fromEnvironment('API_BASE_URL');

class ApiConfig {
  ApiConfig._();

  /// Normalized API origin (scheme + host [:port], no trailing slash).
  static String get baseUrl {
    final fromEnv = _kApiBaseFromEnv.trim();
    if (fromEnv.isNotEmpty) {
      return fromEnv.endsWith('/') ? fromEnv.substring(0, fromEnv.length - 1) : fromEnv;
    }
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static bool get usesRemoteBackend => _kApiBaseFromEnv.trim().isNotEmpty;
}

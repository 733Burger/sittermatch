import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  /// Injected at runtime using --dart-define=GOOGLE_MAPS_API_KEY=your_key_here
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
}
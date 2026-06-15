// lib/config/environment_config.dart
class AppConfig {
  static const String apiUrl = String.fromEnvironment(
    'API_URL', 
    defaultValue: 'http://localhost:8000', // Safe local fallback
  );
}
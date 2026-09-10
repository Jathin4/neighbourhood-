/// Base URL of the TNN backend. Override at run time:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}

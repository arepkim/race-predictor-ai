class ApiConfig {
  // Backend Connection Settings:
  // - Android Emulator: 'http://10.0.2.2:8000'
  // - iOS Simulator / Desktop / Web: 'http://127.0.0.1:8000'
  // - Physical Device: Replace with your machine's local Wi-Fi IP
  static const String baseUrl = 'http://10.72.97.176:8000';

  // Specific endpoints
  static const String predictAllUrl = '$baseUrl/predict_all';
  static const String coachUrl = '$baseUrl/coach';
  static const String healthUrl = '$baseUrl/health';
}

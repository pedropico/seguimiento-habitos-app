class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Proxy del asistente (`mock-server/`). La app no conoce ninguna clave de
  /// IA: solo esta dirección.
  static const String asistenteUrl = String.fromEnvironment(
    'LLM_BACKEND_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}

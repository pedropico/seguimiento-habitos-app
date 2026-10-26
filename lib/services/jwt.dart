import 'dart:convert';

class Jwt {
  Jwt._();

  static Map<String, dynamic>? contenido(String token) {
    final partes = token.split('.');
    if (partes.length != 3) return null;
    try {
      final normalizado = base64Url.normalize(partes[1]);
      final json = jsonDecode(utf8.decode(base64Url.decode(normalizado)));
      return json is Map ? Map<String, dynamic>.from(json) : null;
    } catch (_) {
      return null;
    }
  }

  static int? idUsuario(String token) {
    final sub = contenido(token)?['sub'];
    if (sub is int) return sub;
    if (sub is String) return int.tryParse(sub);
    return null;
  }

  static String? email(String token) {
    final valor = contenido(token)?['email'];
    return valor is String ? valor : null;
  }
}

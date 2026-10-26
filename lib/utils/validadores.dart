class Validadores {
  Validadores._();

  static String? correo(String? valor) {
    final texto = valor?.trim() ?? '';
    final ok = texto.contains('@') && texto.contains('.') && texto.length >= 5;
    return ok ? null : 'Escribe un correo válido';
  }

  static String? password(String? valor) {
    final largo = valor?.length ?? 0;
    return (largo >= 8 && largo <= 72)
        ? null
        : 'La contraseña debe tener entre 8 y 72 caracteres';
  }

  static String? nombreHabito(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.length < 3) return 'El nombre debe tener al menos 3 caracteres';
    if (texto.length > 100) return 'El nombre no puede pasar de 100 caracteres';
    return null;
  }

  static String? frecuencia(String? valor) {
    final numero = int.tryParse(valor?.trim() ?? '');
    if (numero == null) return 'Escribe un número';
    if (numero < 1 || numero > 7) return 'Debe ser un número entre 1 y 7';
    return null;
  }
}

class Registro {
  final int id;
  final int habitoId;

  /// `YYYY-MM-DD`.
  final String fecha;

  const Registro({
    required this.id,
    required this.habitoId,
    required this.fecha,
  });

  /// `fecha` puede llegar como texto o como fecha ISO completa.
  factory Registro.fromJson(Map<String, dynamic> json) {
    final cruda = '${json['fecha'] ?? ''}';
    return Registro(
      id: (json['id'] as num?)?.toInt() ?? 0,
      habitoId: (json['habito_id'] as num?)?.toInt() ?? 0,
      fecha: cruda.length >= 10 ? cruda.substring(0, 10) : cruda,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'habito_id': habitoId,
        'fecha': fecha,
      };

  factory Registro.fromMap(Map mapa) =>
      Registro.fromJson(Map<String, dynamic>.from(mapa));
}

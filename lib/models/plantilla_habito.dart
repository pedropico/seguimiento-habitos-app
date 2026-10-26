class PlantillaHabito {
  final String id;
  final String nombre;
  final String categoria;
  final String descripcion;
  final int frecuenciaSugerida;

  const PlantillaHabito({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.descripcion,
    required this.frecuenciaSugerida,
  });

  factory PlantillaHabito.fromJson(Map<String, dynamic> json) =>
      PlantillaHabito(
        id: '${json['id'] ?? ''}',
        nombre: (json['nombre'] as String?) ?? 'Hábito',
        categoria: (json['categoria'] as String?) ?? 'otros',
        descripcion: (json['descripcion'] as String?) ?? '',
        frecuenciaSugerida:
            (json['frecuencia_sugerida'] as num?)?.toInt().clamp(1, 7) ?? 3,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'categoria': categoria,
        'descripcion': descripcion,
        'frecuencia_sugerida': frecuenciaSugerida,
      };

  factory PlantillaHabito.fromMap(Map mapa) =>
      PlantillaHabito.fromJson(Map<String, dynamic>.from(mapa));
}

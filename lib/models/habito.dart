import 'registro.dart';

class Habito {
  final int id;
  final String nombre;

  final int frecuenciaObjetivo;
  final bool activo;
  final List<Registro> registros;

  const Habito({
    required this.id,
    required this.nombre,
    required this.frecuenciaObjetivo,
    this.activo = true,
    this.registros = const [],
  });

  factory Habito.fromJson(Map<String, dynamic> json) {
    return Habito(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: (json['nombre'] as String?)?.trim().isNotEmpty == true
          ? (json['nombre'] as String).trim()
          : 'Hábito sin nombre',
      frecuenciaObjetivo: (json['frecuencia_objetivo'] as num?)?.toInt() ?? 1,
      activo: json['activo'] as bool? ?? true,
      registros: (json['registros'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => Registro.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'frecuencia_objetivo': frecuenciaObjetivo,
        'activo': activo,
        'registros': registros.map((r) => r.toMap()).toList(),
      };

  factory Habito.fromMap(Map mapa) =>
      Habito.fromJson(Map<String, dynamic>.from(mapa));

  Habito copyWith({List<Registro>? registros, bool? activo}) => Habito(
        id: id,
        nombre: nombre,
        frecuenciaObjetivo: frecuenciaObjetivo,
        activo: activo ?? this.activo,
        registros: registros ?? this.registros,
      );

  Set<String> get _fechas => registros.map((r) => r.fecha).toSet();

  static String _clave(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  bool marcadoHoy({DateTime? hoy}) =>
      _fechas.contains(_clave(hoy ?? DateTime.now()));

  int cumplidosEnSemana({DateTime? hoy}) {
    final base = hoy ?? DateTime.now();
    final fechas = _fechas;
    var total = 0;
    for (var i = 0; i < 7; i++) {
      if (fechas.contains(_clave(base.subtract(Duration(days: i))))) total++;
    }
    return total;
  }

  int get racha {
    final fechas = _fechas;
    if (fechas.isEmpty) return 0;
    final hoy = DateTime.now();
    var dia = fechas.contains(_clave(hoy))
        ? hoy
        : hoy.subtract(const Duration(days: 1));
    var total = 0;
    while (fechas.contains(_clave(dia))) {
      total++;
      dia = dia.subtract(const Duration(days: 1));
    }
    return total;
  }

  double get avanceSemanal {
    if (frecuenciaObjetivo <= 0) return 0;
    final avance = cumplidosEnSemana() / frecuenciaObjetivo;
    return avance > 1 ? 1 : avance;
  }
}

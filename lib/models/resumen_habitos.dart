import 'habito.dart';

class ResumenHabito {
  final String nombre;
  final int objetivoSemanal;
  final int cumplidosSemana;
  final int racha;
  final bool marcadoHoy;

  const ResumenHabito({
    required this.nombre,
    required this.objetivoSemanal,
    required this.cumplidosSemana,
    required this.racha,
    required this.marcadoHoy,
  });

  factory ResumenHabito.desde(Habito h) => ResumenHabito(
        nombre: h.nombre,
        objetivoSemanal: h.frecuenciaObjetivo,
        cumplidosSemana: h.cumplidosEnSemana(),
        racha: h.racha,
        marcadoHoy: h.marcadoHoy(),
      );

  factory ResumenHabito.fromJson(Map<String, dynamic> json) => ResumenHabito(
        nombre: (json['nombre'] as String?) ?? '',
        objetivoSemanal: (json['objetivo_semanal'] as num?)?.toInt() ?? 0,
        cumplidosSemana: (json['cumplidos_semana'] as num?)?.toInt() ?? 0,
        racha: (json['racha'] as num?)?.toInt() ?? 0,
        marcadoHoy: json['marcado_hoy'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'objetivo_semanal': objetivoSemanal,
        'cumplidos_semana': cumplidosSemana,
        'racha': racha,
        'marcado_hoy': marcadoHoy,
      };
}

class ResumenHabitos {
  final List<ResumenHabito> habitos;

  const ResumenHabitos({required this.habitos});

  factory ResumenHabitos.desde(List<Habito> lista) =>
      ResumenHabitos(habitos: lista.map(ResumenHabito.desde).toList());

  factory ResumenHabitos.fromJson(Map<String, dynamic> json) => ResumenHabitos(
        habitos: (json['habitos'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => ResumenHabito.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );

  Map<String, dynamic> toJson() =>
      {'habitos': habitos.map((h) => h.toJson()).toList()};
}

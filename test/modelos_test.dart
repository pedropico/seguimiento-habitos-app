import 'package:seguimiento_habitos_app/models/habito.dart';
import 'package:seguimiento_habitos_app/models/registro.dart';
import 'package:seguimiento_habitos_app/utils/validadores.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String clave(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Habito conFechas(List<DateTime> dias, {int objetivo = 5}) => Habito(
        id: 1,
        nombre: 'Caminar 30 minutos',
        frecuenciaObjetivo: objetivo,
        registros: [
          for (var i = 0; i < dias.length; i++)
            Registro(id: i + 1, habitoId: 1, fecha: clave(dias[i])),
        ],
      );

  final hoy = DateTime.now();
  DateTime haceDias(int n) => hoy.subtract(Duration(days: n));

  group('Habito · estado derivado', () {
    test('un hábito sin registros no tiene racha ni avance', () {
      final h = conFechas([]);
      expect(h.racha, 0);
      expect(h.cumplidosEnSemana(), 0);
      expect(h.avanceSemanal, 0);
      expect(h.marcadoHoy(), isFalse);
    });

    test('marcadoHoy distingue hoy de ayer', () {
      expect(conFechas([hoy]).marcadoHoy(), isTrue);
      expect(conFechas([haceDias(1)]).marcadoHoy(), isFalse);
    });

    test('la racha cuenta los días consecutivos hasta hoy', () {
      final h = conFechas([hoy, haceDias(1), haceDias(2)]);
      expect(h.racha, 3);
    });

    test('un hueco rompe la racha', () {
      final h = conFechas([hoy, haceDias(2), haceDias(3)]);
      expect(h.racha, 1);
    });

    test('si hoy aún no se marcó, la racha se cuenta desde ayer', () {
      final h = conFechas([haceDias(1), haceDias(2)]);
      expect(h.marcadoHoy(), isFalse);
      expect(h.racha, 2);
    });

    test('cumplidosEnSemana solo mira los últimos siete días', () {
      final h = conFechas([hoy, haceDias(3), haceDias(6), haceDias(9)]);
      expect(h.cumplidosEnSemana(), 3);
    });

    test('el avance semanal nunca pasa de 1', () {
      final h = conFechas(
        [for (var i = 0; i < 7; i++) haceDias(i)],
        objetivo: 3,
      );
      expect(h.cumplidosEnSemana(), 7);
      expect(h.avanceSemanal, 1);
    });
  });

  group('Habito · parseo defensivo', () {
    test('un JSON incompleto no tumba el modelo', () {
      final h = Habito.fromJson({'id': 7});
      expect(h.id, 7);
      expect(h.nombre, 'Hábito sin nombre');
      expect(h.frecuenciaObjetivo, 1);
      expect(h.activo, isTrue);
      expect(h.registros, isEmpty);
    });

    test('un campo con el tipo equivocado usa el valor de reserva', () {
      final h = Habito.fromJson({
        'id': 3,
        'nombre': '   ',
        'frecuencia_objetivo': 4.0,
        'activo': null,
      });
      expect(h.nombre, 'Hábito sin nombre');
      expect(h.frecuenciaObjetivo, 4);
      expect(h.activo, isTrue);
    });

    test('toMap y fromMap reconstruyen el mismo hábito (caché de Hive)', () {
      final original = conFechas([hoy, haceDias(1)]);
      final copia = Habito.fromMap(original.toMap());
      expect(copia.id, original.id);
      expect(copia.nombre, original.nombre);
      expect(copia.frecuenciaObjetivo, original.frecuenciaObjetivo);
      expect(copia.registros.length, original.registros.length);
      expect(copia.racha, original.racha);
    });
  });

  group('Registro', () {
    test('recorta una fecha ISO con hora a YYYY-MM-DD', () {
      final r = Registro.fromJson({
        'id': 1,
        'habito_id': 2,
        'fecha': '2026-10-21T18:30:00',
      });
      expect(r.fecha, '2026-10-21');
    });
  });

  group('Validadores · las mismas reglas que el backend', () {
    test('el correo necesita arroba y punto', () {
      expect(Validadores.correo('ana@ejemplo.com'), isNull);
      expect(Validadores.correo('ana-ejemplo.com'), isNotNull);
      expect(Validadores.correo(''), isNotNull);
    });

    test('la contraseña va de 8 a 72 caracteres', () {
      expect(Validadores.password('clave123'), isNull);
      expect(Validadores.password('abc'), isNotNull);
      expect(Validadores.password('x' * 73), isNotNull);
    });

    test('el nombre del hábito necesita 3 caracteres limpios (R1)', () {
      expect(Validadores.nombreHabito('Leer'), isNull);
      expect(Validadores.nombreHabito('  ab  '), isNotNull);
      expect(Validadores.nombreHabito('x' * 101), isNotNull);
    });

    test('la frecuencia va de 1 a 7 (R2)', () {
      expect(Validadores.frecuencia('5'), isNull);
      expect(Validadores.frecuencia('0'), isNotNull);
      expect(Validadores.frecuencia('8'), isNotNull);
      expect(Validadores.frecuencia('tres'), isNotNull);
    });
  });
}

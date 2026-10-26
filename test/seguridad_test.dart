import 'dart:convert';

import 'package:seguimiento_habitos_app/services/ai_assistant_service.dart';
import 'package:seguimiento_habitos_app/services/jwt.dart';
import 'package:seguimiento_habitos_app/utils/reporte_errores.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String tokenDePrueba(Map<String, dynamic> contenido) {
    String parte(Map<String, dynamic> m) =>
        base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
    return '${parte({'alg': 'HS256', 'typ': 'JWT'})}'
        '.${parte(contenido)}'
        '.firmaFalsaQueLaAppNoComprueba';
  }

  group('Jwt · leer el contenido del token', () {
    test('extrae el id del usuario desde «sub»', () {
      final t = tokenDePrueba({'sub': '42', 'email': 'ana@ejemplo.com'});
      expect(Jwt.idUsuario(t), 42);
      expect(Jwt.email(t), 'ana@ejemplo.com');
    });

    test('un token mal formado devuelve null en vez de lanzar', () {
      expect(Jwt.contenido('esto-no-es-un-jwt'), isNull);
      expect(Jwt.idUsuario('a.b.c'), isNull);
      expect(Jwt.idUsuario(''), isNull);
    });

    test('un «sub» que no es un número devuelve null', () {
      expect(Jwt.idUsuario(tokenDePrueba({'sub': 'ana'})), isNull);
    });
  });

  group('AccionPropuesta · la respuesta de la IA es un dato, no código', () {
    test('acepta una acción de marcar bien formada', () {
      final a = AccionPropuesta.desdeJson(
          {'tipo': 'marcar_habito', 'nombre': '  Leer 20 páginas  '});
      expect(a, isNotNull);
      expect(a!.tipo, 'marcar_habito');
      expect(a.nombre, 'Leer 20 páginas');
    });

    test('acepta una acción de crear con frecuencia válida', () {
      final a = AccionPropuesta.desdeJson({
        'tipo': 'crear_habito',
        'nombre': 'Meditar',
        'frecuencia_objetivo': 5,
      });
      expect(a?.frecuenciaObjetivo, 5);
    });

    test('descarta un tipo desconocido', () {
      expect(
        AccionPropuesta.desdeJson({'tipo': 'borrar_todo', 'nombre': 'Caminar'}),
        isNull,
      );
    });

    test('descarta una acción sin nombre', () {
      expect(
        AccionPropuesta.desdeJson({'tipo': 'marcar_habito', 'nombre': '   '}),
        isNull,
      );
    });

    test('descarta crear_habito con la frecuencia fuera de 1 a 7', () {
      for (final f in [0, 8, -3]) {
        expect(
          AccionPropuesta.desdeJson({
            'tipo': 'crear_habito',
            'nombre': 'Correr',
            'frecuencia_objetivo': f,
          }),
          isNull,
          reason: 'la frecuencia $f debería rechazarse',
        );
      }
    });

    test('descarta crear_habito sin frecuencia', () {
      expect(
        AccionPropuesta.desdeJson({'tipo': 'crear_habito', 'nombre': 'Correr'}),
        isNull,
      );
    });

    test('una respuesta sin acción deja solo el texto', () {
      final r = RespuestaIA.fromJson({'respuesta': 'Vas bien.'});
      expect(r.respuesta, 'Vas bien.');
      expect(r.accion, isNull);
    });

    test('una acción basura se descarta pero el texto se conserva', () {
      final r = RespuestaIA.fromJson(
          {'respuesta': 'Vas bien.', 'accion': 'rm -rf /'});
      expect(r.respuesta, 'Vas bien.');
      expect(r.accion, isNull);
    });
  });

  group('ReporteErrores · ningún token en los registros', () {
    test('borra una cabecera Authorization: Bearer', () {
      const sucio =
          'DioException: petición con Authorization: Bearer abc.def.ghi fallida';
      final limpio = ReporteErrores.limpiar(sucio);
      expect(limpio, contains('Bearer ***'));
      expect(limpio, isNot(contains('abc.def.ghi')));
    });

    test('borra un JWT suelto en el texto', () {
      const sucio =
          'token=eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI0MiJ9.firmafalsa al guardar';
      final limpio = ReporteErrores.limpiar(sucio);
      expect(limpio, contains('***'));
      expect(limpio, isNot(contains('eyJhbGciOiJIUzI1NiJ9')));
    });

    test('un mensaje sin credenciales no se toca', () {
      const limpio = 'No hay conexión con el servidor.';
      expect(ReporteErrores.limpiar(limpio), limpio);
    });
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seguimiento_habitos_app/controllers/auth_controller.dart';
import 'package:seguimiento_habitos_app/services/api_client.dart';
import 'package:seguimiento_habitos_app/services/habitos_api_service.dart';
import 'package:seguimiento_habitos_app/services/secure_token_storage.dart';

class _AdaptadorFijo implements HttpClientAdapter {
  _AdaptadorFijo(this.datos);

  final String datos;

  @override
  Future<ResponseBody> fetch(
      RequestOptions opciones, Stream<List<int>>? _, Future<void>? __) async {
    return ResponseBody.fromString(datos, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

class _AlmacenFalso extends SecureTokenStorage {
  String? guardado;

  @override
  Future<String?> leer() async => guardado;

  @override
  Future<void> guardar(String token) async => guardado = token;

  @override
  Future<void> borrar() async => guardado = null;
}

ApiClient _clienteQueResponde(String datos) => ApiClient(
    dio: Dio(BaseOptions(baseUrl: 'http://prueba'))
      ..httpClientAdapter = _AdaptadorFijo(datos));

void main() {
  group('HabitosApiService ante respuestas con otra forma', () {
    test('crear: un texto en vez de un objeto es un error claro', () {
      final api = HabitosApiService(_clienteQueResponde('"ok"'));

      expect(api.crear('Leer', 5), throwsA(isA<ApiException>()));
    });

    test('actualizar: una lista en vez de un objeto es un error claro', () {
      final api = HabitosApiService(_clienteQueResponde('[]'));

      expect(
          api.actualizar(1, {'nombre': 'Leer'}), throwsA(isA<ApiException>()));
    });

    test('marcar: una respuesta vacía es un error claro', () {
      final api = HabitosApiService(_clienteQueResponde('null'));

      expect(api.marcar(1), throwsA(isA<ApiException>()));
    });
  });

  group('AuthController ante un login sin token', () {
    test('muestra un mensaje y no deja la sesión iniciada', () async {
      final almacen = _AlmacenFalso();
      final auth = AuthController(
        api: _clienteQueResponde('{"token_type": "bearer"}'),
        almacen: almacen,
      );

      await auth.iniciarSesion('ana@correo.com', 'contraseña1');

      expect(auth.mensajeError.value, isNotEmpty);
      expect(auth.estaAutenticado, isFalse);
      expect(auth.cargando.value, isFalse);
      expect(almacen.guardado, isNull);
    });
  });
}

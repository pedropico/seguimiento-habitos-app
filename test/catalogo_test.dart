import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:seguimiento_habitos_app/models/plantilla_habito.dart';
import 'package:seguimiento_habitos_app/repositories/catalogo_repository.dart';
import 'package:seguimiento_habitos_app/services/api_client.dart';
import 'package:seguimiento_habitos_app/services/catalogo_service.dart';
import 'package:seguimiento_habitos_app/services/sugerencias_api_service.dart';

class _ApiFalsa extends SugerenciasApiService {
  _ApiFalsa() : super(ApiClient());

  List<PlantillaHabito> aDevolver = const [];
  ApiException? aLanzar;

  @override
  Future<List<PlantillaHabito>> listar({int skip = 0, int limit = 20}) async {
    final error = aLanzar;
    if (error != null) throw error;
    return [...aDevolver];
  }
}

class _AdaptadorFijo implements HttpClientAdapter {
  _AdaptadorFijo(this.datos);

  final String datos;
  RequestOptions? ultima;

  @override
  Future<ResponseBody> fetch(
      RequestOptions opciones, Stream<List<int>>? _, Future<void>? __) async {
    ultima = opciones;
    return ResponseBody.fromString(datos, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

const _agua = PlantillaHabito(
  id: '1',
  nombre: 'Beber 8 vasos de agua',
  categoria: 'salud',
  descripcion: 'Repartir unos dos litros a lo largo del día.',
  frecuenciaSugerida: 7,
);

const _caminar = PlantillaHabito(
  id: '2',
  nombre: 'Caminar 30 minutos',
  categoria: 'movimiento',
  descripcion: 'Una caminata continua a paso vivo.',
  frecuenciaSugerida: 5,
);

void main() {
  group('SugerenciasApiService', () {
    test('pide /sugerencias/ con el límite de 20 y lee los campos', () async {
      final adaptador = _AdaptadorFijo('[{"id": 1, "nombre": "Beber agua", '
          '"categoria": "salud", "descripcion": "Dos litros.", '
          '"frecuencia_sugerida": 7}]');
      final dio = Dio(BaseOptions(baseUrl: 'http://prueba'))
        ..httpClientAdapter = adaptador;

      final lista = await SugerenciasApiService(ApiClient(dio: dio)).listar();

      expect(adaptador.ultima?.path, '/sugerencias/');
      expect(adaptador.ultima?.queryParameters, {'skip': 0, 'limit': 20});
      expect(lista.single.id, '1');
      expect(lista.single.frecuenciaSugerida, 7);
    });

    test('descarta registros sin id y no pasa del límite', () async {
      final registros = [
        '{"nombre": "Sin id"}',
        for (var i = 1; i <= 25; i++) '{"id": $i, "nombre": "Hábito $i"}',
      ];
      final dio = Dio(BaseOptions(baseUrl: 'http://prueba'))
        ..httpClientAdapter = _AdaptadorFijo('[${registros.join(',')}]');

      final lista = await SugerenciasApiService(ApiClient(dio: dio)).listar();

      expect(lista, hasLength(20));
      expect(lista.any((p) => p.nombre == 'Sin id'), isFalse);
    });

    test('una respuesta que no es lista es un error claro', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://prueba'))
        ..httpClientAdapter = _AdaptadorFijo('{"detail": "raro"}');

      expect(SugerenciasApiService(ApiClient(dio: dio)).listar(),
          throwsA(isA<ApiException>()));
    });
  });

  group('CatalogoRepository', () {
    late Directory carpeta;
    late _ApiFalsa api;
    late CatalogoRepository repo;

    setUp(() async {
      carpeta = await Directory.systemTemp
          .createTemp('seguimiento_habitos_app_test_');
      Hive.init(carpeta.path);
      await CatalogoService.abrir();
      api = _ApiFalsa();
      repo = CatalogoRepository(api);
    });

    tearDown(() async {
      await Hive.close();
      if (carpeta.existsSync()) carpeta.deleteSync(recursive: true);
    });

    test('con servidor, devuelve las sugerencias ordenadas y las guarda',
        () async {
      api.aDevolver = const [_caminar, _agua];

      final (lista, deCache) = await repo.obtenerSugerencias();

      expect(deCache, isFalse);
      expect(lista.map((p) => p.nombre),
          ['Beber 8 vasos de agua', 'Caminar 30 minutos']);
      expect(CatalogoService.plantillasGuardadas(), hasLength(2));
    });

    test('sin conexión, usa la última copia guardada', () async {
      api.aDevolver = const [_agua];
      await repo.obtenerSugerencias();

      api.aLanzar = ApiException('Sin conexión');
      final (lista, deCache) = await repo.obtenerSugerencias();

      expect(deCache, isTrue);
      expect(lista.single.id, '1');
      expect(repo.ultimaSincronizacion, isNot('desconocida'));
    });

    test('sin conexión y sin copia previa, propaga el error', () async {
      api.aLanzar = ApiException('Sin conexión');

      expect(repo.obtenerSugerencias(), throwsA(isA<ApiException>()));
    });

    test('un error de petición (4xx) no se tapa con la copia', () async {
      api.aDevolver = const [_agua];
      await repo.obtenerSugerencias();

      api.aLanzar = ApiException('No encontrado', statusCode: 404);

      expect(repo.obtenerSugerencias(), throwsA(isA<ApiException>()));
    });

    test('una sugerencia retirada del servidor desaparece de la copia',
        () async {
      api.aDevolver = const [_agua, _caminar];
      await repo.obtenerSugerencias();

      api.aDevolver = const [_agua];
      await repo.obtenerSugerencias();

      expect(CatalogoService.plantillasGuardadas()?.map((p) => p.id), ['1']);
    });
  });
}

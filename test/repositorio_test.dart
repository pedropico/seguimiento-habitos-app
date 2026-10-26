import 'dart:io';

import 'package:seguimiento_habitos_app/models/habito.dart';
import 'package:seguimiento_habitos_app/models/registro.dart';
import 'package:seguimiento_habitos_app/repositories/habitos_repository.dart';
import 'package:seguimiento_habitos_app/services/api_client.dart';
import 'package:seguimiento_habitos_app/services/habitos_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class _ApiFalsa extends HabitosApiService {
  _ApiFalsa() : super(ApiClient());

  List<Habito> aDevolver = const [];
  ApiException? aLanzar;
  int llamadas = 0;

  @override
  Future<List<Habito>> listar({int skip = 0, int limit = 100}) async {
    llamadas++;
    final error = aLanzar;
    if (error != null) throw error;
    return aDevolver;
  }

  @override
  Future<List<Registro>> registrosDe(int habitoId, {int limit = 60}) async {
    final error = aLanzar;
    if (error != null) throw error;
    return aDevolver
        .firstWhere((h) => h.id == habitoId,
            orElse: () =>
                const Habito(id: 0, nombre: '', frecuenciaObjetivo: 1))
        .registros;
  }
}

void main() {
  late Directory carpeta;
  late _ApiFalsa api;
  late HabitosRepository repo;

  setUp(() async {
    carpeta =
        await Directory.systemTemp.createTemp('seguimiento_habitos_app_test_');
    Hive.init(carpeta.path);
    api = _ApiFalsa();
    repo = HabitosRepository(api);
    await repo.abrirParaUsuario(7);
  });

  tearDown(() async {
    await Hive.close();
    if (carpeta.existsSync()) carpeta.deleteSync(recursive: true);
  });

  const unHabito = Habito(
    id: 1,
    nombre: 'Caminar 30 minutos',
    frecuenciaObjetivo: 5,
  );

  test('con servidor devuelve sus datos y no marca caché', () async {
    api.aDevolver = [unHabito];
    final (lista, deCache) = await repo.obtenerHabitos();

    expect(lista.single.nombre, 'Caminar 30 minutos');
    expect(deCache, isFalse);
  });

  test('sin conexión y con copia guardada, devuelve la copia marcada',
      () async {
    api.aDevolver = [unHabito];
    await repo.obtenerHabitos();

    api.aLanzar = ApiException('No hay conexión con el servidor.');
    final (lista, deCache) = await repo.obtenerHabitos();

    expect(lista.single.nombre, 'Caminar 30 minutos');
    expect(deCache, isTrue);
    expect(repo.ultimaSincronizacion, isNot('desconocida'));
  });

  test('un 500 también usa la copia: es falla de infraestructura', () async {
    api.aDevolver = [unHabito];
    await repo.obtenerHabitos();

    api.aLanzar =
        ApiException('El servidor tuvo un problema.', statusCode: 503);
    final (_, deCache) = await repo.obtenerHabitos();

    expect(deCache, isTrue);
  });

  test('un 401 NO usa la copia: la sesión caducó y hay que decirlo', () async {
    api.aDevolver = [unHabito];
    await repo.obtenerHabitos();

    api.aLanzar = ApiException('Tu sesión caducó.', statusCode: 401);

    expect(() => repo.obtenerHabitos(), throwsA(isA<ApiException>()));
  });

  test('un 404 NO usa la copia: es un error de la petición', () async {
    api.aDevolver = [unHabito];
    await repo.obtenerHabitos();

    api.aLanzar = ApiException('Hábito no encontrado', statusCode: 404);
    expect(() => repo.obtenerHabitos(), throwsA(isA<ApiException>()));
  });

  test('sin copia previa, un fallo de red se propaga', () async {
    api.aLanzar = ApiException('No hay conexión con el servidor.');
    expect(() => repo.obtenerHabitos(), throwsA(isA<ApiException>()));
  });

  test('cada carga exitosa reemplaza la copia entera', () async {
    api.aDevolver = [
      unHabito,
      const Habito(id: 2, nombre: 'Leer', frecuenciaObjetivo: 6),
    ];
    await repo.obtenerHabitos();

    api.aDevolver = [unHabito];
    await repo.obtenerHabitos();

    api.aLanzar = ApiException('Sin conexión');
    final (lista, deCache) = await repo.obtenerHabitos();

    expect(deCache, isTrue);
    expect(lista.length, 1);
    expect(lista.single.nombre, 'Caminar 30 minutos');
  });

  test('vaciar borra la caja del usuario (cerrar sesión)', () async {
    api.aDevolver = [unHabito];
    await repo.obtenerHabitos();

    await repo.vaciar();

    api.aLanzar = ApiException('Sin conexión');
    expect(() => repo.obtenerHabitos(), throwsA(isA<ApiException>()));
  });
}

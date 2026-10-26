import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:seguimiento_habitos_app/controllers/asistente_controller.dart';
import 'package:seguimiento_habitos_app/controllers/auth_controller.dart';
import 'package:seguimiento_habitos_app/controllers/habitos_controller.dart';
import 'package:seguimiento_habitos_app/models/habito.dart';
import 'package:seguimiento_habitos_app/models/registro.dart';
import 'package:seguimiento_habitos_app/models/resumen_habitos.dart';
import 'package:seguimiento_habitos_app/services/ai_assistant_service.dart';
import 'package:seguimiento_habitos_app/services/api_client.dart';
import 'package:seguimiento_habitos_app/services/habitos_api_service.dart';
import 'package:seguimiento_habitos_app/services/secure_token_storage.dart';

class _AsistenteFalso extends AiAssistantService {
  _AsistenteFalso() : super(api: ApiClient(), dio: Dio());

  RespuestaIA aDevolver = const RespuestaIA(respuesta: 'Vas bien.');
  AsistenteException? aLanzar;
  ResumenHabitos? resumenRecibido;

  @override
  Future<RespuestaIA> preguntar(String consulta, ResumenHabitos resumen) async {
    resumenRecibido = resumen;
    final error = aLanzar;
    if (error != null) throw error;
    return aDevolver;
  }
}

class _HabitosApiFalsa extends HabitosApiService {
  _HabitosApiFalsa() : super(ApiClient());

  final List<int> marcados = [];
  final List<String> creados = [];
  ApiException? aLanzar;

  @override
  Future<List<Habito>> listar({int skip = 0, int limit = 100}) async =>
      const [];

  @override
  Future<Registro> marcar(int id, {String? fecha}) async {
    final error = aLanzar;
    if (error != null) throw error;
    marcados.add(id);
    return Registro(id: 1, habitoId: id, fecha: '2026-10-25');
  }

  @override
  Future<Habito> crear(String nombre, int frecuenciaObjetivo) async {
    creados.add(nombre);
    return Habito(
        id: 9, nombre: nombre, frecuenciaObjetivo: frecuenciaObjetivo);
  }
}

class _AlmacenFalso extends SecureTokenStorage {
  @override
  Future<String?> leer() async => null;
}

void main() {
  late _AsistenteFalso servicio;
  late _HabitosApiFalsa api;
  late HabitosController habitos;
  late AsistenteController asistente;

  setUp(() {
    servicio = _AsistenteFalso();
    api = _HabitosApiFalsa();
    habitos = HabitosController(
      auth: AuthController(api: ApiClient(), almacen: _AlmacenFalso()),
      api: api,
    );
    habitos.habitos.assignAll(const [
      Habito(id: 3, nombre: 'Caminar 30 minutos', frecuenciaObjetivo: 5),
    ]);
    asistente = AsistenteController(servicio: servicio, habitos: habitos);
  });

  group('preguntar', () {
    test('guarda la respuesta y envía el resumen de los hábitos', () async {
      final accion = await asistente.preguntar('¿Cómo voy?');

      expect(accion, isNull);
      expect(asistente.respuesta.value, 'Vas bien.');
      expect(asistente.mensajeError.value, isEmpty);
      expect(asistente.cargando.value, isFalse);
      expect(servicio.resumenRecibido?.habitos.single.nombre,
          'Caminar 30 minutos');
    });

    test('un error del proxy queda en mensajeError, sin respuesta', () async {
      servicio.aLanzar = AsistenteException('Proxy apagado');

      await asistente.preguntar('¿Cómo voy?');

      expect(asistente.mensajeError.value, 'Proxy apagado');
      expect(asistente.respuesta.value, isEmpty);
      expect(asistente.cargando.value, isFalse);
    });

    test('una consulta vacía no llama al proxy', () async {
      await asistente.preguntar('   ');

      expect(servicio.resumenRecibido, isNull);
    });

    test('devuelve la acción propuesta sin ejecutarla', () async {
      servicio.aDevolver = const RespuestaIA(
        respuesta: 'Puedo marcarlo.',
        accion: AccionPropuesta(
            tipo: 'marcar_habito', nombre: 'Caminar 30 minutos'),
      );

      final accion = await asistente.preguntar('marca caminar');

      expect(accion?.tipo, 'marcar_habito');
      expect(api.marcados, isEmpty);
    });
  });

  group('ejecutar', () {
    test('marca el hábito que existe', () async {
      final (titulo, _) = await asistente.ejecutar(const AccionPropuesta(
          tipo: 'marcar_habito', nombre: 'caminar 30 minutos'));

      expect(titulo, 'Listo');
      expect(api.marcados, [3]);
    });

    test('no marca un hábito que la IA inventó', () async {
      final (titulo, _) = await asistente.ejecutar(
          const AccionPropuesta(tipo: 'marcar_habito', nombre: 'Volar'));

      expect(titulo, 'No encontré ese hábito');
      expect(api.marcados, isEmpty);
    });

    test('crea el hábito propuesto', () async {
      final (titulo, _) = await asistente.ejecutar(const AccionPropuesta(
          tipo: 'crear_habito', nombre: 'Leer', frecuenciaObjetivo: 4));

      expect(titulo, 'Listo');
      expect(api.creados, ['Leer']);
    });

    test('si el servidor rechaza la acción, muestra su mensaje', () async {
      api.aLanzar =
          ApiException('Ya marcaste este hábito hoy.', statusCode: 409);

      final (titulo, mensaje) = await asistente.ejecutar(const AccionPropuesta(
          tipo: 'marcar_habito', nombre: 'Caminar 30 minutos'));

      expect(titulo, 'El servidor rechazó la acción');
      expect(mensaje, 'Ya marcaste este hábito hoy.');
    });
  });
}

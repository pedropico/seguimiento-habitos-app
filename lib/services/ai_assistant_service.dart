import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../config/api_config.dart';
import '../models/resumen_habitos.dart';
import 'api_client.dart';

class AccionPropuesta {
  final String tipo;

  final String nombre;

  final int? frecuenciaObjetivo;

  const AccionPropuesta({
    required this.tipo,
    required this.nombre,
    this.frecuenciaObjetivo,
  });

  static const tiposValidos = {'marcar_habito', 'crear_habito'};

  static AccionPropuesta? desdeJson(Object? json) {
    if (json is! Map) return null;
    final tipo = json['tipo'];
    final nombre = json['nombre'];
    if (tipo is! String || !tiposValidos.contains(tipo)) return null;
    if (nombre is! String || nombre.trim().isEmpty) return null;

    int? frecuencia;
    if (tipo == 'crear_habito') {
      final cruda = json['frecuencia_objetivo'];
      if (cruda is! num) return null;
      frecuencia = cruda.toInt();
      if (frecuencia < 1 || frecuencia > 7) return null;
    }

    return AccionPropuesta(
      tipo: tipo,
      nombre: nombre.trim(),
      frecuenciaObjetivo: frecuencia,
    );
  }

  String get descripcionParaConfirmar => tipo == 'marcar_habito'
      ? 'Marcar «$nombre» como cumplido hoy.'
      : 'Crear el hábito «$nombre» con un objetivo de $frecuenciaObjetivo día(s) por semana.';
}

class RespuestaIA {
  final String respuesta;
  final AccionPropuesta? accion;
  const RespuestaIA({required this.respuesta, this.accion});

  factory RespuestaIA.fromJson(Map<String, dynamic> json) => RespuestaIA(
        respuesta: (json['respuesta'] as String?) ??
            'El asistente no devolvió ninguna respuesta.',
        accion: AccionPropuesta.desdeJson(json['accion']),
      );
}

class AsistenteException implements Exception {
  final String mensaje;
  AsistenteException(this.mensaje);
  @override
  String toString() => mensaje;
}

class AiAssistantService {
  AiAssistantService({ApiClient? api, Dio? dio})
      : _api = api ?? Get.find<ApiClient>(),
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.asistenteUrl,
              connectTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
            ));

  final ApiClient _api;
  final Dio _dio;

  Future<RespuestaIA> preguntar(String consulta, ResumenHabitos resumen) async {
    final token = _api.token;
    try {
      final r = await _dio.post(
        '/asistente',
        data: {'consulta': consulta, 'resumen': resumen.toJson()},
        options: Options(
            headers: {if (token != null) 'Authorization': 'Bearer $token'}),
      );
      final json = r.data;
      if (json is! Map) {
        throw AsistenteException(
            'La respuesta del asistente no tiene el formato esperado.');
      }
      return RespuestaIA.fromJson(Map<String, dynamic>.from(json));
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw AsistenteException(
              'El asistente tardó demasiado en responder. Inténtalo de nuevo.');
        case DioExceptionType.badResponse:
          final detail = e.response?.data is Map
              ? (e.response!.data as Map)['detail']
              : null;
          throw AsistenteException(detail is String
              ? detail
              : 'El asistente respondió con un error (código ${e.response?.statusCode}).');
        default:
          throw AsistenteException(
              'No se pudo conectar con el asistente. Revisa que el proxy esté encendido.');
      }
    }
  }
}

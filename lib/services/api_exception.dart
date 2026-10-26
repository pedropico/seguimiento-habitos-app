import 'dart:io';

import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String mensaje;
  final int? statusCode;
  ApiException(this.mensaje, {this.statusCode});

  factory ApiException.desde(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
            'El servidor tardó demasiado en responder. Revisa tu conexión e inténtalo de nuevo.');
      case DioExceptionType.badResponse:
        return _desdeRespuesta(e.response!, e.requestOptions.path);
      default:
        if (e.type == DioExceptionType.connectionError ||
            e.error is SocketException) {
          return ApiException(
              'No hay conexión con el servidor. Revisa tu red y que el backend esté encendido.');
        }
        return ApiException(
            'No se pudo completar la petición. Inténtalo de nuevo.');
    }
  }

  static ApiException _desdeRespuesta(Response<dynamic> r, String ruta) {
    final codigo = r.statusCode ?? 0;
    final detail = r.data is Map ? (r.data as Map)['detail'] : null;

    if (codigo == 401) {
      // En el login, 401 = credenciales incorrectas; en otra ruta, token vencido.
      if (ruta == '/usuarios/token' && detail is String) {
        return ApiException(detail, statusCode: 401);
      }
      return ApiException('Tu sesión caducó, inicia sesión de nuevo.',
          statusCode: 401);
    }
    if (codigo >= 500) {
      return ApiException('El servidor tuvo un problema. Inténtalo más tarde.',
          statusCode: codigo);
    }
    // 400 / 403 / 404 / 409: `detail` es un texto en español del backend.
    if (detail is String) return ApiException(detail, statusCode: codigo);
    // 422: `detail` es una LISTA de objetos {loc, msg, type}.
    if (detail is List) {
      final partes = detail.whereType<Map>().map((e) {
        final loc = e['loc'];
        final campo = loc is List && loc.isNotEmpty ? '${loc.last}' : 'dato';
        return '$campo: ${e['msg']}';
      });
      return ApiException('Datos inválidos — ${partes.join('; ')}',
          statusCode: codigo);
    }
    return ApiException('La petición no pudo completarse (código $codigo).',
        statusCode: codigo);
  }

  @override
  String toString() => mensaje;
}

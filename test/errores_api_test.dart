import 'dart:io';

import 'package:seguimiento_habitos_app/services/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RequestOptions opciones(String ruta) => RequestOptions(path: ruta);

  DioException respuesta(int codigo, Object? detail,
          {String ruta = '/habitos/'}) =>
      DioException(
        requestOptions: opciones(ruta),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: opciones(ruta),
          statusCode: codigo,
          data: detail == null ? null : {'detail': detail},
        ),
      );

  group('Errores con respuesta del servidor', () {
    test('401 fuera del login habla de la sesión, no de la contraseña', () {
      final e = ApiException.desde(respuesta(401, 'Credenciales inválidas'));
      expect(e.statusCode, 401);
      expect(e.mensaje, contains('sesión caducó'));
    });

    test('401 en el login muestra el mensaje del servidor tal cual', () {
      final e = ApiException.desde(
          respuesta(401, 'Credenciales inválidas', ruta: '/usuarios/token'));
      expect(e.mensaje, 'Credenciales inválidas');
    });

    test('400 muestra la regla de negocio que el backend devolvió', () {
      final e = ApiException.desde(respuesta(
          400, 'El nombre del hábito debe tener al menos 3 caracteres'));
      expect(e.statusCode, 400);
      expect(e.mensaje, contains('al menos 3 caracteres'));
    });

    test('409 muestra el conflicto tal cual', () {
      final e = ApiException.desde(
          respuesta(409, 'El hábito ya fue marcado en esta fecha'));
      expect(e.statusCode, 409);
      expect(e.mensaje, contains('ya fue marcado'));
    });

    test('403 muestra el motivo de autorización', () {
      final e = ApiException.desde(
          respuesta(403, 'No tienes permiso para acceder a este hábito'));
      expect(e.statusCode, 403);
      expect(e.mensaje, contains('No tienes permiso'));
    });

    test('422 compone un mensaje legible desde la lista de detalles', () {
      final e = ApiException.desde(respuesta(422, [
        {
          'loc': ['body', 'password'],
          'msg': 'String should have at least 8 characters',
          'type': 'string_too_short'
        }
      ]));
      expect(e.statusCode, 422);
      expect(e.mensaje, contains('password'));
      expect(e.mensaje, contains('at least 8 characters'));
      expect(e.mensaje, isNot(contains('string_too_short')));
    });

    test('5xx no culpa a la persona', () {
      final e = ApiException.desde(respuesta(500, null));
      expect(e.statusCode, 500);
      expect(e.mensaje, contains('El servidor tuvo un problema'));
    });
  });

  group('Errores sin respuesta del servidor', () {
    test('sin conexión se distingue de un error del servidor', () {
      final e = ApiException.desde(DioException(
        requestOptions: opciones('/habitos/'),
        type: DioExceptionType.connectionError,
        error: const SocketException('fallo'),
      ));
      expect(e.statusCode, isNull);
      expect(e.mensaje, contains('No hay conexión'));
    });

    test('tiempo agotado tiene su propio mensaje', () {
      final e = ApiException.desde(DioException(
        requestOptions: opciones('/habitos/'),
        type: DioExceptionType.receiveTimeout,
      ));
      expect(e.statusCode, isNull);
      expect(e.mensaje, contains('tardó demasiado'));
    });
  });
}

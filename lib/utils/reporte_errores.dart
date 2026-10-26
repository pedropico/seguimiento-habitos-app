import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/error_pantalla_view.dart';

class ReporteErrores {
  ReporteErrores._();

  static final List<String> recientes = [];

  static String limpiar(String texto) => texto
      .replaceAll(RegExp(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*'), 'Bearer ***')
      .replaceAll(
          RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*'), '***');

  static void registrar(Object error, StackTrace? pila) {
    final mensaje = limpiar('${error.runtimeType}: $error');
    recientes.add(mensaje);
    if (recientes.length > 20) recientes.removeAt(0);
    debugPrint('[seguimiento-habitos-app] error no controlado -> $mensaje');
  }

  static void avisar() {
    try {
      if (Get.key.currentState == null) return;
      Get.snackbar('Algo salió mal',
          'Ya registramos el problema. Puedes seguir usando la app.');
    } catch (_) {}
  }

  static void instalar() {
    FlutterError.onError = (detalles) {
      FlutterError.presentError(detalles);
      registrar(detalles.exception, detalles.stack);
    };
    PlatformDispatcher.instance.onError = (error, pila) {
      registrar(error, pila);
      avisar();
      return true;
    };
    ErrorWidget.builder = (detalles) => const ErrorPantallaView();
  }
}

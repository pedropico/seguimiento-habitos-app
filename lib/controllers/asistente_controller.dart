import 'package:get/get.dart';

import '../services/ai_assistant_service.dart';
import 'habitos_controller.dart';

class AsistenteController extends GetxController {
  AsistenteController(
      {AiAssistantService? servicio, HabitosController? habitos})
      : _servicio = servicio ?? Get.find<AiAssistantService>(),
        _habitos = habitos ?? Get.find<HabitosController>();

  final AiAssistantService _servicio;
  final HabitosController _habitos;

  final RxBool cargando = false.obs;
  final RxString respuesta = ''.obs;
  final RxString mensajeError = ''.obs;

  Future<AccionPropuesta?> preguntar(String consulta) async {
    final texto = consulta.trim();
    if (texto.isEmpty || cargando.value) return null;

    cargando.value = true;
    mensajeError.value = '';
    respuesta.value = '';
    try {
      final r = await _servicio.preguntar(texto, _habitos.resumen());
      respuesta.value = r.respuesta;
      return r.accion;
    } on AsistenteException catch (e) {
      mensajeError.value = e.mensaje;
      return null;
    } finally {
      cargando.value = false;
    }
  }

  Future<(String, String)> ejecutar(AccionPropuesta accion) async {
    try {
      if (accion.tipo == 'marcar_habito') {
        final habito = _habitos.buscarPorNombre(accion.nombre);
        if (habito == null) {
          return (
            'No encontré ese hábito',
            'No tienes ninguno llamado «${accion.nombre}».'
          );
        }
        await _habitos.marcar(habito.id);
        return ('Listo', '«${habito.nombre}» quedó marcado hoy.');
      }
      await _habitos.crear(accion.nombre, accion.frecuenciaObjetivo ?? 3);
      return ('Listo', 'Se creó el hábito «${accion.nombre}».');
    } on Exception catch (e) {
      return ('El servidor rechazó la acción', '$e');
    }
  }
}

import '../models/plantilla_habito.dart';
import '../services/api_exception.dart';
import '../services/catalogo_service.dart';
import '../services/sugerencias_api_service.dart';

class CatalogoRepository {
  CatalogoRepository(this._api);

  final SugerenciasApiService _api;

  Future<(List<PlantillaHabito>, bool)> obtenerSugerencias() async {
    try {
      final plantillas = await _api.listar()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      await CatalogoService.guardarPlantillas(plantillas);
      return (plantillas, false);
    } on ApiException catch (e) {
      final fallaDeInfraestructura =
          e.statusCode == null || e.statusCode! >= 500;
      if (!fallaDeInfraestructura) rethrow;
      final guardadas = CatalogoService.plantillasGuardadas();
      if (guardadas == null) rethrow;
      return (guardadas, true);
    }
  }

  String get ultimaSincronizacion {
    final fecha = CatalogoService.ultimaSincronizacion();
    if (fecha == null) return 'desconocida';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)} ${dos(fecha.hour)}:${dos(fecha.minute)}';
  }
}

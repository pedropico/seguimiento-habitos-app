import 'package:hive/hive.dart';

import '../models/habito.dart';
import '../services/api_exception.dart';
import '../services/habitos_api_service.dart';

/// Una caja por usuario (`habitos_<id>`) porque Hive guarda sin cifrar y dos
/// personas pueden compartir el teléfono. La caché es de solo lectura.
class HabitosRepository {
  HabitosRepository(this._api);

  final HabitosApiService _api;
  Box? _caja;

  static const _claveHabitos = 'habitos';
  static const _claveSincronizado = 'sincronizado';

  Future<void> abrirParaUsuario(int usuarioId) async {
    _caja = await Hive.openBox('habitos_$usuarioId');
  }

  Future<(List<Habito>, bool)> obtenerHabitos() async {
    try {
      final habitos = await _api.listar();
      final conRegistros = await Future.wait(
        habitos.map((h) async {
          final registros = await _api.registrosDe(h.id);
          return h.copyWith(registros: registros);
        }),
      );
      await _guardar(conRegistros);
      return (conRegistros, false);
    } on ApiException catch (e) {
      final fallaDeInfraestructura =
          e.statusCode == null || e.statusCode! >= 500;
      if (!fallaDeInfraestructura) rethrow;
      final guardados = _leer();
      if (guardados == null) rethrow;
      return (guardados, true);
    }
  }

  String get ultimaSincronizacion {
    final iso = _caja?.get(_claveSincronizado) as String?;
    final fecha = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
    if (fecha == null) return 'desconocida';
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)} ${dos(fecha.hour)}:${dos(fecha.minute)}';
  }

  Future<void> vaciar() async {
    await _caja?.deleteFromDisk();
    _caja = null;
  }

  Future<void> _guardar(List<Habito> habitos) async {
    final caja = _caja;
    if (caja == null || !caja.isOpen) return;
    await caja.put(_claveHabitos, habitos.map((h) => h.toMap()).toList());
    await caja.put(_claveSincronizado, DateTime.now().toIso8601String());
  }

  List<Habito>? _leer() {
    final caja = _caja;
    if (caja == null || !caja.isOpen) return null;
    final guardado = caja.get(_claveHabitos);
    if (guardado is! List) return null;
    return guardado.whereType<Map>().map(Habito.fromMap).toList();
  }
}

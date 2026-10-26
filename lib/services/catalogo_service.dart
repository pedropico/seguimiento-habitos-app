import 'package:hive/hive.dart';

import '../models/plantilla_habito.dart';

class CatalogoService {
  CatalogoService._();

  static const String cajaCatalogo = 'catalogo';
  static const String cajaFavoritos = 'favoritos';
  static const String _claveSincronizado = '_sincronizado';

  static Box<Map>? _catalogo;
  static Box<Map>? _favoritos;

  static Future<void> abrir() async {
    _catalogo = await Hive.openBox<Map>(cajaCatalogo);
    _favoritos = await Hive.openBox<Map>(cajaFavoritos);
  }

  static Future<void> guardarPlantillas(
      List<PlantillaHabito> plantillas) async {
    final caja = _catalogo;
    if (caja == null || !caja.isOpen) return;
    await caja.clear();
    await caja.putAll({for (final p in plantillas) p.id: p.toMap()});
    await caja
        .put(_claveSincronizado, {'valor': DateTime.now().toIso8601String()});
  }

  /// `null` si nunca se sincronizó: no hay copia a la que recurrir.
  static List<PlantillaHabito>? plantillasGuardadas() {
    final caja = _catalogo;
    if (caja == null || !caja.isOpen) return null;
    if (!caja.containsKey(_claveSincronizado)) return null;
    return caja.keys
        .where((k) => k != _claveSincronizado)
        .map((k) => caja.get(k))
        .whereType<Map>()
        .map(PlantillaHabito.fromMap)
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  static DateTime? ultimaSincronizacion() {
    final iso = _catalogo?.get(_claveSincronizado)?['valor'];
    return iso is String ? DateTime.tryParse(iso)?.toLocal() : null;
  }

  static List<PlantillaHabito> favoritos() {
    final caja = _favoritos;
    if (caja == null || !caja.isOpen) return const [];
    return caja.values.whereType<Map>().map(PlantillaHabito.fromMap).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  static bool esFavorito(String id) => _favoritos?.containsKey(id) ?? false;

  static Future<void> alternarFavorito(PlantillaHabito p) async {
    final caja = _favoritos;
    if (caja == null) return;
    if (caja.containsKey(p.id)) {
      await caja.delete(p.id);
    } else {
      await caja.put(p.id, p.toMap());
    }
  }
}

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';

import '../models/plantilla_habito.dart';

class CatalogoService {
  CatalogoService._();

  static const String cajaCatalogo = 'catalogo';
  static const String cajaFavoritos = 'favoritos';
  static const String _claveVersion = '_version';
  static const String _rutaAsset = 'assets/data/catalogo.json';

  static Box<Map>? _catalogo;
  static Box<Map>? _favoritos;

  static Future<void> abrir({String? jsonDePrueba}) async {
    _catalogo = await Hive.openBox<Map>(cajaCatalogo);
    _favoritos = await Hive.openBox<Map>(cajaFavoritos);
    await _sembrarSiHaceFalta(jsonDePrueba);
  }

  static Future<void> _sembrarSiHaceFalta(String? jsonDePrueba) async {
    final caja = _catalogo;
    if (caja == null) return;

    final crudo = jsonDePrueba ?? await rootBundle.loadString(_rutaAsset);
    final json = jsonDecode(crudo);
    if (json is! Map) return;
    final version = (json['version'] as num?)?.toInt() ?? 1;
    final guardada = (caja.get(_claveVersion)?['valor'] as num?)?.toInt() ?? 0;

    final hayPlantillas = caja.keys.where((k) => k != _claveVersion).isNotEmpty;
    if (hayPlantillas && guardada >= version) return;

    final plantillas = (json['plantillas'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => PlantillaHabito.fromJson(Map<String, dynamic>.from(m)));
    for (final p in plantillas) {
      await caja.put(p.id, p.toMap());
    }
    await caja.put(_claveVersion, {'valor': version});
  }

  static List<PlantillaHabito> plantillas() {
    final caja = _catalogo;
    if (caja == null || !caja.isOpen) return const [];
    return caja.keys
        .where((k) => k != _claveVersion)
        .map((k) => caja.get(k))
        .whereType<Map>()
        .map(PlantillaHabito.fromMap)
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
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

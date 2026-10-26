import 'package:get/get.dart';

import '../models/plantilla_habito.dart';
import '../services/catalogo_service.dart';

class CatalogoController extends GetxController {
  final RxList<PlantillaHabito> plantillas = <PlantillaHabito>[].obs;
  final RxList<PlantillaHabito> favoritos = <PlantillaHabito>[].obs;

  final RxnString categoria = RxnString();

  @override
  void onInit() {
    super.onInit();
    recargar();
  }

  void recargar() {
    plantillas.assignAll(CatalogoService.plantillas());
    favoritos.assignAll(CatalogoService.favoritos());
  }

  List<String> get categorias =>
      plantillas.map((p) => p.categoria).toSet().toList()..sort();

  List<PlantillaHabito> get plantillasFiltradas {
    final c = categoria.value;
    if (c == null) return plantillas;
    return plantillas.where((p) => p.categoria == c).toList();
  }

  void filtrar(String? nueva) => categoria.value = nueva;

  bool esFavorito(String id) => favoritos.any((p) => p.id == id);

  Future<void> alternarFavorito(PlantillaHabito p) async {
    await CatalogoService.alternarFavorito(p);
    favoritos.assignAll(CatalogoService.favoritos());
  }
}

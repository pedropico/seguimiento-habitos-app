import 'package:get/get.dart';

import '../models/plantilla_habito.dart';
import '../repositories/catalogo_repository.dart';
import '../services/api_client.dart';
import '../services/catalogo_service.dart';
import '../services/sugerencias_api_service.dart';

class CatalogoController extends GetxController {
  CatalogoController({CatalogoRepository? repositorio})
      : _repositorio = repositorio ??
            CatalogoRepository(SugerenciasApiService(Get.find<ApiClient>()));

  final CatalogoRepository _repositorio;

  final RxList<PlantillaHabito> plantillas = <PlantillaHabito>[].obs;
  final RxList<PlantillaHabito> favoritos = <PlantillaHabito>[].obs;

  final RxBool cargando = false.obs;
  final RxString mensajeError = ''.obs;
  final RxBool desdeCache = false.obs;

  final RxnString categoria = RxnString();

  @override
  void onInit() {
    super.onInit();
    favoritos.assignAll(CatalogoService.favoritos());
    cargar();
  }

  Future<void> cargar() async {
    cargando.value = true;
    mensajeError.value = '';
    try {
      final (lista, deCache) = await _repositorio.obtenerSugerencias();
      plantillas.assignAll(lista);
      desdeCache.value = deCache;
      if (!categorias.contains(categoria.value)) categoria.value = null;
    } on ApiException catch (e) {
      mensajeError.value = e.mensaje;
    } finally {
      cargando.value = false;
    }
  }

  String get ultimaSincronizacion => _repositorio.ultimaSincronizacion;

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

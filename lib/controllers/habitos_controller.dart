import 'package:get/get.dart';

import '../models/habito.dart';
import '../models/resumen_habitos.dart';
import '../repositories/habitos_repository.dart';
import '../services/api_client.dart';
import '../services/habitos_api_service.dart';
import 'auth_controller.dart';

enum EstadoCarga { cargando, exito, vacio, error }

class HabitosController extends GetxController {
  HabitosController({AuthController? auth, HabitosApiService? api}) {
    _auth = auth ?? Get.find<AuthController>();
    _api = api ?? HabitosApiService(Get.find<ApiClient>());
    _repository = HabitosRepository(_api);
  }

  late final AuthController _auth;
  late final HabitosApiService _api;
  late final HabitosRepository _repository;

  final RxList<Habito> habitos = <Habito>[].obs;
  final Rx<EstadoCarga> estado = EstadoCarga.exito.obs;
  final RxString mensajeError = ''.obs;

  final RxBool desdeCache = false.obs;
  String get ultimaSincronizacion => _repository.ultimaSincronizacion;

  final RxnBool soloPendientesHoy = RxnBool();

  @override
  void onInit() {
    super.onInit();
    ever(_auth.usuario, (u) {
      if (u != null) {
        cargar();
      } else {
        habitos.clear();
      }
    });
    if (_auth.estaAutenticado) cargar();
  }

  List<Habito> get habitosFiltrados {
    final filtro = soloPendientesHoy.value;
    if (filtro == null) return habitos;
    return habitos.where((h) => h.marcadoHoy() != filtro).toList();
  }

  int get cumplidosHoy => habitos.where((h) => h.marcadoHoy()).length;
  int get totalHabitos => habitos.length;

  int get mejorRacha => habitos.isEmpty
      ? 0
      : habitos.map((h) => h.racha).reduce((a, b) => a > b ? a : b);

  void filtrar(bool? soloPendientes) =>
      soloPendientesHoy.value = soloPendientes;

  Future<void> cargar() async {
    final id = _auth.usuario.value?.id;
    if (id == null) return;
    estado.value = EstadoCarga.cargando;
    try {
      await _repository.abrirParaUsuario(id);
      await _refrescar();
      estado.value = habitos.isEmpty ? EstadoCarga.vacio : EstadoCarga.exito;
    } on ApiException catch (e) {
      mensajeError.value = e.mensaje;
      estado.value = EstadoCarga.error;
    }
  }

  Future<void> _refrescar() async {
    final (lista, cache) = await _repository.obtenerHabitos();
    habitos.value = lista;
    desdeCache.value = cache;
    if (estado.value != EstadoCarga.cargando) {
      estado.value = lista.isEmpty ? EstadoCarga.vacio : EstadoCarga.exito;
    }
  }

  Future<void> crear(String nombre, int frecuenciaObjetivo) async {
    await _api.crear(nombre, frecuenciaObjetivo);
    await _refrescar();
  }

  Future<void> actualizar(int id, Map<String, dynamic> cambios) async {
    try {
      await _api.actualizar(id, cambios);
    } on ApiException catch (e) {
      if (e.statusCode == 404) await _refrescar();
      rethrow;
    }
    await _refrescar();
  }

  Future<void> eliminar(int id) async {
    try {
      await _api.eliminar(id);
    } on ApiException catch (e) {
      if (e.statusCode == 404) await _refrescar();
      rethrow;
    }
    await _refrescar();
  }

  Future<void> marcar(int id) async {
    await _api.marcar(id);
    await _refrescar();
  }

  Habito? buscarPorNombre(String nombre) {
    final buscado = nombre.trim().toLowerCase();
    for (final h in habitos) {
      if (h.nombre.trim().toLowerCase() == buscado) return h;
    }
    return null;
  }

  ResumenHabitos resumen() => ResumenHabitos.desde(habitos);

  Future<void> limpiar() async {
    await _repository.vaciar();
    habitos.clear();
    soloPendientesHoy.value = null;
    desdeCache.value = false;
    mensajeError.value = '';
    estado.value = EstadoCarga.exito;
  }
}

import 'package:get/get.dart';

import '../models/usuario.dart';
import '../services/api_client.dart';
import '../services/jwt.dart';
import '../services/secure_token_storage.dart';
import 'habitos_controller.dart';

class AuthController extends GetxController {
  AuthController({ApiClient? api, SecureTokenStorage? almacen})
      : _api = api ?? Get.find<ApiClient>(),
        _almacen = almacen ?? SecureTokenStorage();

  final ApiClient _api;
  final SecureTokenStorage _almacen;

  final Rxn<Usuario> usuario = Rxn<Usuario>();
  final RxBool cargando = false.obs;
  final RxBool restaurando = false.obs;
  final RxString mensajeError = ''.obs;
  final RxString avisoSesion = ''.obs;

  bool get estaAutenticado => usuario.value != null;

  void limpiarError() => mensajeError.value = '';

  @override
  void onInit() {
    super.onInit();
    _api.alSesionCaducada = sesionCaducada;
    restaurarSesion();
  }

  Future<void> registrar(String email, String password) async {
    cargando.value = true;
    mensajeError.value = '';
    try {
      await _api
          .post('/usuarios/', data: {'email': email, 'password': password});
      await iniciarSesion(email, password);
    } on ApiException catch (e) {
      mensajeError.value = e.mensaje;
    } finally {
      cargando.value = false;
    }
  }

  Future<void> iniciarSesion(String email, String password) async {
    cargando.value = true;
    mensajeError.value = '';
    try {
      final r = await _api.post(
        '/usuarios/token',
        data: {'username': email, 'password': password},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final datos = r.data;
      final token = datos is Map ? datos['access_token'] : null;
      if (token is! String || token.isEmpty) {
        throw ApiException(
            'Respuesta inesperada del servidor al iniciar sesión.');
      }
      _aplicarToken(token);
      await _almacen.guardar(token);
      avisoSesion.value = '';
    } on ApiException catch (e) {
      mensajeError.value = e.mensaje;
    } finally {
      cargando.value = false;
    }
  }

  Future<void> restaurarSesion() async {
    restaurando.value = true;
    try {
      final guardado = await _almacen.leer();
      if (guardado == null) return;
      if (_expirado(guardado)) {
        await _almacen.borrar();
        avisoSesion.value = 'Tu sesión caducó, inicia sesión de nuevo.';
        return;
      }
      _aplicarToken(guardado);
    } finally {
      restaurando.value = false;
    }
  }

  Future<void> sesionCaducada() async {
    await cerrarSesion();
    avisoSesion.value = 'Tu sesión caducó, inicia sesión de nuevo.';
    if (Get.key.currentState != null) Get.until((ruta) => ruta.isFirst);
  }

  Future<void> cerrarSesion() async {
    if (Get.isRegistered<HabitosController>()) {
      await Get.find<HabitosController>().limpiar();
    }
    await _almacen.borrar();
    _api.token = null;
    usuario.value = null;
  }

  void invalidarTokenParaPruebas() => _api.token = 'token.invalido.aqui';

  void _aplicarToken(String token) {
    _api.token = token;
    final id = Jwt.idUsuario(token);
    final email = Jwt.email(token);
    if (id == null) {
      _api.token = null;
      usuario.value = null;
      avisoSesion.value = 'No se pudo leer tu sesión. Inicia sesión de nuevo.';
      return;
    }
    usuario.value = Usuario(id: id, email: email ?? 'usuario@desconocido');
  }

  bool _expirado(String token) {
    final exp = Jwt.contenido(token)?['exp'];
    if (exp is! num) return false;
    final vence = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    return vence.isBefore(DateTime.now());
  }
}

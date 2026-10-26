import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:seguimiento_habitos_app/controllers/auth_controller.dart';
import 'package:seguimiento_habitos_app/screens/login_screen.dart';
import 'package:seguimiento_habitos_app/services/api_client.dart';
import 'package:seguimiento_habitos_app/services/secure_token_storage.dart';

class _AlmacenFalso extends SecureTokenStorage {
  @override
  Future<String?> leer() async => null;

  @override
  Future<void> guardar(String token) async {}

  @override
  Future<void> borrar() async {}
}

void main() {
  late AuthController auth;

  setUp(() {
    auth = Get.put(AuthController(api: ApiClient(), almacen: _AlmacenFalso()));
  });

  tearDown(Get.reset);

  testWidgets(
      'tras un inicio de sesión fallido, «Crear una cuenta» abre el registro '
      'limpio', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: LoginScreen()));

    auth.mensajeError.value = 'Correo o contraseña incorrectos';
    await tester.pump();
    expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);

    await tester.tap(find.text('Crear una cuenta'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Crear cuenta y entrar'), findsOneWidget);
    expect(find.text('Correo o contraseña incorrectos'), findsNothing);
  });
}

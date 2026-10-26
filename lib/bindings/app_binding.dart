import 'package:get/get.dart';

import '../controllers/asistente_controller.dart';
import '../controllers/catalogo_controller.dart';
import '../controllers/habitos_controller.dart';

/// `AuthController` y `ApiClient` no están aquí: se registran en `main()`.
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(HabitosController(), permanent: true);
    Get.put(CatalogoController(), permanent: true);
    Get.put(AsistenteController(), permanent: true);
  }
}

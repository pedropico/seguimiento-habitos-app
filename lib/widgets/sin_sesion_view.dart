import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../screens/login_screen.dart';
import '../theme/app_theme.dart';

class SinSesionView extends StatelessWidget {
  final String titulo;
  final String mensaje;

  const SinSesionView({
    super.key,
    required this.titulo,
    this.mensaje = 'Inicia sesión para ver y registrar tus hábitos.',
  });

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Obx(() {
        if (auth.restaurando.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline,
                    size: 56, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: AppSpacing.md),
                Text(mensaje, textAlign: TextAlign.center),
                if (auth.avisoSesion.value.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    auth.avisoSesion.value,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () {
                    auth.limpiarError();
                    Get.to(() => const LoginScreen());
                  },
                  child: const Text('Iniciar sesión'),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

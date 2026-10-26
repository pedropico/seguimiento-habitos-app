import 'package:flutter/material.dart';

class BannerCache extends StatelessWidget {
  final String ultimaSincronizacion;
  final VoidCallback onReintentar;

  const BannerCache({
    super.key,
    required this.ultimaSincronizacion,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Text(
        'Sin conexión — mostrando tus hábitos guardados '
        '(última sincronización: $ultimaSincronizacion)',
      ),
      leading: const Icon(Icons.cloud_off),
      actions: [
        TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
      ],
    );
  }
}

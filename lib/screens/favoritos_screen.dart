import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/catalogo_controller.dart';
import '../widgets/empty_view.dart';
import '../widgets/plantilla_card.dart';
import 'habito_form_screen.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CatalogoController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: Obx(() {
        if (c.favoritos.isEmpty) {
          return const EmptyView(
            icono: Icons.favorite_border,
            mensaje:
                'Todavía no guardaste ninguna sugerencia.\nToca el corazón en el catálogo para guardarla aquí.',
          );
        }
        return ListView.builder(
          itemCount: c.favoritos.length,
          itemBuilder: (_, i) {
            final p = c.favoritos[i];
            return PlantillaCard(
              plantilla: p,
              esFavorito: true,
              onFavorito: () => c.alternarFavorito(p),
              onAdoptar: () => Get.to(() => HabitoFormScreen(
                    nombreInicial: p.nombre,
                    frecuenciaInicial: p.frecuenciaSugerida,
                  )),
            );
          },
        );
      }),
    );
  }
}

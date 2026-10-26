import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/catalogo_controller.dart';
import '../models/plantilla_habito.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_cache.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';
import '../widgets/plantilla_card.dart';
import 'habito_form_screen.dart';

class CatalogoScreen extends StatelessWidget {
  const CatalogoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CatalogoController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: c.cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (c.cargando.value && c.plantillas.isEmpty) {
          return const LoadingView(mensaje: 'Cargando sugerencias...');
        }
        if (c.mensajeError.value.isNotEmpty && c.plantillas.isEmpty) {
          return ErrorView(
            mensaje: c.mensajeError.value,
            onReintentar: c.cargar,
          );
        }
        if (c.plantillas.isEmpty) {
          return EmptyView(
            icono: Icons.menu_book_outlined,
            mensaje: 'Todavía no hay sugerencias disponibles.',
            textoAccion: 'Recargar',
            onAccion: c.cargar,
          );
        }
        return Column(
          children: [
            if (c.desdeCache.value)
              BannerCache(
                ultimaSincronizacion: c.ultimaSincronizacion,
                onReintentar: c.cargar,
              ),
            _FiltroCategorias(controller: c),
            Expanded(
              child: Obx(() {
                final lista = c.plantillasFiltradas;
                if (lista.isEmpty) {
                  return const EmptyView(
                    icono: Icons.filter_alt_off_outlined,
                    mensaje: 'No hay sugerencias en esta categoría.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: c.cargar,
                  child: ListView.builder(
                    itemCount: lista.length,
                    itemBuilder: (_, i) {
                      final p = lista[i];
                      return Obx(() => PlantillaCard(
                            plantilla: p,
                            esFavorito: c.esFavorito(p.id),
                            onFavorito: () => c.alternarFavorito(p),
                            onAdoptar: () => _adoptar(p),
                          ));
                    },
                  ),
                );
              }),
            ),
          ],
        );
      }),
    );
  }

  void _adoptar(PlantillaHabito p) {
    Get.to(() => HabitoFormScreen(
          nombreInicial: p.nombre,
          frecuenciaInicial: p.frecuenciaSugerida,
        ));
  }
}

class _FiltroCategorias extends StatelessWidget {
  const _FiltroCategorias({required this.controller});

  final CatalogoController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final actual = controller.categoria.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('Todas'),
              selected: actual == null,
              onSelected: (_) => controller.filtrar(null),
            ),
            for (final categoria in controller.categorias) ...[
              const SizedBox(width: AppSpacing.sm),
              ChoiceChip(
                label: Text(categoria),
                selected: actual == categoria,
                onSelected: (_) => controller.filtrar(categoria),
              ),
            ],
          ],
        ),
      );
    });
  }
}

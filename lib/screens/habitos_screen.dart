import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/habitos_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/banner_cache.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/habito_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/sin_sesion_view.dart';
import 'detalle_habito_screen.dart';
import 'habito_form_screen.dart';
import 'pantalla_con_fallo.dart';

class HabitosScreen extends StatelessWidget {
  const HabitosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final controller = Get.find<HabitosController>();

    return Obx(() {
      if (!auth.estaAutenticado) {
        return const SinSesionView(titulo: 'Mis hábitos');
      }
      return Scaffold(
        appBar: AppBar(
          title: Obx(() => Text('Mis hábitos (${controller.totalHabitos})')),
          actions: [
            IconButton(
              tooltip: 'Recargar',
              onPressed: controller.cargar,
              icon: const Icon(Icons.refresh),
            ),
            PopupMenuButton<String>(
              onSelected: (opcion) => _menu(context, opcion, auth),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'salir', child: Text('Cerrar sesión')),
                PopupMenuItem(
                    value: 'token',
                    child: Text('Invalidar token (solo prueba)')),
                PopupMenuItem(
                    value: 'fallo',
                    child: Text('Error de pantalla (solo prueba)')),
                PopupMenuItem(value: 'acerca', child: Text('Acerca de')),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Get.to(() => const HabitoFormScreen()),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo hábito'),
        ),
        body: Obx(() {
          switch (controller.estado.value) {
            case EstadoCarga.cargando:
              return const LoadingView(mensaje: 'Cargando tus hábitos...');
            case EstadoCarga.error:
              return ErrorView(
                mensaje: controller.mensajeError.value,
                onReintentar: controller.cargar,
              );
            case EstadoCarga.vacio:
              return EmptyView(
                icono: Icons.flag_outlined,
                mensaje:
                    'Todavía no tienes hábitos.\nEmpieza por uno pequeño: es más fácil sostenerlo.',
                textoAccion: 'Crear mi primer hábito',
                onAccion: () => Get.to(() => const HabitoFormScreen()),
              );
            case EstadoCarga.exito:
              return _Lista(controller: controller);
          }
        }),
      );
    });
  }

  void _menu(BuildContext context, String opcion, AuthController auth) {
    switch (opcion) {
      case 'salir':
        auth.cerrarSesion();
      case 'token':
        auth.invalidarTokenParaPruebas();
        Get.snackbar('Token invalidado',
            'La siguiente petición recibirá un 401. Toca Recargar.');
      case 'fallo':
        Get.to(() => const PantallaConFallo());
      case 'acerca':
        showAboutDialog(
          context: context,
          applicationName: 'seguimiento-habitos-app',
          applicationVersion: '1.0.0',
          applicationLegalese: 'Proyecto de desarrollo de aplicaciones móviles '
              'robustas con flutter e IA.',
        );
    }
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.controller});

  final HabitosController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() => controller.desdeCache.value
            ? BannerCache(
                ultimaSincronizacion: controller.ultimaSincronizacion,
                onReintentar: controller.cargar,
              )
            : const SizedBox.shrink()),
        const _Resumen(),
        const _Filtros(),
        Expanded(
          child: Obx(() {
            final lista = controller.habitosFiltrados;
            if (lista.isEmpty) {
              return const EmptyView(
                icono: Icons.filter_alt_off_outlined,
                mensaje: 'Ningún hábito coincide con este filtro.',
              );
            }
            return RefreshIndicator(
              onRefresh: controller.cargar,
              child: ListView.builder(
                itemCount: lista.length,
                padding: const EdgeInsets.only(bottom: 88),
                itemBuilder: (_, i) {
                  final h = lista[i];
                  return HabitoCard(
                    habito: h,
                    onMarcar: () => _marcar(h.id),
                    onAbrir: () =>
                        Get.to(() => DetalleHabitoScreen(habitoId: h.id)),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _marcar(int id) async {
    try {
      await controller.marcar(id);
    } on Exception catch (e) {
      Get.snackbar('No se pudo marcar', '$e');
    }
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HabitosController>();
    return Obx(() => Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
          child: Row(
            children: [
              _Dato(
                  valor: '${c.cumplidosHoy}/${c.totalHabitos}',
                  etiqueta: 'hoy'),
              _Dato(valor: '${c.mejorRacha}', etiqueta: 'mejor racha'),
              _Dato(
                  valor: '${c.habitos.where((h) => !h.marcadoHoy()).length}',
                  etiqueta: 'pendientes'),
            ],
          ),
        ));
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.valor, required this.etiqueta});

  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(valor, style: Theme.of(context).textTheme.titleLarge),
          Text(etiqueta, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros();

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HabitosController>();
    return Obx(() {
      final actual = c.soloPendientesHoy.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('Todos'),
              selected: actual == null,
              onSelected: (_) => c.filtrar(null),
            ),
            const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              label: const Text('Pendientes hoy'),
              selected: actual == true,
              onSelected: (_) => c.filtrar(true),
            ),
            const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              label: const Text('Cumplidos hoy'),
              selected: actual == false,
              onSelected: (_) => c.filtrar(false),
            ),
          ],
        ),
      );
    });
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/habitos_controller.dart';
import '../models/habito.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_view.dart';
import 'habito_form_screen.dart';

class DetalleHabitoScreen extends StatelessWidget {
  final int habitoId;

  const DetalleHabitoScreen({super.key, required this.habitoId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HabitosController>();

    return Obx(() {
      Habito? habito;
      for (final h in controller.habitos) {
        if (h.id == habitoId) {
          habito = h;
          break;
        }
      }

      final encontrado = habito;
      if (encontrado == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Hábito')),
          body: EmptyView(
            icono: Icons.search_off,
            mensaje: 'Este hábito ya no existe.',
            textoAccion: 'Volver',
            onAccion: () => Get.back(),
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(encontrado.nombre, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              tooltip: 'Editar',
              onPressed: () =>
                  Get.to(() => HabitoFormScreen(habito: encontrado)),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Eliminar',
              onPressed: () =>
                  _confirmarEliminar(context, controller, encontrado),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _Tarjeta(habito: encontrado),
            const SizedBox(height: AppSpacing.lg),
            Text('Últimos 14 días',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            _Calendario(habito: encontrado),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: encontrado.marcadoHoy()
                  ? null
                  : () => _marcar(controller, encontrado.id),
              icon: const Icon(Icons.check),
              label: Text(encontrado.marcadoHoy()
                  ? 'Ya cumplido hoy'
                  : 'Marcar como cumplido'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _marcar(HabitosController controller, int id) async {
    try {
      await controller.marcar(id);
    } on Exception catch (e) {
      Get.snackbar('No se pudo marcar', '$e');
    }
  }

  Future<void> _confirmarEliminar(
      BuildContext context, HabitosController controller, Habito habito) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar hábito'),
        content: Text(
            'Se eliminará «${habito.nombre}» y su historial. Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmado != true) return;
    try {
      await controller.eliminar(habito.id);
      Get.back();
    } on Exception catch (e) {
      Get.snackbar('No se pudo eliminar', '$e');
    }
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.habito});

  final Habito habito;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department,
                    color: AppTheme.ambar, size: 32),
                const SizedBox(width: AppSpacing.sm),
                Text('${habito.racha}', style: tema.textTheme.titleLarge),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child:
                      Text('días seguidos', style: tema.textTheme.bodyMedium),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: habito.avanceSemanal,
                minHeight: 10,
                backgroundColor: tema.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${habito.cumplidosEnSemana()} de ${habito.frecuenciaObjetivo} días esta semana · '
              '${habito.registros.length} marcas en total',
              style: tema.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Calendario extends StatelessWidget {
  const _Calendario({required this.habito});

  final Habito habito;

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final fechas = habito.registros.map((r) => r.fecha).toSet();
    final tema = Theme.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List.generate(14, (i) {
        final dia = hoy.subtract(Duration(days: 13 - i));
        final clave = '${dia.year.toString().padLeft(4, '0')}-'
            '${dia.month.toString().padLeft(2, '0')}-'
            '${dia.day.toString().padLeft(2, '0')}';
        final cumplido = fechas.contains(clave);
        return Semantics(
          label: '${dia.day}/${dia.month}: '
              '${cumplido ? 'cumplido' : 'sin marcar'}',
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cumplido
                  ? tema.colorScheme.primary
                  : tema.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${dia.day}',
              style: TextStyle(
                color: cumplido
                    ? tema.colorScheme.onPrimary
                    : tema.colorScheme.onSurfaceVariant,
                fontWeight: cumplido ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/habito.dart';
import '../theme/app_theme.dart';

class HabitoCard extends StatelessWidget {
  final Habito habito;
  final VoidCallback onMarcar;
  final VoidCallback onAbrir;

  const HabitoCard({
    super.key,
    required this.habito,
    required this.onMarcar,
    required this.onAbrir,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final hecho = habito.marcadoHoy();
    final cumplidos = habito.cumplidosEnSemana();

    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: InkWell(
        onTap: onAbrir,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(habito.nombre,
                        style: tema.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (habito.racha > 0)
                    Semantics(
                      container: true,
                      label: 'Racha de ${habito.racha} días',
                      excludeSemantics: true,
                      child: Chip(
                        avatar: const Icon(Icons.local_fire_department,
                            size: 18, color: AppTheme.ambar),
                        label: Text('${habito.racha}'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: habito.avanceSemanal,
                  minHeight: 8,
                  backgroundColor: tema.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$cumplidos de ${habito.frecuenciaObjetivo} días esta semana',
                      style: tema.textTheme.bodySmall,
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: hecho
                        ? '${habito.nombre}: ya cumplido hoy'
                        : 'Marcar ${habito.nombre} como cumplido hoy',
                    child: FilledButton.tonalIcon(
                      onPressed: hecho ? null : onMarcar,
                      icon: Icon(hecho ? Icons.check_circle : Icons.check),
                      label: Text(hecho ? 'Hecho hoy' : 'Marcar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

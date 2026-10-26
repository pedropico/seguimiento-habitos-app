import 'package:flutter/material.dart';

import '../models/plantilla_habito.dart';
import '../theme/app_theme.dart';

class PlantillaCard extends StatelessWidget {
  final PlantillaHabito plantilla;
  final bool esFavorito;
  final VoidCallback onFavorito;
  final VoidCallback onAdoptar;

  const PlantillaCard({
    super.key,
    required this.plantilla,
    required this.esFavorito,
    required this.onFavorito,
    required this.onAdoptar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(plantilla.nombre,
                      style: tema.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                Semantics(
                  button: true,
                  label: esFavorito
                      ? 'Quitar ${plantilla.nombre} de favoritos'
                      : 'Guardar ${plantilla.nombre} en favoritos',
                  child: IconButton(
                    onPressed: onFavorito,
                    icon: Icon(
                      esFavorito ? Icons.favorite : Icons.favorite_border,
                      color: esFavorito ? AppTheme.ambar : null,
                    ),
                  ),
                ),
              ],
            ),
            Text(plantilla.descripcion, style: tema.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Chip(
                  label: Text(plantilla.categoria),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Sugerido: ${plantilla.frecuenciaSugerida} día(s)/semana',
                    style: tema.textTheme.bodySmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: onAdoptar,
                  icon: const Icon(Icons.add),
                  label: const Text('Adoptar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

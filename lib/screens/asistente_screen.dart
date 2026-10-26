import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/habitos_controller.dart';
import '../services/ai_assistant_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sin_sesion_view.dart';

/// Al proxy solo se le envía el resumen de hábitos (nombre, objetivo,
/// cumplidos y racha): nunca fechas, identificadores ni el correo.
class AsistenteScreen extends StatefulWidget {
  const AsistenteScreen({super.key});

  @override
  State<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends State<AsistenteScreen> {
  final _consulta = TextEditingController();
  final _auth = Get.find<AuthController>();
  final _habitos = Get.find<HabitosController>();
  late final AiAssistantService _servicio = Get.find<AiAssistantService>();

  bool _cargando = false;
  String _respuesta = '';
  String _error = '';

  static const _sugerencias = [
    '¿Cómo voy esta semana?',
    '¿Qué hábito estoy descuidando?',
    '¿Cuál es mi mejor racha?',
  ];

  @override
  void dispose() {
    _consulta.dispose();
    super.dispose();
  }

  Future<void> _preguntar([String? texto]) async {
    final consulta = (texto ?? _consulta.text).trim();
    if (consulta.isEmpty || _cargando) return;
    _consulta.text = consulta;

    setState(() {
      _cargando = true;
      _error = '';
      _respuesta = '';
    });

    try {
      final r = await _servicio.preguntar(consulta, _habitos.resumen());
      if (!mounted) return;
      setState(() => _respuesta = r.respuesta);
      if (r.accion != null) await _confirmar(r.accion!);
    } on AsistenteException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _confirmar(AccionPropuesta accion) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar acción'),
        content: Text(
          '${accion.descripcionParaConfirmar}\n\n'
          'La sugerencia viene de una IA: revísala antes de aceptar.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      if (accion.tipo == 'marcar_habito') {
        final habito = _habitos.buscarPorNombre(accion.nombre);
        if (habito == null) {
          Get.snackbar('No encontré ese hábito',
              'No tienes ninguno llamado «${accion.nombre}».');
          return;
        }
        await _habitos.marcar(habito.id);
        Get.snackbar('Listo', '«${habito.nombre}» quedó marcado hoy.');
      } else {
        await _habitos.crear(accion.nombre, accion.frecuenciaObjetivo ?? 3);
        Get.snackbar('Listo', 'Se creó el hábito «${accion.nombre}».');
      }
    } on Exception catch (e) {
      Get.snackbar('El servidor rechazó la acción', '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!_auth.estaAutenticado) {
        return const SinSesionView(
          titulo: 'Asistente',
          mensaje: 'Inicia sesión para que el asistente conozca tus hábitos.',
        );
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Asistente')),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const _AvisoIA(),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _consulta,
              decoration: const InputDecoration(
                labelText: 'Pregunta sobre tus hábitos',
                hintText: '¿Cómo voy esta semana?',
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _preguntar(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final s in _sugerencias)
                  ActionChip(
                    label: Text(s),
                    onPressed: _cargando ? null : () => _preguntar(s),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _cargando ? null : () => _preguntar(),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Preguntar'),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_cargando)
              const Center(child: CircularProgressIndicator())
            else if (_error.isNotEmpty)
              _Caja(
                color: Theme.of(context).colorScheme.errorContainer,
                texto: _error,
              )
            else if (_respuesta.isNotEmpty)
              _Caja(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                texto: _respuesta,
              ),
          ],
        ),
      );
    });
  }
}

class _AvisoIA extends StatelessWidget {
  const _AvisoIA();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Las respuestas son sugerencias generadas por IA: conviene '
              'verificarlas. Solo se envía un resumen de tus hábitos, sin '
              'fechas ni datos personales.',
            ),
          ),
        ],
      ),
    );
  }
}

class _Caja extends StatelessWidget {
  const _Caja({required this.color, required this.texto});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(texto, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

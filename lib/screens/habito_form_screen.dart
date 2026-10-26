import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/habitos_controller.dart';
import '../models/habito.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';

class HabitoFormScreen extends StatefulWidget {
  final Habito? habito;

  final String? nombreInicial;
  final int? frecuenciaInicial;

  const HabitoFormScreen({
    super.key,
    this.habito,
    this.nombreInicial,
    this.frecuenciaInicial,
  });

  @override
  State<HabitoFormScreen> createState() => _HabitoFormScreenState();
}

class _HabitoFormScreenState extends State<HabitoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _frecuencia;
  final _controller = Get.find<HabitosController>();

  bool _enviando = false;
  String _error = '';

  bool get _esEdicion => widget.habito != null;

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(
        text: widget.habito?.nombre ?? widget.nombreInicial ?? '');
    _frecuencia = TextEditingController(
        text:
            '${widget.habito?.frecuenciaObjetivo ?? widget.frecuenciaInicial ?? 5}');
  }

  @override
  void dispose() {
    _nombre.dispose();
    _frecuencia.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _error = '';
    });
    try {
      final nombre = _nombre.text.trim();
      final frecuencia = int.parse(_frecuencia.text.trim());
      final anterior = widget.habito;
      if (anterior == null) {
        await _controller.crear(nombre, frecuencia);
      } else {
        final cambios = <String, dynamic>{};
        if (nombre != anterior.nombre) cambios['nombre'] = nombre;
        if (frecuencia != anterior.frecuenciaObjetivo) {
          cambios['frecuencia_objetivo'] = frecuencia;
        }
        if (cambios.isEmpty) {
          Get.back();
          return;
        }
        await _controller.actualizar(anterior.id, cambios);
      }
      Get.back();
    } on Exception catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(_esEdicion ? 'Editar hábito' : 'Nuevo hábito')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre del hábito',
                  helperText: 'Por ejemplo: Caminar 30 minutos',
                ),
                validator: Validadores.nombreHabito,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _frecuencia,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Días por semana',
                  helperText: 'Un número entre 1 y 7',
                ),
                validator: Validadores.frecuencia,
              ),
              const SizedBox(height: AppSpacing.md),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(_error,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
              FilledButton(
                onPressed: _enviando ? null : _guardar,
                child: _enviando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_esEdicion ? 'Guardar cambios' : 'Crear hábito'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

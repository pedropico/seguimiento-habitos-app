import 'package:flutter/material.dart';

class PantallaConFallo extends StatelessWidget {
  const PantallaConFallo({super.key});

  @override
  Widget build(BuildContext context) {
    throw StateError('Fallo provocado a propósito para probar el reporte.');
  }
}

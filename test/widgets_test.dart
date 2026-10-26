import 'package:seguimiento_habitos_app/models/habito.dart';
import 'package:seguimiento_habitos_app/models/registro.dart';
import 'package:seguimiento_habitos_app/theme/app_theme.dart';
import 'package:seguimiento_habitos_app/widgets/empty_view.dart';
import 'package:seguimiento_habitos_app/widgets/error_view.dart';
import 'package:seguimiento_habitos_app/widgets/habito_card.dart';
import 'package:seguimiento_habitos_app/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget envolver(Widget hijo) => MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(body: hijo),
      );

  String clave(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  group('Los tres estados se ven distintos entre sí', () {
    testWidgets('cargando muestra un indicador y su mensaje', (tester) async {
      await tester.pumpWidget(
          envolver(const LoadingView(mensaje: 'Cargando tus hábitos...')));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cargando tus hábitos...'), findsOneWidget);
    });

    testWidgets('vacío explica qué pasa y ofrece una salida', (tester) async {
      var tocado = false;
      await tester.pumpWidget(envolver(EmptyView(
        mensaje: 'Todavía no tienes hábitos.',
        textoAccion: 'Crear mi primer hábito',
        onAccion: () => tocado = true,
      )));

      expect(find.text('Todavía no tienes hábitos.'), findsOneWidget);
      await tester.tap(find.text('Crear mi primer hábito'));
      expect(tocado, isTrue);
    });

    testWidgets('error siempre ofrece reintentar', (tester) async {
      var reintentos = 0;
      await tester.pumpWidget(envolver(ErrorView(
        mensaje: 'No hay conexión con el servidor.',
        onReintentar: () => reintentos++,
      )));

      expect(find.text('No hay conexión con el servidor.'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      expect(reintentos, 1);
    });
  });

  group('HabitoCard', () {
    Habito habito({required bool hechoHoy, int racha = 0}) {
      final hoy = DateTime.now();
      final registros = <Registro>[];
      if (hechoHoy) {
        registros.add(Registro(id: 1, habitoId: 1, fecha: clave(hoy)));
      }
      for (var i = 1; i <= racha; i++) {
        registros.add(Registro(
            id: 100 + i,
            habitoId: 1,
            fecha: clave(hoy.subtract(Duration(days: i)))));
      }
      return Habito(
        id: 1,
        nombre: 'Caminar 30 minutos',
        frecuenciaObjetivo: 5,
        registros: registros,
      );
    }

    testWidgets('muestra el nombre y el avance de la semana', (tester) async {
      await tester.pumpWidget(envolver(HabitoCard(
        habito: habito(hechoHoy: true, racha: 2),
        onMarcar: () {},
        onAbrir: () {},
      )));

      expect(find.text('Caminar 30 minutos'), findsOneWidget);
      expect(find.text('3 de 5 días esta semana'), findsOneWidget);
    });

    testWidgets('con el hábito pendiente, el botón marca', (tester) async {
      var marcados = 0;
      await tester.pumpWidget(envolver(HabitoCard(
        habito: habito(hechoHoy: false),
        onMarcar: () => marcados++,
        onAbrir: () {},
      )));

      expect(find.text('Marcar'), findsOneWidget);
      await tester.tap(find.text('Marcar'));
      expect(marcados, 1);
    });

    testWidgets('si ya se marcó hoy, el botón queda deshabilitado',
        (tester) async {
      var marcados = 0;
      await tester.pumpWidget(envolver(HabitoCard(
        habito: habito(hechoHoy: true),
        onMarcar: () => marcados++,
        onAbrir: () {},
      )));

      expect(find.text('Hecho hoy'), findsOneWidget);
      await tester.tap(find.text('Hecho hoy'));
      await tester.pump();
      expect(marcados, 0);
    });

    testWidgets('tocar la tarjeta abre el detalle', (tester) async {
      var abierto = false;
      await tester.pumpWidget(envolver(HabitoCard(
        habito: habito(hechoHoy: false),
        onMarcar: () {},
        onAbrir: () => abierto = true,
      )));

      await tester.tap(find.text('Caminar 30 minutos'));
      expect(abierto, isTrue);
    });

    testWidgets('la racha se anuncia para lectores de pantalla',
        (tester) async {
      await tester.pumpWidget(envolver(HabitoCard(
        habito: habito(hechoHoy: true, racha: 4),
        onMarcar: () {},
        onAbrir: () {},
      )));

      expect(
        find.bySemanticsLabel('Racha de 5 días'),
        findsOneWidget,
      );
    });
  });
}

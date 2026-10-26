import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'bindings/app_binding.dart';
import 'controllers/auth_controller.dart';
import 'screens/asistente_screen.dart';
import 'screens/catalogo_screen.dart';
import 'screens/favoritos_screen.dart';
import 'screens/habitos_screen.dart';
import 'services/ai_assistant_service.dart';
import 'services/api_client.dart';
import 'services/catalogo_service.dart';
import 'theme/app_theme.dart';
import 'utils/reporte_errores.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Antes que nada, para que cubra también los fallos del propio arranque.
  ReporteErrores.instalar();

  await Hive.initFlutter();
  // La caja de hábitos no se abre aquí: su nombre lleva el id del usuario y
  // se abre al iniciar sesión (`HabitosRepository.abrirParaUsuario`).
  await CatalogoService.abrir();

  Get.put(ApiClient(), permanent: true);
  Get.put(AuthController(), permanent: true);
  Get.put(AiAssistantService(), permanent: true);

  runApp(const SeguimientoHabitosApp());
}

class SeguimientoHabitosApp extends StatelessWidget {
  const SeguimientoHabitosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'seguimiento-habitos-app',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'EC'), Locale('en', 'US')],
      locale: const Locale('es', 'EC'),
      initialBinding: AppBinding(),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _indice = 0;

  static const _pantallas = [
    HabitosScreen(),
    CatalogoScreen(),
    FavoritosScreen(),
    AsistenteScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pantallas[_indice],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.check_circle_outline),
              selectedIcon: Icon(Icons.check_circle),
              label: 'Hábitos'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Catálogo'),
          NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favoritos'),
          NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'Asistente'),
        ],
      ),
    );
  }
}

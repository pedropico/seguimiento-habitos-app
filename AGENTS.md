# AGENTS.md — reglas del proyecto seguimiento-habitos-app

Este archivo lo leen los agentes de código (Claude Code, Codex, Antigravity…) al abrir esta carpeta. Es el **archivo de contexto** del proyecto. Se mantiene corto y concreto, y se mejora cada vez que un agente se equivoca.

## Qué es el proyecto

seguimiento-habitos-app es una app Flutter (Android) para construir hábitos: crear hábitos, marcarlos cada día, ver la racha y el avance semanal, guardar sugerencias de un catálogo y preguntarle a un asistente de IA cómo va la semana.

- Estado con **GetX** (`AuthController`, `HabitosController`, `CatalogoController`, `AsistenteController`).
- Datos remotos con **dio** contra el backend `seguimiento-habitos-backend` (FastAPI + JWT).
- Caché local y catálogo con **Hive**; token en **flutter_secure_storage**.
- Asistente de IA a través de un **proxy propio** (`mock-server/`). La app no tiene ninguna clave de IA.

## Dónde está cada cosa

- `lib/controllers/` — estado compartido entre pantallas (controladores GetX).
- `lib/services/` — acceso al backend, al almacenamiento seguro y al proxy.
- `lib/repositories/` — decide si los datos salen de la red o de la caché.
- `lib/screens/` y `lib/widgets/` — pantallas y piezas de interfaz.
- `lib/models/`, `lib/utils/` — modelos y utilidades.
- El catálogo sale del backend (`GET /sugerencias/`, hasta 20 registros) y se guarda una copia en Hive para usarla sin conexión.
- `mock-server/` — el proxy del asistente (Node.js, sin dependencias).
- `test/` — pruebas de lógica, de widgets y del repositorio.

## Cómo verificar (siempre, antes de dar un cambio por terminado)

```bash
flutter analyze
flutter test
```

Los dos deben terminar sin errores. Si fallan, corrige el código: **no desactives el análisis ni borres pruebas para que pasen**.

## Convenciones

- El estado compartido vive en un controlador GetX. Las pantallas **no** llaman directamente a `dio`, a Hive ni al proxy.
- `setState` solo para estado local de una pantalla (el texto de un formulario, la pestaña activa).
- Todo texto visible para la persona va en español neutro.
- Cada pantalla con datos cubre los cuatro casos: cargando, vacío, error y con datos. Ninguna queda en blanco ni es un callejón sin salida.
- Los valores de color y espaciado salen de `AppTheme` y `AppSpacing`, nunca sueltos en un widget.
- Cambios pequeños y enfocados: una funcionalidad a la vez, con una prueba por cada comportamiento nuevo.

## Prohibido

- Escribir claves, tokens o contraseñas en el código, en los registros o en este archivo. No leer ni modificar `.env`.
- Guardar el token en Hive o en SharedPreferences: va al almacenamiento seguro.
- Agregar dependencias nuevas sin avisar antes y explicar por qué hacen falta.
- Ejecutar `git commit`, `git push` o crear etiquetas: eso lo hace una persona, después de leer el `git diff`.
- Estas prohibiciones sobre `.env` y git las bloquean además los permisos de `.claude/settings.json`.

## Reglas propias de este proyecto

- Los nombres de clases, funciones y variables van en **español**, igual que el resto del código.
- Antes de crear un widget nuevo, revisar si ya existe uno parecido en `lib/widgets/`.
- Todo dato que venga de fuera (backend, Hive o el asistente) se lee de forma **defensiva**: campo opcional, tipo comprobado y valor de reserva. Nunca `!` sobre algo que vino de la red.

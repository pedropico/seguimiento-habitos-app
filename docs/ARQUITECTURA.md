# Arquitectura de seguimiento-habitos-app

Documentación técnica breve. El `README.md` cubre cómo ejecutar el proyecto;
esto explica **por qué está armado así**.

## Las capas

```
┌─────────────────────────────────────────────────────────────┐
│  PANTALLA            lib/screens/  ·  lib/widgets/          │
│  Dibuja. Lee estado con Obx y pide acciones al controlador. │
│  No conoce HTTP, ni Hive, ni el token.                      │
└──────────────────────────┬──────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  CONTROLADOR         lib/controllers/   (GetX)              │
│  Guarda el estado compartido y decide en qué estado está    │
│  la pantalla: cargando, vacío, error o con datos.           │
└──────────────────────────┬──────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  REPOSITORIO         lib/repositories/                      │
│  Decide de dónde salen los datos: servidor o caché local.   │
└──────────────────────────┬──────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  SERVICIO            lib/services/                          │
│  Traduce entre el mundo exterior y los modelos de la app.   │
└──────────────────────────┬──────────────────────────────────┘
                           ↓
     backend FastAPI (JWT)  ·  Hive  ·  proxy del asistente
```

**Cada capa conoce a la de abajo y nunca a la de arriba.** Un servicio no
sabe que existen los widgets; una pantalla no sabe que existe `dio`.

## Qué hay en cada controlador

| Controlador | Qué guarda | Quién lo lee |
|---|---|---|
| `AuthController` | Usuario de la sesión, si está cargando, el último error, el aviso de sesión | Todas las secciones protegidas |
| `HabitosController` | Lista de hábitos, estado de carga, filtro, si viene de caché | Hábitos, Detalle, Asistente |
| `CatalogoController` | Catálogo, favoritos, filtro por categoría | Catálogo, Favoritos |

Los tres se registran una sola vez: `AuthController` en `main()` con
`permanent: true`, y los otros dos en `AppBinding`, que `GetMaterialApp`
ejecuta antes de dibujar la primera pantalla.

`setState` se usa **solo** para estado local: el índice de la pestaña, el
texto de un formulario mientras se escribe, la bandera de «enviando».

## Los dos interceptores

`ApiClient` monta dos piezas de código que corren en **todas** las peticiones:

1. **El token** — añade `Authorization: Bearer <token>` si hay sesión. Ningún
   servicio ni pantalla lo toca.
2. **El 401** — si el servidor rechaza el token, avisa a `AuthController`, que
   cierra la sesión. Una sola vez, no en cada pantalla.

La excepción deliberada: en `/usuarios/token` un 401 significa «contraseña
incorrecta», no «sesión caducada». Cerrar una sesión que nunca se abrió no
tendría sentido.

## La regla de la caché

`HabitosRepository` intenta el servidor primero. Si falla, mira **qué tipo**
de fallo fue:

| Fallo | ¿Usa la caché? | Por qué |
|---|---|---|
| Sin conexión, tiempo agotado | **Sí** | El dato guardado sigue siendo probablemente válido, solo viejo |
| 5xx | **Sí** | El servidor tiene un problema, no la petición |
| 401 | **No** | La sesión caducó: mostrar la lista haría creer que sigue dentro |
| 400 / 403 / 404 / 409 | **No** | Es información sobre la petición que la persona necesita recibir |

Cuando devuelve la copia, la marca (`desdeCache = true`) y la pantalla muestra
un aviso con la hora de la última sincronización. **Nunca se muestran datos
guardados sin decirlo.**

## Las tres cajas de Hive

| Caja | Qué guarda | Al cerrar sesión |
|---|---|---|
| `habitos_<id>` | La copia de los hábitos de esa persona | **Se borra del disco** |
| `catalogo` | La última copia de `GET /sugerencias/` (hasta 20), para usarla sin conexión | Se queda |
| `favoritos` | Las sugerencias guardadas | Se queda |

La primera lleva el id del usuario porque Hive guarda **sin cifrar**: con un
nombre fijo, dos personas que compartan el teléfono mezclarían sus datos. Las
otras dos son datos públicos que pertenecen al dispositivo, no a la cuenta.

El token **no** está en ninguna: va al almacenamiento seguro, donde el sistema
operativo lo cifra con una clave que la app nunca ve.

## Los tres frenos del asistente

```
   La IA propone  →  La persona decide  →  El backend valida
   (puede errar)     (diálogo de            (reglas R1-R6,
                      confirmación)          independientes)
```

Son **independientes**: si uno falla, los otros siguen en pie.

- La app valida la acción antes de mostrarla: tipo conocido, nombre no vacío,
  frecuencia entre 1 y 7. Si no pasa, se descarta y solo se muestra el texto.
- Si la IA inventa un hábito que no existe, se detecta al buscarlo por nombre,
  antes de llamar al backend.
- Y aunque todo lo anterior pase, el backend aplica sus reglas: un nombre
  repetido devuelve 409, una segunda marca del día también.

Es la misma disciplina del parseo defensivo del JSON, aplicada a la respuesta
de un modelo: **lo que viene de fuera se comprueba, no se supone**.

## Errores esperados e inesperados

- **Esperados** — sin conexión, 401, 409, nombre repetido. Tienen su propio
  mensaje y se manejan donde ocurren.
- **Inesperados** — un widget que falla al construirse, un `Future` sin
  `catch`. Nadie los previó, así que se recogen en un solo lugar:
  `ReporteErrores.instalar()`, llamado desde `main()`.

Antes de registrar cualquier mensaje, `limpiar()` reemplaza cabeceras `Bearer`
y tokens JWT por asteriscos. Un cuaderno que lee todo el edificio no es lugar
para anotar claves.

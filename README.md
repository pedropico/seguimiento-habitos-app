# seguimiento-habitos-app

App Flutter para construir hábitos y sostenerlos: crea un hábito, márcalo cada
día, mira tu racha y pregúntale a un asistente cómo vas esta semana.

## Qué hace

| Pestaña | Qué ofrece |
|---|---|
| **Hábitos** | Tus hábitos con su avance semanal y su racha. Crear, editar, eliminar y marcar como cumplido. Filtros por pendientes o cumplidos de hoy. |
| **Catálogo** | 20 hábitos sugeridos con categoría, descripción y frecuencia recomendada. Se pueden adoptar con un toque. |
| **Favoritos** | Las sugerencias que guardaste. Sobreviven al cierre de la app. |
| **Asistente** | Preguntas sobre tus hábitos en lenguaje natural. Puede proponer marcar o crear uno; con confirmación previa del usuario. |

La **racha** son los días seguidos cumplidos. Si hoy todavía no se marca, se
cuenta desde ayer: el día no ha terminado y no sería justo darla por rota a
media mañana.

---

## Requisitos

- **Flutter 3.24+** con Dart 3.5+ (`flutter --version`).
- Para el backend, una de dos: **Docker Desktop** (con Docker Compose) o
  **Python 3.11+** y [uv](https://docs.astral.sh/uv/).
- **Node.js 18+** — solo para el proxy del asistente.
- Un **emulador Android** creado (Android Studio → Device Manager).

Opcional: una cuenta personal de Google, si se desea el asistente con IA real
en lugar del modo de reglas.

---

## Inicialización en desarrollo

Necesitas **tres terminales** abiertas a la vez. El orden importa: la app
espera encontrar el backend encendido.

### 1. Backend de hábitos

El backend vive en otro repositorio, `seguimiento-habitos-pedro`, se recomienda desplegar el repositorio en una
carpeta hermana de `seguimiento-habitos-app` (las dos dentro del mismo directorio) ejemplo:

```
proyecto-habitos/
├── seguimiento-habitos-app/          ← esta app
└── seguimiento-habitos-pedro/        ← el backend
```

Ingresar al directorio del backend con `cd ../seguimiento-habitos-pedro`. Se puede
levantar de dos formas; con Docker no hace falta instalar Python ni uv.

#### Opción A — Docker Compose

Requiere **Docker Desktop** abierto.

```bash
cd ../seguimiento-habitos-pedro
cp .env.example .env          # en PowerShell: copy .env.example .env
docker compose up --build     # la primera vez construye la imagen
```

Para apagarlo: `Ctrl+C`, o `docker compose down` desde otra terminal. Las
siguientes veces basta con `docker compose up` (se puede añadir el parametro `-d` 
para dejarlo en segundo plano y ver los registros con `docker compose logs -f`).

#### Opción B — Sin Docker

```bash
cd ../seguimiento-habitos-pedro
cp .env.example .env          # en PowerShell: copy .env.example .env
uv sync                       # o: python -m venv .venv && pip install -e .
uv run alembic upgrade head   # crea las tablas
uv run uvicorn app.main:app --host 0.0.0.0 --port 8000
```

#### Con cualquiera de las dos alternativas

Comprobar que el backend responde antes de seguir:

```bash
curl http://localhost:8000/health
# {"status":"ok"}
```

La documentación interactiva se expone en <http://localhost:8000/docs>.

### 2. Proxy del asistente

```bash
cd seguimiento-habitos-app
node mock-server/mock-server.js
```

El proxy arranca en **modo REGLAS**, sin ninguna clave: la app funciona igual y no hace
falta crear cuentas en ningún sitio. Para usar el agente de IA real, revisar
[`mock-server/README.md`](mock-server/README.md).

### 3. La app

La primera vez, genera el andamiaje de Android (no está versionado):

```bash
flutter create . --platforms=android --project-name seguimiento_habitos_app
```

Después, comprobar que `android/app/src/main/AndroidManifest.xml` conserve el
permiso de INTERNET y `android:usesCleartextTraffic="true"` — ver
[`android/README.md`](android/README.md).

Y ahora:

```bash
flutter pub get
flutter run
```

### Direcciones por entorno

No están escritas en el código: se pasan al ejecutar, así la misma compilación
sirve en cualquier entorno.

| Dónde corre la app | Comando |
|---|---|
| **Emulador Android** (por defecto) | `flutter run` |
| **Teléfono físico** en la misma red | `flutter run --dart-define=API_BASE_URL=http://192.168.1.X:8000 --dart-define=LLM_BACKEND_URL=http://192.168.1.X:3000` |
| **Backend en otro equipo** | igual, con la IP de ese equipo |

`10.0.2.2` es cómo el emulador Android ve el `localhost` del computador que lo
hospeda. Desde un teléfono físico esa dirección no existe: hay que usar la IP
del computador en la red local.

---

## Probar que todo funciona

```bash
flutter analyze   # sin errores
flutter test      # todas en verde
dart format --output=none --set-exit-if-changed lib test
```

Flujo de un recorrido de la App:

1. **Crear cuenta** → Hábitos → Iniciar sesión → Crear una cuenta. La
   contraseña necesita 8 caracteres.
2. **Adoptar del catálogo** → pestaña Catálogo → «Adoptar» en cualquier ficha
   → Crear hábito.
3. **Marcar** → vuelve a la pestaña de Hábitos y toca «Marcar». El botón pasa a «Hecho hoy».
4. **Favoritos** → marcar con un corazón, estas selecciones se mantienen al cerrar la 
aplicación y al volver a abrirla.
5. **Asistente** → pestaña Asistente → existen opciones predeterminadas como por ejemplo
«¿Cómo voy esta semana?», esta funciona por medio de la conexión al proxy.

---

## Arquitectura - Cómo está construido

```
Pantalla          lib/screens/, lib/widgets/   Solo interfaz. No llama a HTTP ni a Hive.
    ↓
Controlador       lib/controllers/             Estado compartido (GetX). Decide qué mostrar.
    ↓
Repositorio       lib/repositories/            Decide: ¿servidor o caché local?
    ↓
Servicio          lib/services/                Habla con el backend, con Hive y con el proxy.
    ↓
Fuente de datos   backend FastAPI · Hive · proxy del asistente
```

Cada capa conoce a la de abajo y nunca a la de arriba. Ninguna pantalla hace
una llamada HTTP: si lo intentara, no tendría de dónde sacar el token.

### El flujo de un dato

Cuando la pantalla de Hábitos pide la lista:

1. `HabitosController.cargar()` cambia el estado a *cargando*.
2. `HabitosRepository.obtenerHabitos()` intenta el **servidor primero**.
3. Si responde, guarda la copia en Hive y devuelve `(lista, false)`.
4. Si falla **por infraestructura** (sin conexión, tiempo agotado, 5xx),
   devuelve la copia guardada marcada: `(lista, true)`, y la pantalla muestra
   el aviso con la hora de la última sincronización.
5. Si falla por **sesión o petición** (401, 403, 404, 409), **no** usa la
   caché: propaga el error. Mostrar datos viejos ante un 401 le haría creer a
   la persona que sigue dentro de su sesión.

### Se gestiona una desición de leer el `sub` del JWT en vez de pedir el perfil

Se realizó de esta forma ya que cada usuario tiene su propia caja de Hive (`habitos_<id>`), 
ya que de gestionarse por medio del perfil proveniente podría causar la mezcla de datos 
entre usuarios.

El matiz importante es que la app **lee** el contenido del token, no lo **verifica**.
Verificar la firma exige la clave secreta, que solo tiene el servidor. Por ello
el `sub` se usa únicamente para nombrar una caja local — jamás para decidir
permisos. Cada petición la vuelve a validar el servidor, que sí comprueba la
firma, y si el token no sirve el interceptor del 401 cierra la sesión.

---

## Seguridad

| Secreto | Dónde vive | Dónde nunca aparece |
|---|---|---|
| Token JWT de la sesión | `flutter_secure_storage` (Keystore en Android, Keychain en iOS) | Hive, SharedPreferences, un `print`, un commit |
| `SECRET_KEY` del backend | Solo en su `.env`, que está en `.gitignore` | git, la app, los registros |
| Clave de IA (`GEMINI_API_KEY`) | Solo en una variable de entorno del proxy | El código de la app, cualquier archivo del repositorio |
| Contraseña | En ningún lado: se escribe, se envía y se descarta | Disco, registros. El servidor solo guarda un hash |
| Direcciones de los servidores | Se pasan con `--dart-define` al compilar | Escritas fijas en el código |

El token **nunca** llega a los registros: `ReporteErrores.limpiar()` reemplaza
cualquier cabecera `Bearer` y cualquier JWT por asteriscos antes de registrar
un error, y hay pruebas que lo comprueban.

La auditoría de secretos busca patrones de clave en `lib/`, `test/` y
`mock-server/`. Conviene correrla antes de cada commit:

```bash
grep -rniE "AIza[0-9A-Za-z_-]{30,}|sk-[a-zA-Z0-9]{20,}" lib test mock-server
git check-ignore -v .env      # debe mostrar la regla de .gitignore
git log --all --oneline -- .env   # no debe imprimir nada
```

---

## Créditos y licencias

- **Backend**: `seguimiento-habitos-pedro` — FastAPI, SQLAlchemy 2.0, Alembic y MCP.
  Proyecto del módulo 2.
- **Paquetes**: `get`, `dio`, `hive` / `hive_flutter`, `flutter_secure_storage`,
  `path_provider`, `cupertino_icons`. Licencias visibles en la app:
  menú ⋮ → **Acerca de**.
- **Catálogo de hábitos** (`assets/data/catalogo.json`): elaborado para este
  proyecto a partir de recomendaciones generales de salud y productividad. No
  reproduce ninguna fuente con derechos.
- **Proveedor de IA**: Google Gemini a través del proxy, opcional. El modo de
  reglas no usa ningún servicio externo.


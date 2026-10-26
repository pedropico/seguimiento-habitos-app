# Carpeta `android/`

Este repositorio **no versiona el andamiaje completo de Android** (Gradle, el
wrapper, los iconos). Se regenera en un comando, y versionarlo solo añade
ruido binario al historial.

Lo que sí está versionado es el único archivo con decisiones propias:
`app/src/main/AndroidManifest.xml`, con el permiso de INTERNET y
`usesCleartextTraffic` para desarrollo.

## Cómo regenerarlo

Desde la raíz del proyecto, **antes de la primera ejecución**:

```bash
flutter create . --platforms=android --project-name seguimiento_habitos_app
```

El comando crea lo que falta y **no borra** `lib/`, `test/` ni los archivos de
configuración. Después, comprueba que el manifiesto siga teniendo estas dos
líneas (si `flutter create` lo regeneró, se debe volver a agregar estas configuraciones):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
...
android:usesCleartextTraffic="true"
```

Sin la primera, la app no llega al backend. Sin la segunda, Android bloquea
el tráfico HTTP del entorno de desarrollo y la app parece "sin conexión".

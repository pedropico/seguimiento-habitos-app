# Lista de verificación antes de entregar

Para recorrer en un entorno limpio, no en el computador donde se desarrolló.

## Calidad del código

- [ ] `dart format --output=none --set-exit-if-changed lib test` pasa
- [ ] `flutter analyze` termina sin errores
- [ ] `flutter test` termina con todas en verde

## Seguridad

- [ ] `grep -rniE "AIza[0-9A-Za-z_-]{30,}|sk-[a-zA-Z0-9]{20,}" lib test mock-server` no imprime nada
- [ ] `git check-ignore -v .env` muestra la regla de `.gitignore`
- [ ] `git log --all --oneline -- .env` no imprime nada (nunca se subió)
- [ ] `.env.example` está versionado y **no tiene ningún valor real**
- [ ] El token no aparece en ningún `print` ni `debugPrint`

> Si alguna clave se subió alguna vez: **rotarla primero** en el servicio que
> la emitió. Borrarla de un commit no la quita del historial.

## Requisitos funcionales

- [ ] Registro, inicio y cierre de sesión funcionan
- [ ] Una sección protegida rechaza a quien no inició sesión
- [ ] La lista principal tiene estados de carga, vacío y error, y se ven distintos
- [ ] El catálogo trae al menos 15-20 registros y no está escrito en el código
- [ ] Los favoritos sobreviven a cerrar la app por completo
- [ ] Se puede crear, editar, marcar y eliminar un hábito contra el backend
- [ ] Un segundo usuario no ve los hábitos del primero
- [ ] El asistente responde y pide confirmación antes de actuar
- [ ] El estado compartido vive en controladores, no replicado con `setState`

## Errores forzados

- [ ] Backend apagado → aparece el aviso de caché, no una pantalla en blanco
- [ ] Marcar dos veces el mismo día → mensaje del servidor (409)
- [ ] Nombre repetido al crear → mensaje del servidor (409)
- [ ] Nombre de 2 caracteres → el formulario lo bloquea antes de llamar
- [ ] Menú ⋮ → «Invalidar token» y recargar → vuelve a pedir sesión
- [ ] Menú ⋮ → «Error de pantalla» → vista amistosa, no la pantalla roja
- [ ] Proxy apagado → el asistente muestra un mensaje claro, no se congela

## Entrega

- [ ] El `README.md` se puede seguir sin preguntar nada
- [ ] El repositorio tiene historial de commits real, no uno solo al final
- [ ] El enlace del repositorio está subido a Moodle, antes de la hora límite

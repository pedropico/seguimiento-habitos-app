# Proxy del asistente — `mock-server/`

Un servidor pequeño en Node.js que se pone entre la app y el proveedor de IA.

## Por qué existe

Una app compilada se descarga en el teléfono de cualquiera, y **lo que está
dentro puede leerse**: un APK es un archivo comprimido que se abre con
herramientas gratuitas. Una clave escrita en el código viaja con cada copia, y
quien la obtenga puede usarla a tu nombre. Ofuscar solo hace más lento el paso
de buscarla; no protege el secreto.

Por eso la clave vive **solo aquí**, en una variable de entorno del servidor,
y la app únicamente conoce la dirección del proxy. Si la clave se filtra, se
cambia en un solo lugar sin publicar una versión nueva de la app.

El proxy hace además otras tres cosas:

- Decide **qué datos** salen hacia el modelo (solo el resumen, nunca el
  historial completo ni datos personales).
- **Valida** lo que la IA responde antes de dárselo a la app.
- Es el lugar natural para poner **límites de uso** por persona y por día.

## Requisitos

Node.js 18 o superior. No tiene dependencias: usa `fetch` y el módulo `http`
que vienen con Node.

## Encenderlo

### Modo REGLAS (sin clave, para desarrollar)

```bash
node mock-server/mock-server.js
```

Arranca sin ninguna clave y responde con reglas simples. **Mismo contrato**,
así que la app funciona exactamente igual. Es el modo recomendado para
desarrollar y para que quien evalúe el proyecto pueda probarlo sin crear
ninguna cuenta.

### Modo GEMINI (con clave real)

Crea una clave gratuita en <https://aistudio.google.com/apikey> (cuenta
personal de Google; las institucionales suelen no permitirlo) y defínela
**solo en la terminal**, nunca en un archivo del proyecto:

```bash
# Linux / macOS
export GEMINI_API_KEY="pega-aquí-tu-clave"
node mock-server/mock-server.js
```

```powershell
# Windows (PowerShell)
$env:GEMINI_API_KEY="pega-aquí-tu-clave"
node mock-server/mock-server.js
```

La terminal debe decir `modo GEMINI`. Si dice `modo REGLAS`, la variable no
quedó definida en esa terminal.

Para volver al modo reglas: `unset GEMINI_API_KEY` (o
`Remove-Item Env:GEMINI_API_KEY` en PowerShell) y reiniciar el proxy.

## El contrato

```
POST /asistente
Authorization: Bearer <token de la sesión>   (en la cabecera, nunca en el cuerpo)

{
  "consulta": "¿Cómo voy esta semana?",
  "resumen": {
    "habitos": [
      { "nombre": "Caminar 30 minutos", "objetivo_semanal": 5,
        "cumplidos_semana": 4, "racha": 3, "marcado_hoy": true }
    ]
  }
}
```

Respuesta:

```json
{
  "respuesta": "Esta semana llevas 4 de 5 días objetivo...",
  "accion": { "tipo": "marcar_habito", "nombre": "Caminar 30 minutos" }
}
```

`accion` es **opcional**: solo aparece cuando la pregunta pide hacer algo.
Los dos tipos posibles son `marcar_habito` y `crear_habito` (este último con
`frecuencia_objetivo` entre 1 y 7).

**El proxy no ejecuta nada**: solo propone. Quien decide es la persona, en el
diálogo de confirmación de la app, y quien valida es el backend de hábitos.

## Qué NO viaja al proxy

- Las fechas exactas de cada marca.
- Los identificadores del backend.
- El correo de la persona.
- El historial completo.

El token va **solo en la cabecera**, nunca en el cuerpo ni en los registros.
Y el registro de cada petición anota el **tamaño** y los **nombres** de los
campos, nunca su contenido:

```
Petición: 439 bytes · campos: consulta, resumen · hábitos en el resumen: 3
```

Ese tamaño casi no cambia aunque la persona tenga muchas más marcas: el
resumen tiene una fila por hábito, no una por día.

## Probarlo sin la app

```bash
# Comprobar que está encendido y en qué modo
curl http://localhost:3000/health

# Una consulta de ejemplo
curl -X POST -H "Content-Type: application/json" \
  -d @mock-server/ejemplo-consulta.json \
  http://localhost:3000/asistente

# Una que propone una acción
curl -X POST -H "Content-Type: application/json" \
  -d @mock-server/ejemplo-marcar.json \
  http://localhost:3000/asistente
```

En PowerShell usa `curl.exe`: `curl` a secas es otro comando.

## Preguntas que entiende el modo reglas

- «¿Cómo voy esta semana?»
- «¿Qué hábito estoy descuidando?»
- «¿Cuál es mi mejor racha?»
- «marca \<nombre del hábito\>»

Con la clave de Gemini el proxy entiende muchas más variantes, porque es el
modelo quien interpreta la pregunta.

## Límites conocidos

Un proxy de producción necesitaría además validar la sesión contra el
backend, limitar el uso por persona, filtrar contenido y tener registros y
alertas de costo. Este es un proxy de demostración: corre en el computador de
quien desarrolla, y la clave gratuita es solo para desarrollo.

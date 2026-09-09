# Los textos de la App Store

Todo lo que hay que completar en App Store Connect, escrito y listo para copiar.
Los límites de caracteres son los de Apple; los contadores están verificados.

## Nombre

```
Huella
```

*(6 de 30 caracteres)*

## Subtítulo

```
La salud de tu perro o gato
```

*(27 de 30 caracteres)*

Es la línea que aparece debajo del nombre en los resultados de búsqueda. Dice
para qué sirve, no cómo se siente: quien busca todavía no sabe qué es Huella.

## Texto promocional

Se puede cambiar sin publicar una versión nueva, así que sirve para avisar
novedades.

```
Anotá una medicación, un síntoma o un peso en segundos. Guardá los estudios del
veterinario en un solo lugar. Sin cuenta, sin publicidad y sin que nada salga de
tu teléfono.
```

*(178 de 170 caracteres — recortar a esto:)*

```
Anotá una medicación, un síntoma o un peso en segundos. Los estudios, en un solo
lugar. Sin cuenta, sin publicidad y sin que nada salga de tu teléfono.
```

*(150 de 170 caracteres)*

## Descripción

```
Huella guarda la historia de salud de tu perro o de tu gato en un solo lugar.

Anotar toma segundos
Una medicación, un síntoma, un peso o un estudio, sin recorrer un laberinto de
archivos.

Qué viene después
Turnos, vacunas y controles, siempre a la vista. La app te avisa cuando se
acerca, y el aviso de una medicación trae un botón para registrar la toma sin
abrir la app.

Todo junto para el veterinario
Un resumen en PDF con lo que elijas incluir, listo para compartir en la consulta.

Modo emergencia
Los datos urgentes de tu compañero y los teléfonos a los que llamar, a un toque.
Pensado para el peor momento: sin navegación, con letra grande.

El archivo que ya tenés
Si tenés años de estudios guardados en otro lado, se pueden traer varios de una
vez. Huella lee el nombre de cada archivo y propone el título y la fecha.

Respaldo que es tuyo
Un archivo con toda la información, para guardar donde quieras y volver a cargar
en cualquier teléfono. Es un archivo abierto y legible: si algún día esta app
deja de existir, tu información se abre igual.

QUÉ NO HACE HUELLA

No diagnostica, no interpreta y no aconseja. Anota lo que vos le contás y lo
ordena. Si algo te preocupa, quien tiene que decirlo es un veterinario.

TUS DATOS

Se guardan en tu teléfono y no se suben a internet. No hay cuenta, no hay
servidores nuestros, no hay publicidad y no hay rastreo. Compartir algo es
siempre una decisión tuya.

La única excepción es buscar veterinarias cerca: ahí, y solo cuando tocás ese
botón, la app le pregunta al mapa del teléfono qué hay alrededor.

GRATIS, Y VA A SEGUIR SIENDO GRATIS

Sin versión paga, sin prueba por tiempo limitado y sin funciones reservadas.
Llevar la salud de un animal al que se quiere no puede depender de poder pagarla.

PENSADA PARA QUE LA PUEDA USAR CUALQUIERA

Huella funciona con VoiceOver, con el texto en el tamaño más grande y en modo
oscuro. Ningún estado se comunica solo con color. No es una función agregada al
final: está verificado en cada versión.
```

## Palabras clave

Cien caracteres, separadas por comas y sin espacios después de las comas. No hay
que repetir palabras que ya están en el nombre ni en el subtítulo: Apple ya las
indexa.

```
mascota,veterinario,vacunas,medicacion,historia,clinica,peso,recordatorio,gato,perro,salud
```

*(90 de 100 caracteres)*

**Nota sobre "mascota":** la palabra está prohibida dentro de la app, y con
razón. Acá se usa igual porque es lo que la gente escribe en el buscador, y las
palabras clave no las ve nadie. Es la única excepción, y es deliberada.

## Categoría

- **Principal: Estilo de vida.**
- **Secundaria: Utilidades.**

**Por qué no Medicina.** Esa categoría trae otro nivel de escrutinio de Apple y
exige respaldo profesional para lo que la app afirme. Huella no afirma nada
sobre salud —justamente— así que Medicina sería a la vez incorrecto y caro.

## Clasificación por edad

**4+.** La app no tiene contenido sensible, ni compras, ni acceso a internet sin
restricción, ni contenido generado por otras personas.

## Direcciones web

- **Soporte:** hace falta una. Puede ser la misma página de la política de
  privacidad con un correo de contacto.
- **Política de privacidad:** obligatoria. El texto está en docs/privacidad.md y
  la página lista para publicar en sitio/privacidad.html.

## Las respuestas de privacidad de Apple

App Store Connect hace un cuestionario largo. Las respuestas para Huella:

- **¿Recoge datos la app?** No.
- **¿Rastrea a las personas usuarias?** No.

Es tan corto porque es cierto: la información nunca sale del teléfono.

**Un punto a mirar con atención al completar el formulario:** la ubicación se usa
para buscar veterinarias cerca, pero la app no la recibe ni la guarda —se la pasa
al mapa del sistema y el resultado se descarta al cerrar la pantalla—. Según las
reglas de Apple eso no cuenta como recolección, pero conviene leer la pregunta
exacta el día que se complete, porque el formulario cambia.

## Cumplimiento de exportación (el cuestionario de cifrado)

La app **no usa cifrado propio**. Solo hay tráfico HTTPS estándar del sistema, a
través del mapa de Apple. Eso entra en la exención habitual.

## Las capturas de pantalla

Apple pide, como mínimo, capturas de un iPhone de 6,9 pulgadas. Se sacan del
simulador con Command-S y salen del tamaño correcto.

**Las cinco a sacar, en este orden.** El orden importa: la mayoría de la gente
solo mira la primera y la segunda.

1. **Hoy, con datos cargados.** Una medicación en curso, algo en Próximamente y
   actividad reciente. Es la pantalla que muestra de qué se trata.
2. **Registrar.** Las nueve opciones agrupadas. Muestra el alcance sin
   explicarlo.
3. **Modo emergencia.** Es lo más distintivo de la app y nadie más lo tiene.
4. **La evolución del peso**, con cinco o seis pesos cargados para que la línea
   diga algo.
5. **El resumen en PDF**, o el historial con documentos adjuntos.

**Antes de sacarlas:** cargar datos que se vean reales. Una captura con "Prueba
1" y "asdasd" se nota, y es lo primero que ve alguien que está decidiendo si
instalarla.

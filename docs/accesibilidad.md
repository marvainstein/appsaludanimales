# Cómo probar la accesibilidad

La accesibilidad no está terminada porque el código la contemple: está terminada
cuando alguien la usa y funciona.

Hay tres niveles, del más automático al más humano:

1. `Scripts/check-accessibility.sh` verifica reglas que se leen en el código.
2. La **auditoría automática** corre con `⌘U`, dentro de
   `AppSaludAnimalesUITests`: detecta elementos sin etiqueta, contraste
   insuficiente, áreas de toque chicas y texto cortado. Es la misma auditoría
   del Accessibility Inspector de Xcode, pero sin tener que acordarse de
   abrirlo. Si una de esas pruebas falla, el mensaje dice qué elemento, con qué
   identificador, qué texto y en qué parte de la pantalla: alcanza con leer la
   línea de la falla, sin abrir el detalle.

   **Lo que la auditoría no cubre.** En las pantallas con una lista más larga
   que la pantalla, la verificación de tamaño de texto queda apagada. Esa
   verificación agranda el texto al máximo y vuelve a medir: todo lo que queda
   debajo del borde inferior lo mide sin haber crecido y lo reporta como si su
   tipografía no escalara, y lo mismo hace con los botones de la barra de
   navegación, que dibuja el sistema. Se comprobó en el registro rápido, donde
   las seis filas usan la misma función y la misma tipografía y solo se
   reportaban las cuatro de abajo. Como esa verificación ahí no dice nada útil,
   el tamaño de texto en esas pantallas **se prueba a mano**, en el paso de
   Dynamic Type de más abajo. Todo el resto de la auditoría sigue corriendo.
3. Lo que sigue en este documento, que se prueba a mano y no lleva más de veinte
   minutos por vuelta.

Los tres son necesarios: los dos primeros encuentran lo mecánico, y solo el
tercero dice si la app **se puede usar**.

## Criterio de terminado

Una funcionalidad está lista cuando:

- Funciona mirando la pantalla.
- Funciona con VoiceOver, sin mirarla.
- Se puede recorrer en un orden que se entiende.
- Sigue funcionando con el tamaño de texto más grande.
- Tiene contraste suficiente en modo claro y oscuro.
- Ningún estado se comunica solo con color.
- Todo campo de texto tiene una salida del teclado que no dependa de tocar
  afuera. "Tocar afuera" no existe para quien navega con VoiceOver, y el teclado
  numérico ni siquiera trae tecla de retorno.
- Cada control dice qué es y qué va a pasar al activarlo.

Si algo de esto falla, la funcionalidad no está terminada, aunque se vea bien.

## 1. VoiceOver

**Cómo activarlo:** Ajustes → Accesibilidad → VoiceOver. Conviene además
configurar Ajustes → Accesibilidad → Atajo de accesibilidad → VoiceOver, para
prenderlo y apagarlo con tres clics del botón lateral.

**Gestos mínimos:** deslizar a la derecha pasa al siguiente elemento, doble toque
activa, dos dedos hacia arriba lee toda la pantalla desde el principio.

**La prueba de verdad:** apagar la pantalla (o mirar para otro lado) y completar
el flujo entero. Si hace falta espiar, algo no está bien.

Recorrido a probar, uno por vuelta:

1. Crear un compañero desde la bienvenida.
2. Registrar un peso.
3. Registrar una toma de una medicación en curso.
4. Encontrar el modo emergencia y llamar al veterinario.
5. Buscar algo en el historial usando un filtro.
6. Generar un resumen en PDF.

**Qué escuchar:**

- Que cada control diga qué es, no "botón" a secas.
- Que los campos digan si son obligatorios u opcionales.
- Que los estados se escuchen ("Activo", "En seguimiento"), porque el color no
  se oye.
- Que el rotor (girar dos dedos sobre la pantalla) permita saltar por
  encabezados en el dashboard y en el historial.

## 2. Tamaño de texto grande

**Cómo activarlo:** Ajustes → Accesibilidad → Pantalla y tamaño del texto →
Tamaño del texto → mover al máximo. Para los tamaños de accesibilidad, activar
antes "Tamaños más grandes".

Probar en el tamaño **más grande de todos**, no en uno intermedio.

**Qué mirar:**

- Que no se corte ningún texto con puntos suspensivos donde importa.
- Que no se superpongan elementos.
- Que los botones sigan visibles y alcanzables.
- Que las tarjetas crezcan hacia abajo en vez de apretar el contenido.
- Que el modo emergencia siga leyéndose de un vistazo.

## 3. Modo oscuro

**Cómo activarlo:** Ajustes → Pantalla y brillo → Oscuro.

Recorrer las mismas pantallas y verificar que todo tenga contraste suficiente,
en especial los indicadores de estado y los textos secundarios en gris.

## 4. Contraste aumentado y sin color

- Ajustes → Accesibilidad → Pantalla y tamaño del texto → **Aumentar contraste**.
- Ajustes → Accesibilidad → Pantalla y tamaño del texto → **Filtros de color** →
  Escala de grises.

En escala de grises tiene que seguir entendiéndose todo: si un estado deja de
distinguirse, es que estaba apoyado solo en el color.

## 5. Control por voz

**Cómo activarlo:** Ajustes → Accesibilidad → Control por voz.

Decir "mostrar nombres" para ver las etiquetas de los controles. Cada control
tiene que tener un nombre pronunciable y distinto de los demás. Probar registrar
un peso hablando, sin tocar la pantalla.

## 6. Control por botón

**Cómo activarlo:** Ajustes → Accesibilidad → Control por botón. Se puede usar la
pantalla completa como botón para probarlo sin hardware.

Verificar que todo lo que se puede hacer con un gesto de deslizar también se
pueda hacer sin deslizar: un gesto que no tiene alternativa deja gente afuera.

## 7. Reducir movimiento y transparencia

- Ajustes → Accesibilidad → Movimiento → **Reducir movimiento**.
- Ajustes → Accesibilidad → Pantalla y tamaño del texto → **Reducir
  transparencia**.

Hoy la app no depende de ninguna animación para comunicar estado, así que esto es
una verificación rápida: nada debería cambiar de significado.

## Qué hacer con lo que aparezca

Anotarlo con la pantalla, el ajuste activo y qué se esperaba. Un hallazgo de
accesibilidad no es una mejora opcional: entra a la lista de errores como
cualquier otro.

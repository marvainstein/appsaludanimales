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
   Dynamic Type de más abajo.

   Por el mismo motivo, en las pantallas armadas con formularios del sistema
   —perfil, respaldo, acerca de, la despedida— queda apagada también la
   verificación de contraste. Ahí señala cosas que no son nuestras y que no
   podemos cambiar: los botones de la barra de navegación, el texto de pie de
   una lista —que usa los colores por omisión de Apple— y varios hallazgos que
   ni siquiera pueden decir sobre qué elemento cayeron. El contraste de los
   colores del producto no queda sin verificar: `PaletteContrastTests` calcula
   el número real de cada combinación que definimos, en claro y en oscuro, y
   falla si alguna baja de 4,5. Eso es más confiable que muestrear píxeles.
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

## Deuda pendiente

**La pantalla de la despedida.** La auditoría automática avisa que ahí hay
"texto que debería estar expuesto a las tecnologías asistivas", pero no puede
decir cuál: es el tercer hallazgo seguido en esa pantalla sin elemento asociado.
No se puede arreglar lo que no se puede ubicar, así que esa verificación quedó
apagada solo ahí.

**Cómo se salda:** recorrer esa pantalla con VoiceOver en el teléfono. Si de
verdad hubiera texto no expuesto, se escucharía como un pedazo mudo: se ve algo
escrito y VoiceOver no lo lee. Si eso no pasa, era un falso positivo y se puede
cerrar. Si pasa, se arregla y se vuelve a encender la verificación.

## Qué se probó, y cuándo

### Septiembre 2026 — primera pasada completa en teléfono

Hecha en un iPhone, con la app instalada, no en el simulador.

**Lo que se verificó:**

- Texto al tamaño de accesibilidad más grande: todo el contenido sigue siendo
  alcanzable, nada queda cortado ni tapado.
- VoiceOver: todo el contenido es alcanzable en orden, cada elemento se anuncia
  con nombre, y los botones dicen qué hacen antes de tocarlos.
- Escala de grises: los estados se siguen distinguiendo. Activo y suspendido
  tienen íconos distintos, y activo de una medicación se distingue de activo de
  un episodio también por el ícono. La regla de no comunicar nunca un estado
  solo con color está verificada en el dispositivo, no solo en el código.
- Modo oscuro: sin problemas de lectura.

**Lo que encontró:** después de escribir en un campo no había forma de cerrar el
teclado sin tocar afuera, y "afuera" no existe navegando con VoiceOver. El botón
de guardar quedaba tapado. Arreglado con una salida explícita del teclado, que
además quedó como criterio de terminado más arriba.

**El límite de esta pasada, dicho de frente.** La hizo una persona que ve y que
usó VoiceOver por primera vez. Eso alcanza para verificar lo estructural —que
todo esté alcanzable, en orden y con nombre— y no alcanza para saber si la app es
cómoda para alguien que usa VoiceOver todos los días. Esa persona navega con una
fluidez que quien prueba de prestado no tiene, y nota fricciones que a nosotros
se nos pasan de largo.

**Lo que falta, entonces:** que una persona ciega use la app diez minutos, antes
de que la app llegue a alguien más que a quien la construyó. No hay forma de
deducir eso desde acá.


## El contraste de los encabezados y pies de sección

Septiembre de 2026. La auditoría empezó a marcar "contrast nearly passed" en
encabezados y pies de lista: "Archivo", "Veterinarias", "Guardá las que ya
conocés…".

**Era real.** El gris que iOS usa por omisión ahí queda en unos 4,4:1, apenas
por debajo del 4,5:1 que la norma pide para texto de tamaño normal. Por eso el
hallazgo dice *nearly*: pasa el umbral del texto grande y no el del normal.

Se podría haber apagado la verificación de contraste en esas dos pantallas, como
ya estaba apagada en otras. No se hizo, porque teníamos algo mejor: **nuestro
propio `inkMuted` da 7,0:1 sobre fondo claro y 5,6:1 sobre el apagado**, medido
por PaletteContrastTests. El color del producto es más legible que el del
sistema.

Así que los 95 encabezados y pies de la app pasaron a usarlo. Y hay una regla en
`Scripts/check-accessibility.sh` que falla si aparece uno sin él: son muchos
lugares y el que se olvida es siempre el que se agrega después.

Como efecto secundario, la razón "los pies de lista usan los colores por omisión
de Apple" ya no justifica apagar el contraste en ninguna pantalla. Lo que queda
sin poder arreglarse son los botones de la barra de navegación, que dibuja el
sistema, y los hallazgos que no dicen sobre qué elemento cayeron.

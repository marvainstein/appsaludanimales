# Ideas para evaluar después del MVP

Cosas que surgieron mientras construíamos y que no entran ahora. No es una lista
de compromisos: es dónde anotarlas para no perderlas y poder decidirlas con
calma.

## El objetivo cambió: la app se va a distribuir

Septiembre 2026. La app dejó de ser una herramienta para las compañeras de quien
la construyó: la idea es que la use mucha gente. Eso reordena las prioridades y
conviene tenerlo escrito, porque cambia qué es "estar terminado".

**Lo que habilita el Apple Developer Program pagado**, y que no se puede hacer
sin él: TestFlight (poner la app en manos de otras personas antes de publicarla),
iCloud —y por lo tanto la sincronización entre las personas a cargo—, y la
publicación en la App Store. De paso, se termina el vencimiento a los siete días
de la firma gratuita.

**Lo más valioso de los tres no es la sincronización, es TestFlight.** Diez
personas usando la app una semana enseñan más que cualquier cosa que se pueda
deducir desde adentro. Y es la única forma realista de conseguir lo que quedó
abierto en docs/accesibilidad.md: que la pruebe alguien que usa VoiceOver todos
los días.

**Lo que hay que construir sin depender de esa cuenta**, porque hace falta igual:
el respaldo exportable, y una segunda mirada a la app pensando en alguien que la
abre sin haber participado de ninguna de las conversaciones que la formaron.

**Antes de la App Store** van a hacer falta política de privacidad, las etiquetas
de privacidad de Apple, capturas y descripción. Juega a favor que la app no
diagnostica: esa regla, además de ser lo correcto, es lo que la mantiene fuera de
la categoría de aplicaciones médicas.

## Importar documentos en lote (caso Google Drive)

**El caso real.** Alguien que ya tiene años de estudios de sus compañeras
clasificados en Google Drive. Pasarlos a la app de a uno es inviable, y si la
única forma de empezar a usar la app es hacer eso, no la empieza a usar.

**Lo barato primero.** El selector de archivos de iOS ya llega a Google Drive
cuando la app de Drive está instalada: aparece como una ubicación más dentro de
Archivos. Hoy el adjuntar documentos toma un archivo por vez; permitir elegir
varios de una y crear un registro por cada uno resuelve buena parte del problema
sin integrar nada. Hace falta además una pantalla de revisión: adjuntar treinta
archivos sin poder ponerles título ni fecha crea treinta registros inútiles, así
que la importación en lote necesita una forma rápida de repasar y completar.

**La integración de verdad.** Conectar la API de Drive (elegir una carpeta,
recorrerla, respetar su clasificación) es bastante más grande: autenticación,
permisos, mantener sincronizado lo que cambia del otro lado. Y tiene una
consecuencia de privacidad que hay que mirar de frente: hoy ningún dato de salud
sale del dispositivo, y una integración así implica que la app hable con un
servicio de terceros.

**Cómo decidirlo.** Construir primero la selección múltiple con revisión, ver si
alcanza. La integración completa se justifica solo si mucha gente tiene su
archivo organizado afuera y la importación manual sigue siendo el motivo por el
que abandonan.

## Espacios de difusión: marcas y refugios

**La idea.** Sumar algún espacio de publicidad no invasiva —una marca de
alimento, por ejemplo— y/o difundir refugios, en conjunto con la app.

**Lo que sí cierra.** La parte de refugios es la más fuerte de las dos, y no
solo por lo que aporta: encaja con lo que la app ya es. Alguien que lleva la
historia de salud de su compañera es exactamente quien puede adoptar, donar o
difundir. Un espacio así se siente parte del producto y no un peaje. Además es
la puerta más natural para que refugios y protectoras recomienden la app, que
es distribución genuina y gratis.

**Lo que hay que mirar de frente.** Esta app se mete en un tema sensible: la
salud de alguien a quien se quiere. La confianza es el activo principal y es lo
más fácil de romper. Tres riesgos concretos:

1. **Confusión con consejo de salud.** Una marca de alimento al lado de un
   episodio o de una medicación se lee como recomendación. La app tiene
   prohibido diagnosticar y recomendar; una publicidad ubicada sin cuidado
   rompe esa promesa aunque el texto legal diga otra cosa.
2. **Datos.** Las redes de publicidad habituales viven de perfilar. Hoy ningún
   dato de salud sale del teléfono, y eso está dicho en el producto. Si algún
   día hay publicidad, no puede segmentarse con datos de salud, ni mandar
   identificadores afuera.
3. **La pantalla principal.** Es la que se abre con apuro, a veces con el animal
   enfermo al lado. Es la peor pantalla posible para meter algo que compite por
   la atención.

**Cómo lo haría.** Nada de red publicitaria: acuerdos directos, pocos, elegidos.
Un módulo propio, servido por la app, sin rastreo. Ubicación en pantallas de
calma —perfil, historial, un lugar propio tipo "Comunidad"— nunca en Hoy, nunca
en emergencia, nunca dentro del registro de un síntoma. Siempre marcado como
espacio patrocinado, con texto e ícono, no solo con un color. Y arrancaría por
refugios: es lo que se puede probar sin poner en juego la confianza, y si eso no
funciona, la publicidad paga tampoco va a funcionar.

**Decidido (septiembre 2026): la publicidad paga queda descartada, y la app es
gratis para siempre.** Sin versión paga, sin prueba gratuita, sin funciones
reservadas: llevar la salud de un animal al que se quiere no puede depender de
poder pagarla. Lo único que queda en pie de esta sección es la difusión de
refugios y protectoras, sin cobrar y sin rastrear a nadie. El resto queda escrito
como el razonamiento que llevó ahí.

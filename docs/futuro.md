# Ideas para evaluar después del MVP

Cosas que surgieron mientras construíamos y que no entran ahora. No es una lista
de compromisos: es dónde anotarlas para no perderlas y poder decidirlas con
calma.

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

**Cómo decidirlo.** Primero mirar cuánta gente usa la app de forma sostenida.
Monetizar antes de eso resuelve un problema que todavía no existe y crea uno
nuevo. Si hace falta ingreso, comparar contra las alternativas que no tocan la
confianza: una función paga opcional (sincronización entre personas a cargo,
resúmenes ilimitados) suele rendir más que la publicidad y no cambia lo que la
app es.

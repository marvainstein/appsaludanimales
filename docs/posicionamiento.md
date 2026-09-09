# Qué es Huella, y qué se niega a ser

Este documento existe porque las decisiones que definen un producto se toman una
vez, en una conversación, y después se olvidan. Cuando alguien —dentro de un año,
o alguien nuevo— proponga agregar una suscripción o un consejo automático de
salud, la respuesta tiene que estar escrita y tiene que decir por qué.

## De dónde viene

La app nació del seguimiento de Luli, una galga adoptada de adulta, con problemas
articulares, óseos y epilepsia. Llevar esa historia en papeles sueltos y en la
memoria fue el problema real. Todo lo que hay acá —la precisión con las
medicaciones, el modo emergencia, la obsesión con que nada se pierda— sale de ahí
y no de un análisis de mercado.

## Las tres decisiones que no se negocian

**Gratis, siempre.** Sin versión paga, sin prueba gratuita, sin funciones
reservadas. Llevar la salud de un animal al que se quiere no puede depender de
poder pagarla. Esto tiene un costo real y conviene decirlo: la cuenta de
desarrollador de Apple se paga todos los años y sale del bolsillo de quien
sostiene el proyecto. Es una decisión tomada sabiendo eso.

**Sin publicidad paga.** La única excepción posible es difundir refugios y
protectoras, sin cobrar y sin rastrear a nadie. El razonamiento largo está en
docs/futuro.md.

**No diagnostica ni aconseja.** La app registra hechos y los ordena. Nunca dice
si un peso está bien, si un síntoma es grave o qué hacer. Eso lo dice el
veterinario. La regla está sostenida por pruebas que fallan si aparece una
palabra que interprete.

## Qué la separa de las demás

Mirando la categoría en la App Store argentina, las apps de este tipo son anchas:
salud, entrenamiento, paseos, lugares, widgets. Compiten por cantidad de
funciones. Huella no compite ahí.

1. **Se puede usar sin ver la pantalla.** Casi ninguna app de la categoría lo es.
   No es una función que se agrega al final: es auditoría automática en cada
   compilación, un protocolo manual documentado y pruebas que fallan si un color
   pierde contraste. Es lo más difícil de copiar, porque no se puede agregar
   después.
2. **No interpreta.** La categoría está llena de consejos automáticos. Acá viven
   los hechos; el criterio lo pone quien estudió para eso.
3. **Los datos no salen del teléfono por su cuenta.** Sin cuenta, sin nube por
   defecto.
4. **Los datos son de quien los cargó.** El respaldo es un JSON legible: si esta
   app desaparece, la información se abre igual.
5. **Importar lo que ya existe.** Nadie resuelve "tengo ocho años de estudios
   guardados afuera". Es la razón por la que alguien se cambia en lugar de
   empezar de cero.
6. **Está escrita en argentino por alguien que habla argentino**, no traducida a
   máquina.
7. **El modo emergencia** está diseñado para el peor momento, no para los buenos.

## El tono: seria pero con gracia

La regla que resuelve la tensión:

> **La gracia vive en la calma. En la urgencia, sobriedad.**

- **Con gracia:** bienvenida, estados vacíos, el perfil, el cumpleaños, las
  ilustraciones, el tono de los textos.
- **Sin gracia:** modo emergencia, registrar un síntoma, un aviso de medicación,
  un error. Ahí alguien está asustado o apurado, y un dibujo simpático se lee
  como que la app no entiende la gravedad.

## Pendiente

El nombre. "Manada y Huellas" ya existe en la App Store argentina. Los nombres no
son iguales y lo más probable es que Apple no lo rechace, pero hay que revisar el
INPI antes de que "Huella" quede impreso en todos lados.

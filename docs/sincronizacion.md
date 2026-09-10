# Sincronización con iCloud

Decidida en septiembre de 2026, para construir después de pagar la cuenta de
desarrollador. No se puede empezar antes: iCloud es una *capability* que Apple
solo habilita para cuentas del Developer Program pago.

## Por qué

Hoy la información vive solo en el teléfono. Si el teléfono se pierde, se rompe
o se lo roban, la única red es un respaldo que la persona haya hecho a mano. El
respaldo protege a quien es ordenado; el problema lo tiene quien no lo es. Y
ocho años de estudios de un animal no se reconstruyen.

De paso resuelve algo que estaba pendiente desde el principio: dos personas que
comparten el cuidado de un animal, cada una con su teléfono.

## Las decisiones tomadas

**Se pregunta una sola vez, y no hay perilla.** La persona elige activarla o no,
y queda así. No viene prendida por omisión: la app ya funciona con ese criterio
en todo lo demás —el PDF, el respaldo, los documentos— y que la sincronización
fuera la única cosa que se prende sola habría sido la excepción rara.

**Se ofrece donde ya está el aviso de respaldo.** El "¿Hacemos un respaldo?" del
tablero aparece cuando ya hay información que se puede perder. Ese es el momento
en que a la persona le importa; la bienvenida no lo es, porque ahí todavía no
tiene nada cargado.

**No hay cuentas.** CloudKit usa la sesión de iCloud que la persona ya tiene para
bajar apps. La app no pide correo ni contraseña, no ve credenciales y no crea
usuarios. La frase de la política —"no hay cuenta, no hay servidores nuestros"—
sigue siendo cierta después del cambio.

## Lo verificado en el código

El esquema cumple los requisitos de CloudKit, y esto se comprobó, no se supuso:

- Ningún atributo `.unique`.
- Ninguna propiedad obligatoria sin valor por omisión.
- Las 13 relaciones tienen inversa declarada.
- Solo se usan `deleteRule: .cascade` y `.nullify`.

Los documentos adjuntos viven dentro de la base con `@Attribute(.externalStorage)`,
así que CloudKit los sube como adjuntos junto al registro. No quedan registros
sincronizados apuntando a archivos que no viajaron.

El único cambio de configuración es `cloudKitDatabase: .none` en
`ModelContainerFactory`.

## Los dos casos que hay que resolver bien

**iCloud apagado.** Hay gente que lo tiene desactivado. Si toca "sí" y no pasa
nada, es peor que no haberlo ofrecido: cree que está protegida y no lo está.

**Espacio agotado.** iCloud regala 5 GB y mucha gente los tiene llenos. Cada
documento puede pesar hasta 25 MB.

Los dos comparten la misma trampa: **fallar sin avisar.** En una app cuyo
propósito es que no se pierda la historia clínica de un animal, eso es lo único
inaceptable. Cualquiera de los dos casos tiene que decirse con todas las letras.

## Lo que hay que actualizar antes de publicar

La política de privacidad, la pantalla "Acerca de" y los textos de la App Store
dicen hoy que la información no sale del teléfono. Con la sincronización activada
eso deja de ser cierto: pasa a ir al iCloud de la persona, nunca a servidores
nuestros. Se cambia **antes** de que la app llegue a nadie.

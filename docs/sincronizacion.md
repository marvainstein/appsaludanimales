# Sincronización con iCloud

Decidida en septiembre de 2026, para construir después de pagar la cuenta de
desarrollador. No se puede empezar antes: iCloud es una *capability* que Apple
solo habilita para cuentas del Developer Program pago.

## Por qué

Hoy la información vive solo en el teléfono. Si el teléfono se pierde, se rompe
o se lo roban, la única red es un respaldo que la persona haya hecho a mano. El
respaldo protege a quien es ordenado; el problema lo tiene quien no lo es. Y
ocho años de estudios de un animal no se reconstruyen.

## Lo que esto NO resuelve

Dos personas distintas, con dos cuentas de iCloud distintas, cuidando al mismo
animal. Eso quedó para la 2.0 y está en docs/futuro.md.

Es una confusión fácil y conviene dejarla clara acá. Lo de esta página es la
**base de datos privada** de iCloud: la información de una persona, en su propia
cuenta, en todos *sus* dispositivos. Su iPhone y su iPad ven lo mismo. Otra
persona, con otro Apple ID, no ve nada.

Compartir entre cuentas es otra tecnología —`CKShare`— con invitaciones,
permisos y conflictos de edición simultánea. No sale de acá.

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

## Lo construido antes de tener la cuenta

La pantalla está hecha y se puede probar hoy, con una salvedad: `AppCapabilities.cloudSyncIsBuilt`
está en `false`, así que tocar el botón lleva siempre al aviso de "todavía no
está disponible".

Eso no es una limitación, es el punto. **El camino que hay que construir bien es
el que falla**, y hoy la app está justamente en ese estado. El camino de éxito lo
prueba cualquiera; el que arruina una app es el que falla sin avisar.

Cuando exista la cuenta paga, son tres cambios:

1. Activar la capacidad de iCloud en el proyecto (pestaña *Signing & Capabilities*).
2. `cloudKitDatabase: .none` → sincronizado, en `ModelContainerFactory`.
3. `AppCapabilities.cloudSyncIsBuilt` → `true`.

Y recién ahí la prueba de verdad, que necesita dos dispositivos con la misma
cuenta de iCloud.

## Cómo se llama en la app

En ningún texto aparece la palabra "sincronizar". Nadie quiere sincronizar: la
gente quiere no perder las cosas. Se llama **"que se guarde solo"**, que además
es literalmente lo que hace. Hay un test que falla si alguna vez se cuela la
palabra.

## Lo que hay que actualizar antes de publicar

**Ya está hecho** en la pantalla "Acerca de", en docs/privacidad.md y en
sitio/index.html: los tres describen la copia en iCloud como lo que es, algo que
la persona activa si quiere y que va a su propia cuenta.

Se escribió ahora y no cuando la función funcione, por una razón: la app todavía
no la tiene nadie más que quien la construye, así que no hay nadie a quien el
texto pueda confundir, y el riesgo real no es adelantarse sino olvidarse.

**Lo que falta:** volver a subir `sitio/index.html` al repositorio
`estela-privacidad`, para que la página publicada diga lo mismo. Eso se hace
junto con la publicación de la app, no antes.

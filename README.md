# App de salud para animales de compañía

Aplicación iOS para que las personas responsables de perros y gatos organicen y
sigan la salud de sus compañeros y compañeras.

Estado actual: los **cimientos** (modelo de datos, dominio, sistema de diseño
accesible, infraestructura de lenguaje), la **primera porción usable**
—bienvenida, alta y edición de compañeros, dashboard de "Hoy"— y el **registro
rápido** de medicaciones, episodios, peso, vacunas y notas.

## Abrir y compilar

```bash
open AppSaludAnimales.xcodeproj
```

Requiere Xcode 16 o posterior (el proyecto usa carpetas sincronizadas con el
sistema de archivos, así que los archivos nuevos se incorporan solos, sin editar
el archivo del proyecto).

Objetivo mínimo: **iOS 18**. Ejecutar las pruebas desde Xcode con `⌘U`, o:

```bash
xcodebuild test -scheme AppSaludAnimales -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Lenguaje del producto

En esta app los perros y gatos son **compañeros** y **compañeras**, o **animales
de compañía**. La palabra "mascota" no se usa en ninguna parte: ni en la
interfaz, ni en notificaciones, ni en mensajes de error, ni en el código.

Para que la regla no dependa de la memoria de quien escribe:

```bash
./Scripts/check-vocabulary.sh
```

Falla si aparece un término fuera del vocabulario del producto. Conviene
ejecutarlo en integración continua junto con las pruebas.

## Estructura

```
AppSaludAnimales/
  App/            Punto de entrada y vista raíz
  Domain/         Reglas de negocio, sin dependencia de persistencia ni de UI
  Data/           Entidades SwiftData y contenedor de persistencia
  Features/       Pantallas, agrupadas por funcionalidad
  DesignSystem/   Tokens de color, tipografía, espaciado y componentes base
  Resources/      Catálogo de strings y assets
AppSaludAnimalesTests/
Scripts/
```

## Decisiones tomadas en estos cimientos

**Precisión de la fecha de nacimiento, no un interruptor de "aproximada".**
`BirthDatePrecision` (exacta / mes y año / solo año / desconocida) es una sola
fuente de verdad de la que se derivan la edad y el cumpleaños. La edad calculada
arrastra siempre si es estimada, y eso se comunica en texto.

**Los estados nunca se comunican solo con color.** `StatusPresentable` obliga a
que todo estado tenga etiqueta, ícono y tono. Hay una prueba que lo verifica para
cada caso de cada enum de estado.

**Enums guardados como texto.** Las entidades guardan el valor crudo del enum y
exponen una propiedad calculada. Los predicados de SwiftData trabajan mejor sobre
tipos primitivos y la sincronización con CloudKit no admite todos los tipos
compuestos.

**El esquema ya cumple los requisitos de CloudKit** aunque la sincronización
esté apagada (`cloudKitDatabase: .none`): todas las propiedades tienen valor por
defecto o son opcionales, y todas las relaciones tienen inversa. Activar la
sincronización en V1 no debería requerir una migración.

**Categorías como texto libre con sugerencias, no enums cerrados.** Registrar un
tratamiento que la app no conoce no debe requerir una migración de esquema.

**Los recordatorios viven en las entidades, no en una entidad aparte.** Una
medicación, una vacuna o un turno tienen su propio interruptor de recordatorio.
Una entidad `Reminder` separada agregaba una capa de indirección sin resolver un
problema que hoy exista.

**El calendario de Apple es un destino de exportación, no la fuente de verdad.**
`Appointment` guarda el identificador del evento exportado para poder
actualizarlo; los datos siguen viviendo en la app.

**Si el almacenamiento permanente falla, la app abre igual** con almacenamiento
temporal y lo dice con un mensaje claro, en vez de cerrarse.

**Tipografía atada a Dynamic Type.** Ningún tamaño fijo: todos los estilos
derivan de los estilos de texto del sistema, que es lo que permite que la
interfaz funcione en los tamaños de accesibilidad más grandes.

**La bienvenida se deduce de los datos.** No hay una marca de "ya completó el
onboarding": si no hay ningún compañero registrado, se muestra la bienvenida. Un
interruptor aparte sería una segunda fuente de verdad que puede contradecir a la
primera.

**Una sola pantalla de alta, no cinco pasos.** La especificación describe foto,
nombre, especie y cumpleaños como pasos separados. Son cuatro campos: un
formulario corto es menos pasos que cuatro pantallas encadenadas, y el principio
rector es registrar sin fricción.

**La descripción accesible de la foto es un campo del formulario**, no algo
generado automáticamente. Quien conoce a su compañero es quien puede escribir
"Luli, galga negra y blanca". Si no la completa, se usa una descripción armada
con el nombre.

**Las secciones del dashboard se arman fuera de la vista.** Qué aparece en "Hoy"
y qué en "Próximamente" es una regla de producto, así que vive en
`DashboardBuilder` y tiene pruebas propias, sin necesidad de dibujar nada.

**El estado depende de cuándo se lo mire.** `status(on:)` es una consulta con
fecha, no un dato fijo: una medicación que terminó ayer estaba activa anteayer.
Cuando el estado se calculaba contra el reloj, el dashboard dejaba de ser
consistente con la fecha que se le pedía; hay una prueba que cubre ese caso.

**Aviso de dosis repetida, no candado.** Si ya hay una toma registrada dentro de
la hora, la app pregunta antes de guardar otra y la persona decide. Impedirlo
sería peor: a veces la segunda toma existe de verdad.

**Intensidad en tres niveles, no en una escala de cinco.** Quien registra está
describiendo lo que ve, no midiendo. Tres opciones se eligen de un vistazo y
significan lo mismo para cualquiera.

**El peso se lee con coma o con punto.** Acá se escribe "24,3" y en otros lados
"24.3": los dos son válidos y ninguno debería devolver un error.

## Pendiente

- Decisión definitiva sobre compartir datos entre varias personas responsables
  (SwiftData con CloudKit vs. Core Data con `NSPersistentCloudKitContainer` y
  `CKShare`), a validar con una prueba de concepto en dispositivo antes de V1.
- Historial completo, documentos y modo emergencia.
- Recordatorios locales, exportación a PDF y adjuntos.
- Barra de pestañas: se incorpora cuando existan las pantallas que va a
  contener, no antes.

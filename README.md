# App de salud para animales de compañía

Aplicación iOS para que las personas responsables de perros y gatos organicen y
sigan la salud de sus compañeros y compañeras.

Este repositorio contiene, por ahora, los **cimientos**: modelo de datos,
dominio, sistema de diseño accesible y la infraestructura de lenguaje del
producto. Todavía no hay pantallas de producto más allá de una vista raíz
mínima que confirma que la persistencia funciona.

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

## Pendiente

- Decisión definitiva sobre compartir datos entre varias personas responsables
  (SwiftData con CloudKit vs. Core Data con `NSPersistentCloudKitContainer` y
  `CKShare`), a validar con una prueba de concepto en dispositivo antes de V1.
- Pantallas del MVP: dashboard, registro rápido, historial, perfil, documentos,
  modo emergencia.
- Recordatorios locales, exportación a PDF y adjuntos.

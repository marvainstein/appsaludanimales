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

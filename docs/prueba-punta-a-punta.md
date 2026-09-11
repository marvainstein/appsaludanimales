# Prueba de punta a punta

Para hacer en el teléfono, no en el simulador: lo que se está probando es si la
app se sostiene cuando alguien la usa de verdad.

Anotá lo que te llame la atención aunque no parezca un error. La última prueba de
este tipo encontró siete cosas, y la mitad no eran fallas sino frases que no se
entendían.

---

## Antes de empezar: sacá un respaldo

Si tenés información cargada en tu teléfono, **hacé un respaldo y guardalo fuera
del teléfono** antes de tocar nada. Perfil → Respaldo → Crear un respaldo →
compartirlo a donde sea.

Varios pasos de abajo borran datos a propósito. El respaldo es la vuelta atrás.

---

## 0. Que la app abra con lo que ya tenías

**El chequeo más importante de todos, y va primero.**

Desde ayer la app tiene una tabla nueva (las sesiones de tratamiento) y un campo
nuevo (la dosis de cada toma). Tu teléfono tiene datos guardados con la forma
vieja.

- [ ] Abrir la app **sin borrarla**, con los datos que ya tenías.
- [ ] ¿Abre? ¿Están todos los animales? ¿Están las medicaciones y los turnos?

Si la app no abre o aparece vacía, **pará acá y avisá**. Es un problema de
migración y no tiene sentido seguir probando lo demás.

---

## 1. El nombre y el ícono

- [ ] En la pantalla de inicio del teléfono, debajo del ícono, dice **Estela**.
- [ ] El ícono se distingue como una pata al lado de las otras apps.
- [ ] Perfil → La app → **Acerca de Estela**: está al final de todo, en su propia
      sección, y en ningún lado quedó la palabra "Huella".

## 2. Cargar un animal desde cero

- [ ] Cargar un animal nuevo con nombre, especie y cumpleaños.
- [ ] **El texto que escribís, ¿queda apoyado en el renglón o flotando?** Esto se
      cambió ayer y toca todos los campos de la app.
- [ ] Sin foto, ¿la silueta se ve bien?
- [ ] Cargar un segundo animal de la otra especie. ¿Aparece el selector arriba?

## 3. Medicación y tomas

- [ ] Cargar una medicación con dosis y horarios.
- [ ] En "Hoy" → **En curso**, ¿aparece con la casilla **Anotar toma**?
- [ ] Tocar la casilla. ¿Aparece la toma en **Actividad reciente**?
- [ ] Tocar la casilla otra vez enseguida. ¿Avisa que ya hay una toma cercana?
- [ ] **Tocar la fila** (no la casilla). ¿Abre la ficha con las dos últimas tomas?
- [ ] **Ver todas las tomas**: ¿están agrupadas por día, con la hora y la dosis?
- [ ] **Editar la medicación y cambiarle la dosis.** Anotar una toma nueva.
- [ ] Volver a "Ver todas las tomas": **las viejas tienen que seguir diciendo la
      dosis vieja.** Si dicen todas la nueva, es un error grave.

## 4. Tratamiento y sesiones

Todo esto es nuevo desde ayer.

- [ ] Cargar un tratamiento (por ejemplo, fisioterapia).
- [ ] En **En curso**, ¿la casilla dice **Anotar sesión** y no "Anotar toma"?
- [ ] Anotar una sesión. ¿Aparece en Actividad reciente?
- [ ] Tocar la fila: ¿la ficha muestra las últimas sesiones y "Ver todas"?

## 5. El historial

- [ ] Lo último que anotaste, ¿está **arriba de todo**?
- [ ] Si anotaste dos tomas el mismo día, ¿son **un solo renglón** que dice "2
      tomas" con las dos dosis si fueron distintas?
- [ ] En la ficha de una medicación: ¿dice **"Fecha de inicio"** y no "Fecha"?
- [ ] Buscar algo por texto y filtrar por categoría. ¿Funciona?

## 6. El resumen en PDF

- [ ] Generarlo con período **Todo**.
- [ ] **El membrete**, arriba a la derecha: "Informe generado por 🐾 Estela", el
      lema, y "Descargala gratis en el App Store". ¿Se pisa con algo?
- [ ] En **Medicaciones y tratamientos actuales**: ¿dice "ahora <dosis> · empezó
      el <fecha>"? No tiene que dar a entender que viene tomando eso desde
      entonces.
- [ ] En **Historial del período**: ¿hay un renglón por cada **cambio** de dosis
      con cuántas tomas hubo, en vez de uno por cada toma?
- [ ] Las sesiones, ¿aparecen contadas por mes?
- [ ] ¿El PDF se puede compartir?

## 7. El respaldo y la copia automática

- [ ] Perfil → **Respaldo**. ¿Arranca explicando que hay dos maneras?
- [ ] Tocar **Que se guarde solo**. Tiene que aparecer "Todavía no está
      disponible". **¿Se entiende qué pasa y qué podés hacer en cambio?**
- [ ] Crear un respaldo y compartirlo.
- [ ] **Restaurarlo encima**: no tiene que duplicar nada.
- [ ] Después de restaurar, ¿siguen estando las **tomas** y las **sesiones**?

## 8. Emergencia

- [ ] Cargar dos veterinarias, una marcada como de cabecera.
- [ ] Abrir el modo emergencia. ¿Aparecen las dos, la de cabecera primero?
- [ ] ¿Solo la marcada dice "de cabecera"?
- [ ] ¿Los botones para llamar funcionan?

## 9. Recordatorios

- [ ] Cargar una medicación con un horario dentro de los próximos minutos.
- [ ] ¿La app pide permiso **recién ahí** y no al abrirla?
- [ ] Esperar. ¿Llega el aviso, con la hora exacta?
- [ ] Perfil → Recordatorios → **Lo que está programado**: ¿coincide?

## 10. La despedida

Lo último, porque es lo más difícil de mirar.

- [ ] Marcar que un animal de prueba cruzó el arcoíris.
- [ ] ¿Aparece el cartel? ¿Se lee bien?
- [ ] **Mirá con atención el encabezado "Qué pasa"** en la pantalla anterior, en
      claro y en oscuro. La auditoría dice que ahí hay un problema de contraste
      que no pudimos explicar. ¿Se lee bien o se pierde?
- [ ] Deshacer la marca. ¿Vuelve todo a la normalidad?

## 11. Borrar y volver a empezar

Solo si ya sacaste el respaldo del paso de arriba.

- [ ] Desinstalar la app e instalarla de nuevo desde Xcode.
- [ ] ¿Aparece la bienvenida?
- [ ] **¿Pide algún permiso antes de dejarte usar la app?** No tiene que pedir
      ninguno.
- [ ] Restaurar el respaldo. ¿Vuelve todo?


---

# Resultado de la primera corrida — 12 de septiembre de 2026

Todo pasó, después de arreglar lo que la prueba encontró. Lo que salió:

**Errores de verdad**

- La fila de una medicación en el historial mostraba la dosis de ahora, así que
  al cambiarla parecía que siempre había sido esa. Ahora dice "empezó".
- Esa misma fila se veía igual que las de tomas, y parecía que se duplicaban.
  Pasaba también con los tratamientos.
- Los tratamientos no avisaban de una sesión repetida: tocando seis veces se
  anotaban seis.
- "Lo que está programado" listaba los avisos de todos los animales.
- El texto de los campos flotaba a media altura en vez de apoyarse en su
  renglón. Dos intentos de arreglarlo fallaron porque el espacio lo pone iOS en
  cada fila, no el padding.
- **No se podía restaurar sin crear antes un animal.** Quien cambiaba de
  teléfono terminaba con un compañero fantasma al lado de los suyos.

**Lo que parecía error y no lo era**

- El permiso de notificaciones no vuelve a pedirse: iOS lo pide una sola vez en
  la vida de la app.
- El ícono viejo en los avisos es caché del sistema, no código.

**Textos**

"Acerca de" reordenado y acortado, la despedida arranca con un mensaje en vez de
una explicación, y Respaldo quedó en el orden en que se decide.

**Lo que la prueba dejó dicho de fondo**

Que alguien mire la app con atención encuentra cosas que ningún test automático
ve: casi todo lo de arriba está en código que compilaba, pasaba las
verificaciones y hacía exactamente lo que decía hacer.

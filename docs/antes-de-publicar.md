# Lo que falta antes de pagar los 99 dólares

La cuenta de desarrollador de Apple no desbloquea nada de esto: son cosas que se
pueden construir hoy y que conviene tener listas para que la primera persona
ajena al proyecto que abra la app no se choque con un agujero.

El orden es por consecuencia: arriba lo que rompe una promesa, abajo lo que
mejora algo que ya funciona.

## Agujeros que rompen algo

- [x] **Crear turnos y tratamientos.** La app los muestra en el historial y los
      nombra en sus textos —"cuando anotes un turno o una próxima vacuna"— pero
      no hay ninguna pantalla para cargarlos. Es una promesa incumplida a la
      vista.
- [x] **Poder borrar un compañero.** Hoy, quien carga uno por error lo tiene
      para siempre. Con la confirmación clara que corresponde, porque borra toda
      su historia.
- [x] **El ícono de la app.** Una huella en acuarela, dibujada aparte. El
      encargo con los criterios está en docs/encargo-icono.md por si se quiere
      volver sobre él.

## Para que sirva con datos de verdad

- [x] **Buscar en el historial.** Con ocho años de estudios cargados, una lista
      ordenada por fecha no alcanza para encontrar "el análisis de sangre de
      cuando estuvo con la pata".
- [x] **Adjuntar un documento a un episodio o a un turno.** El modelo de datos ya
      lo permite y ninguna pantalla lo ofrece.

## Para que se entienda qué es esta app

- [x] **Pantalla "Acerca de".** Qué hace la app y qué no: que no diagnostica, que
      los datos no salen del teléfono, quién la hizo y por qué. Apple lo valora y
      además es lo honesto.
- [ ] **Ilustraciones propias en los estados vacíos.** Están los tres lugares
      hechos y con dibujos provisorios para poder mirarlos en el teléfono. El
      encargo de las definitivas está en docs/ilustraciones.md.

## Trámites que llevan tiempo y no dependen de nadie

- [~] **Política de privacidad publicada**, con su dirección web. Se puede alojar
      gratis en GitHub Pages.
- [x] **Textos de la App Store**: nombre, subtítulo, descripción, palabras clave,
      categoría.
- [~] **Capturas de pantalla**, que se sacan del simulador. El plan de cuáles y en qué orden está en docs/app-store.md; sacarlas es manual.
- [x] **Respuestas de privacidad de Apple** preparadas: qué datos recoge la app
      (ninguno), si hay rastreo (no), si usa cifrado (no propio).
- [x] **Buscar el nombre en el INPI.** Hecho, y cambió el nombre: la app se
      llamaba "Huella" y ahora se llama **Estela**. El detalle está en
      docs/buscar-el-nombre-en-el-inpi.md.
- [ ] **Poner la dirección real de la app en el membrete del PDF.** Hoy dice
      "Descargala gratis en el App Store". Con "Estela" el nombre ya alcanza para
      encontrarla, pero una dirección corta es lo que alguien puede tipear desde
      una hoja impresa. El día que exista la ficha, va ahí.

> Las marcadas con `~` están escritas pero necesitan una acción manual: publicar
> la página, o sacar las capturas.

## Verificaciones

- [x] **Auditoría de accesibilidad de las pantallas nuevas**: perfil, peso,
      respaldo, acerca de, despedida, emergencia y veterinarias.
- [ ] **Pasada manual en el teléfono** de esas mismas pantallas, según el
      protocolo de docs/accesibilidad.md.

# Cómo publicar la página de privacidad

Apple pide dos direcciones web para publicar una app: una de soporte y una de
política de privacidad. **La misma página sirve para las dos**, porque incluye
la política y una sección de soporte con el correo de contacto.

El archivo listo está en `sitio/index.html`. Es una sola página, sin nada más:
no necesita servidor, ni base de datos, ni dominio propio.

## Publicarla gratis con GitHub Pages

Se hace en un repositorio **nuevo y público**, aparte del de la app. Así se
publica solo la página y no el código ni estos documentos internos.

1. Entrá a **github.com** y tocá el **+** de arriba a la derecha → **New
   repository**.
2. En **Repository name** escribí `estela-privacidad`.
3. Marcá **Public**. Tiene que ser público: GitHub Pages en repositorios
   privados es un plan pago.
4. Tocá **Create repository**.
5. En la página que aparece, tocá **uploading an existing file**.
6. Arrastrá el archivo `index.html`. Abajo tocá **Commit changes**.
7. Andá a la pestaña **Settings** del repositorio, y en la lista de la izquierda
   a **Pages**.
8. En **Source** elegí **Deploy from a branch**. En **Branch** elegí `main` y la
   carpeta `/ (root)`. Tocá **Save**.
9. Esperá un par de minutos y recargá esa misma pantalla. Va a aparecer la
   dirección, con esta forma:

   ```
   https://TU-USUARIO.github.io/estela-privacidad/
   ```

10. Abrila para confirmar que se ve bien, en la computadora y en el teléfono.

Esa dirección es la que va en los dos campos de App Store Connect.

## Cuando haya que cambiar el texto

El texto vive en `docs/privacidad.md` y la página en `sitio/index.html`, los dos
en el repositorio de la app. Se cambian ahí, y después se vuelve a subir el
`index.html` al repositorio de la página.

**Hay un momento en que este texto se tiene que actualizar sí o sí:** el día que
la app sincronice entre dispositivos. Ahí deja de ser cierto que la información
no sale del teléfono, y la política tiene que decirlo antes de que el cambio
llegue a nadie.

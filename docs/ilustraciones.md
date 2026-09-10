> **Este encargo está en pausa desde septiembre de 2026.** Se decidió que los
> dibujos que tiene la app son los definitivos: la huella usa la misma geometría
> que el ícono, y las pantallas miradas en el teléfono no se ven vacías. Queda
> escrito por si alguna vez alguien dice que se sienten frías.

# Las ilustraciones

Hoy en la app hay tres dibujos hechos con formas geométricas, escritos en
código. **Son provisorios.** Están para que se vea dónde va una ilustración y de
qué tamaño, y para poder mirarlo en el teléfono en vez de imaginárselo.

Este documento es el encargo para las de verdad.

## Dónde va cada una, y qué tiene que decir

### 1. El primer día

**Dónde:** la pantalla Hoy, cuando no hay absolutamente nada cargado.
**Cuándo la ve alguien:** al abrir la app por primera vez, siempre. Es la
primera impresión completa del producto y la única que ve todo el mundo.
**Qué tiene que decir:** que este es un lugar tranquilo donde va a vivir algo
querido. No que falta llenar un formulario.
**Es la más importante de las tres.** Si solo se hace una, es esta.

### 2. El historial vacío

**Dónde:** el historial cuando no hay ningún registro.
**Qué tiene que decir:** que acá se va a ir juntando algo con el tiempo. La idea
es acumulación, archivo, memoria.
**No aparece** cuando la lista está vacía por un filtro puesto: ahí lo que hace
falta es sacar el filtro, no un dibujo.

### 3. El peso sin registros

**Dónde:** la pantalla de evolución del peso, antes del primer peso.
**Qué tiene que decir:** algo tranquilo. Es la más prescindible de las tres.

## Reglas

**Dónde nunca va una ilustración:** modo emergencia, registrar un síntoma, un
aviso de medicación, un error. Ahí alguien está asustado o apurado, y un dibujo
simpático se lee como que la app no entiende la gravedad. Es la regla del tono
que está en docs/posicionamiento.md: la gracia vive en la calma.

**Una por pantalla como máximo.** Cuatro dibujos apilados no son cuatro veces
mejor que uno.

**Los colores** salen de la paleta de la app: crema de fondo, terracota, y los
tonos suaves del acento. Están en `DesignSystem/Tokens/Palette.swift`.

**Nada de texto adentro del dibujo.** No se traduce, no crece con el tamaño de
texto del sistema, y no lo lee VoiceOver.

**Los dibujos son decorativos.** Todo lo que dicen tiene que estar también en el
texto de al lado, porque las tecnologías asistivas los ignoran a propósito.

## Cómo entregarlas

- **Formato:** PNG con fondo transparente, o PDF vectorial (mejor: se ve nítido
  en cualquier pantalla y pesa menos).
- **Tamaño:** cuadradas, 1024 × 1024 como mínimo si son PNG.
- **Dónde ponerlas:** en `Assets.xcassets`, y cambiar `EmptyStateIllustration`
  para que muestre la imagen en lugar de las formas dibujadas. Es un archivo y
  no toca nada más.

## Sobre las hechas con inteligencia artificial

Se pueden usar, Apple no las prohíbe. Dos cosas a mirar antes:

1. **Los términos de la herramienta** que las generó: algunas dan derechos
   comerciales y otras no.
2. **Una imagen generada así no se puede registrar como obra propia** en la
   mayoría de los países. Se puede usar, pero no se puede impedir que otro use
   la misma.

Para una app que se va a distribuir y que quiere tener identidad propia, conviene
que las dibuje una persona.

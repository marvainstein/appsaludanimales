#!/usr/bin/env python3
"""Genera el ícono de Huella.

El ícono es una huella de galgo: terracota sobre crema, los mismos colores de la
app. Las proporciones están sacadas de una foto de la pata de Luli, la galga por
la que existe esta app.

Se dibuja por código y no a mano para que sea reproducible —cambiar una
proporción es cambiar un número y volver a correr esto— y para que quede
registrado exactamente de dónde salió cada forma.

Uso:  python3 Scripts/make-app-icon.py
Deja: AppSaludAnimales/Resources/Assets.xcassets/AppIcon.appiconset/icono.png
"""

import math
import struct
import zlib
from pathlib import Path

SIZE = 1024

# Los mismos valores que PaletteValues, en modo claro.
CREAM = (0xF4, 0xF1, 0xE9)
TERRACOTTA = (0xA0, 0x47, 0x2C)


def ellipse(cx, cy, rx, ry, rotation_degrees=0.0):
    """Una elipse, como función que devuelve cuánto la cubre cada píxel.

    Devuelve la distancia aproximada al borde en píxeles: negativa adentro,
    positiva afuera. Con eso se puede suavizar el borde sin dibujar la imagen
    cuatro veces más grande y después achicarla.
    """
    angle = math.radians(rotation_degrees)
    cos_a, sin_a = math.cos(angle), math.sin(angle)
    scale = min(rx, ry)

    def distance(x, y):
        dx, dy = x - cx, y - cy
        local_x = dx * cos_a + dy * sin_a
        local_y = -dx * sin_a + dy * cos_a
        normalized = math.hypot(local_x / rx, local_y / ry)
        return (normalized - 1.0) * scale

    return distance


def smooth_union(distances, softness):
    """Une varias formas sin que se note dónde se tocan.

    Tomar la más cercana deja una muesca en cada unión, como tres óvalos
    pegados. Esto las funde en una sola forma orgánica, que es como se ve una
    almohadilla de verdad.
    """
    total = sum(math.exp(-distance / softness) for distance in distances)
    return -softness * math.log(total)


def toes():
    """Los cuatro dedos, con la forma de una galga.

    Un galgo tiene pie de liebre: los dos dedos del medio salen bastante más
    adelante que los de afuera, los cuatro son largos y angostos, y van
    apretados. Es lo contrario de la huella redonda y abierta que uno dibuja de
    memoria, y es lo que hace que esta huella sea de un galgo y no de cualquiera.
    """
    return [
        ellipse(316, 424, 62, 112, -20),
        ellipse(442, 292, 66, 128, -7),
        ellipse(586, 292, 66, 128, 7),
        ellipse(712, 424, 62, 112, 20),
    ]


def pad():
    """La almohadilla: angosta y algo triangular, como la de un galgo.

    Cuatro óvalos fundidos en uno: el cuerpo, los dos hombros de arriba y la
    base más ancha. Una almohadilla redonda debajo de estos dedos se vería
    prestada de otro perro.
    """
    parts = [
        ellipse(514, 672, 168, 132),
        ellipse(428, 610, 84, 76),
        ellipse(600, 610, 84, 76),
        ellipse(514, 728, 148, 96),
    ]

    def distance(x, y):
        return smooth_union([part(x, y) for part in parts], softness=24.0)

    return distance


def paw_shapes():
    return toes() + [pad()]


def render():
    shapes = paw_shapes()
    rows = []

    for y in range(SIZE):
        row = bytearray()
        py = y + 0.5

        for x in range(SIZE):
            px = x + 0.5

            # Unión de todas las formas: gana la que más cubre este píxel.
            coverage = 0.0
            for shape in shapes:
                distance = shape(px, py)
                if distance < -1.0:
                    coverage = 1.0
                    break
                if distance < 1.0:
                    coverage = max(coverage, min(1.0, max(0.0, 0.5 - distance / 2.0)))

            if coverage <= 0.0:
                row += bytes(CREAM)
            elif coverage >= 1.0:
                row += bytes(TERRACOTTA)
            else:
                row += bytes(
                    round(background + (foreground - background) * coverage)
                    for background, foreground in zip(CREAM, TERRACOTTA)
                )

        rows.append(bytes(row))

    return rows


def write_png(path, rows):
    raw = b"".join(b"\x00" + row for row in rows)

    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    header = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)

    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", header)
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


if __name__ == "__main__":
    destination = Path("AppSaludAnimales/Resources/Assets.xcassets/AppIcon.appiconset/icono.png")
    destination.parent.mkdir(parents=True, exist_ok=True)
    write_png(destination, render())
    print(f"Ícono escrito en {destination}")

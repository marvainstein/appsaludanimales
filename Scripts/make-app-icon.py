#!/usr/bin/env python3
"""Genera el ícono de Huella.

El ícono es una huella: terracota sobre crema, los mismos colores de la app.
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
    """Los cuatro dedos.

    Los de adentro van más arriba y más grandes que los de afuera, y los de las
    puntas giran hacia afuera. Una huella con los cuatro dedos iguales y
    alineados se lee como cuatro pastillas, no como una pata.
    """
    return [
        ellipse(248, 415, 82, 106, -22),
        ellipse(422, 296, 88, 116, -8),
        ellipse(604, 296, 88, 116, 8),
        ellipse(778, 415, 82, 106, 22),
    ]


def pad():
    """La almohadilla: tres óvalos fundidos en uno."""
    parts = [
        ellipse(513, 668, 214, 158),
        ellipse(394, 592, 104, 92),
        ellipse(632, 592, 104, 92),
    ]

    def distance(x, y):
        return smooth_union([part(x, y) for part in parts], softness=26.0)

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

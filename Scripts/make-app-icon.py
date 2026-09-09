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


def paw(center_x, center_y, scale, rotation_degrees=0.0):
    """Una pata de galga entera, ubicable y rotable.

    La forma está definida alrededor del origen para poder ponerla dos veces,
    en distinto tamaño y con distinto ángulo, sin repetir números.

    Un galgo tiene pie de liebre: los dos dedos del medio salen bastante más
    adelante que los de afuera, los cuatro son largos y angostos, y van
    apretados. Es lo contrario de la huella redonda y abierta que uno dibuja de
    memoria, y es lo que hace que estas sean patas de galga y no de cualquiera.
    """
    # x, y, radio en x, radio en y, giro propio. El origen es el centro de la
    # pata; los valores salen de la foto de la pata de Luli.
    toes = [
        (-198, -88, 62, 112, -20),
        (-72, -220, 66, 128, -7),
        (72, -220, 66, 128, 7),
        (198, -88, 62, 112, 20),
    ]

    pad_parts = [
        (0, 160, 168, 132, 0),
        (-86, 98, 84, 76, 0),
        (86, 98, 84, 76, 0),
        (0, 216, 148, 96, 0),
    ]

    angle = math.radians(rotation_degrees)
    cos_a, sin_a = math.cos(angle), math.sin(angle)

    def place(local_x, local_y, rx, ry, own_rotation):
        rotated_x = local_x * cos_a - local_y * sin_a
        rotated_y = local_x * sin_a + local_y * cos_a

        return ellipse(
            center_x + rotated_x * scale,
            center_y + rotated_y * scale,
            rx * scale,
            ry * scale,
            own_rotation + rotation_degrees,
        )

    toe_shapes = [place(*values) for values in toes]
    pad_shapes = [place(*values) for values in pad_parts]

    def distance(x, y):
        pad = smooth_union([shape(x, y) for shape in pad_shapes], softness=24.0 * scale)
        return min([pad] + [shape(x, y) for shape in toe_shapes])

    return distance


def paws():
    """Las dos: la de adelante más grande, la de atrás asomando.

    Van separadas por un hilo de crema en vez de por otro color. Dos tonos
    parecidos se mezclan en una mancha cuando el ícono se ve chico; un contorno
    vacío entre las dos sobrevive a cualquier tamaño.
    """
    front = paw(center_x=628, center_y=596, scale=0.78, rotation_degrees=7)
    back = paw(center_x=326, center_y=398, scale=0.55, rotation_degrees=-20)

    return front, back


def single_paw():
    """Una sola pata, centrada. La versión sobria."""
    return paw(center_x=512, center_y=500, scale=0.98)

def render(single=False):
    if single:
        front, back = single_paw(), None
    else:
        front, back = paws()

    separation = 20.0
    rows = []

    for y in range(SIZE):
        row = bytearray()
        py = y + 0.5

        for x in range(SIZE):
            px = x + 0.5

            front_distance = front(px, py)

            if back is None or front_distance < separation:
                # El hilo de crema que separa una pata de la otra.
                coverage = 1.0 if front_distance < -1.0 else max(0.0, min(1.0, 0.5 - front_distance / 2.0))
            else:
                back_distance = back(px, py)
                coverage = 1.0 if back_distance < -1.0 else max(0.0, min(1.0, 0.5 - back_distance / 2.0))

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
    import sys

    single = "--una" in sys.argv
    destination = Path(
        sys.argv[sys.argv.index("--salida") + 1]
        if "--salida" in sys.argv
        else "AppSaludAnimales/Resources/Assets.xcassets/AppIcon.appiconset/icono.png"
    )

    destination.parent.mkdir(parents=True, exist_ok=True)
    write_png(destination, render(single=single))
    print(f"Ícono escrito en {destination}")

#!/usr/bin/env bash
#
# Verifica reglas de accesibilidad que se pueden comprobar leyendo el código.
# Lo que necesita un dispositivo y una persona está en docs/accesibilidad.md.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCES="$ROOT/AppSaludAnimales"
status=0

# 1. Tamaños de fuente fijos: rompen Dynamic Type. Se permite un tamaño
#    calculado a partir de @ScaledMetric, que sí acompaña al ajuste del sistema.
fixed_fonts="$(grep -rnE '\.font\(\.system\(size: *[0-9]' --include='*.swift' "$SOURCES" || true)"

if [[ -n "$fixed_fonts" ]]; then
	echo "Tamaños de fuente fijos: no acompañan el ajuste de tamaño de texto del sistema." >&2
	echo "$fixed_fonts" >&2
	status=1
fi

# 2. Todo estado del producto tiene que tener texto e ícono, no solo color.
#    El protocolo StatusPresentable lo obliga; esto detecta si alguien lo saltea.
tones="$(grep -rn 'StatusTone\.' --include='*.swift' "$SOURCES" \
	| grep -v 'DesignSystem/Tokens/Palette.swift' \
	| grep -v 'Domain/Model/Status.swift' \
	| grep -v 'softBackground\|\.content' || true)"

if [[ -n "$tones" ]]; then
	echo "Uso de un tono de estado fuera del componente que lo acompaña con texto e ícono:" >&2
	echo "$tones" >&2
	status=1
fi

# 3. Encabezados y pies de sección con el color por omisión del sistema.
#    El gris que iOS usa ahí queda en unos 4,4:1, apenas por debajo del 4,5:1
#    que pide la norma para texto de tamaño normal, y la auditoría lo marca como
#    "contrast nearly passed". Nuestro inkMuted da 7,0:1 sobre fondo claro y
#    5,6:1 sobre el apagado, verificado en PaletteContrastTests.
#
#    Son 95 lugares: la regla existe para que el 96 no se olvide.
missing_color="$(python3 - "$SOURCES" <<'PYEOF'
import pathlib, sys

faltantes = []
for archivo in sorted(pathlib.Path(sys.argv[1]).rglob("*.swift")):
    lineas = archivo.read_text().splitlines()
    for i, linea in enumerate(lineas):
        if not linea.rstrip().endswith(("} header: {", "} footer: {")):
            continue
        # el bloque llega hasta la llave que lo cierra, a la misma sangría
        sangria = len(linea) - len(linea.lstrip())
        bloque = []
        for j in range(i + 1, len(lineas)):
            actual = lineas[j]
            if actual.lstrip().startswith("}") and len(actual) - len(actual.lstrip()) == sangria:
                break
            bloque.append(actual)
        texto = "\n".join(bloque)
        if "Text(" in texto and "foregroundStyle" not in texto:
            faltantes.append(f"{archivo}:{i + 1}: sin color propio")

print("\n".join(faltantes))
PYEOF
)"

if [[ -n "$missing_color" ]]; then
	echo "Encabezados o pies de sección con el gris por omisión del sistema, que queda" >&2
	echo "por debajo de 4,5:1. Agregales .foregroundStyle(Palette.inkMuted)." >&2
	echo "$missing_color" >&2
	status=1
fi

if [[ $status -eq 0 ]]; then
	echo "Accesibilidad: las reglas verificables por código se cumplen."
fi

exit $status

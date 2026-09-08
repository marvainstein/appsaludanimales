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

if [[ $status -eq 0 ]]; then
	echo "Accesibilidad: las reglas verificables por código se cumplen."
fi

exit $status

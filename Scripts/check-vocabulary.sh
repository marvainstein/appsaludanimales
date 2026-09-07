#!/usr/bin/env bash
#
# Verifica el vocabulario del producto: en esta app los perros y gatos son
# compañeros y compañeras, nunca "mascotas".
#
# Se ejecuta a mano antes de un commit o desde integración continua.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORBIDDEN='\bmascotas?\b|\bpets?\b'
TARGETS=("$ROOT/AppSaludAnimales" "$ROOT/AppSaludAnimalesTests")

matches="$(grep -rniE --include='*.swift' --include='*.xcstrings' "$FORBIDDEN" "${TARGETS[@]}" || true)"

if [[ -n "$matches" ]]; then
	echo "Vocabulario del producto: se encontraron términos que no se usan en esta app." >&2
	echo "Usá \"compañero\", \"compañera\" o \"animal de compañía\" en su lugar." >&2
	echo >&2
	echo "$matches" >&2
	exit 1
fi

echo "Vocabulario correcto: no se encontraron términos fuera del lenguaje del producto."

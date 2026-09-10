#!/usr/bin/env bash
#
# Verifica que la app no pida permisos antes de que la persona haya visto para
# qué sirve.
#
# La regla, dicha por quien la usa: "no quiero tarjetas y tarjetas antes de
# poder usar la app. Yo solo quiero probarla, ver si me gusta, y después hacer
# todo eso."
#
# Un permiso se pide cuando la persona acaba de hacer algo que lo necesita
# —guardar una medicación con horario, activar los avisos— y nunca al abrir la
# app, en la bienvenida ni en el tablero.
#
# Existe porque la regla ya se rompió una vez sin que nadie lo notara hasta
# probarlo en un teléfono de verdad.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/AppSaludAnimales"

# Pedidos de permiso del sistema, en cualquiera de sus formas.
REQUESTS='requestAuthorization|requestWhenInUseAuthorization|requestAlwaysAuthorization|PHPhotoLibrary\.requestAuthorization|AVCaptureDevice\.requestAccess'

# Los únicos lugares donde puede aparecer un pedido: el servicio que los
# administra, y la pantalla de recordatorios, donde la persona fue a buscarlo.
ALLOWED='Services/ReminderScheduler\.swift|Features/Reminders/'

# Pantallas por las que se pasa sin haber pedido nada: son las que ve alguien
# que abrió la app por primera vez.
ENTRY='Features/Onboarding/|Features/Dashboard/|AppSaludAnimalesApp\.swift|Data/Persistence/'

fail=0

offenders="$(grep -rnE --include='*.swift' "$REQUESTS" "$APP" | grep -vE "$ALLOWED" || true)"
if [[ -n "$offenders" ]]; then
	echo "Permisos: hay un pedido de permiso fuera de los lugares previstos." >&2
	echo "Un permiso se pide donde la persona acaba de hacer algo que lo necesita." >&2
	echo >&2
	echo "$offenders" >&2
	fail=1
fi

entry_offenders="$(grep -rnE --include='*.swift' "$REQUESTS" "$APP" | grep -E "$ENTRY" || true)"
if [[ -n "$entry_offenders" ]]; then
	echo "Permisos: hay un pedido de permiso en una pantalla de entrada." >&2
	echo "Nadie tiene que dar permisos antes de ver para qué sirve la app." >&2
	echo >&2
	echo "$entry_offenders" >&2
	fail=1
fi

# El sincronizador de recordatorios corre al abrir la app: si pidiera permiso
# ahí, el cartel saltaría en el arranque. Solo puede pedirlo cuando alguien
# acaba de guardar algo, y eso se controla con `askingIfNeeded`.
sync_default="$(grep -n 'askingIfNeeded: Bool = true' "$APP/Services/ReminderScheduler.swift" || true)"
if [[ -n "$sync_default" ]]; then
	echo "Permisos: sync() pide permiso por omisión, así que lo pediría al abrir la app." >&2
	echo "El valor por omisión de askingIfNeeded tiene que ser false." >&2
	fail=1
fi

if (( fail )); then
	exit 1
fi

echo "Permisos: nada se pide antes de que la persona haya visto para qué sirve la app."

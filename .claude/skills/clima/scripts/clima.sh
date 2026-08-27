#!/usr/bin/env bash
# Consulta el clima actual (y opcionalmente el pronóstico) desde wttr.in.
# Uso: clima.sh [ciudad] [--forecast]
#   ciudad     por defecto "Paraiso,Cartago,Costa Rica"
#   --forecast agrega el pronóstico de hoy y mañana (min/max, lluvia)
set -euo pipefail

CITY="Paraiso,Cartago,Costa Rica"
FORECAST=0
for arg in "$@"; do
  case "$arg" in
    --forecast|-f) FORECAST=1 ;;
    *) CITY="$arg" ;;
  esac
done

URL="https://wttr.in/$(printf '%s' "$CITY" | sed 's/ /+/g')?format=j1"

JSON="$(curl -sS --max-time 15 "$URL")" || {
  echo "error: no se pudo contactar wttr.in" >&2
  exit 1
}

FORECAST="$FORECAST" python3 - "$JSON" <<'PY'
import json, os, sys

try:
    data = json.loads(sys.argv[1])
except json.JSONDecodeError:
    print("error: respuesta invalida de wttr.in (rate limit?)", file=sys.stderr)
    sys.exit(1)

c = data["current_condition"][0]
area = data["nearest_area"][0]
place = f"{area['areaName'][0]['value']}, {area['region'][0]['value']}, {area['country'][0]['value']}"

print(f"{place}  (obs. {c['observation_time']} UTC)")
print(
    f"{c['temp_C']}C (sensacion {c['FeelsLikeC']}C) | {c['weatherDesc'][0]['value'].strip()} | "
    f"hum {c['humidity']}% | viento {c['winddir16Point']} {c['windspeedKmph']} km/h | "
    f"nubes {c['cloudcover']}% | UV {c['uvIndex']} | precip {c['precipMM']} mm"
)

if os.environ.get("FORECAST") == "1":
    print()
    for d in data["weather"][:2]:
        rain = max(int(h["chanceofrain"]) for h in d["hourly"])
        print(
            f"{d['date']}: min {d['mintempC']}C / max {d['maxtempC']}C | "
            f"lluvia max {rain}% | sol {d['astronomy'][0]['sunrise']}-{d['astronomy'][0]['sunset']}"
        )
PY

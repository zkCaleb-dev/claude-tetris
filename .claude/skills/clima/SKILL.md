---
name: clima
description: Consulta la temperatura y el estado del clima actual (y el pronóstico de hoy/mañana) para Paraíso de Cartago, Costa Rica, u otra ciudad indicada. Úsala cuando el usuario pregunte por el clima, la temperatura, si va a llover, o pida un reporte del tiempo.
---

# Clima

Reporta el clima actual usando `wttr.in` — sin API key, sin dependencias.

Ciudad por defecto: **Paraíso, Cartago, Costa Rica**.

## Uso

```bash
bash .claude/skills/clima/scripts/clima.sh                      # ciudad por defecto
bash .claude/skills/clima/scripts/clima.sh --forecast           # + pronóstico hoy/mañana
bash .claude/skills/clima/scripts/clima.sh "San Jose,Costa Rica"
bash .claude/skills/clima/scripts/clima.sh "Madrid,Spain" --forecast
```

Ejecuta el script y reporta su salida. No inventes datos si el comando falla.

## Cómo reportar

Una línea, en español, concisa:

> **26 °C** (sens. 27 °C) · Lluvia dispersa cerca · Hum. 57% · Viento NNE 5 km/h

Con `--forecast`, agrega una línea por día (min/max y probabilidad de lluvia).

## Notas

- `observation_time` viene en **UTC**; Costa Rica es UTC−6. Si la hora importa, convierte.
- wttr.in actualiza cada ~15–30 min: consultas seguidas suelen dar el mismo valor. Si el
  usuario pide chequeos frecuentes, adviértele en vez de repetir el mismo dato en silencio.
- Ante rate limit, wttr.in devuelve HTML en lugar de JSON — el script sale con error;
  espera un momento y reintenta, no adivines el clima.
- Sin `--forecast` solo se consultan las condiciones actuales.

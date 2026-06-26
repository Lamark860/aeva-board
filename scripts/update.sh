#!/usr/bin/env bash
# Обновление кода aeva-board (Vikunja) на VPS.
#
# В отличие от Kanboard, у Vikunja нет bind-смонтированных плагинов/темы —
# конфиг идёт через env, код приезжает только образом. Поэтому грабли с chown
# (которые были у Kanboard из-за ./plugins) больше НЕТ — простой git pull.
#
# Запускать на VPS из корня проекта: bash scripts/update.sh
set -euo pipefail
cd "$(dirname "$0")/.."

echo "▶ git pull…"
git pull

echo "✅ Код обновлён. Применить (подтянуть образ/конфиг и пересоздать контейнер):"
echo "   bash scripts/deploy-traefik.sh"

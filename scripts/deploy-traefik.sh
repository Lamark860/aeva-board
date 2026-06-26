#!/usr/bin/env bash
# Деплой aeva-board (Vikunja) за общим Traefik на ${DOMAIN}.
# Запускать на VPS из корня проекта: bash scripts/deploy-traefik.sh
# Идемпотентен для редеплоя того же приложения.
# ВНИМАНИЕ: при СМЕНЕ приложения (миграция Kanboard → Vikunja) перед первым
# запуском сделай `docker compose down` — иначе конфликт имени контейнера aeva-board.
set -euo pipefail
cd "$(dirname "$0")/.."

# --- .env / обязательные переменные ---
if [ ! -f .env ]; then
  echo "✗ Нет .env. Скопируй .env.example → .env и задай DB_PASSWORD + VIKUNJA_SECRET."; exit 1
fi
DOMAIN=$(grep -E '^DOMAIN=' .env | cut -d= -f2- | tr -d '[:space:]')
if [ -z "${DOMAIN:-}" ]; then echo "✗ DOMAIN не задан в .env"; exit 1; fi
if ! grep -qE '^VIKUNJA_SECRET=.+' .env; then
  echo "✗ VIKUNJA_SECRET пуст. Сгенерируй: openssl rand -hex 32 → впиши в .env"; exit 1
fi
echo "▶ Деплой aeva-board (Vikunja) на https://${DOMAIN}"

# --- внешняя сеть proxy (общий Traefik) должна существовать ---
if ! docker network inspect proxy >/dev/null 2>&1; then
  echo "✗ Внешняя сеть 'proxy' не найдена — сначала подними общий Traefik."; exit 1
fi

# --- свежие образы + старт (db → vikunja-init chown → vikunja, по depends_on) ---
docker compose pull
docker compose up -d

# --- smoke: ждём ответ Vikunja API по HTTPS (Traefik может выпускать LE cert) ---
ok=0
for i in $(seq 1 30); do
  if curl -fsS --max-time 10 "https://${DOMAIN}/api/v1/info" >/dev/null 2>&1; then
    echo "  ✓ https://${DOMAIN} отвечает"; ok=1; break
  fi
  sleep 3
done
if [ "$ok" != 1 ]; then
  echo "  ⚠ ${DOMAIN} ещё не отвечает. Проверь:"
  echo "     · DNS A-запись ${DOMAIN} → IP сервера (отрезолвилась?)"
  echo "     · логи Traefik (выпуск сертификата)"
  echo "     · docker compose logs vikunja"
fi

# --- уборка ---
docker image prune -f >/dev/null 2>&1 || true
echo "✅ Готово. https://${DOMAIN}"
echo "   Юзеров заводи: docker compose exec vikunja /app/vikunja/vikunja user create -u <имя> -e <email> -p <пароль≥8>"

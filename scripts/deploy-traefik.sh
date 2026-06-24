#!/usr/bin/env bash
# Деплой aeva-board (Kanboard) за общим Traefik на ${DOMAIN}.
# Запускать на VPS из корня проекта: bash scripts/deploy-traefik.sh
# Идемпотентен: повторный запуск просто обновляет образ и пересоздаёт контейнер.
set -euo pipefail
cd "$(dirname "$0")/.."

# --- .env / DOMAIN ---
if [ ! -f .env ]; then
  echo "✗ Нет .env. Скопируй .env.example → .env и задай DB_PASSWORD."; exit 1
fi
DOMAIN=$(grep -E '^DOMAIN=' .env | cut -d= -f2- | tr -d '[:space:]')
if [ -z "${DOMAIN:-}" ]; then
  echo "✗ DOMAIN не задан в .env"; exit 1
fi
echo "▶ Деплой aeva-board на https://${DOMAIN}"

# --- внешняя сеть proxy (общий Traefik) должна существовать ---
if ! docker network inspect proxy >/dev/null 2>&1; then
  echo "✗ Внешняя сеть 'proxy' не найдена — сначала подними общий Traefik."; exit 1
fi

# --- свежий образ + старт ---
docker compose pull
docker compose up -d db
docker compose up -d kanboard

# --- smoke: ждём ответ по HTTPS (Traefik может выпускать Let's Encrypt cert) ---
ok=0
for i in $(seq 1 30); do
  if curl -fsS --max-time 10 "https://${DOMAIN}/" >/dev/null 2>&1; then
    echo "  ✓ https://${DOMAIN} отвечает"; ok=1; break
  fi
  sleep 3
done
if [ "$ok" != 1 ]; then
  echo "  ⚠ ${DOMAIN} ещё не отвечает. Проверь:"
  echo "     · DNS A-запись ${DOMAIN} → IP сервера (отрезолвилась?)"
  echo "     · логи Traefik (выпуск сертификата)"
  echo "     · docker compose logs kanboard"
fi

# --- уборка ---
docker image prune -f >/dev/null 2>&1 || true
echo "✅ Готово. https://${DOMAIN}"
echo "   Первый вход: admin / admin — СРАЗУ смени пароль и выключи публичную регистрацию."

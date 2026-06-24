#!/usr/bin/env bash
# Обновление кода/темы aeva-board на VPS (git pull с учётом граблей прав).
#
# Грабля: контейнер Kanboard на старте делает chown папки /var/www/app/plugins
# на свой uid (100). Папка bind-смонтирована из репо, поэтому файлы становятся
# не-maxim'овыми, и `git pull` падает на перезаписи (Permission denied).
# Решение: одноразовым root-контейнером возвращаем владение текущему юзеру,
# затем тянем. Тема/код (plugins bind-mount) подхватываются сразу, без рестарта.
#
# Запускать на VPS из корня проекта: bash scripts/update.sh
set -euo pipefail
cd "$(dirname "$0")/.."

echo "▶ Возвращаю владение plugins текущему юзеру ($(id -un))…"
docker run --rm -v "$(pwd)/plugins:/p" alpine sh -c "chown -R $(id -u):$(id -g) /p"

echo "▶ git pull…"
git pull

echo "✅ Готово. Изменения темы/кода уже на диске (bind-mount) — обнови страницу"
echo "   в браузере с очисткой кэша (Ctrl+Shift+R), если правился CSS."

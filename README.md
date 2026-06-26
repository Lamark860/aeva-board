# aeva-board

Доска цеха Aeva на **[Vikunja](https://vikunja.io/)** — производственный поток изделий
(Заказы → формовка → сушка → утильный обжиг → глазуровка → политой обжиг → ОТК → готово) и обычные
задачи команды. Отдельный self-hosted проект на **https://board.aevashop.ru**, за тем же общим
Traefik, что и остальные проекты на VPS. Поддомен `aevashop.ru`, нового домена не требует.

Почему Vikunja: современный вид из коробки, лёгкая (Go + Vue, бинарь + PostgreSQL), AGPLv3,
вью kanban/list/gantt/table, есть русский. Данные в Postgres → удобно тянуть в Grafana. Мигрировано
с Kanboard; сравнение трекеров — `_local_docs/internal/research/task-trackers.md`.

## Что внутри
- `docker-compose.yml` — `vikunja` (порт 3456, за Traefik) + `db` (PostgreSQL 16) +
  `vikunja-init` (one-shot: чинит права тома вложений, чтобы приложение бежало не от root).
- `scripts/deploy-traefik.sh` — деплой (pull → up → smoke-проверка HTTPS).
- `scripts/update.sh` — обновление кода на VPS (`git pull`).
- `.env.example` — шаблон конфигурации.

Плагинов нет (у Vikunja нет плагин-системы) — расширяемость через REST API / вебхуки / CalDAV.
Обложки-картинки на карточках — встроенные (у задачи: Attachments → «Set as cover image»).

## Требования
- На VPS уже поднят **общий Traefik** с внешней сетью `proxy` и certresolver `letsencrypt`.
- Docker + Docker Compose.

## Запуск (первый раз)

**1. DNS:** A-запись `board.aevashop.ru` → IP сервера. Дождись резолва — cert Traefik выпустит сам.

**2. На сервере:**
```bash
cd /opt/projects
git clone <repo> aeva-board
cd aeva-board
cp .env.example .env
# задай DB_PASSWORD (openssl rand -base64 32) и VIKUNJA_SECRET (openssl rand -hex 32)
nano .env
bash scripts/deploy-traefik.sh
```

**3. Первый вход (доступ публичный):**
- Регистрация на проде закрыта. Заведи владельца через CLI:
  ```bash
  docker compose exec vikunja /app/vikunja/vikunja user create -u admin -e you@example.com -p '<пароль≥8>'
  ```
- Войди на https://board.aevashop.ru, поставь нормальный пароль и **включи 2FA** (Settings → 2FA).
- Язык: Settings → General → Language → Русский. Логины сотрудникам — тем же `user create`.

## Как разложить производство
- Проект **«Производство»** → kanban-вью → колонки (buckets) = стадии
  (Заказы/формовка/сушка/утиль/глазуровка/политой/ОТК/готово).
- Карточка = изделие или партия. Метки = глазурь/печь/срочность. Лимит на bucket = WIP.
- Отдельный проект **«Задачи мастерской»** — поручения команде.

## Обслуживание
- **Обновление**: `bash scripts/update.sh` → `bash scripts/deploy-traefik.sh` (на проде запинь
  `VIKUNJA_IMAGE` в `.env`).
- **Бэкап БД**: `docker compose exec db pg_dump -U vikunja vikunja | gzip > backup.sql.gz` (в cron).
- **Логи**: `docker compose logs -f vikunja`.
- **Footprint**: Vikunja + Postgres ≈ пара сотен МБ RAM.

## Grafana (следующий шаг)
Vikunja на PostgreSQL → read-only пользователь в БД `vikunja` + PostgreSQL datasource в Grafana
(доступ в сеть `internal`).

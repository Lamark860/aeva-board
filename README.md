# aeva-board

Доска цеха Aeva на **[Kanboard](https://kanboard.org/)** — производственный поток изделий
(формовка → сушка → утильный обжиг → глазуровка → политой обжиг → ОТК → готово) и обычные
задачи команды. Отдельный self-hosted проект на **https://board.aevashop.ru**, за тем же общим
Traefik, что и остальные проекты на VPS. Нового домена не требует — это поддомен `aevashop.ru`.

Почему Kanboard: чистая MIT-лицензия, лёгкий, kanban из коробки (колонки = стадии, swimlanes =
печи/партии), на PostgreSQL → данные потом удобно тянуть в Grafana, есть русский интерфейс.
Сравнение с альтернативами — в вики ceramic: `_local_docs/internal/research/task-trackers.md`.

## Что внутри
- `docker-compose.yml` — `kanboard` (порт 80, за Traefik) + `db` (PostgreSQL 16).
- `plugins/CeramicTheme/` — брендовая тема (Playfair + терракота, палитра витрины aevashop.ru),
  монтируется в контейнер; правится в git, не из web-UI.
- `scripts/deploy-traefik.sh` — деплой (pull → up → smoke-проверка HTTPS).
- `.env.example` — шаблон конфигурации.

## Требования
- На VPS уже поднят **общий Traefik** с внешней сетью `proxy` и certresolver `letsencrypt`
  (тот же, что обслуживает aevashop.ru). Конвенции — как в проекте ceramic.
- Docker + Docker Compose.

## Запуск (первый раз)

**1. DNS** (reg.ru, где делегирован `aevashop.ru`): добавь A-запись
`board.aevashop.ru` → IP сервера (`5.187.2.81`). Дождись резолва. Cert Traefik выпустит сам.

**2. На сервере:**
```bash
cd /opt/projects
git clone <repo> aeva-board     # или scp каталог проекта
cd aeva-board
cp .env.example .env
# задай DB_PASSWORD:  openssl rand -base64 32
nano .env
bash scripts/deploy-traefik.sh
```

**3. Первый вход — ОБЯЗАТЕЛЬНО (доступ публичный):**
- Открой https://board.aevashop.ru, войди `admin` / `admin`.
- **Сразу смени пароль** (Profile → Password).
- Settings → выключи публичную регистрацию; включи 2FA для админа.
- Заведи аккаунты сотрудникам (My profile → Users management), раздай доступ по проектам.

## Как разложить производство
- Проект **«Производство»** → колонки = стадии (формовка/сушка/утиль/глазуровка/политой/ОТК/готово).
- Карточка = изделие или партия. **Swimlanes** = печи (Печь №1/№2) или заказы.
- Цвета/категории = тип изделия. **Custom Fields** (плагин) = глина / глазурь / температура / № обжига.
- Отдельный проект **«Задачи мастерской»** (To do / В работе / Готово) — поручения команде.

## Тема
Плагин `CeramicTheme` подхватывается автоматически. Палитра и шрифт — в
`plugins/CeramicTheme/Assets/css/skin.css` (терракота `#B7795A`, крем `#F6F3EF`, Playfair).
Точные селекторы доводятся против живого UI — это рабочий старт, не финальный пиксель-перфект.

## Grafana (следующий шаг, не входит в базовый деплой)
Kanboard на PostgreSQL → подключается напрямую:
1. Заведи в БД `kanboard` read-only пользователя.
2. В Grafana добавь **PostgreSQL datasource** на него (дай Grafana доступ в сеть `internal`).
3. Метрики из таблиц `tasks` / `columns` / `transitions` (логи переходов карточек по колонкам
   с таймстемпами → время цикла по стадии). Примеры: «сколько в обжиге сейчас», «завал на ОТК».

## Обслуживание
- **Обновление**: запиновать `KANBOARD_IMAGE` в `.env`, затем `bash scripts/deploy-traefik.sh`.
- **Бэкап БД**: `docker compose exec db pg_dump -U kanboard kanboard | gzip > backup.sql.gz` (в cron).
- **Логи**: `docker compose logs -f kanboard`.
- **Footprint**: Kanboard + Postgres ≈ пара сотен МБ RAM.

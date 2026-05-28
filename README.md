# DevOps Lab 3 — CI/CD Pipeline

Node.js Task Tracker застосунок з повним CI/CD pipeline на базі GitHub Actions.

## Технічний стек

- **Застосунок**: Node.js + Express.js + PostgreSQL
- **Контейнеризація**: Docker + docker-compose
- **Проксі**: Nginx
- **CI/CD**: GitHub Actions
- **Лінтери**: ESLint, Hadolint, ShellCheck, YAMLlint
- **Тести**: Jest + Supertest

## Архітектура

```
GitHub (push / PR / tag)
       │
       ▼
GitHub Actions CI
  ├── lint  — ESLint, Hadolint, ShellCheck, YAMLlint
  ├── test  — Jest (coverage ≥ 40%), artifact: coverage report
  └── build — Docker image → ghcr.io/sonya010/devops_lab3

       │ (тільки на анотовані теги)
       ▼
GitHub Actions CD
  └── self-hosted runner VM
        └── SSH → target VM
              └── docker compose up
                    ├── webapp (Node.js)
                    ├── db (PostgreSQL)
                    └── nginx (reverse proxy)
```

## Структура репозиторію

```
.
├── .github/workflows/
│   ├── ci.yml              # CI: lint + test + build
│   └── cd.yml              # CD: deploy on annotated tags
├── deploy/
│   ├── nginx.conf          # Nginx reverse proxy config
│   ├── mywebapp-docker.service  # systemd unit для Docker
│   ├── setup_target.sh     # підготовка target VM
│   ├── setup_runner.sh     # підготовка runner VM (без токену)
│   └── verify.sh           # верифікація після розгортання
├── tests/
│   ├── app.test.js         # тести CRUD ендпоінтів
│   └── health.test.js      # тести health check ендпоінтів
├── app.js                  # Express застосунок
├── routes.js               # маршрути
├── db.js                   # підключення до PostgreSQL
├── migrate.js              # міграція БД
├── Dockerfile              # production Docker образ
├── docker-compose.yml      # оркестрація контейнерів
└── config.json.example     # приклад конфігурації (без секретів)
```

## API Ендпоінти

| Метод | Шлях | Опис |
|-------|------|------|
| GET | `/` | Головна сторінка |
| GET | `/tasks` | Список всіх задач |
| POST | `/tasks` | Створити задачу `{ "title": "..." }` |
| POST | `/tasks/:id/done` | Позначити задачу як виконану |
| GET | `/health/alive` | Liveness перевірка |
| GET | `/health/ready` | Readiness перевірка (БД) |

## Теги Docker образів

| Тригер | Теги |
|--------|------|
| Push до `main` | `latest`, `sha-<full-commit-hash>` |
| Анотований тег | `stable`, `<tag>` |

## GitHub Secrets

| Назва | Опис |
|-------|------|
| `TARGET_SSH_KEY` | SSH приватний ключ (runner → target VM) |
| `TARGET_HOST` | IP адреса target VM |
| `TARGET_USER` | Користувач на target VM |
| `DB_PASSWORD` | Пароль PostgreSQL |

## Налаштування VM

### Runner VM

```bash
# Від root на runner VM:
curl -fsSL https://raw.githubusercontent.com/Sonya010/DevOps_Lab3/main/deploy/setup_runner.sh | sudo bash
# Потім вручну реєстрація: ./config.sh --url ... --token <TOKEN>
```

### Target VM

```bash
# Від root на target VM:
curl -fsSL https://raw.githubusercontent.com/Sonya010/DevOps_Lab3/main/deploy/setup_target.sh | sudo bash
```

## Локальна розробка

```bash
cp config.json.example config.json
npm install
npm test
```

## Запуск через Docker

```bash
DB_PASSWORD=yourpassword docker compose up -d
```

## Тестування

```bash
npm test
```

Запускає 13 тестів з перевіркою coverage ≥ 40%. Звіт зберігається в `coverage/`.

## CI/CD тригери

| Подія | lint | test | build | deploy |
|-------|------|------|-------|--------|
| Push до `main` | ✅ | ✅ | ✅ | ❌ |
| Pull Request до `main` | ✅ | ✅ | ❌ | ❌ |
| Анотований тег `v*.*.*` | ✅ | ✅ | ✅ | ✅ |

## Запуск деплою

Деплой запускається тільки через анотований тег:

```bash
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0
```

Порядок виконання: CI (lint → test → build + push image) → CD (deploy → verify).

## Branch Protection Rules

У репозиторії налаштований захист гілки `main`:
- Злиття тільки через PR
- Обов'язкові перевірки: `Lint`, `Test`
- Merge заблокований при падінні CI

## Ручна верифікація на target VM

```bash
curl http://localhost/health/alive   # має повернути: OK
curl http://localhost/health/ready   # має повернути: OK
curl http://localhost/tasks          # має повернути: []
docker compose ps                   # всі сервіси Up
```

## Coverage звіт

Artifact `coverage-report` завантажується автоматично з кожного запуску CI.
Мінімальне покриття — 40%. Поточне покриття — ~61%.
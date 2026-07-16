# 🔒 Секретница (Secret Vault)

Веб-сервис для безопасного обмена конфиденциальными данными (паролями, токенами, ключами доступа) по зашифрованным одноразовым ссылкам с автоматическим удалением.

### Как работает сервис:
1. Пользователь вводит секретный текст (до 8 КБ).
2. Система генерирует уникальную ссылку с идентификатором UUID.
3. При переходе по ссылке получатель видит секрет; после исчерпания лимита просмотров (на Free — один) или истечения срока данные **удаляются из базы**.

Опционально на **Pro** можно задать **кодовое слово** (bcrypt), срок жизни ссылки и число просмотров в пределах тарифа.

### Тарифы (кратко)

| | Бесплатно | Pro |
|---|-----------|-----|
| Срок жизни ссылки | 24 часа | 1 ч — 7 дней |
| Просмотров | 1 | до 5 |
| Кодовое слово | — | да |

**Оплата Pro:** реализована через **ЮKassa** (redirect-оплата, HTTP-уведомления, сохранение карты для автопродления). Страница `/billing`, webhook `POST /webhooks/yookassa`; в production нужны ключи магазина, HTTPS webhook и cron для `Billing::RenewProSubscriptionsJob`.

Главная страница (`/`) — лендинг с блоками «как работает», сравнением тарифов и FAQ по безопасности; CTA ведёт на создание секрета без регистрации.

### Публичные legal-страницы

| URL | Содержание |
|-----|------------|
| `/privacy` | Политика конфиденциальности |
| `/terms` | Условия использования |
| `/security` | Меры безопасности, честное предупреждение про расшифровку на сервере |

Доступны без авторизации; ссылки в футере.

### Аккаунты (Devise)

- Регистрация: `/users/sign_up`, вход: `/users/sign_in`
- Гостевое создание секретов **без** входа сохранено
- У залогиненного пользователя при `create` заполняется `secrets.creator_user_id` (зарезервировано под будущие Pro-функции)
- Сброс пароля: `/users/password/new` (нужен настроенный SMTP в production)

---

## 🛠 Особенности реализации и технологии

Проект написан на **Ruby on Rails 8** с использованием современной и легковесной архитектуры:

*   **Шифрование данных:** Текст секрета шифруется алгоритмом AES-256-GCM с помощью встроенного модуля `ActiveRecord::Encryption` перед сохранением в базу. В СУБД данные хранятся в закрытом виде.
*   **Безопасные ссылки:** Вместо обычных порядковых номеров (ID) используются **UUID**, что полностью исключает возможность угадать или перебрать ссылки.
*   **Защита от конкурентных запросов:** Метод удаления данных использует транзакционную блокировку строки (`with_lock`), поэтому секрет гарантированно откроется только один раз, даже если ссылку попробуют открыть одновременно.
*   **Надежная архитектура страниц:** Логика создания ссылок работает по паттерну Post/Redirect/Get. Перезагрузка страницы (F5) на экране готовой ссылки не отправляет форму заново и не создает дубликаты в базе.
*   **Легковесный фронтенд:** Интерфейс построен на **Bootstrap 5** и шаблонизаторе **Slim**. Работа с JavaScript (кнопка копирования ссылки в буфер обмена) реализована через встроенный инструмент **Stimulus JS** без использования Node.js и папки `node_modules`.
*   **Подписка Pro:** интеграция с **ЮKassa** (`Yookassa::Client`, `Billing::Checkout`, обработка webhook, автопродление).

---

## 🚀 Инструкция по локальному запуску

### 1. Требования к системе
Убедитесь, что у вас установлены:
*   Ruby версии `3.2` или выше.
*   База данных MariaDB (или MySQL).
*   **Redis** (лимиты создания, Rack::Attack через `SecretVault::RedisClient`). Локально: `redis-server`, по умолчанию `redis://127.0.0.1:6379/0` (dev) и `/1` (test). Переопределение: `REDIS_URL`.
*   Системный пакет для сборки драйвера базы данных:
    ```bash
    sudo apt-get install libmariadb-dev
    ```

### 2. Установка проекта
Клонируйте репозиторий и установите необходимые гемы:
```bash
git clone https://github.com
cd secret_vault
bundle install
```

### 3. Настройка базы данных
Укажите доступы к вашей локальной базе в файле `config/database.yml`, после чего создайте саму базу и таблицы:
```bash
bin/rails db:create
bin/rails db:migrate
```

### 4. Ключи шифрования
Сгенерируйте три ключа:
```bash
ruby -e "require 'securerandom'; 3.times { puts SecureRandom.hex(32) }"
```
Укажите их через **переменные окружения** (рекомендуется для production) или в `bin/rails credentials:edit` под ключом `active_record_encryption`:

```yaml
active_record_encryption:
  primary_key: ...
  deterministic_key: ...
  key_derivation_salt: ...
```

```bash
export ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY="СТРОКА_1"
export ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY="СТРОКА_2"
export ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT="СТРОКА_3"
```

В development и test при отсутствии ENV/credentials используются локальные ключи из [`config/initializers/active_record_encryption.rb`](config/initializers/active_record_encryption.rb) — для production задайте свои значения обязательно.

### Переменные окружения

Скопируйте [`.env.example`](.env.example) в `.env` (файл в `.gitignore`) или задайте переменные на сервере. Альтернатива для секретов: `bin/rails credentials:edit` (`yookassa`, `active_record_encryption`).

| Переменная | Назначение |
|------------|------------|
| `YOOKASSA_SHOP_ID` | ID магазина ЮKassa |
| `YOOKASSA_SECRET_KEY` | Секретный ключ API ЮKassa |
| `YOOKASSA_RETURN_URL` | URL после оплаты (опционально; в dev обычно `http://localhost:3000/billing/return`) |
| `PRO_MONTHLY_AMOUNT_RUB` | Цена Pro в рублях (по умолчанию `299`) |
| `PRO_CURRENCY` | Валюта платежа (по умолчанию `RUB`) |
| `REDIS_URL` | Redis для Rack::Attack и лимитов создания секретов (dev: `redis://127.0.0.1:6379/0`) |
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | Шифрование секретов в БД (production обязательно) |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | то же |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | то же |
| `SECRET_VAULT_DATABASE_PASSWORD` | Пароль БД в production (`config/database.yml`) |
| `ON_PREM_SALES_EMAIL` | Только SaaS: контакт на странице «Коробочная версия» (по умолчанию `sales@example.com`) |

Коробка: `docker compose up`.

Сброс счётчиков лимитов в dev: `bin/rails runner 'SecretVault::RedisClient.flushdb'`

Webhook ЮKassa в production: `https://<домен>/webhooks/yookassa`. Локально для проверки webhook — `ngrok http 3000`; для входа и оплаты используйте один хост (`localhost` **или** `127.0.0.1`, не смешивать).

### 5. Запуск сервера
Запустите веб-сервер Puma командой:
```bash
rails s
```
Приложение будет доступно по адресу: [http://localhost:3000](http://localhost:3000)

---



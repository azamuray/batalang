# 🧠 English Battle

Многопользовательская игра для изучения английского языка, где игроки соревнуются в правильном переводе слов.

## 🚀 Возможности

- **Многопользовательская игра**: Найдите соперника и играйте в реальном времени
- **Система очков**: Первый игрок, набравший 15 очков, побеждает
- **WebSocket соединение**: Быстрая и отзывчивая игра без перезагрузки страницы
- **Система авторизации**: Безопасный вход и регистрация пользователей
- **Адаптивный дизайн**: Красивый интерфейс на всех устройствах
- **SSL сертификация**: Автоматическая настройка Let's Encrypt для продакшена

## 🛠️ Технологии

- **Backend**: Python, Flask, Flask-SocketIO
- **Frontend**: HTML, CSS (Tailwind CSS), JavaScript
- **База данных**: JSON файл со словами
- **Контейнеризация**: Docker, Docker Compose
- **Веб-сервер**: Nginx с SSL
- **SSL**: Let's Encrypt с автоматическим обновлением

## 📦 Установка и запуск

### Локальная разработка

1. **Клонируйте репозиторий**
   ```bash
   git clone <repository-url>
   cd batalang
   ```

2. **Создайте виртуальное окружение**
   ```bash
   python -m venv venv
   source venv/bin/activate  # Linux/Mac
   # или
   venv\Scripts\activate     # Windows
   ```

3. **Установите зависимости**
   ```bash
   pip install -r requirements.txt
   ```

4. **Запустите приложение**
   ```bash
   python app.py
   ```

5. **Откройте браузер**
   ```
   http://localhost:5000
   ```

### Docker (рекомендуется для продакшена)

#### Простой запуск
```bash
docker-compose up -d
```

#### Полный деплой с SSL (для продакшена)
```bash
./deploy.sh
```

## 🚀 Деплой на VPS с SSL

### Автоматический деплой (рекомендуется)
```bash
# Клонируйте репозиторий на VPS
git clone <repository-url>
cd batalang

# Запустите автоматический деплой с SSL
./deploy.sh
```

### Ручной деплой
```bash
# 1. Создайте директории для SSL
mkdir -p certbot/conf certbot/www ssl

# 2. Запустите основные сервисы
docker-compose up -d web auth

# 3. Запустите nginx с конфигурацией без SSL
docker-compose up -d nginx

# 4. Получите SSL сертификаты
docker-compose --profile init run --rm init

# 5. Переключите nginx на SSL конфигурацию
docker-compose stop nginx
docker-compose up -d nginx
```

### Простой запуск (без SSL)
```bash
docker-compose up -d
```

### Обновление
```bash
git pull
./deploy.sh
```

## 🔐 SSL сертификация

Проект автоматически настраивает SSL сертификаты Let's Encrypt:



- **Автоматическое получение** при первом деплое
- **Автоматическое обновление** каждые 90 дней
- **HTTP → HTTPS редирект** для безопасности
- **Веб-валидация** через nginx

### Требования для SSL:
- Домен `batalang.ru` должен указывать на IP вашего VPS
- Порты 80 и 443 должны быть открыты
- Доступ к интернету для Let's Encrypt

## 🔄 Процесс деплоя

### Этап 1: Инициализация
1. Запуск `web` и `auth` сервисов
2. Запуск nginx с `nginx-no-ssl.conf` (HTTP только)
3. Получение SSL сертификатов через HTTP валидацию

### Этап 2: SSL активация
1. Переключение nginx на `nginx.conf` с SSL
2. Активация HTTPS на порту 443
3. Настройка HTTP → HTTPS редиректа

### Этап 3: Автоматизация
1. Настройка автоматического обновления сертификатов
2. Мониторинг SSL статуса

## 🎮 Как играть

1. **Зарегистрируйтесь** или войдите в систему
2. **Нажмите "Найти соперника"** для поиска игры
3. **Выберите правильный перевод** для английского слова
4. **Наберите 15 очков** первым, чтобы победить!
5. **Начните новую игру** после завершения

## 📁 Структура проекта

```
batalang/
├── app.py                 # Основное Flask приложение
├── auth/                  # Модуль авторизации
├── templates/             # HTML шаблоны
│   └── index.html        # Главная страница игры
├── words.json            # База английских слов
├── requirements.txt       # Python зависимости
├── Dockerfile            # Docker образ
├── docker-compose.yml    # Docker Compose конфигурация
├── nginx.conf            # Nginx конфигурация с SSL (основная)
├── nginx-no-ssl.conf     # Nginx конфигурация без SSL (для инициализации)
├── nginx-test.conf       # Тестовая SSL конфигурация
├── init-ssl.sh           # Скрипт инициализации SSL
├── deploy.sh             # Автоматический деплой
├── fix-ssl.sh            # Исправление SSL конфигурации
├── certbot/              # SSL сертификаты (создается автоматически)
├── ssl/                  # SSL файлы (создается автоматически)
├── CHANGELOG.md          # История изменений
└── README.md             # Документация проекта
```

## 🔧 Конфигурация

### Переменные окружения

- `SECRET_KEY`: Секретный ключ для Flask (по умолчанию: 'secret!')
- `FLASK_ENV`: Окружение Flask (development/production)

### Настройка базы слов

Слова хранятся в файле `words.json` в формате:
```json
{
  "english_word": "русский_перевод",
  "hello": "привет",
  "world": "мир"
}
```

## 🛠️ Полезные команды

```bash
# Просмотр логов
docker-compose logs nginx
docker-compose logs web
docker-compose logs auth

# Перезапуск сервиса
docker-compose restart nginx

# Остановка всех сервисов
docker-compose down

# Проверка статуса
docker-compose ps

# Принудительное обновление SSL
docker-compose run --rm certbot renew --force-renewal

# Только SSL настройка
docker-compose --profile init run --rm init

# Исправление SSL конфигурации
./fix-ssl.sh
```

## 🐛 Известные проблемы

- ~~Игра не завершалась при достижении 15 очков~~ ✅ **Исправлено в v1.0.1**

## 📝 История изменений

См. [CHANGELOG.md](CHANGELOG.md) для подробной истории изменений.

## 🤝 Вклад в проект

1. Форкните репозиторий
2. Создайте ветку для новой функции (`git checkout -b feature/amazing-feature`)
3. Зафиксируйте изменения (`git commit -m 'Add amazing feature'`)
4. Отправьте в ветку (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

## 📄 Лицензия

Этот проект распространяется под лицензией MIT. См. файл `LICENSE` для подробностей.

## 📞 Поддержка

Если у вас есть вопросы или проблемы:

1. Создайте Issue в репозитории
2. Опишите проблему подробно
3. Приложите логи и скриншоты если необходимо

### Решение проблем с SSL:
```bash
# Проверить логи инициализации
docker-compose logs init

# Перезапустить SSL настройку
docker-compose --profile init run --rm init

# Проверить конфигурацию nginx
docker-compose logs nginx

# Исправить SSL конфигурацию
./fix-ssl.sh

---

**Удачной игры и успехов в изучении английского! 🎉**

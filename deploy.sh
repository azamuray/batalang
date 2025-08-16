#!/bin/bash

# Скрипт автоматического деплоя с SSL для batalang.ru

set -e

echo "🚀 Начало деплоя batalang.ru..."

# Создаем необходимые директории
echo "📁 Создание директорий..."
mkdir -p certbot/conf certbot/www ssl

# Останавливаем существующие контейнеры
echo "🛑 Остановка существующих контейнеров..."
docker-compose down

# Собираем и запускаем основные сервисы
echo "🔨 Сборка и запуск основных сервисов..."
docker-compose up -d web auth

# Ждем готовности основных сервисов
echo "⏳ Ожидание готовности основных сервисов..."
sleep 5

# Запускаем nginx с конфигурацией без SSL
echo "🌐 Запуск nginx без SSL..."
docker-compose up -d nginx

# Ждем готовности nginx
echo "⏳ Ожидание готовности nginx..."
sleep 10

# Запускаем инициализацию SSL
echo "🔐 Настройка SSL сертификатов..."
docker-compose --profile init run --rm init

# Проверяем статус
echo "✅ Проверка статуса сервисов..."
docker-compose ps

echo ""
echo "🎉 Деплой завершен!"
echo "🌐 Сайт доступен по адресу: https://batalang.ru"
echo ""
echo "📋 Логи nginx: docker-compose logs nginx"
echo "📋 Логи web: docker-compose logs web"
echo "📋 Логи auth: docker-compose logs auth"
echo ""
echo "🔄 Для обновления: ./deploy.sh"
echo "🛑 Для остановки: docker-compose down"

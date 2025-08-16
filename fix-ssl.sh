#!/bin/bash

echo "🔧 Исправление SSL конфигурации nginx..."

# Останавливаем nginx
echo "🛑 Остановка nginx..."
docker-compose stop nginx

# Копируем SSL конфигурацию
echo "📋 Копирование SSL конфигурации..."
cp nginx.conf nginx-ssl.conf
cp nginx-ssl.conf nginx.conf

# Запускаем nginx с SSL
echo "🚀 Запуск nginx с SSL..."
docker-compose up -d nginx

# Ждем готовности
echo "⏳ Ожидание готовности nginx..."
sleep 5

# Проверяем статус
echo "✅ Проверка статуса..."
docker-compose ps nginx

echo ""
echo "🎉 SSL конфигурация исправлена!"
echo "🌐 Проверьте https://batalang.ru"

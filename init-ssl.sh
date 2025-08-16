#!/bin/bash

# Скрипт для автоматической инициализации SSL сертификатов Let's Encrypt
# Работает внутри контейнера init

echo "=== Автоматическая настройка SSL для batalang.ru ==="

# Функция для ожидания готовности nginx
wait_for_nginx() {
    echo "Ожидание готовности nginx..."
    while ! curl -s http://nginx:80 > /dev/null 2>&1; do
        echo "nginx еще не готов, ожидание..."
        sleep 2
    done
    echo "nginx готов!"
}

# Функция для проверки существования сертификатов
check_certificates() {
    if [ -f "/etc/letsencrypt/live/batalang.ru/fullchain.pem" ] && [ -f "/etc/letsencrypt/live/batalang.ru/privkey.pem" ]; then
        echo "SSL сертификаты уже существуют"
        return 0
    else
        echo "SSL сертификаты не найдены, необходимо получить новые"
        return 1
    fi
}

# Функция для получения сертификатов
get_certificates() {
    echo "Получение SSL сертификатов..."
    
    # Создаем временный nginx конфиг для веб-валидации
    cat > /tmp/nginx-temp.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name batalang.ru;
        
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        location / {
            return 200 "OK";
        }
    }
}
EOF

    # Копируем временный конфиг в nginx
    cp /tmp/nginx-temp.conf /etc/nginx/nginx.conf
    
    # Перезагружаем nginx
    echo "Перезагрузка nginx для веб-валидации..."
    curl -X POST http://nginx:80/nginx-reload || true
    
    # Ждем немного
    sleep 3
    
    # Получаем сертификаты
    certbot certonly \
        --webroot \
        -w /var/www/certbot \
        --email admin@batalang.ru \
        -d batalang.ru \
        --agree-tos \
        --non-interactive \
        --force-renewal || {
        echo "Ошибка получения сертификатов"
        return 1
    }
    
    echo "Сертификаты успешно получены!"
}

# Функция для настройки cron для автоматического обновления
setup_cron() {
    echo "Настройка автоматического обновления сертификатов..."
    
    # Создаем скрипт для обновления
    cat > /update-certs.sh << 'EOF'
#!/bin/bash
cd /app
docker-compose run --rm certbot renew --quiet
docker-compose exec nginx nginx -s reload
EOF
    
    chmod +x /update-certs.sh
    
    # Добавляем в crontab (если доступен)
    if command -v crontab >/dev/null 2>&1; then
        (crontab -l 2>/dev/null; echo "0 12 * * * /update-certs.sh") | crontab -
        echo "Cron задача добавлена для обновления в 12:00 каждый день"
    else
        echo "Crontab недоступен, добавьте вручную:"
        echo "0 12 * * * cd /path/to/project && docker-compose run --rm certbot renew --quiet && docker-compose exec nginx nginx -s reload"
    fi
}

# Основная логика
main() {
    echo "Начало автоматической настройки SSL..."
    
    # Ждем готовности nginx
    wait_for_nginx
    
    # Проверяем существующие сертификаты
    if check_certificates; then
        echo "Сертификаты уже настроены, проверяем валидность..."
        
        # Проверяем срок действия сертификатов
        if certbot certificates | grep -q "VALID"; then
            echo "Сертификаты валидны, настройка завершена"
            return 0
        else
            echo "Сертификаты истекли, обновляем..."
        fi
    fi
    
    # Получаем новые сертификаты
    if get_certificates; then
        echo "SSL настройка успешно завершена!"
        echo "Сайт доступен по адресу: https://batalang.ru"
        
        # Настраиваем автоматическое обновление
        setup_cron
        
        return 0
    else
        echo "Ошибка настройки SSL"
        return 1
    fi
}

# Запуск основной логики
main "$@"

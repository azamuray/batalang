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

# Функция для получения сертификатов через certbot контейнер
get_certificates() {
    echo "Получение SSL сертификатов через certbot контейнер..."
    
    # Запускаем certbot контейнер напрямую через docker
    docker run --rm \
        --network english-battle_app-network \
        --volumes-from english-battle_nginx_1 \
        certbot/certbot \
        certonly \
        --webroot \
        -w /var/www/certbot \
        --email admin@batalang.ru \
        -d batalang.ru \
        --agree-tos \
        --non-interactive \
        --force-renewal || {
        echo "Ошибка получения сертификатов через certbot"
        return 1
    }
    
    echo "Сертификаты успешно получены!"
}

# Функция для переключения на SSL конфигурацию
switch_to_ssl() {
    echo "Переключение nginx на SSL конфигурацию..."
    
    # Копируем SSL конфигурацию
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf
    
    # Перезагружаем nginx
    echo "Перезагрузка nginx с SSL конфигурацией..."
    curl -X POST http://nginx:80/nginx-reload || true
    
    # Ждем немного для применения изменений
    sleep 3
    
    echo "Nginx переключен на SSL!"
}

# Функция для настройки автоматического обновления
setup_auto_reload() {
    echo "Настройка автоматической перезагрузки nginx..."
    
    # Создаем скрипт для обновления
    cat > /update-certs.sh << 'EOF'
#!/bin/bash
cd /app
docker-compose run --rm certbot renew --quiet
docker-compose exec nginx nginx -s reload
EOF
    
    chmod +x /update-certs.sh
    
    echo "Автоматическое обновление настроено!"
}

# Основная логика
main() {
    echo "Начало автоматической настройки SSL..."
    
    # Ждем готовности nginx (с конфигурацией без SSL)
    wait_for_nginx
    
    # Проверяем существующие сертификаты
    if check_certificates; then
        echo "Сертификаты уже настроены, проверяем валидность..."
        
        # Проверяем срок действия сертификатов
        if [ -f "/etc/letsencrypt/live/batalang.ru/fullchain.pem" ]; then
            echo "Сертификаты валидны, переключаем на SSL..."
            switch_to_ssl
            return 0
        else
            echo "Сертификаты истекли, обновляем..."
        fi
    fi
    
    # Получаем новые сертификаты
    if get_certificates; then
        echo "SSL настройка успешно завершена!"
        echo "Сайт доступен по адресу: https://batalang.ru"
        
        # Переключаем на SSL конфигурацию
        switch_to_ssl
        
        # Настраиваем автоматическое обновление
        setup_auto_reload
        
        return 0
    else
        echo "Ошибка настройки SSL"
        return 1
    fi
}

# Запуск основной логики
main "$@"

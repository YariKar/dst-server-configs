# Используем легковесный nginx образ
FROM nginx:alpine

# Устанавливаем зависимости для наблюдения за файлами (опционально)
RUN apk add --no-cache inotify-tools

# Копируем конфигурацию nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Создаем директории для статических файлов
RUN mkdir -p /usr/share/nginx/html/css \
    && mkdir -p /usr/share/nginx/html/js

# Копируем статические файлы по умолчанию
COPY index.html /usr/share/nginx/html/
COPY login.html /usr/share/nginx/html/
COPY dashboard.html /usr/share/nginx/html/
COPY css/styles.css /usr/share/nginx/html/css/
COPY js/auth.js /usr/share/nginx/html/js/
COPY config.js /usr/share/nginx/html/

# Создаем скрипт для автоматического обновления файлов при изменении
COPY reload.sh /reload.sh
RUN chmod +x /reload.sh

# Открываем порт
EXPOSE 80

# Запускаем nginx и скрипт наблюдения
CMD ["sh", "-c", "/reload.sh & nginx -g 'daemon off;'"]
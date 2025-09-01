#!/bin/sh

# Скрипт для наблюдения за изменениями файлов и их автоматического обновления

WATCH_DIR="/usr/share/nginx/html"
TMP_DIR="/tmp/nginx-html"

# Создаем временную директорию для хранения исходных файлов
mkdir -p $TMP_DIR
cp -r $WATCH_DIR/* $TMP_DIR/

echo "Starting file watcher for $WATCH_DIR..."

# Бесконечный цикл для наблюдения за изменениями
while true; do
    # Проверяем изменения каждые 2 секунды
    inotifywait -r -e modify,create,delete --exclude='\.swp|\.swx' $WATCH_DIR 2>/dev/null
    
    # Если обнаружены изменения, копируем файлы обратно
    echo "Files changed, updating..."
    cp -r $TMP_DIR/* $WATCH_DIR/
    
    # Перезагружаем nginx для применения изменений
    nginx -s reload 2>/dev/null || true
    
    # Ждем немного перед следующей проверкой
    sleep 2
done
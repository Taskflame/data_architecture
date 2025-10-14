#!/bin/bash

MAIN_SCRIPT="./main_script.sh"
# LOG_DIR="$HOME/log"
# BACKUP_DIR="$HOME/backup"

#ТОЛЬКО ДЛЯ ЛОГИНОВА:
LOG_DIR="/mnt/lab1_disk/log"
BACKUP_DIR="/mnt/lab1_disk/backup"


# echo "Очищаю тестовую среду..."
# rm -rf "$LOG_DIR" "$BACKUP_DIR"
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

echo "Создаю 5 больших файлов в $LOG_DIR..."
# for i in {1..5}; do
#   base64 /dev/urandom | head -c 5242880 > "$LOG_DIR/file_$i.log"
#   echo "Создан файл_$i.log"
# done
for i in {1..5}; do
  base64 /dev/urandom | head -c 5242880 > "$LOG_DIR/file_${i}_$(date +%s).log"
done

echo "Запускаю основной скрипт..."
bash "$MAIN_SCRIPT"

echo "Проверяю результаты..."

ARCHIVE_COUNT=$(ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
if [ "$ARCHIVE_COUNT" -ge 1 ]; then
  echo "Тест 1: архив создан."
else
  echo "Тест 1: архив не создан."
fi

LOG_COUNT=$(ls "$LOG_DIR" | wc -l)
if [ "$LOG_COUNT" -lt 5 ]; then
  echo "Тест 2: старые файлы удалены (осталось $LOG_COUNT)."
else
  echo "Тест 2: файлы не удалены."
fi

if [ -f "$BACKUP_DIR/archive.log" ]; then
  echo "Тест 3: лог архивации создан."
else
  echo "Тест 3: лог архивации отсутствует."
fi


echo "Тестирование завершено."

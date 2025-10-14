#!/bin/bash

MAIN_SCRIPT="./main_script.sh"

# ТВОИ ПУТИ (проверь, что это ровно так, без опечаток)
LOG_DIR="$HOME/log"
BACKUP_DIR="$HOME/backup"

mkdir -p "$LOG_DIR" "$BACKUP_DIR"

echo "Создаю 12 больших файлов в $LOG_DIR (по ~50MB каждый)..."
for i in {1..12}; do
  base64 /dev/urandom | head -c 52428800 > "$LOG_DIR/file_${i}_$(date +%s).log"
  echo "Создан: file_${i}_*.log"
  sleep 1
done

echo "Запускаю основной скрипт (ожидаем архивацию при THRESHOLD=20)…"
THRESHOLD=20 LOG_DIR="$LOG_DIR" BACKUP_DIR="$BACKUP_DIR" bash "$MAIN_SCRIPT"

echo "Проверяю результаты после архивации..."
ARCHIVE_COUNT=$(ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
if [ "$ARCHIVE_COUNT" -ge 1 ]; then
  echo "Тест 1: архив создан."
else
  echo "Тест 1: архив не создан."
fi

LOG_COUNT=$(ls -1 "$LOG_DIR" | wc -l)
echo "Сейчас в LOG: $LOG_COUNT файлов."

if [ -f "$BACKUP_DIR/archive.log" ]; then
  echo "Тест 2: лог архивации создан."
else
  echo "Тест 2: лог архивации отсутствует."
fi

echo "Удаляю 2 любых файла, чтобы проверить восстановление..."
DEL=($(ls -1 "$LOG_DIR" | head -n 2))
for f in "${DEL[@]}"; do
  rm -f "$LOG_DIR/$f"
  echo "Удалён: $f"
done

echo "Запускаю основной скрипт повторно (ожидаем восстановление до 5)…"
THRESHOLD=100 LOG_DIR="$LOG_DIR" BACKUP_DIR="$BACKUP_DIR" bash "$MAIN_SCRIPT"
sleep 1
sync
RESTORED_COUNT=$(ls -1 "$LOG_DIR" | wc -l)
if [ "$RESTORED_COUNT" -ge 5 ]; then
  echo "Тест 3: восстановление сработало ($RESTORED_COUNT файлов в папке)."
else
  echo "Тест 3: восстановление не выполнено (осталось $RESTORED_COUNT файлов)."
fi

echo "Тестирование завершено."
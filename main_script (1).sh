#!/bin/bash

LOG_DIR="$HOME/log"
BACKUP_DIR="$HOME/backup"

#ТОЛЬКО ДЛЯ ЛОГИНОВА:
# LOG_DIR="/mnt/lab1_disk/log"
# BACKUP_DIR="/mnt/lab1_disk/backup"


THRESHOLD=20
M=3

RESTORE_COUNT=2

mkdir -p "$LOG_DIR"
mkdir -p "$BACKUP_DIR"

# DIR_SIZE_MB=$(du -sm "$LOG_DIR" | awk '{print $1}')
# DISK_SIZE_MB=$(df -m "$LOG_DIR" | tail -1 | awk '{print $2}')
# USED_MB=$(df -m "$LOG_DIR" | tail -1 | awk '{print $3}')
# AVAIL_MB=$(df -m "$LOG_DIR" | tail -1 | awk '{print $4}')
# DISK_SIZE_MB=$((USED_MB + AVAIL_MB))
# PERCENT=$(echo "scale=2; $DIR_SIZE_MB / $DISK_SIZE_MB * 100" | bc -l 2>/dev/null)


DIR_SIZE_KB=$(du -sk "$LOG_DIR" | awk '{print $1}')
USED_KB=$(df -k "$LOG_DIR" | tail -1 | awk '{print $3}')
AVAIL_KB=$(df -k "$LOG_DIR" | tail -1 | awk '{print $4}')
DISK_SIZE_KB=$(echo "$USED_KB + $AVAIL_KB" | bc)
PERCENT=$(echo "scale=2; $DIR_SIZE_KB / $DISK_SIZE_KB * 100" | bc -l)

DIR_SIZE_MB=$(echo "scale=2; $DIR_SIZE_KB / 1024" | bc)
DISK_SIZE_MB=$(echo "scale=2; $DISK_SIZE_KB / 1024" | bc)

echo "Размер папки логов: ${DIR_SIZE_MB} МБ"
echo "Размер диска: ${DISK_SIZE_MB} МБ"
echo "Папка занимает: ${PERCENT}% от объёма диска"

if (( $(echo "$PERCENT > $THRESHOLD" | bc -l) )); then
  echo "Превышен порог ${THRESHOLD}%. Архивирую $M старых файлов..."

  FILES=$(ls -tp "$LOG_DIR" | grep -v '/$' | tail -n "$M")


  if [ -z "$FILES" ]; then
    echo "Нет файлов для архивации."
    exit 0
  fi

  ARCHIVE_NAME="log_backup_$(date +%Y-%m-%d_%H-%M-%S).tar.gz"
  ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"
  tar -czf "$ARCHIVE_PATH" -C "$LOG_DIR" $FILES

  if [ $? -eq 0 ]; then
    echo "Архив создан: $ARCHIVE_PATH"
    for f in $FILES; do
      rm -f "$LOG_DIR/$f"
      echo "Удалён: $f"
    done
  else
    echo "Ошибка при создании архива."
    exit 1
  fi

  echo "$(date '+%Y-%m-%d %H:%M:%S') — Архив: $ARCHIVE_NAME — Удалено: $M файлов — Папка занимала ${PERCENT}%" >> "$BACKUP_DIR/archive.log"
else
  echo "Размер ≤ ${THRESHOLD}%. Архивация не требуется."
fi


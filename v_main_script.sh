#!/bin/bash

# читаем пути из env, иначе дефолт к $HOME
LOG_DIR="${LOG_DIR:-$HOME/log}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/backup}"

#ТОЛЬКО ДЛЯ ЛОГИНОВА (можно раскомментировать и закрепить жестко)
# LOG_DIR="/mnt/lab1_disk/log"
# BACKUP_DIR="/mnt/lab1_disk/backup"

THRESHOLD=0.00000001
M=3
RESTORE_COUNT=2

mkdir -p "$LOG_DIR"
mkdir -p "$BACKUP_DIR"

# ------------------восстанавление--------------------
CURRENT_COUNT=$(ls -1 "$LOG_DIR" | wc -l)
DESIRED_COUNT=${DESIRED_COUNT:-5}

# если файлов больше, чем надо, удалим лишние — для демонстрации восстановления
if [ "$CURRENT_COUNT" -gt "$DESIRED_COUNT" ]; then
  TO_DELETE=$((CURRENT_COUNT - DESIRED_COUNT + 2))
  echo "Удаляю $TO_DELETE файлов, чтобы имитировать потерю..."
  ls -1 "$LOG_DIR" | head -n "$TO_DELETE" | xargs -I{} rm -f "$LOG_DIR/{}"
  CURRENT_COUNT=$(ls -1 "$LOG_DIR" | wc -l)
fi

if [ "$CURRENT_COUNT" -lt "$DESIRED_COUNT" ]; then
  echo "В логах не хватает файлов (текущие: $CURRENT_COUNT, нужно: $DESIRED_COUNT)."
  echo "Пытаюсь восстановить недостающие из последнего архива..."

  LAST_ARCHIVE=$(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -n 1)
  if [ -z "$LAST_ARCHIVE" ]; then
    echo "Нет архивов для восстановления."
    exit 0
  fi

  NEED_TO_RESTORE=$((DESIRED_COUNT - CURRENT_COUNT))
  echo "Восстанавливаю $NEED_TO_RESTORE файлов из архива: $LAST_ARCHIVE"

  FILE_LIST=$(tar -tzf "$LAST_ARCHIVE" | head -n "$NEED_TO_RESTORE")
  # shellcheck disable=SC2086
  tar -xzf "$LAST_ARCHIVE" -C "$LOG_DIR" $FILE_LIST

  if [ $? -eq 0 ]; then
    echo "Успешно восстановлено $NEED_TO_RESTORE файлов."
  else
    echo "Ошибка при восстановлении."
  fi
else
  echo "В логах достаточно файлов ($CURRENT_COUNT). Восстановление не требуется."
fi
# ------------------конец восстановления--------------------

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

  # M самых старых обычных файлов
  FILES=$(ls -tp "$LOG_DIR" | grep -v '/$' | tail -n "$M")

  if [ -z "$FILES" ]; then
    echo "Нет файлов для архивации."
    exit 0
  fi

  ARCHIVE_NAME="log_backup_$(date +%Y-%m-%d_%H-%M-%S).tar.gz"
  ARCHIVE_PATH="$BACKUP_DIR/$ARCHIVE_NAME"
  # shellcheck disable=SC2086
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
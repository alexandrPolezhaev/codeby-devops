#!/usr/bin/env bash
set -euo pipefail

folder="${HOME:?Не задана домашняя папка}/myfolder"

if [[ -L "$folder" || ( -e "$folder" && ! -d "$folder" ) ]]; then
    printf 'Ошибка: %s должен быть обычным каталогом.\n' "$folder" >&2
    exit 1
fi

# Отсутствие папки при первом запуске — нормальная ситуация.
if [[ ! -d "$folder" ]]; then
    printf 'Количество файлов: 0. Папка %s ещё не создана.\n' "$folder"
    exit 0
fi

# Считаем обычные файлы непосредственно в myfolder до удаления.
file_count=$(find "$folder" -maxdepth 1 -type f -printf '.' | wc -c)
printf 'Количество файлов: %s\n' "$file_count"

if [[ -f "$folder/file2.txt" && ! -L "$folder/file2.txt" ]]; then
    chmod 664 -- "$folder/file2.txt"
fi

find "$folder" -maxdepth 1 -type f -empty -delete
find "$folder" -maxdepth 1 -type f -exec sed -i '1!d' {} +

printf 'Пустые файлы удалены. В остальных оставлена первая строка.\n'

#!/usr/bin/env bash
set -euo pipefail

folder="${HOME:?Не задана домашняя папка}/myfolder"

# Работаем только с обычным каталогом и обычными файлами.
if [[ -L "$folder" || ( -e "$folder" && ! -d "$folder" ) ]]; then
    printf 'Ошибка: %s должен быть обычным каталогом.\n' "$folder" >&2
    exit 1
fi

mkdir -p -- "$folder"

for number in 1 2 3 4 5; do
    file="$folder/file${number}.txt"
    if [[ -L "$file" || ( -e "$file" && ! -f "$file" ) ]]; then
        printf 'Ошибка: %s должен быть обычным файлом.\n' "$file" >&2
        exit 1
    fi
done

# 10 случайных байт превращаются в 20 символов: 0-9 и a-f.
random_string=$(od -An -N10 -tx1 /dev/urandom | tr -d ' \n')

printf 'Привет!\n%s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')" > "$folder/file1.txt"
: > "$folder/file2.txt"
chmod 777 -- "$folder/file2.txt"
printf '%s\n' "$random_string" > "$folder/file3.txt"
: > "$folder/file4.txt"
: > "$folder/file5.txt"

printf 'Созданы или обновлены 5 файлов в %s\n' "$folder"

#!/usr/bin/env bash
# Создаёт пять файлов в ~/myfolder. Повторный запуск обновляет их.
# Запуск: bash script1.sh. Аргументы не требуются.
# Коды завершения: 0 — успех, 1 — ошибка команды/записи, 2 — неверный тип пути.

# Ошибки команд проверяются явно; pipefail учитывает ошибки внутри конвейера.
set -uo pipefail

readonly WORK_DIR="${HOME:?Не задана домашняя папка}/myfolder"
readonly FILE_COUNT=5
readonly GREETING='Привет!'
readonly RANDOM_BYTE_COUNT=10
readonly DATE_FORMAT='+%Y-%m-%d %H:%M:%S %Z'
readonly INITIAL_MODE='777'
readonly E_IO=1
readonly E_PATH=2

# Подготавливает каталог и проверяет типы пяти выходных файлов.
# Параметры: нет. Возврат: 0, E_IO или E_PATH.
prepare_directory() {
    local file_number file_path

    if [[ -L "$WORK_DIR" || ( -e "$WORK_DIR" && ! -d "$WORK_DIR" ) ]]; then
        printf 'Ошибка: %s должен быть обычным каталогом.\n' "$WORK_DIR" >&2
        return "$E_PATH"
    fi
    mkdir -p -- "$WORK_DIR" || return "$E_IO"

    # Не допускаем запись через символические ссылки или в специальные файлы.
    for ((file_number = 1; file_number <= FILE_COUNT; file_number++)); do
        file_path="$WORK_DIR/file${file_number}.txt"
        if [[ -L "$file_path" || ( -e "$file_path" && ! -f "$file_path" ) ]]; then
            printf 'Ошибка: %s должен быть обычным файлом.\n' "$file_path" >&2
            return "$E_PATH"
        fi
    done
    return 0
}

# Записывает содержимое файлов и задаёт права второго файла.
# Параметры: нет. Возврат: 0 или E_IO.
create_files() {
    local current_datetime random_text file_number

    # Каждый случайный байт даёт два шестнадцатеричных символа: 10 байт -> 20.
    # Источник ограничен через od; раннее закрытие бесконечного конвейера не нужно.
    random_text=$(od -An -N "$RANDOM_BYTE_COUNT" -tx1 /dev/urandom |
        tr -d ' \n') || return "$E_IO"
    if [[ ${#random_text} -ne $((RANDOM_BYTE_COUNT * 2)) ]]; then
        printf 'Ошибка: не удалось получить %s случайных символов.\n' "$((RANDOM_BYTE_COUNT * 2))" >&2
        return "$E_IO"
    fi
    # Отдельное присваивание позволяет проверить код возврата date.
    current_datetime=$(date "$DATE_FORMAT") || return "$E_IO"

    printf '%s\n%s\n' "$GREETING" "$current_datetime" > "$WORK_DIR/file1.txt" || return "$E_IO"
    : > "$WORK_DIR/file2.txt" || return "$E_IO"
    chmod "$INITIAL_MODE" -- "$WORK_DIR/file2.txt" || return "$E_IO"
    printf '%s\n' "$random_text" > "$WORK_DIR/file3.txt" || return "$E_IO"

    # Встроенная команда : с перенаправлением создаёт или очищает файл.
    for file_number in 4 5; do
        : > "$WORK_DIR/file${file_number}.txt" || return "$E_IO"
    done
    return 0
}

# Выполняет этапы по порядку, передавая код ошибки вызывающей оболочке.
# Параметры: нет. Возврат: 0, E_IO или E_PATH.
main() {
    prepare_directory || return "$?"
    create_files || return "$?"
    printf 'Созданы или обновлены %s файлов в %s\n' "$FILE_COUNT" "$WORK_DIR" || return "$E_IO"
    return 0
}

main
exit "$?"

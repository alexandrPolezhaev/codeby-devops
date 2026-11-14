#!/usr/bin/env bash
# Считает файлы в ~/myfolder, меняет права file2.txt на 664, удаляет пустые
# файлы и оставляет только первую строку в непустых. Подкаталоги не обрабатывает.
# Запуск: bash script2.sh. Повторный запуск и запуск до script1.sh допустимы.
# Коды завершения: 0 — успех, 1 — ошибка команды/доступа, 2 — неверный тип пути.

# Ошибки команд проверяются явно; pipefail учитывает ошибки внутри конвейера.
set -uo pipefail

readonly WORK_DIR="${HOME:?Не задана домашняя папка}/myfolder"
readonly SECOND_FILE="$WORK_DIR/file2.txt"
readonly CORRECT_MODE='664'
readonly E_IO=1
readonly E_PATH=2

# Проверяет, что рабочий путь не является ссылкой или посторонним файлом.
# Параметры: нет. Возврат: 0 или E_PATH. Отсутствие каталога допустимо.
validate_directory() {
    if [[ -L "$WORK_DIR" || ( -e "$WORK_DIR" && ! -d "$WORK_DIR" ) ]]; then
        printf 'Ошибка: %s должен быть обычным каталогом.\n' "$WORK_DIR" >&2
        return "$E_PATH"
    fi
    return 0
}

# Выводит количество обычных файлов непосредственно в каталоге до удаления.
# Параметры: нет. Возврат: 0 или E_IO.
show_file_count() {
    local file_count

    # Одна точка на файл: имена с пробелами и переводами строк не искажают счёт.
    file_count=$(find "$WORK_DIR" -maxdepth 1 -type f -printf '.' | wc -c) || return "$E_IO"
    printf 'Количество файлов: %s\n' "$file_count" || return "$E_IO"
    return 0
}

# Исправляет права второго файла, удаляет пустые файлы, сокращает остальные.
# Параметры: нет. Возврат: 0 или E_IO.
process_files() {
    # После первого запуска file2.txt может отсутствовать — это не ошибка.
    if [[ -f "$SECOND_FILE" && ! -L "$SECOND_FILE" ]]; then
        chmod "$CORRECT_MODE" -- "$SECOND_FILE" || return "$E_IO"
    fi

    # find учитывает скрытые файлы, не проходит по ссылкам и не обходит подкаталоги.
    find "$WORK_DIR" -maxdepth 1 -type f -empty -delete || return "$E_IO"
    # Сохраняем пакетную обработку: один вызов sed получает сразу несколько файлов.
    find "$WORK_DIR" -maxdepth 1 -type f -exec sed -i '1!d' {} + || return "$E_IO"
    return 0
}

# Выполняет этапы и передаёт код ошибки вызывающей оболочке.
# Параметры: нет. Возврат: 0, E_IO или E_PATH.
main() {
    validate_directory || return "$?"

    # Отсутствие папки при запуске script2.sh первым — штатная ситуация.
    if [[ ! -d "$WORK_DIR" ]]; then
        printf 'Количество файлов: 0. Папка %s ещё не создана.\n' "$WORK_DIR" || return "$E_IO"
        return 0
    fi

    show_file_count || return "$?"
    process_files || return "$?"
    printf 'Пустые файлы удалены. В остальных оставлена первая строка.\n' || return "$E_IO"
    return 0
}

main
exit "$?"

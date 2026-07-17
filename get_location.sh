#!/bin/bash
# Получает реальную локацию по IP через ip-api.com.
# Кеширует результат не более чем на N секунд (по умолчанию 10).
# Если запрос не удался или кеш устарел, выводит "?" – старые данные НЕ используются.
# Это гарантирует, что при смене VPN вы увидите новую локацию с задержкой не более TTL.

CACHE_FILE="/tmp/tmux_location_cache"
TTL=10   # секунд – можно уменьшить до 5, если нужно ещё быстрее, но учтите лимиты API

# Функция реального запроса к API
fetch_location() {
    command -v curl >/dev/null || return 1
    local data
    data=$(curl -s --max-time 5 http://ip-api.com/json) || return 1
    [[ -z "$data" ]] && return 1

    local status
    status=$(echo "$data" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    [[ "$status" != "success" ]] && return 1

    local city country_code
    if command -v jq >/dev/null; then
        city=$(echo "$data" | jq -r '.city')
        country_code=$(echo "$data" | jq -r '.countryCode')
    else
        city=$(echo "$data" | grep -o '"city":"[^"]*"' | cut -d'"' -f4)
        country_code=$(echo "$data" | grep -o '"countryCode":"[^"]*"' | cut -d'"' -f4)
    fi

    [[ "$city" == "St Petersburg" ]] && city="SPb"
    [[ "$city" == "null" || -z "$city" ]] && city=""
    [[ "$country_code" == "null" || -z "$country_code" ]] && country_code=""

    if [[ -n "$city" && -n "$country_code" ]]; then
        echo "$city,$country_code"
    elif [[ -n "$country_code" ]]; then
        echo "$country_code"
    else
        return 1
    fi
    return 0
}

# Проверяем, есть ли свежий кеш (моложе TTL)
if [[ -f "$CACHE_FILE" ]]; then
    cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)))
    if [[ $cache_age -lt $TTL ]]; then
        # Кеш свежий – выводим его (это актуальные данные, полученные не более TTL секунд назад)
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# Кеша нет или он устарел – делаем реальный запрос
if location=$(fetch_location); then
    # Запрос успешен – сохраняем новый кеш и выводим
    echo "$location" > "$CACHE_FILE"
    echo "$location"
else
    # Запрос не удался – НЕ используем старый кеш, а показываем "?"
    # Это гарантирует, что вы не увидите ложную локацию при проблемах с сетью или смене VPN.
    echo "?"
    # Также можно удалить устаревший кеш, чтобы при следующем вызове не было соблазна (хотя мы его всё равно не используем)
    rm -f "$CACHE_FILE" 2>/dev/null
fi

#!/bin/bash
# Fetches location from ip-api.com and formats it as "City,CountryCode"

if ! command -v curl &> /dev/null; then
    exit
fi

# Use ip-api.com as the new source
location_data=$(curl -s --max-time 5 http://ip-api.com/json)

if [ -n "$location_data" ]; then
    # Check for success status from ip-api
    status=$(echo "$location_data" | grep '"status"' | awk -F'"' '{print $4}')
    if [ "$status" != "success" ]; then
        exit
    fi

    if command -v jq &> /dev/null; then
        city=$(echo "$location_data" | jq -r '.city')
        country_code=$(echo "$location_data" | jq -r '.countryCode')
    else
        city=$(echo "$location_data" | grep '"city"' | awk -F'"' '{print $4}')
        country_code=$(echo "$location_data" | grep '"countryCode"' | awk -F'"' '{print $4}')
    fi

    # Abbreviate St Petersburg
    if [ "$city" == "St Petersburg" ]; then
        city="SPb"
    fi

    if [ -n "$city" ] && [ "$city" != "null" ] && [ -n "$country_code" ] && [ "$country_code" != "null" ]; then
        echo "$city,$country_code"
    elif [ -n "$country_code" ] && [ "$country_code" != "null" ]; then
        echo "$country_code"
    fi
fi

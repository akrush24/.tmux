#!/bin/bash
# Fetches location from ip-api.com and formats it as "City,Country"

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
        country=$(echo "$location_data" | jq -r '.country')
    else
        city=$(echo "$location_data" | grep '"city"' | awk -F'"' '{print $4}')
        country=$(echo "$location_data" | grep '"country"' | awk -F'"' '{print $4}')
    fi

    if [ -n "$city" ] && [ "$city" != "null" ] && [ -n "$country" ] && [ "$country" != "null" ]; then
        echo "$city,$country"
    elif [ -n "$country" ] && [ "$country" != "null" ]; then
        echo "$country"
    fi
fi

#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title utc
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🌏
# @raycast.packageName utc

# Documentation:
# @raycast.description display the current UTC and local time
# @raycast.author rm

printf "Week %s\n\n" "$(date +%V)" \
    && printf "UTC:\n" \
    && date -u +"%Y/%m/%d - %H:%M (%I:%M %p)" \
    && printf "\nLocal:\n" \
    && date +"%Y/%m/%d - %H:%M (%I:%M %p)"

exit 0
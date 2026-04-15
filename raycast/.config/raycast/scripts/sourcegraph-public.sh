#!/bin/bash

# Required parameters: repo
# @raycast.schemaVersion 1
# @raycast.title sourcegraph repo
# @raycast.mode silent

# Optional parameters:
# @raycast.icon icons/sourcegraph.svg
# @raycast.argument1 { "type": "text", "placeholder": "repo" }
# @raycast.argument2 { "type": "text", "placeholder": "query", "optional": true }
# @raycast.packageName sourcegraph-public

# Documentation:
# @raycast.description go directly to a repo in sourcegraph or search it
# @raycast.author rm

# Function to URL encode a string
urlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * )               printf -v o '%%%02x' "'$c"
        esac
        encoded+="${o}"
    done
    echo "${encoded}"
}

if [ -z "$2" ]; then
  URL="https://sourcegraph.com/search?q=context%3Aglobal+repo%3A${1}&patternType=keyword&sm=0&df=%5B%22type%22%2C%22Repositories%22%2C%22type%3Arepo%22%5D&__cc=1"
else
    ENCODED_QUERY=$(urlencode "$2")
    REGEX_SEARCH_URL='https://sourcegraph.com/search?patternType=regexp&q=context%3Aglobal+repo:'
    URL="${REGEX_SEARCH_URL}${1}+${ENCODED_QUERY}"
fi

open "${URL}"

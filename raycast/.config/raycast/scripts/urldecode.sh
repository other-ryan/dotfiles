#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title urldecode
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ✨
# @raycast.argument1 { "type": "text", "placeholder": "url-encoded string" }
# @raycast.packageName urldecode

# Documentation:
# @raycast.description runs urldecode {url-encoded string}
# @raycast.author rm

/usr/bin/python3 -c "import sys, urllib.parse as ul;print(ul.unquote_plus(sys.argv[1]))" ${1} | /usr/bin/pbcopy
/bin/echo "URL Decoded String: $(/usr/bin/pbpaste)"

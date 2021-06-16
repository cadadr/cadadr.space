#!/usr/bin/env bash
# htmlise.bash --- convert gmi to html

# bash strict mode
set -euo pipefail
IFS=$'\n\t'

find gemini -name '*.gmi' -exec sh -c 'gawk -v header=templates/header.html -v footer=templates/footer.html -f scripts/spaceh.awk {} > html/wormhole/$(basename -s .gmi {}).html' \;

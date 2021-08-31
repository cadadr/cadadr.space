#!/usr/bin/env bash
# htmlise.bash --- convert gmi to html

# bash strict mode
set -euo pipefail
IFS=$'\n\t'

find gemini -name '*.gmi' -exec sh -c 'gawk -v header=templates/header.html -v footer=templates/footer.html -f scripts/spaceh.awk {} > html/wormhole/$(basename -s .gmi {}).html' \;

python3 scripts/g2ra.py static \
    -u cadadr.space -a 'Göktuğ Kayaalp' -t atom -p \
    gemini/blag.gmi \
    > html/wormhole/blag.atom.xml

sed -i "/<\\/style>/a \ \ \ \ <link rel='alternate' type='application/atom+xml' href='blag.atom.xml' title='Atom feed'/>" html/wormhole/blag.html 

python3 scripts/g2ra.py static \
    -u cadadr.space -a 'Göktuğ Kayaalp' -t atom -p \
    gemini/poesy.gmi \
    > html/wormhole/poesy.atom.xml

sed -i "/<\\/style>/a \ \ \ \ <link rel='alternate' type='application/atom+xml' href='poesy.atom.xml' title='Atom feed'/>" html/wormhole/poesy.html 

python3 scripts/g2ra.py static \
    -u cadadr.space -a 'Göktuğ Kayaalp' -t atom -p \
    gemini/laurea-maestrale.gmi \
    > html/wormhole/laurea-maestrale.atom.xml

sed -i "/<\\/style>/a \ \ \ \ <link rel='alternate' type='application/atom+xml' href='laurea-maestrale.atom.xml' title='Atom feed'/>" html/wormhole/laurea-maestrale.html 


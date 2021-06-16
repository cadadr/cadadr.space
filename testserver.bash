#!/usr/bin/env bash
# testserver.bash --- run test server using jetforce

# bash strict mode
set -euo pipefail
IFS=$'\n\t'

which jetforce || pip3 install jetforce
exec jetforce --dir ./gemini/

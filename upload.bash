#!/usr/bin/env bash
# upload.bash --- upload to public server

# bash strict mode
set -euo pipefail
IFS=$'\n\t'

scp gemini/* root@cadadr.space:/var/gemini

bash ./htmlise.bash

scp -r html/* root@cadadr.space:/var/www/htdocs/cadadr.space/

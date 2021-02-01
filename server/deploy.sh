#!/bin/bash

[ "${FLOCKER}" != "$0" ] && exec env FLOCKER="$0" flock -en "$0" "$0" "$@" || :

set -eu
SCRIPT_PATH="$(realpath "$0")"
cd "$(dirname "$0")/.."

PUJAS_LIVE_DIR="/opt/pujas.live"

LOG_PREFIX="plausible-deploy-"
LOG_DIR="$PUJAS_LIVE_DIR/logs/deploy"
LOG_FILE="$LOG_PREFIX$(date +%Y-%m-%d).log"
LOG_PATH="$LOG_DIR/$LOG_FILE"
LATEST_PATH="$LOG_DIR/latest.log"

test -x /usr/bin/ts || apt-get install -yqq moreutils

mkdir -p "$LOG_DIR"

(
  echo "$SCRIPT_PATH START"

  git fetch
  git reset --hard origin/main

  docker-compose pull -q
  docker-compose up -d -t 3
  docker image prune -f

  echo "$SCRIPT_PATH END"

) 2>&1 | ts "[%Y-%m-%d %H:%M:%S]" | tee -a "$LOG_PATH"

ls -rt1 "$LOG_DIR/$LOG_PREFIX"*.log | head -n -10 | xargs --no-run-if-empty rm
ln -sf "$LOG_FILE" "$LATEST_PATH"

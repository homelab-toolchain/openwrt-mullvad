#!/bin/ash
# shellcheck shell=dash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

git pull --rebase --autostash

find . -type f -name "*.sh" -exec chmod +x {} \;

reboot
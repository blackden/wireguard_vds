#!/usr/bin/env bash
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'This script must be run as root.\n' >&2
    exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

printf '# Installing WireGuard\n'

"${SCRIPT_DIR}/20-remove.sh"
"${SCRIPT_DIR}/10-install.sh"
"${SCRIPT_DIR}/11-add-client.sh"

printf '# WireGuard installed\n'

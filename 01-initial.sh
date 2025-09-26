#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_root

log_info 'Installing WireGuard'

"${SCRIPT_DIR}/20-remove.sh"
"${SCRIPT_DIR}/10-install.sh"
"${SCRIPT_DIR}/11-add-client.sh"

log_info 'WireGuard installed'

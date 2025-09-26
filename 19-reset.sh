#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_root

if [[ ! -d /etc/wireguard ]]; then
    log_info 'WireGuard directory not found, nothing to reset.'
    exit 0
fi

log_info 'Resetting...'

cd /etc/wireguard

rm -rf ./clients
printf '1\n' > last_used_ip.var
cp -f wg0.conf.def wg0.conf

stop_wg_service
down_wg_interface

log_info 'Reset complete'

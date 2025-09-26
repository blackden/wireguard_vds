#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_root

log_info 'Removing'

down_wg_interface
stop_wg_service
disable_wg_service

DEBIAN_FRONTEND=noninteractive apt-get autoremove -y wireguard wireguard-dkms wireguard-tools || true
DEBIAN_FRONTEND=noninteractive apt-get update -y

rm -rf /etc/wireguard

log_info 'Removed'

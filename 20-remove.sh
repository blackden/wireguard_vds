#!/usr/bin/env bash
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'This script must be run as root.\n' >&2
    exit 1
fi

printf '# Removing\n'

wg-quick down wg0 || true
systemctl stop wg-quick@wg0 || true
systemctl disable wg-quick@wg0 || true

DEBIAN_FRONTEND=noninteractive apt-get autoremove -y wireguard wireguard-dkms wireguard-tools || true
DEBIAN_FRONTEND=noninteractive apt-get update -y

rm -rf /etc/wireguard

printf '# Removed\n'

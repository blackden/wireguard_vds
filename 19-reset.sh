#!/usr/bin/env bash
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'This script must be run as root.\n' >&2
    exit 1
fi

if [[ ! -d /etc/wireguard ]]; then
    printf 'WireGuard directory not found, nothing to reset.\n'
    exit 0
fi

printf '# Resetting...\n'

cd /etc/wireguard

rm -rf ./clients
printf '1\n' > last_used_ip.var
cp -f wg0.conf.def wg0.conf

systemctl stop wg-quick@wg0 || true
wg-quick down wg0 || true

printf '# Reset complete\n'

#!/usr/bin/env bash
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
    printf 'This script must be run as root.\n' >&2
    exit 1
fi

WORK_DIR=/etc/wireguard

if [[ -z "${1:-}" ]]; then
    read -r -p "Enter VPN user email: " EMAIL
    if [[ -z "${EMAIL}" ]]; then
        printf 'Empty VPN user email. Exit.\n' >&2
        exit 1
    fi
else
    EMAIL="${1}"
fi

USERNAME=$(printf '%s' "${EMAIL}" | awk -F '@' '{print $1}')
if [[ -z "${USERNAME}" ]]; then
    printf 'Failed to derive username from email %s.\n' "${EMAIL}" >&2
    exit 1
fi
printf 'Username is %s\n' "${USERNAME}"

cd "${WORK_DIR}"
umask 077

if [[ ! -f dns.var || ! -f endpoint.var || ! -f vpn_subnet.var || ! -f last_used_ip.var ]]; then
    printf 'WireGuard server has not been initialized. Please run 10-install.sh first.\n' >&2
    exit 1
fi

read -r DNS < dns.var
read -r ENDPOINT < endpoint.var
read -r VPN_SUBNET < vpn_subnet.var
PRESHARED_KEY_SUFFIX=.preshared
PRIV_KEY_SUFFIX=.key
PUB_KEY_SUFFIX=.pub
ALLOWED_IP="0.0.0.0/0"

CLIENT_DIR="clients/${USERNAME}"
mkdir -p "${CLIENT_DIR}"
chmod 700 "${CLIENT_DIR}"
cd "${CLIENT_DIR}"

CLIENT_PRESHARED_KEY=$(wg genpsk)
CLIENT_PRIVKEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(printf '%s' "${CLIENT_PRIVKEY}" | wg pubkey)

printf '%s\n' "${CLIENT_PRESHARED_KEY}" > "${USERNAME}${PRESHARED_KEY_SUFFIX}"
printf '%s\n' "${CLIENT_PRIVKEY}" > "${USERNAME}${PRIV_KEY_SUFFIX}"
printf '%s\n' "${CLIENT_PUBLIC_KEY}" > "${USERNAME}${PUB_KEY_SUFFIX}"

read -r SERVER_PUBLIC_KEY < /etc/wireguard/server.pub

read -r LAST_USED_IP < /etc/wireguard/last_used_ip.var
if [[ ! ${LAST_USED_IP} =~ ^[0-9]+$ ]]; then
    printf 'Unexpected value in last_used_ip.var: %s\n' "${LAST_USED_IP}" >&2
    exit 1
fi

if (( LAST_USED_IP >= 254 )); then
    printf 'Client IP pool is exhausted.\n' >&2
    exit 1
fi

NEXT_IP=$((LAST_USED_IP + 1))
printf '%s\n' "${NEXT_IP}" > /etc/wireguard/last_used_ip.var

CLIENT_IP="${VPN_SUBNET}${NEXT_IP}/32"

cat > "${USERNAME}.conf" <<EOF2
[Interface]
PrivateKey = ${CLIENT_PRIVKEY}
Address = ${CLIENT_IP}
DNS = ${DNS}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
PresharedKey = ${CLIENT_PRESHARED_KEY}
AllowedIPs = ${ALLOWED_IP}
Endpoint = ${ENDPOINT}
PersistentKeepalive = 25
EOF2

cat >> /etc/wireguard/wg0.conf <<EOF2

[Peer] # ${EMAIL}
PublicKey = ${CLIENT_PUBLIC_KEY}
PresharedKey = ${CLIENT_PRESHARED_KEY}
AllowedIPs = ${CLIENT_IP}
EOF2

systemctl restart wg-quick@wg0

qrencode -t ansiutf8 < "${USERNAME}.conf"

printf '# Display %s.conf\n' "${USERNAME}"
cat "${USERNAME}.conf"

qrencode -t png -o "${USERNAME}.png" < "${USERNAME}.conf"

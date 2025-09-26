#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

require_root

WORK_DIR=/etc/wireguard
FORWARD_FILE=/etc/sysctl.d/99-ip_forward.conf
DEFAULT_SERVER_ADDRESS="10.8.0.1/24"
DEFAULT_DNS="9.9.9.9"
DEFAULT_ENDPOINT_PORT=51820

mkdir -p "${WORK_DIR}"

DEBIAN_FRONTEND=noninteractive apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y wireguard-dkms wireguard-tools qrencode curl

echo "net.ipv4.ip_forward=1" > "${FORWARD_FILE}"
sysctl -p "${FORWARD_FILE}" >/dev/null

cd "${WORK_DIR}"
umask 077

if [[ -f server.key && -f server.pub ]]; then
    SERVER_PRIVKEY=$(< server.key)
    SERVER_PUBKEY=$(< server.pub)
else
    SERVER_PRIVKEY=$(wg genkey)
    SERVER_PUBKEY=$(printf '%s' "${SERVER_PRIVKEY}" | wg pubkey)
    printf '%s\n' "${SERVER_PRIVKEY}" > server.key
    printf '%s\n' "${SERVER_PUBKEY}" > server.pub
fi

WAN_IP=$(curl -fsSL --max-time 5 https://ifconfig.co 2>/dev/null || curl -fsSL --max-time 5 https://api.ipify.org 2>/dev/null || true)
DEFAULT_ENDPOINT="${WAN_IP:-0.0.0.0}:${DEFAULT_ENDPOINT_PORT}"
read -r -p "Enter the endpoint (external ip and port) in format ipv4:port [${DEFAULT_ENDPOINT}]: " ENDPOINT
ENDPOINT=${ENDPOINT:-${DEFAULT_ENDPOINT}}
if [[ ! ${ENDPOINT} =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]{1,5}$ ]]; then
    printf 'Invalid endpoint format: %s\n' "${ENDPOINT}" >&2
    exit 1
fi
printf '%s\n' "${ENDPOINT}" > endpoint.var

read -r -p "Enter the server address in the VPN subnet (CIDR format) [${DEFAULT_SERVER_ADDRESS}]: " SERVER_ADDRESS
SERVER_ADDRESS=${SERVER_ADDRESS:-${DEFAULT_SERVER_ADDRESS}}
if [[ ! ${SERVER_ADDRESS} =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}\/[0-9]{1,2}$ ]]; then
    printf 'Invalid server address format: %s\n' "${SERVER_ADDRESS}" >&2
    exit 1
fi
SERVER_IP=${SERVER_ADDRESS%%/*}
VPN_SUBNET="${SERVER_IP%.*}."
printf '%s\n' "${VPN_SUBNET}" > vpn_subnet.var

read -r -p "Enter the DNS server address [${DEFAULT_DNS}]: " DNS
DNS=${DNS:-${DEFAULT_DNS}}
printf '%s\n' "${DNS}" > dns.var

printf '1\n' > last_used_ip.var

WAN_INTERFACE_NAME=$("${SCRIPT_DIR}/detect_wan.sh")
printf '%s\n' "${WAN_INTERFACE_NAME}" > wan_interface.var

IFS=':' read -r _ SERVER_EXTERNAL_PORT <<< "${ENDPOINT}"

cat > wg0.conf.def <<EOF2
[Interface]
Address = ${SERVER_ADDRESS}
SaveConfig = false
PrivateKey = ${SERVER_PRIVKEY}
ListenPort = ${SERVER_EXTERNAL_PORT}
PostUp   = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o ${WAN_INTERFACE_NAME} -j MASQUERADE;
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o ${WAN_INTERFACE_NAME} -j MASQUERADE;
EOF2

cp -f wg0.conf.def wg0.conf

enable_wg_service

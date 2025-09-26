#!/usr/bin/env bash
set -euo pipefail

detect_default_interface() {
    ip -o route show to default 2>/dev/null | awk '{print $5}' | head -n1
}

DEFAULT_INTERFACE=$(detect_default_interface || true)

if [[ -n "${DEFAULT_INTERFACE}" ]]; then
    printf 'Detected default WAN interface: %s\n' "${DEFAULT_INTERFACE}" >&2
else
    printf 'Could not detect a default WAN interface automatically.\n' >&2
fi

read -r -p "Enter the name of the WAN network interface [${DEFAULT_INTERFACE:-manual}]: " WAN_INTERFACE_NAME

if [[ -z "${WAN_INTERFACE_NAME}" ]]; then
    WAN_INTERFACE_NAME="${DEFAULT_INTERFACE:-}"
fi

if [[ -z "${WAN_INTERFACE_NAME}" ]]; then
    printf 'WAN interface name is required.\n' >&2
    exit 1
fi

printf '%s\n' "${WAN_INTERFACE_NAME}"

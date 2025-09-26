#!/usr/bin/env bash

WIREGUARD_SERVICE="wg-quick@wg0"
WIREGUARD_INTERFACE="wg0"

require_root() {
    if [[ $(id -u) -ne 0 ]]; then
        printf 'This script must be run as root.\n' >&2
        exit 1
    fi
}

log_info() {
    printf '# %s\n' "$*"
}

log_error() {
    printf '%s\n' "$*" >&2
}

restart_wg_service() {
    systemctl restart "${WIREGUARD_SERVICE}"
}

stop_wg_service() {
    systemctl stop "${WIREGUARD_SERVICE}" || true
}

disable_wg_service() {
    systemctl disable "${WIREGUARD_SERVICE}" || true
}

down_wg_interface() {
    wg-quick down "${WIREGUARD_INTERFACE}" || true
}

enable_wg_service() {
    systemctl enable "${WIREGUARD_SERVICE}" >/dev/null
}

ensure_directory_secure() {
    local dir=$1
    mkdir -p "${dir}"
    chmod 700 "${dir}"
}

ensure_files_exist() {
    local missing=()
    for file in "$@"; do
        if [[ ! -f ${file} ]]; then
            missing+=("${file}")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        log_error "Missing required files: ${missing[*]}"
        return 1
    fi
}

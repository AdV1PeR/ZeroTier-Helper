#!/usr/bin/env bash
#
# zt — ZeroTier Helper
#
# Обёртка над zerotier-cli: сеть по умолчанию, короткие команды, проверка ID.
# По умолчанию вызывает zerotier-cli через sudo; от root — напрямую.
#
# Конфиг: ~/.config/zt/config (или $ZT_CONFIG)
#   ZT_DEFAULT_NETWORK="8056c2e21c000001"
#
# Лицензия: MIT
#
set -euo pipefail

readonly VERSION="2.0"
readonly CONFIG="${ZT_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/zt/config}"
readonly NET_ID_RE='^[0-9a-fA-F]{16}$'

if [ -r "$CONFIG" ]; then
    # shellcheck source=/dev/null
    . "$CONFIG"
fi

DEFAULT_NETWORK="${ZT_DEFAULT_NETWORK:-}"

# sudo по умолчанию; пустая строка отключает (полезно от root или в тестах)
ZT_SUDO="${ZT_SUDO-sudo}"
SUDO=()
if [ "$(id -u)" -ne 0 ] && [ -n "$ZT_SUDO" ]; then
    read -r -a SUDO <<<"$ZT_SUDO"
fi

RED='\033[0;31m'
NC='\033[0m'

die() {
    printf '%bERROR:%b %s\n' "$RED" "$NC" "$*" >&2
    exit 1
}

usage_error() {
    printf '%bERROR:%b %s\n' "$RED" "$NC" "$*" >&2
    echo "Use 'zt help' for usage information" >&2
    exit 2
}

zt() {
    if [ "${#SUDO[@]}" -gt 0 ]; then
        "${SUDO[@]}" zerotier-cli "$@"
    else
        zerotier-cli "$@"
    fi
}

require_zerotier() {
    command -v zerotier-cli >/dev/null 2>&1 \
        || die "zerotier-cli не найден. Установи ZeroTier One: https://www.zerotier.com/download/"
}

valid_id() {
    [[ "$1" =~ $NET_ID_RE ]]
}

resolve_id() {
    local id="${1:-}"
    [ -n "$id" ] || id="$DEFAULT_NETWORK"
    if [ -z "$id" ]; then
        die "Сеть не указана и сеть по умолчанию не настроена. Пример: zt join 8056c2e21c000001"
    fi
    valid_id "$id" || die "Неверный Network ID: '$id' (нужно 16 hex-символов)"
    printf '%s' "$id"
}

cmd_join() {
    local id
    id="$(resolve_id "${1:-}")"
    echo "Joining network ${id}"
    zt join "$id"
}

cmd_leave() {
    local id
    id="$(resolve_id "${1:-}")"
    echo "Leaving network ${id}"
    zt leave "$id"
}

cmd_status() {
    local id
    id="$(resolve_id "${1:-}")"
    local out
    out="$(zt listnetworks)" || die "Не удалось получить список сетей (zerotier-one запущен?)"
    if ! awk -v id="$id" '$3 == id { found = 1; print } END { exit !found }' <<<"$out"; then
        echo "Network ${id} is not joined" >&2
        return 1
    fi
}

cmd_ip() {
    local id
    id="$(resolve_id "${1:-}")"
    local out
    out="$(zt listnetworks)" || die "Не удалось получить список сетей (zerotier-one запущен?)"
    if ! awk -v id="$id" '
        $3 == id {
            for (i = 4; i <= NF; i++) {
                n = split($i, parts, ",")
                for (j = 1; j <= n; j++) {
                    if (parts[j] ~ /^[0-9a-fA-F:.]+\/[0-9]+$/) {
                        print parts[j]
                        found = 1
                    }
                }
            }
        }
        END { exit !found }
    ' <<<"$out"; then
        echo "No assigned IP for network ${id} (not joined or no lease)" >&2
        return 1
    fi
}

cmd_restart() {
    echo "Restarting ZeroTier service"
    if command -v systemctl >/dev/null 2>&1; then
        if [ "${#SUDO[@]}" -gt 0 ]; then
            "${SUDO[@]}" systemctl restart zerotier-one
        else
            systemctl restart zerotier-one
        fi
    elif command -v service >/dev/null 2>&1; then
        if [ "${#SUDO[@]}" -gt 0 ]; then
            "${SUDO[@]}" service zerotier-one restart
        else
            service zerotier-one restart
        fi
    else
        die "Не найден ни systemctl, ни service — перезапусти сервис вручную"
    fi
}

cmd_default() {
    if [ $# -eq 0 ]; then
        if [ -n "$DEFAULT_NETWORK" ]; then
            echo "$DEFAULT_NETWORK"
        else
            echo "Сеть по умолчанию не задана" >&2
            return 1
        fi
        return 0
    fi

    local id="$1"
    valid_id "$id" || die "Неверный Network ID: '$id' (нужно 16 hex-символов)"

    mkdir -p "$(dirname "$CONFIG")"
    chmod 700 "$(dirname "$CONFIG")" 2>/dev/null || true
    (
        umask 077
        printf 'ZT_DEFAULT_NETWORK="%s"\n' "$id" >"$CONFIG"
    )
    echo "Сеть по умолчанию: ${id} (${CONFIG})"
}

usage() {
    cat <<EOF
zt ${VERSION} — ZeroTier Helper

Usage: zt <command> [network-id]

Commands:
  join [id]          Join network (default: configured network)
  leave [id]         Leave network
  status [id]        Show status of one network
  ip [id]            Show assigned IP address
  default [id]       Show or set the default network
  restart            Restart the zerotier-one service
  info               Node information
  listnetworks       List all networks
  listpeers | peers  List peers
  listmoons          List moons
  dump               Debug information
  raw <args...>      Pass arguments straight to zerotier-cli
  help               This help
  version            Show version

Config: ${CONFIG}
  ZT_DEFAULT_NETWORK="8056c2e21c000001"

Переменные:
  ZT_CONFIG          путь к конфигу
  ZT_DEFAULT_NETWORK сеть по умолчанию
  ZT_SUDO            команда sudo (по умолчанию "sudo", пусто — без sudo)

Examples:
  zt join 8056c2e21c000001
  zt default 8056c2e21c000001
  zt join
  zt ip
  zt raw get 8056c2e21c000001 ipAssignments
EOF
}

main() {
    local cmd="${1:-help}"
    if [ $# -gt 0 ]; then shift; fi

    case "$cmd" in
        join)                   require_zerotier; cmd_join "$@" ;;
        leave)                  require_zerotier; cmd_leave "$@" ;;
        status)                 require_zerotier; cmd_status "$@" ;;
        ip)                     require_zerotier; cmd_ip "$@" ;;
        restart)                cmd_restart ;;
        default|set-default)    cmd_default "$@" ;;
        info|listpeers|peers|listnetworks|listmoons|dump)
                                require_zerotier; zt "$cmd" "$@" ;;
        raw|cli)                require_zerotier; zt "$@" ;;
        help|-h|--help)         usage ;;
        version|-v|--version)   echo "zt ${VERSION}" ;;
        *)                      usage_error "Unknown command: $cmd" ;;
    esac
}

main "$@"

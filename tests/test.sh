#!/usr/bin/env bash
#
# Функциональные тесты zt с подставным zerotier-cli.
# Запуск: bash tests/test.sh
#
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ZT="$ROOT/zt.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/bin"
cat >"$TMP/bin/zerotier-cli" <<'MOCK'
#!/usr/bin/env bash
case "${1:-}" in
    listnetworks)
        echo "200 listnetworks 8056c2e21c000001 My Home Network 12:34:56:78:9a:bc OK PRIVATE zt0 10.147.17.5/24,fd00::5/64"
        echo "200 listnetworks abcdefabcdefabcd Other Net 00:11:22:33:44:55 OK PUBLIC zt1 192.168.191.2/24"
        ;;
    join)  echo "200 join OK ($2)" ;;
    leave) echo "200 leave OK ($2)" ;;
    info)  echo "200 info deadbeef 1.14.0 ONLINE" ;;
    *)     echo "200 $*" ;;
esac
MOCK
chmod +x "$TMP/bin/zerotier-cli"

export PATH="$TMP/bin:$PATH"
export ZT_SUDO=""
export ZT_CONFIG="$TMP/config"

OUT=""
RC=0
FAILED=0

run() {
    OUT="$("$ZT" "$@" 2>&1)"
    RC=$?
}

expect_rc() {
    local desc="$1" want="$2"
    if [ "$RC" -ne "$want" ]; then
        printf 'FAIL: %s (rc=%s, want %s)\n%s\n' "$desc" "$RC" "$want" "$OUT"
        FAILED=$((FAILED + 1))
    else
        printf 'ok:   %s\n' "$desc"
    fi
}

expect_out() {
    local desc="$1" needle="$2"
    case "$OUT" in
        *"$needle"*) printf 'ok:   %s\n' "$desc" ;;
        *) printf 'FAIL: %s (нет "%s")\n%s\n' "$desc" "$needle" "$OUT"; FAILED=$((FAILED + 1)) ;;
    esac
}

run version
expect_rc "version" 0
expect_out "version" "zt 2.0"

run help
expect_rc "help" 0
expect_out "help" "raw <args...>"

run join
expect_rc "join без сети и без дефолта" 1
expect_out "join без сети" "не настроена"

run join 123
expect_rc "join с кривым ID" 1

run default 8056c2e21c000001
expect_rc "default set" 0
if [ "$(stat -c %a "$ZT_CONFIG" 2>/dev/null)" = "600" ]; then
    echo "ok:   конфиг 600"
else
    echo "FAIL: конфиг не 600"; FAILED=$((FAILED + 1))
fi

run join
expect_rc "join сети по умолчанию" 0
expect_out "join default id" "8056c2e21c000001"

run status
expect_rc "status default" 0
expect_out "status default" "My Home Network"

run ip
expect_rc "ip default" 0
expect_out "ip v4" "10.147.17.5/24"
expect_out "ip v6" "fd00::5/64"

run status abcdefabcdefabcd
expect_rc "status другой сети" 0
expect_out "status другая" "192.168.191.2/24"

run status ffffffffffffffff
expect_rc "status неизвестной" 1

run ip ffffffffffffffff
expect_rc "ip неизвестной" 1

run raw get 8056c2e21c000001 ipAssignments
expect_rc "raw" 0
expect_out "raw args" "200 get 8056c2e21c000001 ipAssignments"

run wat
expect_rc "неизвестная команда" 2

if [ "$FAILED" -gt 0 ]; then
    echo "Провалено: $FAILED"
    exit 1
fi
echo "Все тесты прошли"

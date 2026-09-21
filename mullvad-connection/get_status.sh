#!/bin/ash
# shellcheck shell=dash

# Read-only status probe for the LuCI UI. Unlike check_connection.sh, this never
# reboots or notifies - it only reports the current state as JSON.

set -u

CONFIG_FILE="/homelab-toolchain/config/export_openwrt_mullvad_values.sh"
LOG_FILE="/tmp/homelab-toolchain/logs/last_check.json"

EXPECTED_CITY=""
EXPECTED_COUNTRY=""
CONFIGURED="false"
if [ -r "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
    CONFIGURED="true"
fi

MULLVAD_INFO="$(curl -sSL -m 10 --retry 2 https://am.i.mullvad.net/json 2>/dev/null || echo '{}')"

IS_MULLVAD_NETWORK="$(echo "$MULLVAD_INFO" | jq -r '.mullvad_exit_ip // false')"
IP="$(echo "$MULLVAD_INFO" | jq -r '.ip // empty')"
COUNTRY="$(echo "$MULLVAD_INFO" | jq -r '.country // empty')"
CITY="$(echo "$MULLVAD_INFO" | jq -r '.city // empty')"
EXIT_HOSTNAME="$(echo "$MULLVAD_INFO" | jq -r '.mullvad_exit_ip_hostname // empty')"

CURRENT_PEER_DESCRIPTION="$(uci get network.@wireguard_wg0[0].description 2>/dev/null || echo "")"
WG_INTERFACE_PRESENT="false"
[ "$(uci get network.wg0.proto 2>/dev/null || echo "")" = "wireguard" ] && WG_INTERFACE_PRESENT="true"

MATCHES_EXPECTED="false"
if [ -n "$EXPECTED_CITY" ] && [ "$IS_MULLVAD_NETWORK" = "true" ] && [ "$CITY, $COUNTRY" = "$EXPECTED_CITY, $EXPECTED_COUNTRY" ]; then
    MATCHES_EXPECTED="true"
fi

LAST_CHECK="null"
[ -s "$LOG_FILE" ] && LAST_CHECK="$(cat "$LOG_FILE")"

cat <<EOF
{
  "configured": $CONFIGURED,
  "wg_interface_present": $WG_INTERFACE_PRESENT,
  "mullvad_exit_ip": $IS_MULLVAD_NETWORK,
  "ip": "$IP",
  "country": "$COUNTRY",
  "city": "$CITY",
  "exit_hostname": "$EXIT_HOSTNAME",
  "current_peer_description": "$CURRENT_PEER_DESCRIPTION",
  "expected_city": "$EXPECTED_CITY",
  "expected_country": "$EXPECTED_COUNTRY",
  "matches_expected": $MATCHES_EXPECTED,
  "last_check": $LAST_CHECK
}
EOF

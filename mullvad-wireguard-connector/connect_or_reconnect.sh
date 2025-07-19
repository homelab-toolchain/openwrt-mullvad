#!/bin/ash
# shellcheck shell=dash

set -eu

# ----------------------------------------------------------------------------------------------------
. /homelab-toolchain/config/export_openwrt_mullvad_values.sh
# ----------------------------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# ----------------------------------------------------------------------------------------------------
# Select server to be used
# ----------------------------------------------------------------------------------------------------
JSON_FILE="../mullvad-metadata-fetcher/fetched/active_servers/${COUNTRY_CODE}.json"
[ -s "$JSON_FILE" ] || { echo "JSON missing or empty: $JSON_FILE" >&2; exit 1; }

# Current description (used to match the hostname field)
CURRENT_DESCRIPTION="$(uci get network.@wireguard_wg0[0].description 2>/dev/null || echo "")"

# Build filtered list (TSV rows: hostname, ipv4_addr_in, pubkey)
filtered_tsv="$(
  jq -r \
    --arg city "$EXPECTED_CITY" \
    --arg country "$EXPECTED_COUNTRY" \
    --arg isOwned "$OWNED_SERVERS_ONLY" \
    '
    .[]
    | select(.city_name == $city and .country_name == $country and (.owned | tostring) == $isOwned)
    | [
        .hostname,
        .ipv4_addr_in,
        .pubkey,
        .owned
      ]
    | @tsv
    ' "$JSON_FILE"
)"

[ -n "$filtered_tsv" ] || { echo "No servers match City='$EXPECTED_CITY' and Country='$EXPECTED_COUNTRY' and IsOwned='$OWNED_SERVERS_ONLY'." >&2; exit 3; }

# Pick the "next" line based on CURRENT_DESCRIPTION (field 1), wrap around if needed.
picked_line="$(printf '%s\n' "$filtered_tsv" | awk -v cur="$CURRENT_DESCRIPTION" '
  BEGIN { idx = 0; n = 0 }
  {
    ++n; line[n] = $0
    split($0, f, "\t")
    host[n] = f[1]
    if (f[1] == cur) idx = n
  }
  END {
    if (n == 0) exit 1
    # If current found -> take next; else -> take first
    if (idx > 0) ni = (idx % n) + 1; else ni = 1
    print line[ni]
  }
')"

# Split TSV → variables
IFS="$(printf '\t')" set -- $picked_line
DESCRIPTION="$1"
ENDPOINT_HOST="$2"
PUBLIC_KEY="$3"
ENDPOINT_PORT=443
# ----------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------
# Configure WireGuard Peer
# ----------------------------------------------------------------------------------------------------
for i in $(uci show network | grep '=wireguard_wg0' | cut -d'[' -f2 | cut -d']' -f1 | sort -nr); do uci delete network.@wireguard_wg0[$i] > /dev/null 2>&1; done
uci add network wireguard_wg0 > /dev/null 2>&1
uci set network.@wireguard_wg0[0].description="$DESCRIPTION"
uci set network.@wireguard_wg0[0].endpoint_host="$ENDPOINT_HOST"
uci set network.@wireguard_wg0[0].endpoint_port="$ENDPOINT_PORT"
uci set network.@wireguard_wg0[0].public_key="$PUBLIC_KEY"
uci add_list network.@wireguard_wg0[0].allowed_ips='0.0.0.0/0'
uci add_list network.@wireguard_wg0[0].allowed_ips='::0/0'
uci set network.@wireguard_wg0[0].route_allowed_ips='1'
uci commit network
/etc/init.d/network reload
ifdown wg0 && ifup wg0
# ----------------------------------------------------------------------------------------------------

echo "Applied the following WireGuard peer: $DESCRIPTION"

# ----------------------------------------------------------------------------------------------------
. /homelab-toolchain/openwrt-mullvad/mullvad-connection/check_connection.sh
# ----------------------------------------------------------------------------------------------------
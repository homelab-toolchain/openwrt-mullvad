#!/bin/ash
# shellcheck shell=dash

# ----------------------------------------------------------------------------------------------------
# Export environment variables
# ----------------------------------------------------------------------------------------------------
. import_config_parameters.sh
# ----------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------
# Select next server
# ----------------------------------------------------------------------------------------------------
JSON_FILE="../mullvad-metadata-fetcher/fetched/active_servers/$COUNTRY_CODE.json"
CURRENT_DESCRIPTION=$(uci get network.@wireguard_wg0[0].description 2>/dev/null)
TOTAL_SERVERS=$(jq length "$JSON_FILE")

while :; do
    RANDOM_INDEX=$(shuf -i 0-$(($TOTAL_SERVERS - 1)) -n1)
    DESCRIPTION=$(jq -r ".[$RANDOM_INDEX].hostname" "$JSON_FILE")
    [ "$DESCRIPTION" != "$CURRENT_DESCRIPTION" ] && break
done

ENDPOINT_HOST=$(jq -r ".[$RANDOM_INDEX].ipv4_addr_in" "$JSON_FILE")
ENDPOINT_PORT=443
PUBLIC_KEY=$(jq -r ".[$RANDOM_INDEX].pubkey" "$JSON_FILE")
# ----------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------
# Configure Wireguard Peer
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

echo "Enabled the following wireguard peer: $DESCRIPTION"
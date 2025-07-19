#!/bin/ash
# shellcheck shell=dash

trap 'echo "Tunnel is not ok. Shutting down..."; reboot' ERR
set -e

# ----------------------------------------------------------------------------------------------------
. /homelab-toolchain/config/export_openwrt_mullvad_values.sh
# ----------------------------------------------------------------------------------------------------

MULLVAD_INFO=$(curl -s --retry 5 https://am.i.mullvad.net/json)

IS_MULLVAD_NETWORK=$(echo "$MULLVAD_INFO" | jq -r '.mullvad_exit_ip')
COUNTRY=$(echo "$MULLVAD_INFO" | jq -r '.country')
CITY=$(echo "$MULLVAD_INFO" | jq -r '.city')
HOSTNAME=$(echo "$MULLVAD_INFO" | jq -r '.mullvad_exit_ip_hostname')

CURRENT_LOCATION="$CITY, $COUNTRY"
EXPECTED_LOCATION="$EXPECTED_CITY, $EXPECTED_COUNTRY"

if [ "$IS_MULLVAD_NETWORK" != "true" ] || [ "$CURRENT_LOCATION" != "$EXPECTED_LOCATION" ]; then
    echo "Something is wrong. Rebooting..."
    reboot
else
    echo -e "There is Mullvad network! Nothing to do."

    if [ "$MONITOR_VIA_HEALTHCHECKS" == "true" ]; then
        mkdir -p /tmp/homelab-toolchain/logs
        echo -e "\n" >> /tmp/homelab-toolchain/logs/hc-ping.log
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Running health check" >> /tmp/homelab-toolchain/logs/hc-ping.log
        curl -fsS -m 10 --retry 5 https://hc-ping.com/"$HEALTHCHECKS_ID" >> /tmp/homelab-toolchain/logs/hc-ping.log 2>&1
        echo -e "\n" >> /tmp/homelab-toolchain/logs/hc-ping.log
    fi

fi
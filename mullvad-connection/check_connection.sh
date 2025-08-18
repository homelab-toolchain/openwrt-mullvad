#!/bin/ash
# shellcheck shell=dash

trap 'echo "Tunnel is not ok. Rebooting..."; reboot' ERR
set -e

MULLVAD_INFO=$(curl -s https://am.i.mullvad.net/json)

IS_MULLVAD_NETWORK=$(echo "$MULLVAD_INFO" | jq -r '.mullvad_exit_ip')
IP=$(echo "$MULLVAD_INFO" | jq -r '.ip')
COUNTRY=$(echo "$MULLVAD_INFO" | jq -r '.country')
CITY=$(echo "$MULLVAD_INFO" | jq -r '.city')

CURRENT_LOCATION="$CITY, $COUNTRY"
EXPECTED_LOCATION="Amsterdam, Netherlands"

if [ "$IS_MULLVAD_NETWORK" != "true" ]; then
    echo "Something is wrong. Rebooting..."
    reboot
else
    echo -e "There is Mullvad network!\n\nLocation: $CITY, $COUNTRY\nIP: $IP"
fi
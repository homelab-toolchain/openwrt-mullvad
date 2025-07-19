#!/bin/ash
# shellcheck shell=dash

set -eu

# ----------------------------------------------------------------------------------------------------
. /homelab-toolchain/config/export_openwrt_mullvad_values.sh
# ----------------------------------------------------------------------------------------------------

MULLVAD_LOCAL_ADDRESSES="$(curl -sSL -m 10 --retry 10 https://api.mullvad.net/wg/ \
  -d "account=$MULLVAD_LOGIN" \
  --data-urlencode "pubkey=$PERSONAL_PUBLIC_KEY")"

MULLVAD_LOCAL_IPV4="$(printf '%s' "$MULLVAD_LOCAL_ADDRESSES" | tr -d '\r' | cut -d',' -f1)"
MULLVAD_LOCAL_IPV6="$(printf '%s' "$MULLVAD_LOCAL_ADDRESSES" | tr -d '\r' | cut -d',' -f2)"

# ----------------------------------------------------------------------------------------------------

DNS_IP="10.64.0.1"

# ----------------------------------------------------------------------------------------------------

# --------------------------------
# Configure LAN Interface
# --------------------------------
echo "Configuring LAN interface..."
# Remove "Router Advertisements: Stateless Address Autoconfiguration" if exists
uci del dhcp.lan.ra_slaac > /dev/null 2>&1
# Remove "Router Advertisements (RA)" if exists
uci del dhcp.lan.ra_flags > /dev/null 2>&1
# enable "Force DHCP on this network even if another server is detected"
uci set dhcp.lan.force='1'
#uci del dhcp.lan.dhcp_option > /dev/null 2>&1
#uci add_list dhcp.lan.dhcp_option="6,$DNS_IP"
uci commit network
/etc/init.d/network restart
# --------------------------------

# --------------------------------
# Configure WAN Interface
# --------------------------------
echo "Configuring WAN interface..."
# disable "Use DNS servers advertised by peer"
uci set network.wan.peerdns='0'
uci commit network
/etc/init.d/network restart
# --------------------------------

# --------------------------------
# Create WireGuard Interface
# --------------------------------
echo "Creating WireGuard interface..."
uci set network.wg0=interface
uci set network.wg0.proto='wireguard'
uci set network.wg0.private_key="$PERSONAL_PRIVATE_KEY"
uci add_list network.wg0.addresses="$MULLVAD_LOCAL_IPV4"
uci add_list network.wg0.addresses="$MULLVAD_LOCAL_IPV6"
uci commit network
/etc/init.d/network restart
# --------------------------------

# --------------------------------
# Configure DHCP
# --------------------------------
echo "Creating DHCP..."
uci del dhcp.@dnsmasq[0].nonwildcard > /dev/null 2>&1
uci del dhcp.@dnsmasq[0].boguspriv > /dev/null 2>&1
uci del dhcp.@dnsmasq[0].filterwin2k > /dev/null 2>&1
uci del dhcp.@dnsmasq[0].filter_aaaa > /dev/null 2>&1
uci del dhcp.@dnsmasq[0].filter_a > /dev/null 2>&1
uci del dhcp.@dnsmasq[0].nonegcache > /dev/null 2>&1
uci del dhcp.@dnsmasq[0].server > /dev/null 2>&1
uci set dhcp.@dnsmasq[0].strictorder='1'
uci add_list dhcp.@dnsmasq[0].server="$DNS_IP"
uci commit dhcp
#/etc/init.d/odhcpd restart
# --------------------------------

# --------------------------------
# Configure Firewall
# --------------------------------
echo "Creating firewall..."
uci add firewall zone
uci set firewall.@zone[2].name='wireguard'
uci set firewall.@zone[2].input='REJECT'
uci set firewall.@zone[2].output='ACCEPT'
uci set firewall.@zone[2].forward='REJECT'
uci set firewall.@zone[2].masq='1'
uci set firewall.@zone[2].mtu_fix='1'
uci add_list firewall.@zone[2].network='wg0'
for i in $(uci show firewall | grep '=forwarding' | cut -d'[' -f2 | cut -d']' -f1 | sort -nr); do uci del firewall.@forwarding[$i] > /dev/null 2>&1; done
uci add firewall forwarding
uci set firewall.@forwarding[0].src='lan'
uci set firewall.@forwarding[0].dest='wireguard'
uci commit firewall
service firewall restart
# --------------------------------

# --------------------------------
# Reboot the system
# --------------------------------
echo "Rebooting..."
reboot
# --------------------------------
#!/bin/ash
# shellcheck shell=dash

# ----------------------------------------------------------------------------------------------------
. /homelab-toolchain/config/export_openwrt_mullvad_values.sh
# ----------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------
# Configure WireGuard Interface
# ----------------------------------------------------------------------------------------------------
uci set network.wg0.private_key="$PRIVATE_KEY"
uci set network.wg0.public_key="$PUBLIC_KEY"
uci delete network.wg0.addresses > /dev/null 2>&1
uci add_list network.wg0.addresses='10.67.114.172/32'
#uci add_list network.wg0.addresses='fc00:bbbb:bbbb:bb01::9:8282/128'
uci commit network
/etc/init.d/network restart
# ----------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------
# Configure DNS
# ----------------------------------------------------------------------------------------------------
DNS_IP="10.64.0.1"
uci delete dhcp.@dnsmasq[0].server > /dev/null 2>&1
uci add_list dhcp.@dnsmasq[0].server="$DNS_IP"
uci delete dhcp.lan.dhcp_option > /dev/null 2>&1
uci add_list dhcp.lan.dhcp_option="6,$DNS_IP"
uci set dhcp.lan.force='1'
uci commit dhcp
/etc/init.d/odhcpd restart
/etc/init.d/network restart
# ----------------------------------------------------------------------------------------------------
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-mullvad-wireguard
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_LICENSE:=MIT
PKG_MAINTAINER:=ahmad2702

LUCI_TITLE:=Mullvad WireGuard Manager
LUCI_DESCRIPTION:=LuCI web interface for the openwrt-mullvad toolchain: run setup, reconnect, browse Mullvad servers by country/city, and view connection status
LUCI_DEPENDS:=+luci-base +luci-proto-wireguard +wireguard-tools +curl +jq
LUCI_PKGARCH:=all

include ../../luci.mk

# call BuildPackage - OpenWrt buildroot signature

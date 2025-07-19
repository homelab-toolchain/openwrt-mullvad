<h1 align="center">OpenWrt Mullvad</h1>
<h3 align="center">Automated WireGuard control handled by OpenWrt instance</h3>
<p align="center">
<a href="#">
<img src="https://img.shields.io/github/last-commit/homelab-toolchain/openwrt-mullvad?style=for-the-badge"/>
</a>
</p>

---

## Prerequisites

1. You have your activated Mullvad account
2. Your Mullvad account contains a public key of your client to be used

---

## Introduction

The WireGuard configuration for Mullvad is based on the following guide: https://web.archive.org/web/20250830180859/https://mullvad.net/en/help/running-wireguard-router

OpenWrt 24.10.x was used to test this repository.

---

## Quick Start

**Step 1:** Install necessary packages and clone repository
```
opkg update && opkg install git git-http nano luci-proto-wireguard wireguard-tools jq coreutils-shuf
```
```
reboot
```
```
mkdir -p /homelab-toolchain && \
git clone https://github.com/homelab-toolchain/openwrt-mullvad.git /homelab-toolchain/openwrt-mullvad
```

**Step 2:** Create configuration script 
```
mkdir -p /homelab-toolchain/config && \
touch /homelab-toolchain/config/export_openwrt_mullvad_values.sh && \
chmod +x /homelab-toolchain/config/export_openwrt_mullvad_values.sh
```
```
nano /homelab-toolchain/config/export_openwrt_mullvad_values.sh
```
Add the following content with your values:
```
#!/bin/ash
# shellcheck shell=dash

# Mullvad Config Values
export MULLVAD_LOGIN=""
export PERSONAL_PRIVATE_KEY=""
export PERSONAL_PUBLIC_KEY=""
export COUNTRY_CODE=""
export EXPECTED_CITY=""
export EXPECTED_COUNTRY=""
export OWNED_SERVERS_ONLY=false

# Telegram Notification (optional)
export NOTIFY_VIA_TELEGRAM=false
export TELEGRAM_BOT_ID=""
export TELEGRAM_BOT_TOKEN=""
export TELEGRAM_CHAT_ID=""

# Healthchecks.io Monitoring (optional)
export MONITOR_VIA_HEALTHCHECKS=false
export HEALTHCHECKS_ID=""
```

**Step 3:** Init configuration
```
chmod +x /homelab-toolchain/openwrt-mullvad/init.sh && \
ash /homelab-toolchain/openwrt-mullvad/init.sh
```

**Step 4:** Setup and Run WireGuard Connection
```
ash /homelab-toolchain/openwrt-mullvad/mullvad-wireguard-connector/setup.sh
```
```
ash /homelab-toolchain/openwrt-mullvad/mullvad-wireguard-connector/connect_or_reconnect.sh
```

**Step 5:** Add cronjob tasks
```
# Init Mullvad WireGuard Updates
0 4 * * * /homelab-toolchain/openwrt-mullvad/init.sh

# Check connection and restart system if required
*/5 * * * * /homelab-toolchain/openwrt-mullvad/mullvad-connection/reboot_system_if_required.sh
```

**Step 6:** Add startup task to `/etc/rc.local`:
```
sleep 1

/homelab-toolchain/openwrt-mullvad/mullvad-wireguard-connector/connect_or_reconnect.sh

exit 0
```

---

> [!Warning]
> **Disclaimer**: This project is not affiliated with any WireGuard provider. All actions demonstrated here could have 
> been carried out by anyone and are not intended to be, nor should they be interpreted as, hacking. If certain servers 
> or functionalities do not work as expected, this repository is not responsible. For typical use cases, it is 
> recommended to use the official files and documentation provided by your chosen WireGuard provider.

---

> [!Tip]
> Do you have an idea for this to be better/faster/more useful, please create an issue.
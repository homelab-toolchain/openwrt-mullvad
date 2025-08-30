<h1 align="center">OpenWrt Mullvad</h1>

<p align="center">
<a href="#">
<img src="https://img.shields.io/github/last-commit/homelab-toolchain/openwrt-mullvad?style=for-the-badge"/>
</a>
</p>

---

## Quick Start

**Step 1:** Install `git` and clone repository
```
opkg update && opkg install git git-http
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
Add the following content with your values:
```
#!/bin/ash
# shellcheck shell=dash

# Mullvad Config Values
export PRIVATE_KEY=""
export PUBLIC_KEY=""
export COUNTRY_CODE=""
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

**Step 4:** Add cronjob to periodically pull and init repository updates
```
0 * * * * /homelab-toolchain/openwrt-mullvad/init.sh
```

---

> [!Warning]
> **Disclaimer**: This project is not affiliated with any WireGuard provider. No affiliate links are used or included in this repository.
All actions demonstrated here could have been carried out by anyone and are not intended to be, nor should they be interpreted as, hacking.
If certain servers or functionalities do not work as expected, this repository is not responsible.
For typical use cases, it is recommended to use the official files and documentation provided by your chosen WireGuard provider.

---

> [!Tip]
> Do you have an idea for this to be better/faster/more useful, please create an issue.
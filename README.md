<h1 align="center">OpenWrt Mullvad</h1>
<h3 align="center">Automated WireGuard control handled by OpenWrt instance</h3>
<p align="center">
<a href="#">
<img src="https://img.shields.io/github/last-commit/homelab-toolchain/openwrt-mullvad/main?style=for-the-badge&label=last%20update&display_timestamp=committer"/>
</a>
</p>

---

The WireGuard setup follows Mullvad's router guidance: https://web.archive.org/web/20250830180859/https://mullvad.net/en/help/running-wireguard-router

---

## What this repository provides
- `init.sh` keeps the repo up to date (including import of available servers), ensures scripts are executable, and reboots.
- `mullvad-wireguard-connector/setup.sh` configures LAN/WAN DNS behavior, creates the `wg0` interface, and sets firewall rules (reboots when finished).
- `mullvad-wireguard-connector/connect_or_reconnect.sh` selects the next Mullvad endpoint for your city/country/ownership preference, updates the WireGuard peer, and reloads networking.
- `mullvad-connection/check_connection.sh` validates the active exit IP/location and optionally notifies via Telegram and Healthchecks.io.
- `mullvad-connection/reboot_system_if_required.sh` lightweight cron-friendly check that reboots if the exit IP or location is wrong.
- `mullvad-metadata-fetcher/runner.py` refreshes the bundled Mullvad server metadata (using GitHub workflow); pre-fetched JSON lives in `mullvad-metadata-fetcher/fetched/active_servers/<country>.json`.

---

## Prerequisites
- Active Mullvad account and WireGuard key pair added to Mullvad.
- OpenWrt 24.10.x (or similar) with internet access for `opkg`.
- Ability to store the repo at `/homelab-toolchain/openwrt-mullvad` and configs at `/homelab-toolchain/config`.
- Optional: Telegram bot credentials and a Healthchecks.io ping URL for notifications.

---

## Quick start
**1) Install base packages and reboot**
```
opkg update && opkg install git git-http nano luci-proto-wireguard wireguard-tools jq coreutils-shuf
reboot
```

**2) Clone the repository**
```
mkdir -p /homelab-toolchain
git clone https://github.com/homelab-toolchain/openwrt-mullvad.git /homelab-toolchain/openwrt-mullvad
```

**3) Create your configuration file**
```
mkdir -p /homelab-toolchain/config
cat >/homelab-toolchain/config/export_openwrt_mullvad_values.sh <<'EOF'
#!/bin/ash
# shellcheck shell=dash

# Required Mullvad values
export MULLVAD_LOGIN=""           # Mullvad account number
export PERSONAL_PRIVATE_KEY=""    # WireGuard private key for the router
export PERSONAL_PUBLIC_KEY=""     # WireGuard public key registered with Mullvad
export COUNTRY_CODE=""            # e.g. nl
export EXPECTED_CITY=""           # e.g. Amsterdam
export EXPECTED_COUNTRY=""        # e.g. Netherlands
export OWNED_SERVERS_ONLY=false   # true to limit to owned servers
export MULLVAD_SERVER_PORT="51820"# typically 51820 but you can use a different port

# Telegram notification (optional)
export NOTIFY_VIA_TELEGRAM=false
export TELEGRAM_BOT_ID=""
export TELEGRAM_BOT_TOKEN=""
export TELEGRAM_CHAT_ID=""

# Healthchecks.io monitoring (optional)
export MONITOR_VIA_HEALTHCHECKS=false
export HEALTHCHECKS_ID=""
EOF
chmod +x /homelab-toolchain/config/export_openwrt_mullvad_values.sh
```

**4) Initialize the toolkit (pull latest changes, set execute bits, reboot)**
```
chmod +x /homelab-toolchain/openwrt-mullvad/init.sh
ash /homelab-toolchain/openwrt-mullvad/init.sh
```

**5) Configure WireGuard and network defaults**
```
ash /homelab-toolchain/openwrt-mullvad/mullvad-wireguard-connector/setup.sh
```

**6) Connect or rotate to the next endpoint**
```
ash /homelab-toolchain/openwrt-mullvad/mullvad-wireguard-connector/connect_or_reconnect.sh
```

---

## Automation
- Cron suggestions:
```
0 4 * * * /homelab-toolchain/openwrt-mullvad/init.sh
*/5 * * * * /homelab-toolchain/openwrt-mullvad/mullvad-connection/reboot_system_if_required.sh
```
- Add to `/etc/rc.local` to bring the tunnel up after boot:
```
sleep 1
/homelab-toolchain/openwrt-mullvad/mullvad-wireguard-connector/connect_or_reconnect.sh
exit 0
```

---

## Notes and disclaimer
- Scripts assume OpenWrt defaults; if you customized LAN/WAN heavily, review `setup.sh` before running.
- Reboots are intentional after setup and on health check failures to restore a clean state.

> [!Tip]
> **Disclaimer:** This project is not affiliated with Mullvad or any WireGuard provider. It automates tasks that could be performed manually with official tooling. If specific servers or features fail, this repository is not responsible; rely on your provider's documentation for production use.
